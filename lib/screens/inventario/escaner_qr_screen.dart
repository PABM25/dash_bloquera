import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/failure.dart';
import '../../models/producto_modelo.dart';
import '../../providers/inventario_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/material_qr.dart';
import '../../widgets/app_shell.dart';
import 'escaner_stock_screen.dart';

/// Escanea el QR de un material con la cámara y registra entrada o salida.
class EscanerQrScreen extends StatefulWidget {
  const EscanerQrScreen({super.key});

  @override
  State<EscanerQrScreen> createState() => _EscanerQrScreenState();
}

class _EscanerQrScreenState extends State<EscanerQrScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _procesando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_procesando || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _procesando = true;
    await _controller.stop();
    HapticFeedback.mediumImpact();
    if (!mounted) return;

    final provider = context.read<InventarioProvider>();
    final messenger = ScaffoldMessenger.of(context);
    Producto? producto;
    try {
      final id = MaterialQr.productoIdDesde(raw);
      // También acepta códigos de barras ya cargados en los productos.
      producto = id != null
          ? await provider.buscarProductoPorId(id)
          : await provider.buscarProductoPorBarcode(raw.trim());
    } catch (e) {
      debugPrint("Buscar material QR: $e");
    }

    if (!mounted) return;
    if (producto == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("QR no reconocido o material inexistente."), backgroundColor: AppTheme.brandRed),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _MovimientoSheet(producto: producto!),
      );
    }

    if (!mounted) return;
    _procesando = false;
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: ShellScope.menuButton(context),
        title: const Text('Escanear QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined),
            tooltip: 'Linterna',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_outlined),
            tooltip: 'Usar lector USB',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EscanerStockScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ErrorCamara(error: error),
          ),
          // Marco de referencia
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLargeCard),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: const Text(
                  "Apunta al QR de un material",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCamara extends StatelessWidget {
  final MobileScannerException error;

  const _ErrorCamara({required this.error});

  @override
  Widget build(BuildContext context) {
    final sinPermiso = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            sinPermiso
                ? "Sin permiso para usar la cámara. Actívalo en la configuración del navegador o del teléfono."
                : "No se pudo iniciar la cámara (${error.errorCode.name}).",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Hoja inferior para registrar la entrada o salida del material escaneado.
class _MovimientoSheet extends StatefulWidget {
  final Producto producto;

  const _MovimientoSheet({required this.producto});

  @override
  State<_MovimientoSheet> createState() => _MovimientoSheetState();
}

class _MovimientoSheetState extends State<_MovimientoSheet> {
  final TextEditingController _cantidadCtrl = TextEditingController(text: "1");
  bool _esEntrada = true;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  void _ajustar(int delta) {
    final actual = int.tryParse(_cantidadCtrl.text) ?? 0;
    final nuevo = (actual + delta).clamp(1, 1000000);
    _cantidadCtrl.text = "$nuevo";
  }

  Future<void> _registrar() async {
    final cantidad = int.tryParse(_cantidadCtrl.text.trim()) ?? 0;
    if (cantidad <= 0) {
      setState(() => _error = "Ingresa una cantidad mayor a 0.");
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final nuevoStock = await context
          .read<InventarioProvider>()
          .registrarMovimientoQr(widget.producto, cantidad, esEntrada: _esEntrada);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "${_esEntrada ? 'Entrada' : 'Salida'} de $cantidad · ${widget.producto.nombre} · Stock: $nuevoStock",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on Failure catch (f) {
      setState(() => _error = f.message);
    } catch (e) {
      debugPrint("Movimiento QR: $e");
      setState(() => _error = "No se pudo registrar el movimiento.");
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.producto.nombre,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text("Stock actual: ${widget.producto.stock}", style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, icon: Icon(Icons.add_circle_outline), label: Text("Entrada")),
              ButtonSegment(value: false, icon: Icon(Icons.remove_circle_outline), label: Text("Salida")),
            ],
            selected: {_esEntrada},
            onSelectionChanged: (s) => setState(() => _esEntrada = s.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton.outlined(onPressed: () => _ajustar(-1), icon: const Icon(Icons.remove)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cantidadCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: "Cantidad"),
                  onSubmitted: (_) => _registrar(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.outlined(onPressed: () => _ajustar(1), icon: const Icon(Icons.add)),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _guardando ? null : _registrar,
              child: Text(_guardando
                  ? "Registrando…"
                  : (_esEntrada ? "Registrar entrada" : "Registrar salida")),
            ),
          ),
        ],
      ),
    );
  }
}
