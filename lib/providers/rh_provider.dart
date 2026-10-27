import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/failure.dart';
import '../firebase_options.dart';
import '../models/registro_produccion_model.dart';
import '../models/trabajador_model.dart';
import '../repositories/produccion_repository.dart';
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

  Future<void> deleteTrabajador(Trabajador t) async {
    // La cuenta vinculada es t.uid; las fichas antiguas usaban el uid como id.
    final uid = t.uid ?? t.id;
    // Evita que un administrador se quite el acceso a sí mismo.
    if (uid == FirebaseAuth.instance.currentUser?.uid) {
      throw Failure(message: "No puedes eliminar tu propia ficha.");
    }

    // Nota: Esto borra la ficha de RRHH, pero NO borra el usuario de Auth
    // (Borrar de Auth requiere Cloud Functions o re-autenticación admin).
    // Si el trabajador tiene cuenta, se le quita el acceso en el mismo batch
    // (las reglas niegan todo a DESACTIVADO). Para bloquear también el login,
    // deshabilitar la cuenta en Firebase Auth.
    final id = t.id;
    final userRef = _db.collection('users').doc(uid);
    final userSnap = await userRef.get();

    final batch = _db.batch();
    batch.delete(_db.collection('trabajadores').doc(id));
    if (userSnap.exists) {
      batch.update(userRef, {'role': 'DESACTIVADO'});
    }
    await batch.commit();
  }

  // --- ACCESO A LA APP (cuentas BLOQUERO) ---

  /// Crea la cuenta (email y contraseña) del trabajador con rol BLOQUERO.
  ///
  /// Se usa una instancia secundaria de Firebase: crear el usuario con la
  /// principal cerraría la sesión del ADMIN e iniciaría la del bloquero.
  Future<void> crearAccesoBloquero(Trabajador t, String email, String password) async {
    if (t.id.isEmpty) throw Failure(message: "Guarda el trabajador antes de crear su acceso.");
    if (t.uid != null) throw Failure(message: "${t.nombre} ya tiene una cuenta.");

    final secundaria = await Firebase.initializeApp(
      name: 'crear-cuenta-${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final String uid;
    try {
      final cred = await FirebaseAuth.instanceFor(app: secundaria)
          .createUserWithEmailAndPassword(email: email.trim(), password: password);
      uid = cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw Failure(
        code: e.code,
        message: switch (e.code) {
          'email-already-in-use' => "Ese email ya tiene una cuenta.",
          'invalid-email' => "El email no es válido.",
          'weak-password' => "La contraseña debe tener al menos 6 caracteres.",
          'network-request-failed' => "Sin conexión. Crear una cuenta requiere internet.",
          _ => "No se pudo crear la cuenta (${e.code}).",
        },
      );
    } finally {
      await secundaria.delete();
    }

    // El ADMIN (sesión principal) crea el perfil: las reglas solo se lo permiten a él.
    final batch = _db.batch();
    batch.set(_db.collection('users').doc(uid), {
      'nombre': t.nombre.length > 100 ? t.nombre.substring(0, 100) : t.nombre,
      'email': email.trim(),
      'role': 'BLOQUERO',
      'trabajadorId': t.id,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('trabajadores').doc(t.id), {
      'uid': uid,
      'email': email.trim(),
      'acceso_activo': true,
    });
    await batch.commit();
  }

  /// Quita o devuelve el acceso a la app sin borrar la cuenta.
  Future<void> setAccesoActivo(Trabajador t, bool activo) async {
    final uid = t.uid;
    if (uid == null) throw Failure(message: "${t.nombre} no tiene cuenta.");
    if (uid == FirebaseAuth.instance.currentUser?.uid) {
      throw Failure(message: "No puedes quitarte el acceso a ti mismo.");
    }
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid), {'role': activo ? 'BLOQUERO' : 'DESACTIVADO'});
    batch.update(_db.collection('trabajadores').doc(t.id), {'acceso_activo': activo});
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

  /// Registros de producción de un trabajador pagado por unidad, en un rango
  /// de días ambos incluidos. El total es la suma de cada registro (con la
  /// tarifa vigente cuando se registró).
  Future<List<RegistroProduccion>> registrosProduccion(String trabajadorId, DateTime inicio, DateTime fin) {
    return ProduccionRepository().registrosDeTrabajador(
      trabajadorId,
      _inicioDelDia(inicio),
      _inicioDelDia(fin).add(const Duration(days: 1)),
    );
  }
}
