import 'package:cloud_firestore/cloud_firestore.dart';

class Trabajador {
  final String id;
  final String nombre;
  final String rut;
  final String? telefono;
  final String? email;
  final String? cargo;
  final String tipoProyecto; // CONSTRUCTORA o BLOQUERA
  final double salarioPorDia;

  Trabajador({
    required this.id,
    required this.nombre,
    required this.rut,
    this.telefono,
    this.email,
    this.cargo,
    required this.tipoProyecto,
    required this.salarioPorDia,
  });

  factory Trabajador.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Trabajador(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      rut: data['rut'] ?? '',
      telefono: data['telefono'],
      email: data['email'],
      cargo: data['cargo'],
      tipoProyecto: data['tipo_proyecto'] ?? 'CONSTRUCTORA',
      salarioPorDia: (data['salario_por_dia'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'rut': rut,
      'telefono': telefono,
      'email': email,
      'cargo': cargo,
      'tipo_proyecto': tipoProyecto,
      'salario_por_dia': salarioPorDia,
    };
  }
}