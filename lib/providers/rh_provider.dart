import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/trabajador_model.dart';


class RhProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- TRABAJADORES ---
  Stream<List<Trabajador>> get trabajadoresStream {
    return _db.collection('trabajadores').orderBy('nombre').snapshots().map(
      (snap) => snap.docs.map((doc) => Trabajador.fromFirestore(doc)).toList(),
    );
  }

  Future<void> saveTrabajador(Trabajador t) async {
    if (t.id.isEmpty) {
      await _db.collection('trabajadores').add(t.toFirestore());
    } else {
      await _db.collection('trabajadores').doc(t.id).update(t.toFirestore());
    }
  }

  Future<void> deleteTrabajador(String id) async {
    await _db.collection('trabajadores').doc(id).delete();
  }

  // --- ASISTENCIA ---
  
  // Registrar asistencia validando duplicados (Logica de tu view 'asistencia_manual')
  Future<String?> registrarAsistencia(String trabajadorId, String nombre, DateTime fecha, String tipoProyecto) async {
    // Normalizar fecha (sin horas) para buscar
    DateTime inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
    DateTime finDia = inicioDia.add(const Duration(days: 1));

    // Buscar si ya existe asistencia ese día
    final query = await _db.collection('asistencias')
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fecha', isLessThan: Timestamp.fromDate(finDia))
        .get();

    if (query.docs.isNotEmpty) {
      return "Este trabajador ya tiene asistencia registrada hoy.";
    }

    await _db.collection('asistencias').add({
      'trabajadorId': trabajadorId,
      'nombre_trabajador': nombre, // Desnormalizado para lista rápida
      'fecha': Timestamp.fromDate(fecha),
      'tipo_proyecto': tipoProyecto,
    });
    return null;
  }

  // --- CÁLCULO DE SALARIOS ---
  
  // Calcula el salario basado en asistencias en un rango (como tu 'calcular_salario')
  Future<Map<String, dynamic>> calcularSalario(String trabajadorId, double salarioDiario, DateTime inicio, DateTime fin) async {
    final query = await _db.collection('asistencias')
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(fin))
        .get();

    int diasTrabajados = query.docs.length;
    double totalPagar = diasTrabajados * salarioDiario;

    return {
      'dias': diasTrabajados,
      'total': totalPagar,
    };
  }
}