import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'app_drawer.dart';

/// Navigator principal de la app (se asigna en MaterialApp.navigatorKey).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Sección activa del menú.
final ValueNotifier<int> _selectedSection = ValueNotifier<int>(0);

const String _sectionRoutePrefix = 'section:';

/// Aumenta cada vez que se vuelve a la pantalla base (Dashboard), para que
/// esta recargue sus totales.
final ValueNotifier<int> homeVisits = ValueNotifier<int>(0);

/// Mantiene marcada la sección correcta al volver atrás.
class ShellRouteObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _syncWith(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _syncWith(previousRoute);
  }

  void _syncWith(Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name ?? '';
    if (route.isFirst) {
      _selectedSection.value = 0;
      homeVisits.value++;
    } else if (name.startsWith(_sectionRoutePrefix)) {
      _selectedSection.value = int.parse(name.substring(_sectionRoutePrefix.length));
    }
  }
}

/// Layout común: envuelve el Navigator principal (MaterialApp.builder), por lo
/// que el menú queda visible en todas las páginas, incluidas las subpáginas,
/// sin cambiar cómo se abren o cierran pantallas y diálogos.
///
/// - Escritorio (>= 1000 px): barra lateral fija.
/// - Móvil: el mismo menú como cajón, abierto con el botón ☰.
/// Solo se muestra con una sesión con acceso (no en Login ni "Sin acceso").
class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const double wideBreakpoint = 1000;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _wasActive = false;

  void _select(int index) {
    _scaffoldKey.currentState?.closeDrawer();
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    // La sección 0 (Dashboard) es la pantalla base; las demás se abren encima,
    // así el "atrás" de cada sección sigue llevando al Dashboard como antes.
    navigator.popUntil((route) => route.isFirst);
    _selectedSection.value = index;
    if (index != 0) {
      navigator.push(
        PageRouteBuilder(
          settings: RouteSettings(name: '$_sectionRoutePrefix$index'),
          pageBuilder: (context, _, _) => appSections[index].builder(context),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  // Al cerrar sesión se vuelve a la pantalla base, para que Login no quede
  // tapado por las páginas que estaban abiertas.
  void _onSessionEnded() {
    _selectedSection.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // El menú completo es solo para ADMIN; el bloquero tiene su propia pantalla.
    final active = auth.currentUser != null && auth.roleLoaded && auth.isAdmin;

    if (_wasActive && !active) _onSessionEnded();
    _wasActive = active;

    if (!active) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppShell.wideBreakpoint;
        final menu = ValueListenableBuilder<int>(
          valueListenable: _selectedSection,
          builder: (context, selected, _) => AppNavMenu(selectedIndex: selected, onSelect: _select),
        );

        final content = ShellScope(
          isWide: isWide,
          openMenu: () => _scaffoldKey.currentState?.openDrawer(),
          child: widget.child,
        );

        if (isWide) {
          return Row(
            children: [
              SizedBox(
                width: 248,
                child: Material(
                  color: Theme.of(context).drawerTheme.backgroundColor,
                  shape: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                  child: menu,
                ),
              ),
              Expanded(child: content),
            ],
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          drawer: Drawer(child: menu),
          body: content,
        );
      },
    );
  }
}

/// Da a las pantallas acceso al menú del AppShell.
class ShellScope extends InheritedWidget {
  final bool isWide;
  final VoidCallback openMenu;

  const ShellScope({
    super.key,
    required this.isWide,
    required this.openMenu,
    required super.child,
  });

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  /// Botón ☰ para el `leading` del AppBar de las pantallas de sección.
  /// Devuelve null en escritorio (el menú ya está visible), fuera del shell
  /// o si la pantalla se abrió desde otra (ahí el AppBar muestra "volver").
  static Widget? menuButton(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null || scope.isWide) return null;
    final route = ModalRoute.of(context);
    final esSeccion = route == null ||
        route.isFirst ||
        (route.settings.name ?? '').startsWith(_sectionRoutePrefix);
    if (!esSeccion) return null;
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Menú',
      onPressed: scope.openMenu,
    );
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) => isWide != oldWidget.isWide;
}
