import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finanzas_provider.dart';
import '../../models/gasto_model.dart';
import '../../utils/formatters.dart';
import 'form_gasto_screen.dart';

class ListaGastosScreen extends StatelessWidget {
  const ListaGastosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gastos")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormGastoScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Consumer<FinanzasProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<Gasto>>(
            stream: provider.gastosStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final gastos = snapshot.data!;
              if (gastos.isEmpty) {
                return const Center(child: Text("No hay gastos registrados"));
              }

              return ListView.separated(
                itemCount: gastos.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final g = gastos[index];
                  // Icono según categoría
                  IconData icono = Icons.money_off;
                  if (g.categoria == 'SALARIO') icono = Icons.people;
                  if (g.categoria == 'MATERIAL') icono = Icons.build;
                  if (g.categoria == 'TRANSPORTE') icono = Icons.local_shipping;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(icono, color: Colors.white),
                    ),
                    title: Text(g.descripcion),
                    subtitle: Text(
                      "${Formatters.formatDate(g.fecha)} | ${g.categoria}",
                    ),
                    trailing: Text(
                      Formatters.formatCurrency(g.monto),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onLongPress: () {
                      // Borrar gasto
                      provider.deleteGasto(g.id);
                    },
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
