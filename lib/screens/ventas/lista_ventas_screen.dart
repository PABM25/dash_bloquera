import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/ventas_provider.dart';
import '../../models/venta_model.dart';
import 'crear_venta_screen.dart';
import 'detalle_venta_screen.dart';
import '../../utils/export_util.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/loading_dialog.dart';

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
      // Cargar la siguiente página un poco antes de llegar al final.
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 200) {
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

    return Scaffold(
      appBar: AppBar(
        leading: ShellScope.menuButton(context),
        title: const Text('Órdenes de Compra'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar CSV',
            onPressed: () async {
              final ventasProvider = Provider.of<VentasProvider>(context, listen: false);
              await runWithLoading(
                context,
                message: 'Generando reporte…',
                (close) async {
                  final List<Venta> ventas = await ventasProvider.fetchVentasParaExportar();
                  if (ventas.isEmpty || !context.mounted) return;
                  List<List<dynamic>> rows = [
                    ["Folio", "Cliente", "Fecha", "Total", "Estado"]
                  ];
                  for (var v in ventas) {
                    rows.add([v.folio, v.cliente, dateFormat.format(v.fecha), v.total, v.estadoPago]);
                  }
                  await ExportUtil.exportToCSV(context, rows, "ventas_reporte", onGenerated: close);
                },
              );
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearVentaScreen())),
        label: const Text("Nueva Venta"),
        icon: const Icon(Icons.shopping_cart),
        backgroundColor: AppTheme.primary,
      ),
      body: Consumer<VentasProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.ventas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final ventas = provider.ventas;
          if (ventas.isEmpty && provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => provider.fetchVentas(refresh: true),
                    child: const Text("Reintentar"),
                  ),
                ],
              ),
            );
          }
          if (ventas.isEmpty) return const Center(child: Text("No hay ventas registradas"));

          return RefreshIndicator(
            onRefresh: () => provider.fetchVentas(refresh: true),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: ventas.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == ventas.length) {
                      // Botón visible también cuando la página cabe en pantalla
                      // (ahí no hay scroll que dispare la carga).
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: provider.isLoading
                              ? const CircularProgressIndicator()
                              : OutlinedButton(
                                  onPressed: provider.fetchVentas,
                                  child: Text(provider.error != null ? "Reintentar" : "Cargar más"),
                                ),
                        ),
                      );
                    }
                final venta = ventas[index];
                  Color estadoColor = venta.estadoPago == 'PAGADA' ? Colors.green : Colors.orange;
                  String estadoTexto = venta.estadoPago;

                  return Card(
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
                          color: estadoColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
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
              ),
            ),
          );
        },
      ),
    );
  }
}