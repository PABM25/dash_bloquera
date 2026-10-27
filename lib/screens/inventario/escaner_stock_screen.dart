import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/producto_modelo.dart';
import '../../utils/background_write.dart';

class EscanerStockScreen extends StatefulWidget {
  const EscanerStockScreen({super.key});

  @override
  State<EscanerStockScreen> createState() => _EscanerStockScreenState();
}

class _EscanerStockScreenState extends State<EscanerStockScreen> {
  final TextEditingController _barcodeCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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
    super.dispose();
  }

  void _onBarcodeScanned(String barcode) async {
    if (barcode.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<InventarioProvider>(context, listen: false);
    bool fallo = false;
    final Producto? producto = await provider.buscarProductoPorBarcode(barcode.trim()).catchError((Object e) {
      debugPrint("Buscar por código: $e");
      fallo = true;
      return null;
    });

    if (!mounted) return;

    if (fallo) {
      setState(() {
        _mensaje = "No se pudo buscar el código. Revisa la conexión.";
        _mensajeColor = Colors.red;
      });
    } else if (producto != null) {
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
      final messenger = ScaffoldMessenger.of(context);
      guardarEnSegundoPlano(
        messenger,
        provider.reponerStock(producto, cantidad),
        mensajeError: "No se pudo sumar stock a ${producto.nombre}.",
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Se sumaron $cantidad unidades a ${producto.nombre}')),
      );
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
