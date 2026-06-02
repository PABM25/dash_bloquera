import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/proveedores_provider.dart';
import '../../models/proveedor_model.dart';

class ListaProveedoresScreen extends StatelessWidget {
  const ListaProveedoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Directorio de Proveedores')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoProveedor(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ProveedoresProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<Proveedor>>(
            stream: provider.proveedoresStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No hay proveedores registrados."));
              }

              final proveedores = snapshot.data!;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: proveedores.length,
                    itemBuilder: (context, index) {
                      final p = proveedores[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.business)),
                          title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("RUT: ${p.rut}\nContacto: ${p.contacto}"),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _mostrarDialogoProveedor(context, proveedor: p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => provider.eliminarProveedor(p.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarDialogoProveedor(BuildContext context, {Proveedor? proveedor}) {
    final nombreCtrl = TextEditingController(text: proveedor?.nombre ?? '');
    final rutCtrl = TextEditingController(text: proveedor?.rut ?? '');
    final contactoCtrl = TextEditingController(text: proveedor?.contacto ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(proveedor == null ? "Nuevo Proveedor" : "Editar Proveedor"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre / Razón Social"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              TextFormField(
                controller: rutCtrl,
                decoration: const InputDecoration(labelText: "RUT / Identificación"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              TextFormField(
                controller: contactoCtrl,
                decoration: const InputDecoration(labelText: "Teléfono / Email"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final provider = Provider.of<ProveedoresProvider>(context, listen: false);
                if (proveedor == null) {
                  provider.agregarProveedor(nombreCtrl.text.trim(), rutCtrl.text.trim(), contactoCtrl.text.trim());
                } else {
                  provider.actualizarProveedor(Proveedor(
                    id: proveedor.id,
                    nombre: nombreCtrl.text.trim(),
                    rut: rutCtrl.text.trim(),
                    contacto: contactoCtrl.text.trim(),
                  ));
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}
