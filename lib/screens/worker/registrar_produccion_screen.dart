import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/producto_modelo.dart';
import '../../providers/inventario_provider.dart';

class RegistrarProduccionScreen extends StatefulWidget {
  const RegistrarProduccionScreen({super.key});

  @override
  State<RegistrarProduccionScreen> createState() => _RegistrarProduccionScreenState();
}

class _RegistrarProduccionScreenState extends State<RegistrarProduccionScreen> {
  final _cantidadCtrl = TextEditingController();
  Producto? _productoSeleccionado;
  bool _isLoading = false;

  void _guardarProduccion() async {
    if (_productoSeleccionado == null || _cantidadCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Seleccione producto y cantidad")));
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<InventarioProvider>(context, listen: false);
    final int cantidad = int.parse(_cantidadCtrl.text);

    try {
      // This method (to be added to provider) updates stock AND logs production for salary
      await provider.registrarProduccionBloquero(
        producto: _productoSeleccionado!,
        cantidad: cantidad,
        fecha: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Producción registrada y Stock actualizado"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Bloques Fabricados")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Reporte de Producción Diaria",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Product Selector (Only manufactured items ideally)
            Consumer<InventarioProvider>(
              builder: (context, provider, _) => StreamBuilder<List<Producto>>(
                stream: provider.productosStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  
                  // Filter maybe only categories like 'BLOQUES'
                  final productos = snapshot.data!; 
                  
                  return DropdownButtonFormField<Producto>(
                    decoration: const InputDecoration(
                      labelText: "Producto Fabricado",
                      border: OutlineInputBorder(),
                    ),
                    value: _productoSeleccionado,
                    items: productos.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(p.nombre),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _productoSeleccionado = val),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Cantidad Fabricada",
                helperText: "Total de unidades producidas hoy",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardarProduccion,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("CONFIRMAR PRODUCCIÓN"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}