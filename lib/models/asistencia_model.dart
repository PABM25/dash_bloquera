import 'package:cloud_firestore/cloud_firestore.dart';

class Asistencia {
  final String id;
  final String trabajadorId;
  final String nombreTrabajador; // Desnormalizado para visualización rápida
  final DateTime fecha;
  final String tipoProyecto;

  Asistencia({
    required this.id,
    required this.trabajadorId,
    required this.nombreTrabajador,
    required this.fecha,
    required this.tipoProyecto,
  });

  factory Asistencia.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Asistencia(
      id: doc.id,
      trabajadorId: data['trabajadorId'] ?? '',
      nombreTrabajador: data['nombre_trabajador'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      tipoProyecto: data['tipo_proyecto'] ?? 'CONSTRUCTORA',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'trabajadorId': trabajadorId,
      'nombre_trabajador': nombreTrabajador,
      'fecha': Timestamp.fromDate(fecha),
      'tipo_proyecto': tipoProyecto,
    };
  }
}