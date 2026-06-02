import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ventas_provider.dart';

class DespachosScreen extends StatelessWidget {
  const DespachosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Despachos Pendientes')),
      body: Consumer<VentasProvider>(
        builder: (context, provider, _) {
          final despachos = provider.ventas.where((v) => v.estadoEntrega == 'PENDIENTE').toList();

          if (despachos.isEmpty) {
            return const Center(child: Text("No hay despachos pendientes."));
          }

          return ListView.builder(
            itemCount: despachos.length,
            itemBuilder: (context, index) {
              final v = despachos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.local_shipping, color: Colors.orange),
                  title: Text("${v.folio} - ${v.cliente}"),
                  subtitle: Text(v.direccion ?? "Sin dirección"),
                  trailing: ElevatedButton(
                    onPressed: () {
                      provider.marcarEntrega(v.id, "ENTREGADO");
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Marcado como entregado")));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text("ENTREGAR"),
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
