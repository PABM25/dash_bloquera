import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatear moneda
import '../../providers/inventario_provider.dart';
import '../../models/producto_modelo.dart';
import 'form_producto_screen.dart';

class ListaProductosScreen extends StatelessWidget {
  const ListaProductosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario Maestro')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormProductoScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text("Nuevo Producto"),
      ),
      body: Consumer<InventarioProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<List<Producto>>(
            stream: provider.productosStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Error al cargar inventario"));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final productos = snapshot.data!;
              if (productos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Inventario vacío",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final prod = productos[index];
                  final bool stockBajo = prod.stock < 10;
                  final bool sinStock = prod.stock == 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: sinStock
                            ? Colors.red.shade200
                            : (stockBajo
                                  ? Colors.orange.shade200
                                  : Colors.transparent),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.construction,
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(
                        prod.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "Costo Unitario: ${currency.format(prod.precioCosto)}",
                          ),
                          const SizedBox(height: 8),
                          Row(children: [_StockBadge(stock: prod.stock)]),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text("Editar"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "Eliminar",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (val) {
                          if (val == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FormProductoScreen(producto: prod),
                              ),
                            );
                          } else if (val == 'delete') {
                            // Lógica de borrado (provider.deleteProducto...)
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Widget auxiliar para la etiqueta de stock
class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.green;
    String text = "En Stock ($stock)";

    if (stock == 0) {
      color = Colors.red;
      text = "Agotado";
    } else if (stock < 10) {
      color = Colors.orange;
      text = "Bajo Stock ($stock)";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
