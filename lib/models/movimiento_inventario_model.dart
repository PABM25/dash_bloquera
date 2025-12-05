import 'package:cloud_firestore/cloud_firestore.dart';

class MovimientoInventario {
  final String id;
  final String productoId;
  final String productoNombre;
  final int cantidad;
  final String tipo; // 'ENTRADA', 'SALIDA', 'AJUSTE'
  final String motivo; // 'COMPRA', 'VENTA', 'MERMA', 'INVENTARIO_INICIAL'
  final DateTime fecha;
  final String usuarioId;
  final String usuarioNombre;

  MovimientoInventario({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.tipo,
    required this.motivo,
    required this.fecha,
    required this.usuarioId,
    required this.usuarioNombre,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'productoId': productoId,
      'productoNombre': productoNombre,
      'cantidad': cantidad,
      'tipo': tipo,
      'motivo': motivo,
      'fecha': Timestamp.fromDate(fecha),
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
    };
  }
}
