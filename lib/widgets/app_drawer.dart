import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard/home_screen.dart';
import '../screens/inventario/lista_productos_screen.dart';
import '../screens/ventas/lista_ventas_screen.dart';
import '../screens/rh/lista_trabajadores_screen.dart';
import '../screens/rh/calculo_salario_screen.dart';
import '../screens/finanzas/lista_gastos_screen.dart';
import '../screens/settings/user_settings_screen.dart';
import '../utils/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primary),
            accountName: Text(user?.displayName ?? "Usuario"),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppTheme.primary),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildItem(
                  context,
                  Icons.dashboard,
                  "Dashboard",
                  const HomeScreen(),
                  isHome: true,
                ),
                _buildItem(
                  context,
                  Icons.inventory,
                  "Inventario",
                  const ListaProductosScreen(),
                ),
                _buildItem(
                  context,
                  Icons.shopping_cart,
                  "Ventas",
                  const ListaVentasScreen(),
                ),

                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                  child: Text(
                    "ADMINISTRACIÓN",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                // AHORA ESTOS ÍTEMS SON VISIBLES PARA TODOS LOS LOGUEADOS
                _buildItem(
                  context,
                  Icons.people,
                  "Personal",
                  const ListaTrabajadoresScreen(),
                ),
                _buildItem(
                  context,
                  Icons.calculate,
                  "Salarios",
                  const CalculoSalarioScreen(),
                ),
                _buildItem(
                  context,
                  Icons.attach_money,
                  "Finanzas",
                  const ListaGastosScreen(),
                ),

                const Divider(),
                _buildItem(
                  context,
                  Icons.settings,
                  "Mi Cuenta",
                  const UserSettingsScreen(),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text(
              "Cerrar Sesión",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => auth.logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget page, {
    bool isHome = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (isHome) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => page),
            (Route<dynamic> route) => false,
          );
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
      },
    );
  }
}