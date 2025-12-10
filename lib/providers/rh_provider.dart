import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Necesario para la app secundaria
import '../models/trabajador_model.dart';


class RhProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// --- TRABAJADORES ---
  Stream<List<Trabajador>> get trabajadoresStream {
    return _db.collection('trabajadores').orderBy('nombre').snapshots().map(
      (snap) => snap.docs.map((doc) => Trabajador.fromFirestore(doc)).toList(),
    );
  }

  // NUEVO: Crea usuario de Auth + Perfil de Usuario + Ficha de Trabajador
  Future<void> crearTrabajadorConCuenta({
    required Trabajador trabajador,
    required String password,
    required String rol, // 'BLOQUERO', 'VENDEDOR', 'ADMIN', 'TRABAJADOR'
  }) async {
    FirebaseApp? tempApp;
    try {
      // 1. Inicializamos una app secundaria para no cerrar la sesión del admin actual
      tempApp = await Firebase.initializeApp(
        name: 'registroTemporal',
        options: Firebase.app().options,
      );

      // 2. Creamos el usuario en Auth usando esa app secundaria
      UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: trabajador.email!, // El email es obligatorio aquí
        password: password,
      );

      String uid = cred.user!.uid;

      // 3. Guardamos el Rol en la colección 'users' (Para el Login)
      await _db.collection('users').doc(uid).set({
        'email': trabajador.email,
        'nombre': trabajador.nombre,
        'role': rol,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Guardamos la Ficha en 'trabajadores' usando EL MISMO UID (Para RRHH)
      //    Esto vincula automáticamente el Login con los datos de RRHH.
      final trabajadorConId = Trabajador(
        id: uid, // Usamos el UID de Auth como ID del documento
        nombre: trabajador.nombre,
        rut: trabajador.rut,
        email: trabajador.email,
        cargo: trabajador.cargo,
        tipoProyecto: trabajador.tipoProyecto,
        salarioPorDia: trabajador.salarioPorDia,
        telefono: trabajador.telefono,
      );

      await _db.collection('trabajadores').doc(uid).set(trabajadorConId.toFirestore());

    } catch (e) {
      throw e; // Re-anzamos el error para que la pantalla lo muestre
    } finally {
      // Importante: Borrar la app temporal para liberar memoria
      await tempApp?.delete();
    }
  }

  // Guardar/Actualizar trabajador existente (sin tocar Auth)
  Future<void> saveTrabajador(Trabajador t) async {
    if (t.id.isEmpty) {
      // Si llega aquí sin ID, es un error de lógica, pero lo manejamos guardando normal
      await _db.collection('trabajadores').add(t.toFirestore());
    } else {
      await _db.collection('trabajadores').doc(t.id).update(t.toFirestore());
    }
  }

  Future<void> deleteTrabajador(String id) async {
    // Nota: Esto borra la ficha de RRHH, pero NO borra el usuario de Auth 
    // (Borrar de Auth requiere Cloud Functions o re-autenticación admin)
    await _db.collection('trabajadores').doc(id).delete();
    
    // Opcional: Desactivar en 'users' para que no pueda entrar
    await _db.collection('users').doc(id).update({'role': 'DESACTIVADO'});
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