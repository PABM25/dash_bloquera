import 'dart:js_interop';
import 'dart:js_interop_unsafe';

// El SDK JS de App Check lee esta variable global al activarse: con `true`
// genera un token de depuración (se imprime en la consola del navegador) que
// debe registrarse en Firebase Console > App Check > Administrar tokens de depuración.
void enableAppCheckDebugToken() {
  globalContext['FIREBASE_APPCHECK_DEBUG_TOKEN'] = true.toJS;
}
