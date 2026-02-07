import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/producto_modelo.dart';

class InventarioRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Producto>> getProductosStream() {
    return _db
        .collection('productos')
        .orderBy('nombre')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Producto.fromFirestore(doc)).toList(),
        );
  }

  Future<void> agregarProducto(
    String nombre,
    int stock,
    double costo,
    String desc,
  ) async {
    WriteBatch batch = _db.batch();

    DocumentReference prodRef = _db.collection('productos').doc();
    batch.set(prodRef, {
      'nombre': nombre,
      'stock': stock,
      'precio_costo': costo,
      'descripcion': desc,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Kardex: Inventario Inicial
    if (stock > 0) {
      DocumentReference movRef = _db.collection('movimientos_inventario').doc();
      batch.set(movRef, {
        'productoId': prodRef.id,
        'productoNombre': nombre,
        'cantidad': stock,
        'tipo': 'ENTRADA',
        'motivo': 'INVENTARIO_INICIAL',
        'fecha': FieldValue.serverTimestamp(),
        'usuarioId': _auth.currentUser?.uid,
        'usuarioNombre': _auth.currentUser?.displayName,
      });
    }

    await batch.commit();
  }

  Future<void> updateProducto(Producto producto) async {
    await _db
        .collection('productos')
        .doc(producto.id)
        .update(producto.toFirestore());
  }

  Future<void> deleteProducto(String id) async {
    await _db.collection('productos').doc(id).delete();
  }

  // Método para añadir stock (Reposición)
  Future<void> agregarStock(
    String productoId,
    String nombre,
    int cantidad,
  ) async {
    await _db.runTransaction((transaction) async {
      DocumentReference prodRef = _db.collection('productos').doc(productoId);
      DocumentSnapshot snap = await transaction.get(prodRef);

      if (!snap.exists) return;
      int stockActual = (snap.get('stock') as num?)?.toInt() ?? 0;

      transaction.update(prodRef, {'stock': stockActual + cantidad});

      // Registro en Kardex
      DocumentReference movRef = _db.collection('movimientos_inventario').doc();
      transaction.set(movRef, {
        'productoId': productoId,
        'productoNombre': nombre,
        'cantidad': cantidad,
        'tipo': 'ENTRADA',
        'motivo': 'COMPRA_REPOSICION',
        'fecha': FieldValue.serverTimestamp(),
        'usuarioId': _auth.currentUser?.uid,
        'usuarioNombre': _auth.currentUser?.displayName,
      });
    });
  }

  // NUEVO METODO MOVIDO DESDE EL PROVIDER
  Future<void> registrarProduccionBloquero({
    required String productoId,
    required String productoNombre,
    required int cantidad,
    required DateTime fecha,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw "Usuario no identificado";

    WriteBatch batch = _db.batch();

    // 1. Referencias
    final prodRef = _db.collection('productos').doc(productoId);
    final prodRecordRef = _db.collection('registros_produccion').doc();
    final kardexRef = _db.collection('movimientos_inventario').doc();

    // 2. Operaciones
    // A: Incrementar Stock
    batch.update(prodRef, {
      'stock': FieldValue.increment(cantidad),
    });

    // B: Registro para nómina
    batch.set(prodRecordRef, {
      'trabajadorId': user.uid,
      'trabajadorNombre': user.displayName ?? 'Trabajador',
      'productoId': productoId,
      'productoNombre': productoNombre,
      'cantidad': cantidad,
      'fecha': Timestamp.fromDate(fecha),
      'pagoProcesado': false,
    });

    // C: Kardex
    batch.set(kardexRef, {
      'productoId': productoId,
      'productoNombre': productoNombre,
      'cantidad': cantidad,
      'tipo': 'ENTRADA',
      'motivo': 'PRODUCCION_INTERNA',
      'fecha': FieldValue.serverTimestamp(),
      'usuarioId': user.uid,
    });

    await batch.commit();
  }
}