import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../providers/inventario_provider.dart';
import '../../models/producto_modelo.dart';

class EscanerStockScreen extends StatefulWidget {
  const EscanerStockScreen({super.key});

  @override
  State<EscanerStockScreen> createState() => _EscanerStockScreenState();
}

class _EscanerStockScreenState extends State<EscanerStockScreen> {
  final TextEditingController _barcodeCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = false;
  String _mensaje = "Escanea un código de barras para buscar el producto.";
  Color _mensajeColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    // Forzar foco en el campo oculto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onBarcodeScanned(String barcode) async {
    if (barcode.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<InventarioProvider>(context, listen: false);
    final producto = await provider.buscarProductoPorBarcode(barcode.trim());

    if (!mounted) return;

    if (producto != null) {
      // Opcional: Reproducir sonido de éxito
      // await _audioPlayer.play(AssetSource('sounds/beep.mp3')); // Si tienes el asset

      setState(() {
        _mensaje = "Producto encontrado: ${producto.nombre}";
        _mensajeColor = Colors.green;
      });

      _mostrarDialogoActualizarStock(producto);

    } else {
      // Opcional: Reproducir sonido de error
      setState(() {
        _mensaje = "Código no encontrado: $barcode";
        _mensajeColor = Colors.red;
      });
    }

    setState(() {
      _isLoading = false;
    });

    _barcodeCtrl.clear();
    // Volver a dar foco a la caja para el siguiente escaneo
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _mostrarDialogoActualizarStock(Producto producto) {
    final TextEditingController cantCtrl = TextEditingController(text: "1");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Añadir Stock: ${producto.nombre}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Stock actual: ${producto.stock}"),
              const SizedBox(height: 15),
              TextField(
                controller: cantCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Cantidad a sumar",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (val) {
                  _procesarActualizacion(ctx, producto, val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                FocusScope.of(context).requestFocus(_focusNode);
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () => _procesarActualizacion(ctx, producto, cantCtrl.text),
              child: const Text("Actualizar"),
            ),
          ],
        );
      },
    );
  }

  void _procesarActualizacion(BuildContext ctx, Producto producto, String cantidadStr) {
    final int cantidad = int.tryParse(cantidadStr) ?? 0;
    if (cantidad > 0) {
      final provider = Provider.of<InventarioProvider>(context, listen: false);
      provider.reponerStock(producto, cantidad);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Se sumaron $cantidad unidades a ${producto.nombre}')),
        );
      }
    }
    Navigator.pop(ctx);
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escáner de Stock"),
      ),
      body: GestureDetector(
        // Si el usuario toca cualquier parte de la pantalla, devolvemos el foco al textfield
        onTap: () => FocusScope.of(context).requestFocus(_focusNode),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey),
                const SizedBox(height: 30),

                Text(
                  _mensaje,
                  style: TextStyle(fontSize: 18, color: _mensajeColor, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  const Text(
                    "Esperando escaneo...",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),

                // Campo oculto (o casi invisible) que captura la entrada de la pistola
                Opacity(
                  opacity: 0.0,
                  child: TextField(
                    controller: _barcodeCtrl,
                    focusNode: _focusNode,
                    autofocus: true,
                    onSubmitted: _onBarcodeScanned,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
