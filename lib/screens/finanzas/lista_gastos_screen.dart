import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finanzas_provider.dart';
import '../../models/gasto_model.dart';
import '../../utils/formatters.dart';
import '../../utils/background_write.dart';
import 'form_gasto_screen.dart';
import '../../widgets/app_shell.dart';

class ListaGastosScreen extends StatefulWidget {
  const ListaGastosScreen({super.key});

  @override
  State<ListaGastosScreen> createState() => _ListaGastosScreenState();
}

class _ListaGastosScreenState extends State<ListaGastosScreen> {
  int _limit = FinanzasProvider.pageSize;
  // La consulta se crea una vez (y al pedir más), no en cada build().
  late Stream<List<Gasto>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<FinanzasProvider>().gastosStream(limit: _limit);
  }

  void _cargarMas() {
    setState(() {
      _limit += FinanzasProvider.pageSize;
      _stream = context.read<FinanzasProvider>().gastosStream(limit: _limit);
    });
  }

  void _confirmarEliminar(FinanzasProvider provider, Gasto g) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar gasto"),
        content: Text(
          "¿Eliminar '${g.descripcion}' por ${Formatters.formatCurrency(g.monto)}?"
          "${g.categoria == 'MATERIAL' ? '\nSi corresponde a una compra, la compra y el stock no se modifican.' : ''}",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              guardarEnSegundoPlano(messenger, provider.deleteGasto(g.id),
                  mensajeError: "No se pudo eliminar el gasto.");
              Navigator.pop(ctx);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FinanzasProvider>();

    return Scaffold(
      appBar: AppBar(leading: ShellScope.menuButton(context), title: const Text("Gastos")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormGastoScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Gasto>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final gastos = snapshot.data!;
              if (gastos.isEmpty) {
                return const Center(child: Text("No hay gastos registrados"));
              }

              final hayMas = gastos.length >= _limit;

              return ListView.separated(
                itemCount: gastos.length + (hayMas ? 1 : 0),
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  if (index == gastos.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: OutlinedButton(onPressed: _cargarMas, child: const Text("Cargar más")),
                      ),
                    );
                  }
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
                    onLongPress: () => _confirmarEliminar(provider, g),
                  );
                },
              );
            },
      ),
    );
  }
}
