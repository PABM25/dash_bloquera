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

  // --- NUEVOS GETTERS PARA CONTROLAR LA APP ---
  bool get isAdmin => _role == 'admin';
  bool get isDemo => _role == 'demo';

  // Cargar rol al iniciar sesión
  Future<void> fetchUserRole() async {
    if (currentUser == null) return;
    try {
      final doc = await _db.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        _role = doc.data()?['role'] ?? 'demo'; // Si no tiene rol, asumimos demo por seguridad
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching role: $e");
    }
  }

  // --- LOGIN ---
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

  // --- REGISTRO ---
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

      // 3. Crear documento en Firestore
      // CAMBIO IMPORTANTE: Ahora registramos como 'demo' por defecto
      // para que cualquiera que pruebe la app pueda ver datos sin ser admin.
      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'nombre': nombre,
        'role': 'demo', 
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

  // --- ACTUALIZAR NOMBRE ---
  Future<String?> updateName(String newName) async {
    try {
      await _auth.currentUser?.updateDisplayName(newName);
      await _auth.currentUser?.reload();

      await _db.collection('users').doc(_auth.currentUser!.uid).update({
        'nombre': newName,
      });

      notifyListeners();
      return null;
    } catch (e) {
      return 'Error al actualizar perfil: $e';
    }
  }

  // --- CAMBIAR CONTRASEÑA ---
  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return "No hay usuario activo";

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(cred);
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