import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);

    // Intentamos loguear
    final error = await Provider.of<AuthProvider>(
      context,
      listen: false,
    ).login(email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());

    // --- CORRECCIÓN ---
    // Verificamos si el widget sigue montado.
    // Si el login fue exitoso, AuthWrapper habrá eliminado esta pantalla,
    // por lo que 'mounted' será false y saldremos de la función aquí
    // evitando el error de setState().
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, size: 60, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Bienvenido",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Ingresa a tu cuenta para continuar",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        hintText: 'ejemplo@empresa.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        hintText: 'Tu contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 32),

                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          backgroundColor: AppTheme.primary,
                        ),
                        child: const Text(
                          "INGRESAR",
                          style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1),
                        ),
                      ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              final error = await authProvider.loginAsDemo();

                              if (!mounted) return;
                              setState(() => _isLoading = false);

                              if (error != null) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(error),
                                        backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                      child: const Text(
                        "VER DEMO",
                        style: TextStyle(color: AppTheme.primary, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}