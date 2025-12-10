import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rh_provider.dart';
import '../../providers/auth_provider.dart'; // IMPORTANTE
import '../../models/trabajador_model.dart';
import 'form_trabajador_screen.dart';

class ListaTrabajadoresScreen extends StatelessWidget {
  const ListaTrabajadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Detectar Rol
    final authProvider = Provider.of<AuthProvider>(context);
    final bool esSoloLectura = authProvider.role == 'demo';

    return Scaffold(
      appBar: AppBar(title: const Text("Personal")),
      // 2. Ocultar FAB
      floatingActionButton: esSoloLectura ? null : FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormTrabajadorScreen())),
        child: const Icon(Icons.add),
      ),
      body: Consumer<RhProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<Trabajador>>(
            stream: provider.trabajadoresStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final t = snapshot.data![index];
                  return ListTile(
                    title: Text(t.nombre),
                    subtitle: Text(t.cargo ?? "Sin cargo"),
                    // 3. Bloquear acciones
                    trailing: esSoloLectura
                      ? const Icon(Icons.lock_outline, color: Colors.grey)
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => provider.deleteTrabajador(t.id),
                        ),
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