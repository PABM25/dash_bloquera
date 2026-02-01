import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/presupuestos_provider.dart';
import '../../models/presupuesto_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/pdf_generator.dart'; // Para regenerar el PDF
import '../../widgets/app_drawer.dart';
import '../screens/ventas/crear_presupuesto_screen.dart';

class ListaPresupuestosScreen extends StatelessWidget {
  const ListaPresupuestosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Cotizaciones"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: Consumer<PresupuestosProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<Presupuesto>>(
            stream: provider.presupuestosStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final presupuestos = snapshot.data ?? [];

              if (presupuestos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 20),
                      const Text("No hay cotizaciones registradas", style: TextStyle(color: Colors.grey, fontSize: 18)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Crear Primera Cotización"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CrearPresupuestoScreen()),
                          );
                        },
                      )
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: presupuestos.length,
                itemBuilder: (context, index) {
                  final p = presupuestos[index];
                  // Verificar si está vencida
                  final bool vencida = DateTime.now().isAfter(p.fechaVencimiento);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: vencida ? Colors.red[100] : Colors.blueGrey[100],
                        child: Icon(Icons.description, color: vencida ? Colors.red : Colors.blueGrey),
                      ),
                      title: Text(p.cliente, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.folio, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          Text("Emisión: ${dateFormat.format(p.fechaEmision)}"),
                          if (vencida)
                             Text("VENCIDA (${dateFormat.format(p.fechaVencimiento)})", style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))
                          else
                             Text("Vence: ${dateFormat.format(p.fechaVencimiento)}", style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currencyFormat.format(p.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          InkWell(
                            onTap: () => PdfGenerator.generatePresupuestoA4(p),
                            child: Container(
                              margin: const EdgeInsets.only(top: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.picture_as_pdf, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text("PDF", style: TextStyle(color: Colors.white, fontSize: 10)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearPresupuestoScreen()),
          );
        },
      ),
    );
  }
}