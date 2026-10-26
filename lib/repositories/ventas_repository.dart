import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/failure.dart';
import '../models/venta_model.dart';
import '../models/producto_modelo.dart';

class VentasRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Original stream definition with optional limit
  Stream<List<Venta>> getVentasStream({int limit = 100}) {
    return _db
        .collection('ventas')
        .orderBy('fecha', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Venta.fromFirestore(doc)).toList(),
        );
  }

  // Future for pagination
  Future<Map<String, dynamic>> getVentasPaginadas({int limit = 20, DocumentSnapshot? startAfter}) async {
    Query query = _db.collection('ventas').orderBy('fecha', descending: true).limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();

    final ventas = snap.docs.map((doc) => Venta.fromFirestore(doc)).toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;

    return {
      'ventas': ventas,
      'lastDoc': lastDoc,
    };
  }

  Future<void> crearVentaTransaccion({
    required String cliente,
    String? rut,
    String? direccion,
    required List<ItemOrden> items,
    required DateTime fecha,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Failure(message: "Sesión expirada. Vuelve a ingresar.");
    if (items.isEmpty) throw Failure(message: "La venta no tiene productos.");
    for (final item in items) {
      if (item.cantidad <= 0 || !item.precioUnitario.isFinite || item.precioUnitario <= 0) {
        throw Failure(message: "Cantidad o precio inválido en ${item.nombre}.");
      }
    }

    try {
      await _db.runTransaction((transaction) async {
        double total = 0;
        double totalCosto = 0;

        // Listas temporales para guardar los datos leídos
        List<Map<String, dynamic>> actualizacionesStock = [];
        List<Map<String, dynamic>> movimientosKardex = [];

        // --- FASE 1: LECTURAS (Solo validaciones y cálculos) ---
        final correlativosRef = _db.collection('config').doc('correlativos');
        final correlativosSnap = await transaction.get(correlativosRef);
        final int nextFolio =
            ((correlativosSnap.data()?['ventas_count'] as num?)?.toInt() ?? 0) + 1;

        for (var item in items) {
          DocumentReference prodRef = _db.collection('productos').doc(item.productoId);
          DocumentSnapshot prodSnap = await transaction.get(prodRef); // Lectura segura

          if (!prodSnap.exists) {
            throw Failure(message: "Producto no encontrado: ${item.nombre}");
          }

          Producto producto = Producto.fromFirestore(prodSnap);

          if (producto.stock < item.cantidad) {
            throw Failure(
              message: "Stock insuficiente para ${producto.nombre}. Disponible: ${producto.stock}",
            );
          }

          // Guardamos lo que haremos en la Fase 2 (sin escribir todavía)
          actualizacionesStock.add({
            'ref': prodRef,
            'nuevoStock': producto.stock - item.cantidad,
          });

          movimientosKardex.add({
            'productoId': producto.id,
            'productoNombre': producto.nombre,
            'cantidad': item.cantidad,
          });

          // El total se recalcula aquí; no se confía en totalLinea del cliente.
          total += item.precioUnitario * item.cantidad;
          totalCosto += (producto.precioCosto * item.cantidad);
        }

        // --- FASE 2: ESCRITURAS (Solo Updates y Sets) ---

        // 1. Aplicar actualizaciones de stock
        for (var update in actualizacionesStock) {
          transaction.update(update['ref'], {
            'stock': update['nuevoStock'],
          });
        }

        // 2. Registrar movimientos de inventario
        for (var mov in movimientosKardex) {
          DocumentReference movRef = _db.collection('movimientos_inventario').doc();
          transaction.set(movRef, {
            'productoId': mov['productoId'],
            'productoNombre': mov['productoNombre'],
            'cantidad': mov['cantidad'],
            'tipo': 'SALIDA',
            'motivo': 'VENTA',
            'fecha': Timestamp.fromDate(fecha),
            'usuarioId': user.uid,
            'usuarioNombre': user.displayName,
          });
        }

        // 3. Crear la Venta con folio correlativo único
        DocumentReference ventaRef = _db.collection('ventas').doc();
        final String folio = "OC-${fecha.year}-${nextFolio.toString().padLeft(5, '0')}";

        final ventaData = {
          'folio': folio,
          'fecha': Timestamp.fromDate(fecha),
          'cliente': cliente.trim(),
          'rut': rut?.trim(),
          'direccion': direccion?.trim(),
          'total': total,
          'total_costo': totalCosto,
          'total_utilidad': total - totalCosto,
          'estado_pago': 'PENDIENTE',
          'monto_pagado': 0,
          'items': items.map((i) => i.toMap()).toList(),
          'createdBy': user.uid,
          'createdByName': user.displayName,
        };

        transaction.set(ventaRef, ventaData);
        transaction.set(correlativosRef, {'ventas_count': nextFolio}, SetOptions(merge: true));
      });
    } on Failure {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint("crearVentaTransaccion: ${e.code}");
      throw Failure(message: _mensajeFirebase(e), code: e.code);
    }
  }

  // Registrar Pago: lee el estado actual dentro de una transacción
  Future<void> registrarPago(String ventaId, double monto) async {
    if (!monto.isFinite || monto <= 0) {
      throw Failure(message: "El monto debe ser mayor a 0.");
    }
    try {
      final ventaRef = _db.collection('ventas').doc(ventaId);
      await _db.runTransaction((transaction) async {
        final snap = await transaction.get(ventaRef);
        if (!snap.exists) throw Failure(message: "La venta no existe.");

        final data = snap.data()!;
        final double total = (data['total'] as num?)?.toDouble() ?? 0;
        final double pagadoActual = (data['monto_pagado'] as num?)?.toDouble() ?? 0;

        double nuevoPagado = pagadoActual + monto;
        if (nuevoPagado > total) nuevoPagado = total;

        String nuevoEstado = 'PENDIENTE';
        if (nuevoPagado >= total) {
          nuevoEstado = 'PAGADA';
        } else if (nuevoPagado > 0) {
          nuevoEstado = 'ABONADA';
        }

        transaction.update(ventaRef, {
          'monto_pagado': nuevoPagado,
          'estado_pago': nuevoEstado,
          'lastPaymentDate': FieldValue.serverTimestamp(),
          'lastPaymentBy': _auth.currentUser?.uid,
        });
      });
    } on Failure {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint("registrarPago: ${e.code}");
      throw Failure(message: _mensajeFirebase(e), code: e.code);
    }
  }

  // Mensajes genéricos: nunca se exponen detalles internos al usuario.
  String _mensajeFirebase(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return "No tienes permisos para realizar esta acción.";
      case 'unavailable':
        return "Sin conexión. Esta operación requiere internet.";
      default:
        return "No se pudo completar la operación. Intenta nuevamente.";
    }
  }
}
