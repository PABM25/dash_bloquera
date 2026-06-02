import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/compras_provider.dart';
import '../../providers/proveedores_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/proveedor_model.dart';
import '../../models/compra_model.dart';
import '../../models/producto_modelo.dart';

class CrearCompraScreen extends StatefulWidget {
  const CrearCompraScreen({super.key});

  @override
  State<CrearCompraScreen> createState() => _CrearCompraScreenState();
}

class _CrearCompraScreenState extends State<CrearCompraScreen> {
  Proveedor? _proveedorSeleccionado;
  final List<CompraItem> _carrito = [];
  bool _isLoading = false;

  void _agregarProducto() async {
    final invProvider = Provider.of<InventarioProvider>(context, listen: false);
    final productos = await invProvider.productosStream.first;

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: productos.length,
        itemBuilder: (ctx, index) {
          final p = productos[index];
          return ListTile(
            title: Text(p.nombre),
            subtitle: Text("Stock actual: ${p.stock}"),
            onTap: () {
              Navigator.pop(ctx);
              _dialogoCantidadCosto(p);
            },
          );
        },
      ),
    );
  }

  void _dialogoCantidadCosto(Producto p) {
    final cantCtrl = TextEditingController(text: "1");
    final costoCtrl = TextEditingController(text: p.precioCosto.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Agregar ${p.nombre}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cantCtrl, decoration: const InputDecoration(labelText: "Cantidad a comprar"), keyboardType: TextInputType.number),
            TextField(controller: costoCtrl, decoration: const InputDecoration(labelText: "Costo de compra unitario"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final cant = int.tryParse(cantCtrl.text) ?? 0;
              final costo = double.tryParse(costoCtrl.text) ?? 0.0;
              if (cant > 0 && costo > 0) {
                setState(() {
                  _carrito.add(CompraItem(productoId: p.id, nombre: p.nombre, cantidad: cant, costoUnitario: costo, totalLinea: cant * costo));
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

  void _guardarCompra() async {
    if (_proveedorSeleccionado == null || _carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione proveedor y productos")));
      return;
    }
    setState(() => _isLoading = true);

    final total = _carrito.fold(0.0, (sum, item) => sum + item.totalLinea);
    await Provider.of<ComprasProvider>(context, listen: false).registrarCompra(
      proveedorId: _proveedorSeleccionado!.id,
      proveedorNombre: _proveedorSeleccionado!.nombre,
      items: _carrito,
      total: total,
      fecha: DateTime.now(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Compra registrada. Stock sumado.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Compra")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Seleccionar Proveedor", style: TextStyle(fontWeight: FontWeight.bold)),
                StreamBuilder<List<Proveedor>>(
                  stream: Provider.of<ProveedoresProvider>(context, listen: false).proveedoresStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    return DropdownButton<Proveedor>(
                      isExpanded: true,
                      value: _proveedorSeleccionado,
                      hint: const Text("Elija un proveedor"),
                      items: snapshot.data!.map((p) => DropdownMenuItem(value: p, child: Text(p.nombre))).toList(),
                      onChanged: (val) => setState(() => _proveedorSeleccionado = val),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Productos a Comprar", style: TextStyle(fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(onPressed: _agregarProducto, icon: const Icon(Icons.add), label: const Text("Añadir")),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _carrito.length,
                    itemBuilder: (context, index) {
                      final item = _carrito[index];
                      return ListTile(
                        title: Text(item.nombre),
                        subtitle: Text("${item.cantidad} x \$${item.costoUnitario} = \$${item.totalLinea}"),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _carrito.removeAt(index))),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _guardarCompra,
                    child: _isLoading ? const CircularProgressIndicator() : const Text("FINALIZAR COMPRA"),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
