import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../../providers/settings_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_shell.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      appBar: AppBar(leading: ShellScope.menuButton(context), title: const Text("Mi Cuenta")),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.person, size: 26, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? "Usuario",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? "",
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            leading: const Icon(Icons.percent, color: Colors.green),
            title: const Text("Configuración de Impuestos"),
            subtitle: Consumer<SettingsProvider>(
              builder: (context, settings, _) => Text("Tasa actual: ${(settings.taxRate * 100).toInt()}%"),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final settings = Provider.of<SettingsProvider>(context, listen: false);
              final ctrl = TextEditingController(text: (settings.taxRate * 100).toStringAsFixed(0));
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Tasa de Impuesto (%)"),
                  content: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: "%"),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                    ElevatedButton(
                      onPressed: () {
                        final val = double.tryParse(ctrl.text);
                        if (val != null && val >= 0 && val <= 100) {
                          settings.setTaxRate(val / 100.0);
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text("Guardar"),
                    ),
                  ],
                ),
              );
            },
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