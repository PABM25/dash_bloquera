import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/producto_modelo.dart';
import '../../providers/inventario_provider.dart';

class FormProductoScreen extends StatefulWidget {
  final Producto? producto; // Si es null, estamos creando. Si no, editando.
  const FormProductoScreen({super.key, this.producto});

  @override
  State<FormProductoScreen> createState() => _FormProductoScreenState();
}

class _FormProductoScreenState extends State<FormProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _costoCtrl;
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.producto?.nombre ?? '');
    _stockCtrl = TextEditingController(text: widget.producto?.stock.toString() ?? '');
    _costoCtrl = TextEditingController(text: widget.producto?.precioCosto.toString() ?? '');
    _descCtrl = TextEditingController(text: widget.producto?.descripcion ?? '');
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<InventarioProvider>(context, listen: false);
    final nombre = _nombreCtrl.text.trim();
    final stock = int.parse(_stockCtrl.text);
    final costo = double.parse(_costoCtrl.text);
    final desc = _descCtrl.text.trim();

    if (widget.producto == null) {
      provider.addProducto(nombre, stock, costo, desc);
    } else {
      // Crear objeto actualizado manteniendo el ID original
      final actualizado = Producto(
        id: widget.producto!.id,
        nombre: nombre,
        stock: stock,
        precioCosto: costo,
        descripcion: desc,
      );
      provider.updateProducto(actualizado);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.producto == null ? "Nuevo Producto" : "Editar Producto")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(labelText: "Stock"),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Requerido" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _costoCtrl,
                      decoration: const InputDecoration(labelText: "Costo Unitario"),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Requerido" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: "Descripción (Opcional)"),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: const Text("GUARDAR"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBF2642),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}