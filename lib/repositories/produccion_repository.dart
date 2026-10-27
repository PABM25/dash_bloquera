import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/failure.dart';
import '../models/producto_modelo.dart';
import '../models/registro_produccion_model.dart';

class ProduccionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int maxPorRegistro = 10000; // Igual que en firestore.rules

  CollectionReference<Map<String, dynamic>> get _registros =>
      _db.collection('registros_produccion');

  /// Suma [cantidad] al stock y deja el registro para el pago, en un batch
  /// (no transacción) para que funcione sin señal: se sincroniza después.
  /// Las reglas exigen que el stock suba exactamente [cantidad], que la
  /// tarifa sea la del producto y que el registro sea del propio usuario.
  ///
  /// Devuelve el Future del commit; con caché offline no termina hasta que
  /// el servidor confirma (ver guardarEnSegundoPlano).
  Future<void> registrarProduccion({
    required Producto producto,
    required int cantidad,
    required String trabajadorId,
    required String trabajadorNombre,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Failure(message: "Sesión expirada. Vuelve a ingresar.");
    if (!producto.esFabricable) {
      throw Failure(message: "${producto.nombre} no se registra como producción.");
    }
    if (cantidad <= 0 || cantidad > maxPorRegistro) {
      throw Failure(message: "La cantidad debe estar entre 1 y $maxPorRegistro.");
    }

    final tarifa = producto.tarifaProduccion!;
    final registroRef = _registros.doc();
    final batch = _db.batch();

    batch.set(registroRef, {
      'uid': user.uid,
      'trabajadorId': trabajadorId,
      'trabajadorNombre': trabajadorNombre,
      'productoId': producto.id,
      'productoNombre': producto.nombre,
      'cantidad': cantidad,
      'tarifa': tarifa,
      'monto': cantidad * tarifa,
      'fecha': FieldValue.serverTimestamp(),
      'fecha_local': Timestamp.now(),
    });
    batch.update(_db.collection('productos').doc(producto.id), {
      'stock': FieldValue.increment(cantidad),
      'ultima_produccion': registroRef.id,
    });
    batch.set(_db.collection('movimientos_inventario').doc(), {
      'productoId': producto.id,
      'productoNombre': producto.nombre,
      'cantidad': cantidad,
      'tipo': 'ENTRADA',
      'motivo': 'PRODUCCION',
      'fecha': FieldValue.serverTimestamp(),
      'usuarioId': user.uid,
      'usuarioNombre': trabajadorNombre,
    });
    await batch.commit();
  }

  /// Productos que el bloquero puede registrar (con tarifa de producción).
  Stream<List<Producto>> productosFabricablesStream() {
    return _db
        .collection('productos')
        .where('tarifa_produccion', isGreaterThan: 0)
        .snapshots()
        .map((s) => s.docs.map(Producto.fromFirestore).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre)));
  }

  /// Registros del usuario actual desde [desde] (pantalla del bloquero).
  Stream<List<RegistroProduccion>> misRegistrosStream(DateTime desde) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _registros
        .where('uid', isEqualTo: uid)
        .where('fecha_local', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .orderBy('fecha_local', descending: true)
        .snapshots()
        .map((s) => s.docs.map(RegistroProduccion.fromFirestore).toList());
  }

  /// Registros de un trabajador entre dos fechas (cálculo de salario).
  Future<List<RegistroProduccion>> registrosDeTrabajador(
    String trabajadorId,
    DateTime desde,
    DateTime hasta,
  ) async {
    final snap = await _registros
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where('fecha_local', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .where('fecha_local', isLessThan: Timestamp.fromDate(hasta))
        .orderBy('fecha_local')
        .get();
    return snap.docs.map(RegistroProduccion.fromFirestore).toList();
  }

  /// Anula un registro erróneo (solo ADMIN): lo borra y descuenta el stock
  /// que había sumado, dejando la salida en el kardex.
  Future<void> anularRegistro(RegistroProduccion r) {
    final batch = _db.batch();
    batch.delete(_registros.doc(r.id));
    batch.update(_db.collection('productos').doc(r.productoId), {
      'stock': FieldValue.increment(-r.cantidad),
    });
    batch.set(_db.collection('movimientos_inventario').doc(), {
      'productoId': r.productoId,
      'productoNombre': r.productoNombre,
      'cantidad': r.cantidad,
      'tipo': 'SALIDA',
      'motivo': 'ANULACION_PRODUCCION',
      'fecha': FieldValue.serverTimestamp(),
      'usuarioId': _auth.currentUser?.uid,
      'usuarioNombre': _auth.currentUser?.displayName,
    });
    return batch.commit();
  }
}
