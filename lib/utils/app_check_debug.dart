// Activa el token de depuración de App Check solo en Web (en otras
// plataformas no hace nada). Llamar únicamente en builds de debug.
export 'app_check_debug_stub.dart'
    if (dart.library.js_interop) 'app_check_debug_web.dart';
