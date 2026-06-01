import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inventario_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/producto_modelo.dart';
import 'form_producto_screen.dart';
import 'escaner_stock_screen.dart';
import '../../utils/export_util.dart';

class ListaProductosScreen extends StatelessWidget {
  const ListaProductosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    
    // 1. Detectar Rol
    final authProvider = Provider.of<AuthProvider>(context);
    final bool esSoloLectura = authProvider.role == 'demo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario Maestro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar CSV',
            onPressed: () async {
              final prodProvider = Provider.of<InventarioProvider>(context, listen: false);
              final List<Producto> productos = await prodProvider.productosStream.first;
              if (productos.isNotEmpty) {
                List<List<dynamic>> rows = [
                  ["ID", "Nombre", "Descripción", "Stock", "Precio Costo"]
                ];
                for (var p in productos) {
                  rows.add([p.id, p.nombre, p.descripcion ?? "", p.stock, p.precioCosto]);
                }
                if (context.mounted) {
                  await ExportUtil.exportToCSV(context, rows, "inventario_maestro");
                }
              }
            },
          )
        ],
      ),
      
      // 2. Ocultar botón si es solo lectura
      floatingActionButton: esSoloLectura ? null : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn_escaner",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EscanerStockScreen())),
            backgroundColor: Colors.blueGrey,
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "btn_nuevo_prod",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormProductoScreen())),
            icon: const Icon(Icons.add),
            label: const Text("Nuevo Producto"),
          ),
        ],
      ),
      
      body: Consumer<InventarioProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<Producto>>(
            stream: provider.productosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // CORRECCIÓN DE UI: Estado Vacío (Empty State)
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "No hay productos registrados",
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      if (!esSoloLectura)
                        TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormProductoScreen())),
                          icon: const Icon(Icons.add),
                          label: const Text("Agregar el primero"),
                        ),
                    ],
                  ),
                );
              }

              final productos = snapshot.data!;
              
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final prod = productos[index];
                      return Card( // Agregamos un Card para mejor visualización
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: prod.stock < 10 ? Colors.red[100] : Colors.blue[100],
                        child: Icon(
                          Icons.dns, 
                          color: prod.stock < 10 ? Colors.red : Colors.blue,
                        ),
                      ),
                      title: Text(prod.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Stock: ${prod.stock} | Costo: ${currency.format(prod.precioCosto)}"),
                      trailing: esSoloLectura 
                        ? const Icon(Icons.lock_outline, color: Colors.grey)
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmarEliminar(context, provider, prod),
                          ),
                          onTap: esSoloLectura ? null : () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => FormProductoScreen(producto: prod)));
                          },
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper para confirmar eliminación (Mejora de UX adicional)
  void _confirmarEliminar(BuildContext context, InventarioProvider provider, Producto prod) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text("¿Estás seguro de eliminar '${prod.nombre}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              provider.deleteProducto(prod.id);
              Navigator.pop(ctx);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}