import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ventas_provider.dart';
import '../../models/venta_model.dart';
import 'crear_venta_screen.dart';
import 'detalle_venta_screen.dart';
import '../../utils/export_util.dart';

class ListaVentasScreen extends StatefulWidget {
  const ListaVentasScreen({super.key});

  @override
  State<ListaVentasScreen> createState() => _ListaVentasScreenState();
}

class _ListaVentasScreenState extends State<ListaVentasScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<VentasProvider>(context, listen: false).fetchVentas();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final isDemo = Provider.of<AuthProvider>(context).isDemo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes de Compra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar CSV',
            onPressed: () async {
              final ventasProvider = Provider.of<VentasProvider>(context, listen: false);
              final List<Venta> ventas = await ventasProvider.ventasStream.first;
              if (ventas.isNotEmpty) {
                List<List<dynamic>> rows = [
                  ["Folio", "Cliente", "Fecha", "Total", "Estado"]
                ];
                for (var v in ventas) {
                  rows.add([v.folio, v.cliente, dateFormat.format(v.fecha), v.total, v.estadoPago]);
                }
                if (context.mounted) {
                  await ExportUtil.exportToCSV(context, rows, "ventas_reporte");
                }
              }
            },
          )
        ],
      ),
      floatingActionButton: isDemo ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearVentaScreen())),
        label: const Text("Nueva Venta"),
        icon: const Icon(Icons.shopping_cart),
        backgroundColor: const Color(0xFFBF2642),
      ),
      body: Consumer<VentasProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.ventas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final ventas = provider.ventas;
          if (ventas.isEmpty) return const Center(child: Text("No hay ventas registradas"));

          return RefreshIndicator(
            onRefresh: () => provider.fetchVentas(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: ventas.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == ventas.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final venta = ventas[index];
                  Color estadoColor = venta.estadoPago == 'PAGADA' ? Colors.green : Colors.orange;
                  String estadoTexto = venta.estadoPago;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        "${venta.folio} - ${venta.cliente}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(dateFormat.format(venta.fecha)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Total: ${currency.format(venta.total)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          // CAMBIO: withOpacity -> withValues
                          color: estadoColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          // CAMBIO: withOpacity -> withValues
                          border: Border.all(color: estadoColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          estadoTexto,
                          style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => DetalleVentaScreen(ventaInicial: venta)
                      ));
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}