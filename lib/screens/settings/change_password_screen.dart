import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;

  void _cambiar() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Las nuevas contraseñas no coinciden")));
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La contraseña debe tener al menos 6 caracteres")));
      return;
    }

    setState(() => _isLoading = true);

    final error = await Provider.of<AuthProvider>(context, listen: false).changePassword(
      _currentPassCtrl.text,
      _newPassCtrl.text,
    );

    setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contraseña actualizada exitosamente"), backgroundColor: Colors.green));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cambiar Contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(controller: _currentPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Contraseña Actual")),
            const SizedBox(height: 15),
            TextFormField(controller: _newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Nueva Contraseña")),
            const SizedBox(height: 15),
            TextFormField(controller: _confirmPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Confirmar Nueva Contraseña")),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _cambiar,
                child: const Text("ACTUALIZAR CONTRASEÑA"),
              ),
            )
          ],
        ),
      ),
    );
  }
}