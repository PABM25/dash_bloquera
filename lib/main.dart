import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';

// Utils
import 'utils/app_theme.dart';
import 'utils/app_check_debug.dart';

// Providers
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/inventario_provider.dart';
import 'providers/ventas_provider.dart';
import 'providers/rh_provider.dart';
import 'providers/finanzas_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/presupuestos_provider.dart'; // Ya lo tenías importado
import 'providers/proveedores_provider.dart';
import 'providers/compras_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/produccion_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/home_screen.dart';
import 'screens/bloquero/bloquero_home_screen.dart';

// Widgets
import 'widgets/offline_banner.dart';
import 'widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics solo existe en móvil/macOS; en Web y Windows se omite.
  if (_crashlyticsDisponible) {
    // En debug no se envían reportes para no mezclar errores de desarrollo.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // App Check: sin llave válida en Web se falla de forma visible en lugar de
  // activar un proveedor con una llave ficticia que no protege nada.
  final recaptchaKey = dotenv.env['RECAPTCHA_V3_SITE_KEY'];
  if (kIsWeb && (recaptchaKey == null || recaptchaKey.isEmpty)) {
    throw StateError('Falta RECAPTCHA_V3_SITE_KEY para App Check en Web.');
  }
  // En desarrollo Web se usa un token de depuración en lugar de reCAPTCHA
  // (localhost suele no estar autorizado en la key). Nunca en release.
  if (kDebugMode && kIsWeb) {
    enableAppCheckDebugToken();
  }
  await FirebaseAppCheck.instance.activate(
    // ignore: deprecated_member_use
    androidProvider: AndroidProvider.playIntegrity,
    // ignore: deprecated_member_use
    appleProvider: AppleProvider.deviceCheck,
    // En plataformas nativas este proveedor se ignora; en Web la llave ya se validó.
    // ignore: deprecated_member_use
    webProvider: ReCaptchaV3Provider(recaptchaKey ?? ''),
  );

  // CONFIGURACIÓN DE PERSISTENCIA
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventarioProvider()),
        ChangeNotifierProvider(create: (_) => VentasProvider()),
        ChangeNotifierProvider(create: (_) => RhProvider()),
        ChangeNotifierProvider(create: (_) => FinanzasProvider()),
        // [CORRECCIÓN] Agregamos el proveedor de presupuestos aquí:
        ChangeNotifierProvider(create: (_) => PresupuestosProvider()), 
        ChangeNotifierProvider(create: (_) => ProveedoresProvider()),
        ChangeNotifierProvider(create: (_) => ProduccionProvider()),

        // Se crean una sola vez: antes se recreaban (y reabrían sus consultas)
        // cada vez que Inventario o Ventas notificaban un cambio.
        ChangeNotifierProvider(create: (_) => ComprasProvider()),
        Provider(create: (_) => DashboardProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Dash Bloquera',
            debugShowCheckedModeBanner: false,
            navigatorKey: rootNavigatorKey,
            navigatorObservers: [ShellRouteObserver()],
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
            supportedLocales: const [
              Locale('es', 'ES'),
            ],
            builder: (context, child) {
              // El menú (AppShell) envuelve al Navigator: visible en todas las páginas.
              return OfflineBanner(child: AppShell(child: child!));
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return StreamBuilder(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const LoginScreen();
        }
        if (!authProvider.roleLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Las reglas de Firestore son la barrera real; esto evita mostrar una
        // app vacía a cuentas sin rol válido (ej. DESACTIVADO o sin perfil).
        if (!authProvider.hasAccess) {
          return const NoAccessScreen();
        }
        // El bloquero solo ve el registro de producción.
        if (authProvider.isBloquero) return const BloqueroHomeScreen();
        return const HomeScreen();
      },
    );
  }
}

class NoAccessScreen extends StatelessWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Tu cuenta no tiene acceso a esta aplicación.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Contacta al administrador.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Provider.of<AuthProvider>(context, listen: false).logout(),
                child: const Text("Cerrar sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool get _crashlyticsDisponible =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);
