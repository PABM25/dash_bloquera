import 'package:cloud_firestore/cloud_firestore.dart';

/// Unidades fabricadas por un trabajador pagado por producción.
class RegistroProduccion {
  final String id;
  final String uid;
  final String trabajadorId;
  final String trabajadorNombre;
  final String productoId;
  final String productoNombre;
  final int cantidad;
  final double tarifa; // Pago por unidad vigente al registrar
  final double monto;
  final DateTime fecha;
  // Guardado en el teléfono pero aún sin confirmar por el servidor.
  final bool pendiente;

  RegistroProduccion({
    required this.id,
    required this.uid,
    required this.trabajadorId,
    required this.trabajadorNombre,
    required this.productoId,
    required this.productoNombre,
    required this.cantidad,
    required this.tarifa,
    required this.monto,
    required this.fecha,
    this.pendiente = false,
  });

  factory RegistroProduccion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // 'fecha' es la hora del servidor; mientras se sincroniza (sin conexión)
    // vale null y se usa la hora del teléfono.
    final fecha = (data['fecha'] as Timestamp?) ?? (data['fecha_local'] as Timestamp?);
    return RegistroProduccion(
      id: doc.id,
      uid: data['uid'] ?? '',
      trabajadorId: data['trabajadorId'] ?? '',
      trabajadorNombre: data['trabajadorNombre'] ?? '',
      productoId: data['productoId'] ?? '',
      productoNombre: data['productoNombre'] ?? '',
      cantidad: (data['cantidad'] as num?)?.toInt() ?? 0,
      tarifa: (data['tarifa'] as num?)?.toDouble() ?? 0,
      monto: (data['monto'] as num?)?.toDouble() ?? 0,
      fecha: fecha?.toDate() ?? DateTime.now(),
      pendiente: data['fecha'] == null,
    );
  }
}
