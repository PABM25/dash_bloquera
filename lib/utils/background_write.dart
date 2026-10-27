import 'package:flutter/material.dart';
import '../core/failure.dart';

/// Lanza una escritura a Firestore sin esperarla y avisa si falla.
///
/// No se espera porque, con la caché offline, el Future de una escritura no
/// termina hasta que el servidor confirma (sin red quedaría colgado), aunque
/// el cambio ya se ve en la app. Si el servidor la rechaza (permisos, reglas
/// de validación) se muestra [mensajeError] en lugar de fallar en silencio.
void guardarEnSegundoPlano(
  ScaffoldMessengerState messenger,
  Future<void> escritura, {
  String mensajeError = 'No se pudo guardar el cambio. Intenta nuevamente.',
}) {
  escritura.catchError((Object e) {
    debugPrint('Escritura rechazada: $e');
    messenger.showSnackBar(SnackBar(
      content: Text(e is Failure ? e.message : mensajeError),
      backgroundColor: Colors.red,
    ));
  });
}
