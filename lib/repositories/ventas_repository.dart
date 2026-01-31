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
    required DateTime fecha,
  }) async {
    try {
      await _db.runTransaction((transaction) async {
        double total = 0;
        double totalCosto = 0;

        // Listas temporales para guardar los datos leídos
        List<Map<String, dynamic>> actualizacionesStock = [];
        List<Map<String, dynamic>> movimientosKardex = [];

        // --- FASE 1: LECTURAS (Solo validaciones y cálculos) ---
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

          total += item.totalLinea;
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
            'usuarioId': _auth.currentUser?.uid,
            'usuarioNombre': _auth.currentUser?.displayName,
          });
        }

        // 3. Crear la Venta
        DocumentReference ventaRef = _db.collection('ventas').doc();
        String folio = "OC-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";

        final ventaData = {
          'folio': folio,
          'fecha': Timestamp.fromDate(fecha),
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