import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/producto_modelo.dart';
import '../../models/venta_model.dart';
import '../../providers/inventario_provider.dart';
import '../../providers/ventas_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ticket_preview.dart';

class CrearVentaScreen extends StatefulWidget {
  const CrearVentaScreen({super.key});

  @override
  State<CrearVentaScreen> createState() => _CrearVentaScreenState();
}

class _CrearVentaScreenState extends State<CrearVentaScreen> {
  final _clienteCtrl = TextEditingController();
  final _rutCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  List<ItemOrden> carrito = [];
  double get totalVenta =>
      carrito.fold(0, (sum, item) => sum + item.totalLinea);

  void _mostrarSelector() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Consumer<InventarioProvider>(
        builder: (context, provider, _) => StreamBuilder<List<Producto>>(
          stream: provider.productosStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final productos = snapshot.data!;
            return ListView.builder(
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final p = productos[index];
                return ListTile(
                  title: Text(p.nombre),
                  subtitle: Text("Stock: ${p.stock}"),
                  enabled: p.stock > 0,
                  onTap: () {
                    Navigator.pop(ctx);
                    _dialogoCantidad(p);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _dialogoCantidad(Producto p) {
    final cantCtrl = TextEditingController(text: "1");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Agregar ${p.nombre}"),
        content: TextField(
          controller: cantCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Cantidad"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              int cant = int.tryParse(cantCtrl.text) ?? 0;
              if (cant > 0 && cant <= p.stock) {
                setState(() {
                  carrito.add(
                    ItemOrden(
                      productoId: p.id,
                      nombre: p.nombre,
                      cantidad: cant,
                      precioUnitario: p.precioCosto * 1.3, // Ejemplo margen 30%
                      totalLinea: (p.precioCosto * 1.3) * cant,
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }

  void _guardar() async {
    if (carrito.isEmpty || _clienteCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete cliente y agregue productos")),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final provider = Provider.of<VentasProvider>(context, listen: false);

    try {
      await provider.crearVenta(
        cliente: _clienteCtrl.text,
        rut: _rutCtrl.text,
        direccion: _direccionCtrl.text,
        items: carrito,
      );

      // Cerrar loading
      if (mounted) Navigator.pop(context);
      // Cerrar pantalla
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Venta creada exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Cerrar loading
      if (mounted) Navigator.pop(context);

      String errorMsg = "Ocurrió un error inesperado";
      if (e.toString().contains("STOCK_INSUFICIENTE")) {
        errorMsg = "Stock insuficiente para uno de los productos.";
      } else if (e.toString().contains("PRODUCTO_NO_EXISTE")) {
        errorMsg = "Un producto seleccionado ya no existe.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Layout Responsivo: Columna en celular, Fila en Tablet
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Venta")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          Widget form = _buildForm();
          Widget ticket = TicketPreview(
            cliente: _clienteCtrl.text,
            rut: _rutCtrl.text,
            direccion: _direccionCtrl.text,
            items: carrito,
            total: totalVenta,
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: form,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ticket,
                  ),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  form,
                  const Divider(height: 40),
                  const Text(
                    "VISTA PREVIA",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ticket,
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        TextField(
          controller: _clienteCtrl,
          decoration: const InputDecoration(labelText: "Cliente"),
          onChanged: (v) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _rutCtrl,
                decoration: const InputDecoration(labelText: "RUT"),
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(labelText: "Dirección"),
                onChanged: (v) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Productos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: _mostrarSelector,
              child: const Text("AGREGAR"),
            ),
          ],
        ),
        // Lista Items Editable
        ...carrito.map(
          (item) => ListTile(
            title: Text(item.nombre),
            subtitle: Text("${item.cantidad} x ${item.precioUnitario}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => carrito.remove(item)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("GUARDAR VENTA"),
          ),
        ),
      ],
    );
  }
}
