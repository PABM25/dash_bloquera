import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSub;

  AuthProvider() {
    // Carga el rol también cuando la sesión se restaura al reabrir la app.
    _authSub = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _role = null;
        _roleLoaded = true;
        notifyListeners();
      } else {
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
  bool get hasAccess => isAdmin;

  // Cargar rol del usuario actual
  Future<void> fetchUserRole() async {
    final user = currentUser;
    if (user == null) return;
    _roleLoaded = false;
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      final value = doc.data()?['role'];
      _role = value is String ? value : null;
    } on FirebaseException catch (e) {
      // Sin perfil o sin permisos: se trata como usuario sin acceso.
      debugPrint("Error fetching role: ${e.code}");
      _role = null;
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
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await fetchUserRole();
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

      // Las reglas solo permiten modificar el propio campo 'nombre'.
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
