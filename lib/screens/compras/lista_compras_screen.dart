import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/compras_provider.dart';
import '../../models/compra_model.dart';
import 'crear_compra_screen.dart';

class ListaComprasScreen extends StatelessWidget {
  const ListaComprasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Compras')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearCompraScreen())),
        label: const Text("Nueva Compra"),
        icon: const Icon(Icons.add_shopping_cart),
      ),
      body: Consumer<ComprasProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<Compra>>(
            stream: provider.comprasStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No hay compras registradas."));
              }

              final compras = snapshot.data!;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: compras.length,
                    itemBuilder: (context, index) {
                      final c = compras[index];
                      return Card(
                        child: ExpansionTile(
                          leading: const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.inventory, color: Colors.white)),
                          title: Text("${c.folio} - ${c.proveedorNombre}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${dateFormat.format(c.fecha)} | Total: ${currency.format(c.total)}"),
                          children: c.items.map((item) {
                            return ListTile(
                              dense: true,
                              title: Text(item.nombre),
                              trailing: Text("${item.cantidad} x ${currency.format(item.costoUnitario)} = ${currency.format(item.totalLinea)}"),
                            );
                          }).toList(),
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
}
