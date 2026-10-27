import 'package:cloud_firestore/cloud_firestore.dart';

class Trabajador {
  static const String pagoPorDia = 'DIA';
  static const String pagoPorProduccion = 'PRODUCCION';

  final String id;
  final String nombre;
  final String rut;
  final String? telefono;
  final String? email;
  final String? cargo;
  final String tipoProyecto; // CONSTRUCTORA o BLOQUERA
  final double salarioPorDia;
  final String tipoPago; // DIA (asistencias) o PRODUCCION (unidades fabricadas)
  // Cuenta de la app vinculada (users/{uid}), si se le creó acceso.
  final String? uid;
  final bool accesoActivo;

  Trabajador({
    required this.id,
    required this.nombre,
    required this.rut,
    this.telefono,
    this.email,
    this.cargo,
    required this.tipoProyecto,
    required this.salarioPorDia,
    this.tipoPago = pagoPorDia,
    this.uid,
    this.accesoActivo = false,
  });

  bool get pagaPorProduccion => tipoPago == pagoPorProduccion;
  bool get tieneAcceso => uid != null && accesoActivo;

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
      tipoPago: data['tipo_pago'] == pagoPorProduccion ? pagoPorProduccion : pagoPorDia,
      uid: data['uid'],
      accesoActivo: data['acceso_activo'] == true,
    );
  }

  // uid y acceso_activo no van aquí: solo los cambia RhProvider al crear o
  // quitar el acceso, así editar la ficha no los pisa.
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'rut': rut,
      'telefono': telefono,
      'email': email,
      'cargo': cargo,
      'tipo_proyecto': tipoProyecto,
      'salario_por_dia': salarioPorDia,
      'tipo_pago': tipoPago,
    };
  }
}
