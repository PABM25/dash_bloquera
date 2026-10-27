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
    ).login(email: _emailCtrl.text.trim(), password: _passCtrl.text);

    // --- CORRECCIÓN ---
    // Verificamos si el widget sigue montado.
    // Si el login fue exitoso, AuthWrapper habrá eliminado esta pantalla,
    // por lo que 'mounted' será false y saldremos de la función aquí
    // evitando el error de setState().
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.brandRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomPaint(
        painter: _DotGridPainter(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.07),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLargeCard),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: isDark ? null : AppTheme.ringShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/images/logo_app.png',
                        height: 96,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.lock, size: 60, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Bienvenido",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.6,
                          height: 1.1,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Ingresa a tu cuenta para continuar",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),

                      TextField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          hintText: 'ejemplo@empresa.com',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          hintText: 'Tu contraseña',
                          prefixIcon: Icon(Icons.lock_outline, size: 20),
                        ),
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text("Ingresar"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fondo de puntos finos (textura tipo "plano") detrás del formulario.
class _DotGridPainter extends CustomPainter {
  final Color color;

  const _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 20.0;
    final paint = Paint()..color = color;
    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => oldDelegate.color != color;
}
