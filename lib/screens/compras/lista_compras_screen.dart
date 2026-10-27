import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/compras_provider.dart';
import '../../models/compra_model.dart';
import 'crear_compra_screen.dart';
import '../../widgets/app_shell.dart';

class ListaComprasScreen extends StatefulWidget {
  const ListaComprasScreen({super.key});

  @override
  State<ListaComprasScreen> createState() => _ListaComprasScreenState();
}

class _ListaComprasScreenState extends State<ListaComprasScreen> {
  int _limit = ComprasProvider.pageSize;
  // La consulta se crea una vez (y al pedir más), no en cada build().
  late Stream<List<Compra>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<ComprasProvider>().comprasStream(limit: _limit);
  }

  void _cargarMas() {
    setState(() {
      _limit += ComprasProvider.pageSize;
      _stream = context.read<ComprasProvider>().comprasStream(limit: _limit);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(leading: ShellScope.menuButton(context), title: const Text('Historial de Compras')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearCompraScreen())),
        label: const Text("Nueva Compra"),
        icon: const Icon(Icons.add_shopping_cart),
      ),
      body: StreamBuilder<List<Compra>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.isEmpty) {
                return const Center(child: Text("No hay compras registradas."));
              }

              final compras = snapshot.data!;
              final hayMas = compras.length >= _limit;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: compras.length + (hayMas ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == compras.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: OutlinedButton(onPressed: _cargarMas, child: const Text("Cargar más")),
                          ),
                        );
                      }
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
      ),
    );
  }
}
