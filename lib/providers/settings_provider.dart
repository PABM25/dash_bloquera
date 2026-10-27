import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/failure.dart';

/// Ajustes compartidos por todos los dispositivos (config/ajustes).
class SettingsProvider with ChangeNotifier {
  static const double _tasaPorDefecto = 0.19;

  final DocumentReference<Map<String, dynamic>> _ajustesRef =
      FirebaseFirestore.instance.collection('config').doc('ajustes');

  // Tasa guardada antes en el dispositivo: solo se usa mientras nadie haya
  // definido la tasa en Firestore, para no cambiar el IVA sin aviso.
  double _tasaLocal = _tasaPorDefecto;
  double? _tasaRemota;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _ajustesSub;

  double get taxRate => _tasaRemota ?? _tasaLocal;

  SettingsProvider() {
    _loadLocal();
    // Solo se escucha con sesión iniciada: sin ella las reglas niegan la lectura.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _ajustesSub?.cancel();
      _ajustesSub = null;
      if (user != null) _escucharAjustes();
    });
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _tasaLocal = prefs.getDouble('taxRate') ?? _tasaPorDefecto;
    notifyListeners();
  }

  void _escucharAjustes() {
    _ajustesSub = _ajustesRef.snapshots().listen(
      (snap) {
        final tasa = (snap.data()?['tasa_iva'] as num?)?.toDouble();
        _tasaRemota = (tasa != null && tasa >= 0 && tasa <= 1) ? tasa : null;
        notifyListeners();
      },
      // Sin permiso (cuenta sin rol) se sigue con la tasa local.
      onError: (Object e) => debugPrint('No se pudo leer config/ajustes: $e'),
    );
  }

  /// Guarda la tasa para todos los dispositivos. No conviene esperar el
  /// Future sin conexión (ver guardarEnSegundoPlano).
  Future<void> setTaxRate(double rate) async {
    if (!rate.isFinite || rate < 0 || rate > 1) {
      throw Failure(message: 'La tasa debe estar entre 0% y 100%.');
    }
    _tasaRemota = rate;
    notifyListeners();
    await _ajustesRef.set({
      'tasa_iva': rate,
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': FirebaseAuth.instance.currentUser?.uid,
    }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _ajustesSub?.cancel();
    super.dispose();
  }
}
