import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/shared_stream.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSub;

  AuthProvider() {
    // Carga el rol también cuando la sesión se restaura al reabrir la app.
    _authSub = _auth.authStateChanges().listen((user) {
      if (user == null) {
        // No dejar en memoria datos de la sesión anterior.
        SharedStream.resetAll();
        _role = null;
        _trabajadorId = null;
        _roleLoaded = true;
        notifyListeners();
      } else {
        // Marcar "cargando" antes de consultar: si no, la pantalla puede
        // mostrar un instante "Sin acceso" con el estado del cierre anterior.
        _roleLoaded = false;
        notifyListeners();
        fetchUserRole();
      }
    });
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Gestión de Roles (la autorización real la imponen las reglas de Firestore;
  // esto solo adapta la interfaz).
  String? _role;
  String? get role => _role;
  bool _roleLoaded = false;
  bool get roleLoaded => _roleLoaded;
  bool get isAdmin => _role == 'ADMIN';
  bool get isBloquero => _role == 'BLOQUERO';
  bool get hasAccess => isAdmin || isBloquero;

  // Ficha de RRHH vinculada a la cuenta (solo cuentas BLOQUERO).
  String? _trabajadorId;
  String? get trabajadorId => _trabajadorId;
  String _nombre = '';
  String get nombre => _nombre;

  // Cargar rol del usuario actual
  Future<void> fetchUserRole() async {
    final user = currentUser;
    if (user == null) return;
    _roleLoaded = false;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data();
      final value = data?['role'];
      _role = value is String ? value : null;
      final trabajadorId = data?['trabajadorId'];
      _trabajadorId = trabajadorId is String && trabajadorId.isNotEmpty ? trabajadorId : null;
      _nombre = (data?['nombre'] as String?) ?? user.displayName ?? '';
      // Un bloquero sin ficha vinculada no podría registrar nada.
      if (isBloquero && _trabajadorId == null) _role = null;
    } catch (e) {
      // Sin perfil, sin permisos u otro error: se trata como usuario sin
      // acceso (nunca dejar la carga colgada).
      debugPrint("Error fetching role: $e");
      _role = null;
      _trabajadorId = null;
    }
    _roleLoaded = true;
    notifyListeners();
  }

  // --- LOGIN ---
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // El rol lo carga el listener de authStateChanges.
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-email':
          return 'Credenciales inválidas.';
        case 'user-disabled':
          return 'Esta cuenta está deshabilitada.';
        case 'too-many-requests':
          return 'Demasiados intentos. Intenta más tarde.';
        case 'network-request-failed':
          return 'Sin conexión. Revisa tu red.';
        default:
          debugPrint("Login error: ${e.code}");
          return 'No se pudo iniciar sesión.';
      }
    } catch (e) {
      // Ej. fallos de App Check o de plataforma: no dejar el login colgado.
      debugPrint("Login error: $e");
      return 'No se pudo iniciar sesión.';
    }
  }

  // --- ACTUALIZAR NOMBRE ---
  Future<String?> updateName(String newName) async {
    final user = _auth.currentUser;
    final nombre = newName.trim();
    if (user == null) return 'No hay usuario activo.';
    if (nombre.isEmpty || nombre.length > 100) {
      return 'El nombre debe tener entre 1 y 100 caracteres.';
    }
    try {
      await user.updateDisplayName(nombre);
      await user.reload();

      // Las reglas solo permiten a un ADMIN modificar perfiles (y validan 'nombre').
      await _db.collection('users').doc(user.uid).update({'nombre': nombre});

      notifyListeners();
      return null;
    } on FirebaseException catch (e) {
      debugPrint("Update name error: ${e.code}");
      return 'No se pudo actualizar el perfil.';
    }
  }

  // --- CAMBIAR CONTRASEÑA ---
  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return "No hay usuario activo.";

    // Credencial para re-autenticar (seguridad requerida por Firebase)
    final cred = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'La contraseña actual es incorrecta.';
        case 'weak-password':
          return 'La nueva contraseña es muy débil.';
        case 'too-many-requests':
          return 'Demasiados intentos. Intenta más tarde.';
        default:
          debugPrint("Change password error: ${e.code}");
          return 'No se pudo cambiar la contraseña.';
      }
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await _auth.signOut();
    _role = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
