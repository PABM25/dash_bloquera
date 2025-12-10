import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/failure.dart';
import '../models/venta_model.dart';
import '../models/producto_modelo.dart';

class VentasRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Venta>> getVentasStream() {
    return _db
        .collection('ventas')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Venta.fromFirestore(doc)).toList(),
        );
  }

  Future<void> crearVentaTransaccion({
    required String cliente,
    String? rut,
    String? direccion,
    required List<ItemOrden> items,
    required DateTime fecha, // Nuevo parámetro de fecha
  }) async {
    try {
      await _db.runTransaction((transaction) async {
        double total = 0;
        double totalCosto = 0;

        // 1. Validaciones y Cálculos
        for (var item in items) {
          DocumentReference prodRef = _db
              .collection('productos')
              .doc(item.productoId);
          DocumentSnapshot prodSnap = await transaction.get(prodRef);

          if (!prodSnap.exists) {
            throw Failure(message: "Producto no encontrado: ${item.nombre}");
          }

          Producto producto = Producto.fromFirestore(prodSnap);

          if (producto.stock < item.cantidad) {
            throw Failure(
              message:
                  "Stock insuficiente para ${producto.nombre}. Disponible: ${producto.stock}",
            );
          }

          // Actualizar Stock
          transaction.update(prodRef, {
            'stock': producto.stock - item.cantidad,
          });

          // Registrar Movimiento de Kardex (Salida por Venta)
          DocumentReference movRef = _db
              .collection('movimientos_inventario')
              .doc();
          
          transaction.set(movRef, {
            'productoId': producto.id,
            'productoNombre': producto.nombre,
            'cantidad': item.cantidad,
            'tipo': 'SALIDA',
            'motivo': 'VENTA',
            'fecha': Timestamp.fromDate(fecha), // Usamos la fecha manual para consistencia
            'usuarioId': _auth.currentUser?.uid,
            'usuarioNombre': _auth.currentUser?.displayName,
          });

          total += item.totalLinea;
          totalCosto += (producto.precioCosto * item.cantidad);
        }

        // 2. Crear Venta
        DocumentReference ventaRef = _db.collection('ventas').doc();
        // Generamos un folio simple basado en el tiempo actual para unicidad
        String folio =
            "OC-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";

        final ventaData = {
          'folio': folio,
          'fecha': Timestamp.fromDate(fecha), // Fecha manual registrada
          'cliente': cliente,
          'rut': rut,
          'direccion': direccion,
          'total': total,
          'total_costo': totalCosto,
          'total_utilidad': total - totalCosto,
          'estado_pago': 'PENDIENTE',
          'monto_pagado': 0,
          'items': items.map((i) => i.toMap()).toList(),
          'createdBy': _auth.currentUser?.uid,
          'createdByName': _auth.currentUser?.displayName,
        };

        transaction.set(ventaRef, ventaData);
      });
    } catch (e) {
      if (e is Failure) rethrow;
      throw Failure(message: "Error al procesar venta: $e");
    }
  }

  // Registrar Pago
  Future<void> registrarPago(
    String ventaId,
    double monto,
    double pagadoActual,
    double total,
  ) async {
    try {
      DocumentReference ventaRef = _db.collection('ventas').doc(ventaId);

      double nuevoPagado = pagadoActual + monto;
      if (nuevoPagado > total) nuevoPagado = total;

      String nuevoEstado = 'PENDIENTE';
      if (nuevoPagado >= total) {
        nuevoEstado = 'PAGADA';
      } else if (nuevoPagado > 0) {
        nuevoEstado = 'ABONADA';
      }

      await ventaRef.update({
        'monto_pagado': nuevoPagado,
        'estado_pago': nuevoEstado,
        'lastPaymentDate': FieldValue.serverTimestamp(),
        'lastPaymentBy': _auth.currentUser?.uid,
      });
    } catch (e) {
      throw Failure(message: "Error al registrar pago: $e");
    }
  }
}