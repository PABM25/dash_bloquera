import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/failure.dart';
import '../../providers/compras_provider.dart';
import '../../providers/proveedores_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../models/proveedor_model.dart';
import '../../models/compra_model.dart';
import '../../models/producto_modelo.dart';
import '../../utils/formatters.dart';

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
    final costoCtrl = TextEditingController(text: Formatters.montoParaEditar(p.precioCosto));

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
              final costo = Formatters.parseMonto(costoCtrl.text) ?? 0.0;
              if (cant > 0 && cant <= 1000000 && costo > 0) {
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

    try {
      await Provider.of<ComprasProvider>(context, listen: false).registrarCompra(
        proveedorId: _proveedorSeleccionado!.id,
        proveedorNombre: _proveedorSeleccionado!.nombre,
        items: _carrito,
        fecha: DateTime.now(),
      );
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: Colors.red));
      return;
    }

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
                    final proveedores = snapshot.data!;
                    // Se usa el ID como valor: cada actualización del stream crea
                    // objetos nuevos y comparar por instancia rompía el Dropdown.
                    final seleccionado = proveedores.where((p) => p.id == _proveedorSeleccionado?.id).firstOrNull;
                    return DropdownButton<String>(
                      isExpanded: true,
                      value: seleccionado?.id,
                      hint: const Text("Elija un proveedor"),
                      items: proveedores.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre))).toList(),
                      onChanged: (id) => setState(() {
                        _proveedorSeleccionado = proveedores.firstWhere((p) => p.id == id);
                      }),
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
                        subtitle: Text("${item.cantidad} x ${Formatters.formatCurrency(item.costoUnitario)} = ${Formatters.formatCurrency(item.totalLinea)}"),
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
