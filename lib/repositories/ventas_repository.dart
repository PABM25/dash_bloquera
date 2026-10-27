import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/failure.dart';
import '../models/venta_model.dart';
import '../models/producto_modelo.dart';

class VentasRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Despachos: consulta propia, independiente de cuántas ventas se hayan
  // paginado en la lista. Se ordena en el cliente para no requerir un índice
  // compuesto (los pendientes son pocos).
  Stream<List<Venta>> getDespachosPendientesStream() {
    return _db
        .collection('ventas')
        .where('estado_entrega', isEqualTo: 'PENDIENTE')
        .snapshots()
        .map((snap) {
          final ventas = snap.docs.map((doc) => Venta.fromFirestore(doc)).toList();
          ventas.sort((a, b) => b.fecha.compareTo(a.fecha));
          return ventas;
        });
  }

  Future<Venta?> getVentaById(String id) async {
    final snap = await _db.collection('ventas').doc(id).get();
    if (!snap.exists) return null;
    return Venta.fromFirestore(snap);
  }

  Future<void> marcarEntrega(String ventaId, String nuevoEstado) async {
    await _db.collection('ventas').doc(ventaId).update({'estado_entrega': nuevoEstado});
  }

  // Migración única: las ventas creadas antes de guardar 'estado_entrega'
  // no aparecen en la consulta de despachos. Se les asigna PENDIENTE, que es
  // como la app ya las mostraba. Devuelve cuántas se actualizaron.
  Future<int> completarEstadoEntregaAntiguo() async {
    try {
      final snap = await _db.collection('ventas').get();
      final sinEstado = snap.docs.where((d) => !d.data().containsKey('estado_entrega')).toList();

      // Un batch admite hasta 500 escrituras.
      for (var i = 0; i < sinEstado.length; i += 450) {
        final batch = _db.batch();
        for (final doc in sinEstado.skip(i).take(450)) {
          batch.update(doc.reference, {'estado_entrega': 'PENDIENTE'});
        }
        await batch.commit();
      }
      return sinEstado.length;
    } on FirebaseException catch (e) {
      debugPrint("completarEstadoEntregaAntiguo: ${e.code}");
      throw Failure(message: _mensajeFirebase(e), code: e.code);
    }
  }

  // Lectura única (sin escucha en tiempo real) para exportar reportes.
  Future<List<Venta>> getTodasLasVentas() async {
    final snap = await _db.collection('ventas').orderBy('fecha', descending: true).get();
    return snap.docs.map((doc) => Venta.fromFirestore(doc)).toList();
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
    required double tasaIva,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Failure(message: "Sesión expirada. Vuelve a ingresar.");
    if (items.isEmpty) throw Failure(message: "La venta no tiene productos.");
    if (!tasaIva.isFinite || tasaIva < 0 || tasaIva > 1) {
      throw Failure(message: "Tasa de IVA inválida.");
    }
    for (final item in items) {
      if (item.cantidad <= 0 || !item.precioUnitario.isFinite || item.precioUnitario <= 0) {
        throw Failure(message: "Cantidad o precio inválido en ${item.nombre}.");
      }
    }

    try {
      await _db.runTransaction((transaction) async {
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

          totalCosto += (producto.precioCosto * item.cantidad);
        }

        // Los totales se recalculan aquí; no se confía en totalLinea del cliente.
        final totales = TotalesOrden.calcular(items, tasaIva);

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
          'neto': totales.neto,
          'iva': totales.iva,
          'tasa_iva': tasaIva,
          'total': totales.total,
          'total_costo': totalCosto,
          // La utilidad se mide sobre el neto: el IVA no es ingreso.
          'total_utilidad': totales.neto - totalCosto,
          'estado_pago': 'PENDIENTE',
          'estado_entrega': 'PENDIENTE',
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
