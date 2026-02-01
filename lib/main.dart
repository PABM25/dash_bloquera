import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // [NUEVO]
import 'firebase_options.dart';

// Utils
import 'utils/app_theme.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/inventario_provider.dart';
import 'providers/ventas_provider.dart';
import 'providers/rh_provider.dart';
import 'providers/finanzas_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/presupuestos_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventarioProvider()),
        ChangeNotifierProvider(create: (_) => VentasProvider()),
        ChangeNotifierProvider(create: (_) => RhProvider()),
        ChangeNotifierProvider(create: (_) => FinanzasProvider()),
        ProxyProvider2<VentasProvider, FinanzasProvider, DashboardProvider>(
          update: (_, ventas, finanzas, __) =>
              DashboardProvider(ventas, finanzas),
        ),
      ],
      child: MaterialApp(
        title: 'Dash Bloquera',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // [NUEVO] Configuración de idioma Español
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'), 
        ],
        home: const AuthWrapper(),
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
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}