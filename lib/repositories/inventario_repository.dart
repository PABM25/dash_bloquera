import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/failure.dart';
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
    String? barcode,
  ) async {
    WriteBatch batch = _db.batch();

    DocumentReference prodRef = _db.collection('productos').doc();
    batch.set(prodRef, {
      'nombre': nombre,
      'stock': stock,
      'precio_costo': costo,
      'descripcion': desc,
      'barcode': barcode,
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

  // Actualiza los datos del producto sin sobrescribir el stock. Si se pidió
  // un ajuste, se aplica como diferencia atómica y queda en el kardex, de modo
  // que las ventas hechas mientras el formulario estaba abierto no se pierden.
  Future<void> updateProducto(Producto producto, {int ajusteStock = 0}) async {
    final prodRef = _db.collection('productos').doc(producto.id);
    final datos = producto.toFirestore()..remove('stock');

    WriteBatch batch = _db.batch();
    if (ajusteStock != 0) {
      datos['stock'] = FieldValue.increment(ajusteStock);
      batch.set(_db.collection('movimientos_inventario').doc(), {
        'productoId': producto.id,
        'productoNombre': producto.nombre,
        'cantidad': ajusteStock.abs(),
        'tipo': ajusteStock > 0 ? 'ENTRADA' : 'SALIDA',
        'motivo': 'AJUSTE_MANUAL',
        'fecha': FieldValue.serverTimestamp(),
        'usuarioId': _auth.currentUser?.uid,
        'usuarioNombre': _auth.currentUser?.displayName,
      });
    }
    batch.update(prodRef, datos);
    await batch.commit();
  }

  Future<void> deleteProducto(String id) async {
    await _db.collection('productos').doc(id).delete();
  }

  // Método para buscar producto por código de barras
  Future<Producto?> getProductoByBarcode(String barcode) async {
    final query = await _db
        .collection('productos')
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return Producto.fromFirestore(query.docs.first);
  }

  Future<Producto?> getProductoById(String id) async {
    final snap = await _db.collection('productos').doc(id).get();
    if (!snap.exists) return null;
    return Producto.fromFirestore(snap);
  }

  // Entrada o salida registrada al escanear el QR de un material.
  // Transacción: la salida nunca deja el stock negativo. Devuelve el stock nuevo.
  Future<int> registrarMovimientoQr({
    required String productoId,
    required int cantidad,
    required bool esEntrada,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Failure(message: "Sesión expirada. Vuelve a ingresar.");
    if (cantidad <= 0) throw Failure(message: "La cantidad debe ser mayor a 0.");

    try {
      return await _db.runTransaction((transaction) async {
        final prodRef = _db.collection('productos').doc(productoId);
        final snap = await transaction.get(prodRef);
        if (!snap.exists) throw Failure(message: "El material ya no existe.");

        final producto = Producto.fromFirestore(snap);
        if (!esEntrada && producto.stock < cantidad) {
          throw Failure(message: "Stock insuficiente. Disponible: ${producto.stock}");
        }
        final nuevoStock = producto.stock + (esEntrada ? cantidad : -cantidad);

        transaction.update(prodRef, {'stock': nuevoStock});
        transaction.set(_db.collection('movimientos_inventario').doc(), {
          'productoId': productoId,
          'productoNombre': producto.nombre,
          'cantidad': cantidad,
          'tipo': esEntrada ? 'ENTRADA' : 'SALIDA',
          'motivo': 'ESCANEO_QR',
          'fecha': FieldValue.serverTimestamp(),
          'usuarioId': user.uid,
          'usuarioNombre': user.displayName,
        });
        return nuevoStock;
      });
    } on FirebaseException catch (e) {
      throw Failure(
        message: e.code == 'unavailable'
            ? "Sin conexión. Esta operación requiere internet."
            : "No se pudo registrar el movimiento. Intenta nuevamente.",
        code: e.code,
      );
    }
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

      if (!snap.exists) throw Failure(message: "El producto $nombre ya no existe.");
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
}
