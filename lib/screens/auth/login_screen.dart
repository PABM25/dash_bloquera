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
    _ejecutarLogin(_emailCtrl.text.trim(), _passCtrl.text.trim());
  }

  void _ejecutarLogin(String email, String password) async {
    setState(() => _isLoading = true);
    final error = await Provider.of<AuthProvider>(context, listen: false)
        .login(email: email, password: password);
    setState(() => _isLoading = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  void _loginDemo() {
    // Credenciales del usuario demo que creaste en Firebase
    _emailCtrl.text = "demo@portafolio.com";
    _passCtrl.text = "DemoPortafolio17654"; 
    _ejecutarLogin(_emailCtrl.text, _passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: AppTheme.primary),
              const SizedBox(height: 20),
              const Text("Dash Bloquera", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.key), border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 30),

              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: AppTheme.primary),
                      child: const Text("INGRESAR", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _loginDemo,
                      icon: const Icon(Icons.visibility),
                      label: const Text("Ingresar MODO DEMO (Solo Lectura)"),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}