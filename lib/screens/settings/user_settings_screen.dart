import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Mi Cuenta")),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? "Usuario"),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: const CircleAvatar(child: Icon(Icons.person, size: 40)),
            decoration: const BoxDecoration(color: Color(0xFFBF2642)),
          ),
          
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text("Editar Perfil"),
            subtitle: const Text("Actualizar nombre"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.orange),
            title: const Text("Cambiar Contraseña"),
            subtitle: const Text("Mantén tu cuenta segura"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // Salir de settings
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
    );
  }
}