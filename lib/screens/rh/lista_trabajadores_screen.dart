import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rh_provider.dart';
import '../../models/trabajador_model.dart';
import '../../utils/formatters.dart';
import 'form_trabajador_screen.dart';

class ListaTrabajadoresScreen extends StatelessWidget {
  const ListaTrabajadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormTrabajadorScreen())),
        child: const Icon(Icons.person_add),
      ),
      body: Consumer<RhProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<Trabajador>>(
            stream: provider.trabajadoresStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final trabajadores = snapshot.data!;
              
              if (trabajadores.isEmpty) return const Center(child: Text("No hay trabajadores registrados"));

              return ListView.builder(
                itemCount: trabajadores.length,
                itemBuilder: (context, index) {
                  final t = trabajadores[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: t.tipoProyecto == 'CONSTRUCTORA' ? Colors.orange.shade100 : Colors.blue.shade100,
                      child: Icon(Icons.person, color: t.tipoProyecto == 'CONSTRUCTORA' ? Colors.orange : Colors.blue),
                    ),
                    title: Text(t.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${t.cargo ?? 'Sin cargo'} | ${Formatters.formatCurrency(t.salarioPorDia)}/día"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FormTrabajadorScreen(trabajador: t))),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmarEliminar(context, provider, t),
                        ),
                      ],
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

  void _confirmarEliminar(BuildContext context, RhProvider provider, Trabajador t) {
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        title: const Text("Eliminar Trabajador"),
        content: Text("¿Seguro que deseas eliminar a ${t.nombre}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(onPressed: () {
            provider.deleteTrabajador(t.id);
            Navigator.pop(context);
          }, child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      )
    );
  }
}