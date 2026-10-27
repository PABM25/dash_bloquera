import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/producto_modelo.dart';
import '../../providers/inventario_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/material_qr.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/loading_dialog.dart';

/// Genera, muestra, descarga e imprime los QR de los materiales del Inventario.
class EtiquetasQrScreen extends StatefulWidget {
  const EtiquetasQrScreen({super.key});

  @override
  State<EtiquetasQrScreen> createState() => _EtiquetasQrScreenState();
}

class _EtiquetasQrScreenState extends State<EtiquetasQrScreen> {
  final Set<String> _seleccionados = {};
  bool _seleccionInicial = false;
  bool _creandoBase = false;
  int _copias = 1;

  void _preseleccionar(List<Producto> productos) {
    if (_seleccionInicial) return;
    _seleccionInicial = true;
    final base = MaterialQr.materialesBase.map(MaterialQr.normalizar).toSet();
    _seleccionados.addAll(
      productos.where((p) => base.contains(MaterialQr.normalizar(p.nombre))).map((p) => p.id),
    );
  }

  Future<void> _crearMaterialesBase(List<String> faltantes) async {
    setState(() => _creandoBase = true);
    final provider = context.read<InventarioProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      for (final nombre in faltantes) {
        await provider.addProducto(nombre, 0, 0, '', null);
      }
      // Se vuelven a preseleccionar al llegar los nuevos productos.
      _seleccionInicial = false;
      messenger.showSnackBar(SnackBar(content: Text("Materiales creados: ${faltantes.join(', ')}")));
    } catch (e) {
      debugPrint("Crear materiales base: $e");
      messenger.showSnackBar(
        const SnackBar(content: Text("No se pudieron crear los materiales."), backgroundColor: AppTheme.brandRed),
      );
    } finally {
      if (mounted) setState(() => _creandoBase = false);
    }
  }

  Future<void> _generar(List<Producto> productos, {required bool imprimir}) async {
    await runWithLoading(
      context,
      message: 'Generando etiquetas…',
      (close) => MaterialQr.generarEtiquetas(
        productos,
        copias: _copias,
        imprimir: imprimir,
        onGenerated: close,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<InventarioProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: ShellScope.menuButton(context),
        title: const Text('Etiquetas QR'),
      ),
      body: StreamBuilder<List<Producto>>(
        stream: provider.productosStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final productos = snapshot.data!;
          _preseleccionar(productos);
          final faltantes = MaterialQr.faltantes(productos);
          final seleccion = productos.where((p) => _seleccionados.contains(p.id)).toList();
          final totalEtiquetas = seleccion.length * _copias;
          final hojas = (totalEtiquetas / MaterialQr.porHoja).ceil();

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (faltantes.isNotEmpty) _bannerFaltantes(faltantes),
                        _barraOpciones(productos),
                        const SizedBox(height: 8),
                        if (productos.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text("No hay materiales en el inventario.")),
                          ),
                        for (final p in productos) _filaMaterial(p),
                      ],
                    ),
                  ),
                ),
              ),
              _barraAcciones(seleccion, totalEtiquetas, hojas),
            ],
          );
        },
      ),
    );
  }

  Widget _bannerFaltantes(List<String> faltantes) {
    return Card(
      color: AppTheme.blueTint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Faltan en el inventario: ${faltantes.join(', ')}.",
                style: const TextStyle(color: AppTheme.charcoal),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _creandoBase ? null : () => _crearMaterialesBase(faltantes),
              child: Text(_creandoBase ? "Creando…" : "Crear"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barraOpciones(List<Producto> productos) {
    final todos = productos.isNotEmpty && productos.every((p) => _seleccionados.contains(p.id));
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        TextButton.icon(
          icon: Icon(todos ? Icons.check_box : Icons.check_box_outline_blank),
          label: Text(todos ? "Quitar selección" : "Seleccionar todos"),
          onPressed: () => setState(() {
            if (todos) {
              _seleccionados.clear();
            } else {
              _seleccionados.addAll(productos.map((p) => p.id));
            }
          }),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Copias por material"),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: _copias > 1 ? () => setState(() => _copias--) : null,
            ),
            Text("$_copias", style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _copias < MaterialQr.porHoja ? () => setState(() => _copias++) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _filaMaterial(Producto p) {
    final seleccionado = _seleccionados.contains(p.id);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: () => setState(() {
          seleccionado ? _seleccionados.remove(p.id) : _seleccionados.add(p.id);
        }),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: seleccionado,
              onChanged: (v) => setState(() {
                v == true ? _seleccionados.add(p.id) : _seleccionados.remove(p.id);
              }),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(2),
              child: QrImageView(data: MaterialQr.payload(p), size: 44, padding: EdgeInsets.zero),
            ),
          ],
        ),
        title: Text(p.nombre),
        subtitle: Text("Stock: ${p.stock}"),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_full),
          tooltip: 'Ver QR',
          onPressed: () => _verQr(p),
        ),
      ),
    );
  }

  Widget _barraAcciones(List<Producto> seleccion, int totalEtiquetas, int hojas) {
    final habilitado = seleccion.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              habilitado
                  ? "$totalEtiquetas etiquetas · $hojas ${hojas == 1 ? 'hoja' : 'hojas'} A4 (21 por hoja)"
                  : "Selecciona materiales para generar etiquetas",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Descargar PDF"),
              onPressed: habilitado ? () => _generar(seleccion, imprimir: false) : null,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text("Imprimir"),
              onPressed: habilitado ? () => _generar(seleccion, imprimir: true) : null,
            ),
          ],
        ),
      ),
    );
  }

  void _verQr(Producto p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p.nombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: QrImageView(data: MaterialQr.payload(p), size: 220, padding: EdgeInsets.zero),
            ),
            const SizedBox(height: 12),
            Text(
              "Escanéalo para registrar entradas o salidas de stock.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.image_outlined),
            label: const Text("Descargar PNG"),
            onPressed: () => _descargarPng(p),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text("Imprimir"),
            onPressed: () {
              Navigator.pop(ctx);
              _generar([p], imprimir: true);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _descargarPng(Producto p) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _qrPng(MaterialQr.payload(p));
      final nombre = 'QR_${p.nombre.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.png';
      final file = XFile.fromData(bytes, mimeType: 'image/png', name: nombre);
      if (kIsWeb) {
        await file.saveTo(nombre);
      } else {
        // ignore: deprecated_member_use
        await Share.shareXFiles([file]);
      }
    } catch (e) {
      debugPrint("Descargar QR: $e");
      messenger.showSnackBar(
        const SnackBar(content: Text("No se pudo generar la imagen."), backgroundColor: AppTheme.brandRed),
      );
    }
  }

  // PNG de 600 px con fondo blanco y margen, legible al imprimir.
  static Future<Uint8List> _qrPng(String data) async {
    const double size = 600;
    const double margin = 40;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), Paint()..color = Colors.white);
    canvas.translate(margin, margin);
    QrPainter(data: data, version: QrVersions.auto, gapless: true)
        .paint(canvas, const Size(size - margin * 2, size - margin * 2));
    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
