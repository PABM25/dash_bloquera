import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <--- IMPORTAR

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions web = FirebaseOptions(
    apiKey: dotenv.env['WEB_API_KEY']!,
    appId: dotenv.env['WEB_APP_ID']!,
    messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['PROJECT_ID']!,
    authDomain: dotenv.env['WEB_AUTH_DOMAIN'],
    storageBucket: dotenv.env['STORAGE_BUCKET'],
  );

  static FirebaseOptions android = FirebaseOptions(
    apiKey: dotenv.env['ANDROID_API_KEY']!,
    appId: dotenv.env['ANDROID_APP_ID']!,
    messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['PROJECT_ID']!,
    storageBucket: dotenv.env['STORAGE_BUCKET'],
  );

  static FirebaseOptions ios = FirebaseOptions(
    apiKey: dotenv.env['IOS_API_KEY']!,
    appId: dotenv.env['IOS_APP_ID']!,
    messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['PROJECT_ID']!,
    storageBucket: dotenv.env['STORAGE_BUCKET'],
    iosBundleId: dotenv.env['IOS_BUNDLE_ID'],
  );

  static FirebaseOptions macos = FirebaseOptions(
    apiKey: dotenv
        .env['IOS_API_KEY']!, // Usa la misma que iOS según tu archivo original
    appId: dotenv.env['IOS_APP_ID']!,
    messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['PROJECT_ID']!,
    storageBucket: dotenv.env['STORAGE_BUCKET'],
    iosBundleId: dotenv.env['IOS_BUNDLE_ID'],
  );

  static FirebaseOptions windows = FirebaseOptions(
    apiKey: dotenv
        .env['WEB_API_KEY']!, // Usa la misma que Web según tu archivo original
    appId: dotenv
        .env['WEB_APP_ID']!, // Windows usa el AppID de Web en tu configuración original? Revisar abajo.
    // NOTA: En tu archivo original, Windows usaba un appId diferente al de Web.
    // Web: ...2a1, Windows: ...2a1 (parecen iguales en la configuración que subiste,
    // pero si fueran diferentes, crea una variable WINDOWS_APP_ID en el .env)
    messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['PROJECT_ID']!,
    authDomain: dotenv.env['WEB_AUTH_DOMAIN'],
    storageBucket: dotenv.env['STORAGE_BUCKET'],
  );
}
