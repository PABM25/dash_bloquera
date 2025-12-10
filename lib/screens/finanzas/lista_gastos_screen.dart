import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finanzas_provider.dart';
import '../../providers/auth_provider.dart'; // IMPORTANTE
import '../../models/gasto_model.dart';
import '../../utils/formatters.dart';
import 'form_gasto_screen.dart';

class ListaGastosScreen extends StatelessWidget {
  const ListaGastosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Detectar Rol
    final authProvider = Provider.of<AuthProvider>(context);
    final bool esSoloLectura = authProvider.role == 'demo';

    return Scaffold(
      appBar: AppBar(title: const Text("Gastos")),
      // 2. Ocultar FAB
      floatingActionButton: esSoloLectura ? null : FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormGastoScreen())),
        child: const Icon(Icons.add),
      ),
      body: Consumer<FinanzasProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<Gasto>>(
            stream: provider.gastosStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.separated(
                itemCount: snapshot.data!.length,
                separatorBuilder: (_,__) => const Divider(),
                itemBuilder: (context, index) {
                  final g = snapshot.data![index];
                  return ListTile(
                    title: Text(g.descripcion),
                    subtitle: Text("${Formatters.formatDate(g.fecha)} | ${g.categoria}"),
                    trailing: Text(Formatters.formatCurrency(g.monto)),
                    // 3. Bloquear borrado
                    onLongPress: esSoloLectura ? null : () => provider.deleteGasto(g.id),
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