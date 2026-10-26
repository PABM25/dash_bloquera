import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/failure.dart';
import '../models/compra_model.dart';
import '../providers/inventario_provider.dart';

class ComprasProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ComprasProvider(InventarioProvider invProvider);

  Stream<List<Compra>> get comprasStream {
    return _db.collection('compras').orderBy('fecha', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Compra.fromFirestore(doc)).toList();
    });
  }

  // Compra, stock, kardex y gasto se escriben en UNA transacción:
  // o se aplica todo o no se aplica nada.
  Future<void> registrarCompra({
    required String proveedorId,
    required String proveedorNombre,
    required List<CompraItem> items,
    required DateTime fecha,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Failure(message: "Sesión expirada. Vuelve a ingresar.");
    if (items.isEmpty) throw Failure(message: "La compra no tiene productos.");
    for (final item in items) {
      if (item.cantidad <= 0 || !item.costoUnitario.isFinite || item.costoUnitario <= 0) {
        throw Failure(message: "Cantidad o costo inválido en ${item.nombre}.");
      }
    }

    // El total se recalcula aquí; no se confía en totalLinea del cliente.
    final double total =
        items.fold(0.0, (sum, item) => sum + item.cantidad * item.costoUnitario);

    try {
      await _db.runTransaction((transaction) async {
        // --- FASE 1: LECTURAS ---
        final correlativosRef = _db.collection('config').doc('correlativos');
        final correlativosSnap = await transaction.get(correlativosRef);
        final int nextFolio =
            ((correlativosSnap.data()?['compras_count'] as num?)?.toInt() ?? 0) + 1;

        for (final item in items) {
          final pSnap = await transaction.get(_db.collection('productos').doc(item.productoId));
          if (!pSnap.exists) {
            throw Failure(message: "Producto no encontrado: ${item.nombre}");
          }
        }

        // --- FASE 2: ESCRITURAS ---
        final docRef = _db.collection('compras').doc();
        final String folio = "COM-${fecha.year}-${nextFolio.toString().padLeft(5, '0')}";

        final compra = Compra(
          id: docRef.id,
          folio: folio,
          proveedorId: proveedorId,
          proveedorNombre: proveedorNombre,
          fecha: fecha,
          total: total,
          items: items,
        );
        transaction.set(docRef, compra.toFirestore());

        for (final item in items) {
          transaction.update(_db.collection('productos').doc(item.productoId), {
            'stock': FieldValue.increment(item.cantidad),
          });
          transaction.set(_db.collection('movimientos_inventario').doc(), {
            'productoId': item.productoId,
            'productoNombre': item.nombre,
            'cantidad': item.cantidad,
            'tipo': 'ENTRADA',
            'motivo': 'COMPRA_PROVEEDOR',
            'referenciaId': docRef.id,
            'fecha': Timestamp.fromDate(fecha),
            'usuarioId': user.uid,
            'usuarioNombre': user.displayName,
          });
        }

        // Registrar como gasto con los mismos campos que usa el modelo Gasto
        transaction.set(_db.collection('gastos').doc(), {
          'descripcion': 'Compra $folio a $proveedorNombre',
          'monto': total,
          'categoria': 'MATERIAL',
          'tipo_proyecto': 'BLOQUERA',
          'fecha': Timestamp.fromDate(fecha),
          'referenciaId': docRef.id,
        });

        transaction.set(correlativosRef, {'compras_count': nextFolio}, SetOptions(merge: true));
      });
    } on Failure {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint("registrarCompra: ${e.code}");
      throw Failure(
        message: e.code == 'permission-denied'
            ? "No tienes permisos para registrar compras."
            : "No se pudo registrar la compra. Intenta nuevamente.",
        code: e.code,
      );
    }

    notifyListeners();
  }
}
