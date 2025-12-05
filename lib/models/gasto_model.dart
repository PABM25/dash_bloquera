import 'package:cloud_firestore/cloud_firestore.dart';

class Gasto {
  final String id;
  final DateTime fecha;
  final String categoria; // SALARIO, MATERIAL, etc.
  final String descripcion;
  final double monto;
  final String tipoProyecto;

  Gasto({
    required this.id,
    required this.fecha,
    required this.categoria,
    required this.descripcion,
    required this.monto,
    required this.tipoProyecto,
  });

  factory Gasto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Gasto(
      id: doc.id,
      fecha: (data['fecha'] as Timestamp).toDate(),
      categoria: data['categoria'] ?? 'OTRO',
      descripcion: data['descripcion'] ?? '',
      monto: (data['monto'] ?? 0).toDouble(),
      tipoProyecto: data['tipo_proyecto'] ?? 'CONSTRUCTORA',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fecha': Timestamp.fromDate(fecha),
      'categoria': categoria,
      'descripcion': descripcion,
      'monto': monto,
      'tipo_proyecto': tipoProyecto,
    };
  }
}