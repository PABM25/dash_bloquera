import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Gestión de Roles
  String? _role;
  String? get role => _role;

  // Cargar rol al iniciar sesión
  Future<void> fetchUserRole() async {
    if (currentUser == null) return;
    try {
      final doc = await _db.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        _role = doc.data()?['role'] ?? 'user';
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching role: $e");
    }
  }

  // --- LOGIN (Con parámetros nombrados) ---
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await fetchUserRole(); // Cargar rol inmediatamente
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return 'Credenciales inválidas.';
      }
      return e.message;
    } catch (e) {
      return 'Error desconocido: $e';
    }
  }

  // --- REGISTRO (Con parámetros nombrados y creación de documento) ---
  Future<String?> register({
    required String email,
    required String password,
    required String nombre,
  }) async {
    try {
      // 1. Crear usuario en Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Actualizar Display Name
      await cred.user?.updateDisplayName(nombre);

      // 3. Crear documento en Firestore (Para roles y auditoría)
      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'nombre': nombre,
        'role': 'user', // Rol por defecto
        'createdAt': FieldValue.serverTimestamp(),
      });

      await cred.user?.reload();
      await fetchUserRole();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'La contraseña es muy débil.';
      if (e.code == 'email-already-in-use') {
        return 'El correo ya está registrado.';
      }
      return e.message;
    } catch (e) {
      return 'Error al registrar: $e';
    }
  }

  // --- ACTUALIZAR NOMBRE (Restaurado) ---
  Future<String?> updateName(String newName) async {
    try {
      // Actualizar en Auth
      await _auth.currentUser?.updateDisplayName(newName);
      await _auth.currentUser?.reload();

      // Actualizar también en Firestore para mantener consistencia
      await _db.collection('users').doc(_auth.currentUser!.uid).update({
        'nombre': newName,
      });

      notifyListeners();
      return null;
    } catch (e) {
      return 'Error al actualizar perfil: $e';
    }
  }

  // --- CAMBIAR CONTRASEÑA (Restaurado) ---
  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return "No hay usuario activo";

    // Credencial para re-autenticar (seguridad requerida por Firebase)
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      // 1. Re-autenticar al usuario
      await user.reauthenticateWithCredential(cred);
      // 2. Actualizar contraseña
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'La contraseña actual es incorrecta.';
      }
      return e.message;
    } catch (e) {
      return 'Error al cambiar contraseña: $e';
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await _auth.signOut();
    _role = null;
    notifyListeners();
  }
}
