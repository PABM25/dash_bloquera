import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/ventas_provider.dart';
import '../../providers/auth_provider.dart'; // AGREGAR
import '../../models/venta_model.dart';
import 'crear_venta_screen.dart';
import 'detalle_venta_screen.dart';

class ListaVentasScreen extends StatelessWidget {
  const ListaVentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    // 1. Detectar Rol
    final authProvider = Provider.of<AuthProvider>(context);
    final bool esSoloLectura = authProvider.role == 'demo';

    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes de Compra')),
      // 2. Ocultar FAB
      floatingActionButton: esSoloLectura ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearVentaScreen())),
        label: const Text("Nueva Venta"),
        icon: const Icon(Icons.shopping_cart),
      ),
      body: Consumer<VentasProvider>(
        // ... (el resto del código del body se mantiene igual, ya que es solo visualización)
        builder: (context, provider, _) {
             return StreamBuilder<List<Venta>>(
                stream: provider.ventasStream,
                builder: (context, snapshot) {
                  // ... (código existente de tu StreamBuilder) ...
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final venta = snapshot.data![index];
                      return ListTile(
                        title: Text("${venta.folio} - ${venta.cliente}"),
                        subtitle: Text(currency.format(venta.total)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DetalleVentaScreen(ventaInicial: venta)
                        )),
                      );
                    }
                  );
                }
             );
        }
      ),
    );
  }
}