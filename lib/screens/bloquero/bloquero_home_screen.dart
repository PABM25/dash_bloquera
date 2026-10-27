import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/producto_modelo.dart';
import '../../models/registro_produccion_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/produccion_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/background_write.dart';
import '../../utils/formatters.dart';
import '../../utils/material_qr.dart';

/// Única pantalla de las cuentas BLOQUERO: escanear el QR del producto,
/// ingresar las unidades fabricadas y ver lo ganado.
class BloqueroHomeScreen extends StatefulWidget {
  const BloqueroHomeScreen({super.key});

  @override
  State<BloqueroHomeScreen> createState() => _BloqueroHomeScreenState();
}

class _BloqueroHomeScreenState extends State<BloqueroHomeScreen> {
  late final ProduccionProvider _produccion = context.read<ProduccionProvider>();
  late final Stream<List<Producto>> _productosStream = _produccion.productosFabricablesStream();
  late final Stream<List<RegistroProduccion>> _registrosStream =
      _produccion.misRegistrosStream(_inicioDelMes(DateTime.now()));

  // Últimos productos recibidos: el QR se resuelve aquí, sin consultar la
  // red, para que funcione sin señal.
  List<Producto> _productos = const [];

  static DateTime _inicioDelDia(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _inicioDelMes(DateTime d) => DateTime(d.year, d.month);
  static DateTime _inicioDeSemana(DateTime d) =>
      _inicioDelDia(d).subtract(Duration(days: d.weekday - 1));

  Future<void> _escanear() async {
    final raw = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _EscanerProduccionScreen()),
    );
    if (raw == null || !mounted) return;

    final id = MaterialQr.productoIdDesde(raw);
    Producto? producto;
    for (final p in _productos) {
      if (p.id == id || (id == null && p.barcode == raw.trim())) producto = p;
    }
    if (producto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Este QR no corresponde a un producto que fabriques."),
        backgroundColor: AppTheme.brandRed,
      ));
      return;
    }
    _abrirRegistro(producto);
  }

  void _elegirSinQr() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: _productos.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text("No hay productos con pago por producción. Avísale al administrador."),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(title: Text("¿Qué fabricaste?", style: TextStyle(fontWeight: FontWeight.bold))),
                  for (final p in _productos)
                    ListTile(
                      leading: const Icon(Icons.view_module),
                      title: Text(p.nombre),
                      subtitle: Text("${Formatters.formatCurrency(p.tarifaProduccion!)} por unidad"),
                      onTap: () {
                        Navigator.pop(ctx);
                        _abrirRegistro(p);
                      },
                    ),
                ],
              ),
      ),
    );
  }

  void _abrirRegistro(Producto producto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RegistroSheet(producto: producto),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi producción"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar sesión",
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: StreamBuilder<List<Producto>>(
        stream: _productosStream,
        builder: (context, prodSnap) {
          if (prodSnap.hasData) _productos = prodSnap.data!;
          return StreamBuilder<List<RegistroProduccion>>(
            stream: _registrosStream,
            builder: (context, snap) {
              final registros = snap.data ?? const <RegistroProduccion>[];
              final ahora = DateTime.now();
              final hoy = registros.where((r) => !r.fecha.isBefore(_inicioDelDia(ahora)));
              final semana = registros.where((r) => !r.fecha.isBefore(_inicioDeSemana(ahora)));

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        "Hola${auth.nombre.isEmpty ? '' : ', ${auth.nombre}'}",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _Resumen(titulo: "Hoy", registros: hoy)),
                          const SizedBox(width: 12),
                          Expanded(child: _Resumen(titulo: "Esta semana", registros: semana)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _Resumen(titulo: "Este mes", registros: registros),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 64,
                        child: ElevatedButton.icon(
                          onPressed: _escanear,
                          icon: const Icon(Icons.qr_code_scanner, size: 32),
                          label: const Text("ESCANEAR QR", style: TextStyle(fontSize: 20)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _elegirSinQr,
                        child: const Text("¿El QR no se lee? Elegir producto"),
                      ),
                      const SizedBox(height: 16),
                      const Text("Mis registros del mes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (snap.hasError)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text("No se pudieron cargar tus registros."),
                        )
                      else if (!snap.hasData)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (registros.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text("Aún no registras producción este mes."),
                        ),
                      for (final r in registros)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            r.pendiente ? Icons.cloud_upload_outlined : Icons.check_circle,
                            color: r.pendiente ? Colors.orange : Colors.green,
                          ),
                          title: Text("${r.cantidad} × ${r.productoNombre}"),
                          subtitle: Text(
                            "${Formatters.formatDate(r.fecha)}${r.pendiente ? ' · se enviará al tener señal' : ''}",
                          ),
                          trailing: Text(
                            Formatters.formatCurrency(r.monto),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        "Si te equivocaste en un registro, avísale al administrador para que lo anule.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  final String titulo;
  final Iterable<RegistroProduccion> registros;

  const _Resumen({required this.titulo, required this.registros});

  @override
  Widget build(BuildContext context) {
    final unidades = registros.fold<int>(0, (acc, r) => acc + r.cantidad);
    final monto = registros.fold<double>(0, (acc, r) => acc + r.monto);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(Formatters.formatCurrency(monto),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
            Text("$unidades unidades"),
          ],
        ),
      ),
    );
  }
}

/// Ingreso de unidades fabricadas de un producto.
class _RegistroSheet extends StatefulWidget {
  final Producto producto;

  const _RegistroSheet({required this.producto});

  @override
  State<_RegistroSheet> createState() => _RegistroSheetState();
}

class _RegistroSheetState extends State<_RegistroSheet> {
  final _cantidadCtrl = TextEditingController();

  int get _cantidad => int.tryParse(_cantidadCtrl.text) ?? 0;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  void _registrar() {
    final cantidad = _cantidad;
    if (cantidad <= 0) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final p = widget.producto;

    // Sin esperar al servidor: el registro se ve al tiro y se sincroniza
    // cuando haya señal. Si el servidor lo rechaza, se avisa.
    guardarEnSegundoPlano(
      messenger,
      context.read<ProduccionProvider>().registrarProduccion(
            producto: p,
            cantidad: cantidad,
            trabajadorId: auth.trabajadorId!,
            trabajadorNombre: auth.nombre,
          ),
      mensajeError: "No se pudo registrar la producción. Avísale al administrador.",
    );
    HapticFeedback.mediumImpact();
    messenger.showSnackBar(SnackBar(
      content: Text("Registrado: $cantidad × ${p.nombre} (${Formatters.formatCurrency(cantidad * p.tarifaProduccion!)})"),
      backgroundColor: Colors.green,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final tarifa = p.tarifaProduccion!;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(p.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text("Pago: ${Formatters.formatCurrency(tarifa)} por unidad", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _cantidadCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            style: const TextStyle(fontSize: 28),
            decoration: const InputDecoration(labelText: "¿Cuántas unidades hiciste?"),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _registrar(),
          ),
          const SizedBox(height: 12),
          Text(
            "Ganas: ${Formatters.formatCurrency(_cantidad * tarifa)}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _cantidad > 0 && _cantidad <= 10000 ? _registrar : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: Text(_cantidad > 10000 ? "Máximo 10.000 por registro" : "REGISTRAR",
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cámara para leer el QR; devuelve el texto leído.
class _EscanerProduccionScreen extends StatefulWidget {
  const _EscanerProduccionScreen();

  @override
  State<_EscanerProduccionScreen> createState() => _EscanerProduccionScreenState();
}

class _EscanerProduccionScreenState extends State<_EscanerProduccionScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _leido = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_leido || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _leido = true;
    HapticFeedback.mediumImpact();
    Navigator.pop(context, raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanea el QR del producto")),
      body: MobileScanner(controller: _controller, onDetect: _onDetect),
    );
  }
}
