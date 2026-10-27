import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/failure.dart';
import '../models/trabajador_model.dart';
import '../utils/shared_stream.dart';


class RhProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// --- TRABAJADORES ---
  late final SharedStream<List<Trabajador>> _trabajadores = SharedStream(
    () => _db.collection('trabajadores').orderBy('nombre').snapshots().map(
      (snap) => snap.docs.map((doc) => Trabajador.fromFirestore(doc)).toList(),
    ),
  );

  Stream<List<Trabajador>> get trabajadoresStream => _trabajadores.stream;

  // Guardar/Actualizar trabajador existente (sin tocar Auth)
  Future<void> saveTrabajador(Trabajador t) async {
    if (t.id.isEmpty) {
      await _db.collection('trabajadores').add(t.toFirestore());
    } else {
      await _db.collection('trabajadores').doc(t.id).update(t.toFirestore());
    }
  }

  Future<void> deleteTrabajador(String id) async {
    // Evita que un administrador se quite el acceso a sí mismo.
    if (id == FirebaseAuth.instance.currentUser?.uid) {
      throw Failure(message: "No puedes eliminar tu propia ficha.");
    }

    // Nota: Esto borra la ficha de RRHH, pero NO borra el usuario de Auth
    // (Borrar de Auth requiere Cloud Functions o re-autenticación admin).
    // Si el trabajador tiene cuenta, se le quita el acceso en el mismo batch
    // (las reglas niegan todo a DESACTIVADO). Para bloquear también el login,
    // deshabilitar la cuenta en Firebase Auth.
    final userRef = _db.collection('users').doc(id);
    final userSnap = await userRef.get();

    final batch = _db.batch();
    batch.delete(_db.collection('trabajadores').doc(id));
    if (userSnap.exists) {
      batch.update(userRef, {'role': 'DESACTIVADO'});
    }
    await batch.commit();
  }


  // --- ASISTENCIA ---

  static DateTime _inicioDelDia(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  // Registrar asistencia validando duplicados (Logica de tu view 'asistencia_manual')
  Future<String?> registrarAsistencia(String trabajadorId, String nombre, DateTime fecha, String tipoProyecto) async {
    // Normalizar fecha (sin horas) para buscar y para guardar
    DateTime inicioDia = _inicioDelDia(fecha);
    DateTime finDia = inicioDia.add(const Duration(days: 1));

    // Buscar si ya existe asistencia ese día
    final query = await _db.collection('asistencias')
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fecha', isLessThan: Timestamp.fromDate(finDia))
        .get();

    if (query.docs.isNotEmpty) {
      return "Este trabajador ya tiene asistencia registrada en esa fecha.";
    }

    await _db.collection('asistencias').add({
      'trabajadorId': trabajadorId,
      'nombre_trabajador': nombre, // Desnormalizado para lista rápida
      'fecha': Timestamp.fromDate(inicioDia),
      'tipo_proyecto': tipoProyecto,
    });
    return null;
  }

  // --- CÁLCULO DE SALARIOS ---

  // Calcula el salario basado en asistencias en un rango de días, ambos
  // incluidos (como tu 'calcular_salario'). Antes el día final quedaba fuera
  // porque "Hasta" llega a las 00:00 y las asistencias se guardaban con hora.
  Future<Map<String, dynamic>> calcularSalario(String trabajadorId, double salarioDiario, DateTime inicio, DateTime fin) async {
    final desde = _inicioDelDia(inicio);
    final hasta = _inicioDelDia(fin).add(const Duration(days: 1));

    final query = await _db.collection('asistencias')
        .where('trabajadorId', isEqualTo: trabajadorId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .where('fecha', isLessThan: Timestamp.fromDate(hasta))
        .get();

    int diasTrabajados = query.docs.length;
    double totalPagar = diasTrabajados * salarioDiario;

    return {
      'dias': diasTrabajados,
      'total': totalPagar,
    };
  }
}
