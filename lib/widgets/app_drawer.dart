import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard/home_screen.dart';
import '../screens/inventario/lista_productos_screen.dart';
import '../screens/ventas/lista_ventas_screen.dart';
// IMPORTANTE: Importamos la pantalla de presupuestos/cotizaciones
import '../screens/ventas/crear_presupuesto_screen.dart';
import '../screens/rh/lista_trabajadores_screen.dart';
import '../screens/rh/asistencia_screen.dart';
import '../screens/rh/calculo_salario_screen.dart';
import '../screens/finanzas/lista_gastos_screen.dart';
import '../screens/settings/user_settings_screen.dart';
import '../utils/app_theme.dart';
import '../providers/theme_provider.dart';
import '../screens/compras/lista_proveedores_screen.dart';
import '../screens/compras/lista_compras_screen.dart';
import '../screens/ventas/despachos_screen.dart';
import '../screens/inventario/etiquetas_qr_screen.dart';
import '../screens/inventario/escaner_qr_screen.dart';

/// Una sección del menú principal.
class AppSection {
  final IconData icon;
  final String label;
  final WidgetBuilder builder;
  /// Etiqueta de grupo que se muestra antes de esta sección (opcional).
  final String? group;

  const AppSection({
    required this.icon,
    required this.label,
    required this.builder,
    this.group,
  });
}

/// Única definición del menú: la usan la barra lateral (escritorio)
/// y el cajón (móvil) del AppShell. Para agregar una sección, agrégala aquí.
final List<AppSection> appSections = [
  AppSection(icon: Icons.dashboard, label: "Dashboard", builder: (_) => const HomeScreen()),
  AppSection(icon: Icons.inventory, label: "Inventario", builder: (_) => const ListaProductosScreen()),
  AppSection(icon: Icons.qr_code_2, label: "Etiquetas QR", builder: (_) => const EtiquetasQrScreen()),
  AppSection(icon: Icons.qr_code_scanner, label: "Escanear QR", builder: (_) => const EscanerQrScreen()),
  AppSection(icon: Icons.shopping_cart, label: "Ventas", builder: (_) => const ListaVentasScreen()),
  AppSection(icon: Icons.local_shipping, label: "Despachos", builder: (_) => const DespachosScreen()),
  AppSection(icon: Icons.description, label: "Cotizaciones", builder: (_) => const CrearPresupuestoScreen()),
  AppSection(
    icon: Icons.store,
    label: "Proveedores",
    builder: (_) => const ListaProveedoresScreen(),
    group: "COMPRAS Y PROVEEDORES",
  ),
  AppSection(icon: Icons.shopping_bag, label: "Compras", builder: (_) => const ListaComprasScreen()),
  AppSection(
    icon: Icons.people,
    label: "Personal",
    builder: (_) => const ListaTrabajadoresScreen(),
    group: "ADMINISTRACIÓN",
  ),
  AppSection(icon: Icons.how_to_reg, label: "Asistencia", builder: (_) => const AsistenciaScreen()),
  AppSection(icon: Icons.calculate, label: "Salarios", builder: (_) => const CalculoSalarioScreen()),
  AppSection(icon: Icons.attach_money, label: "Finanzas", builder: (_) => const ListaGastosScreen()),
  AppSection(icon: Icons.settings, label: "Mi Cuenta", builder: (_) => const UserSettingsScreen(), group: ""),
];

/// Contenido del menú (encabezado, secciones, tema y cierre de sesión).
class AppNavMenu extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AppNavMenu({super.key, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Column(
      children: [
        _DrawerHeader(
          name: user?.displayName ?? "Usuario",
          email: user?.email ?? "",
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              for (var i = 0; i < appSections.length; i++) ...[
                if (appSections[i].group != null)
                  appSections[i].group!.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(),
                        )
                      : _SectionLabel(appSections[i].group!),
                _buildItem(context, i),
              ],
            ],
          ),
        ),
        const Divider(),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return SwitchListTile(
              title: const Text("Modo Oscuro"),
              secondary: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
              value: isDark,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListTile(
            dense: true,
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error, size: 20),
            title: Text(
              "Cerrar Sesión",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => auth.logout(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final section = appSections[index];
    final selected = index == selectedIndex;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      selected: selected,
      leading: Icon(section.icon, size: 20),
      title: Text(
        section.label,
        style: selected ? const TextStyle(fontWeight: FontWeight.w600) : null,
      ),
      onTap: () => onSelect(index),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String name;
  final String email;

  const _DrawerHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo_app.png',
                height: 40,
                width: 40,
                errorBuilder: (_, _, _) => const Icon(Icons.store, size: 32),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Construcciones V&G",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.person, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: scheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 20, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
