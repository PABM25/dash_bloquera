import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rh_provider.dart';
import '../../models/trabajador_model.dart';
import '../../utils/formatters.dart';

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  Trabajador? _trabajadorSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Asistencia")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Selector de Fecha
            ListTile(
              title: const Text("Fecha de Asistencia"),
              subtitle: Text(Formatters.formatDate(_fechaSeleccionada)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaSeleccionada,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _fechaSeleccionada = picked);
              },
            ),
            const Divider(),
            
            // Selector de Trabajador (desde Provider)
            Expanded(
              child: Consumer<RhProvider>(
                builder: (context, provider, _) {
                  return StreamBuilder<List<Trabajador>>(
                    stream: provider.trabajadoresStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final trabajadores = snapshot.data!;

                      return ListView.builder(
                        itemCount: trabajadores.length,
                        itemBuilder: (context, index) {
                          final t = trabajadores[index];
                          final isSelected = _trabajadorSeleccionado?.id == t.id;

                          return Card(
                            color: isSelected ? Colors.red.shade50 : null,
                            child: ListTile(
                              leading: Icon(Icons.person, color: isSelected ? Colors.red : Colors.grey),
                              title: Text(t.nombre),
                              subtitle: Text(t.tipoProyecto),
                              trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.red) : null,
                              onTap: () => setState(() => _trabajadorSeleccionado = t),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            
            // Botón Guardar
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _trabajadorSeleccionado == null ? null : () async {
                  final provider = Provider.of<RhProvider>(context, listen: false);
                  String? error = await provider.registrarAsistencia(
                    _trabajadorSeleccionado!.id,
                    _trabajadorSeleccionado!.nombre,
                    _fechaSeleccionada,
                    _trabajadorSeleccionado!.tipoProyecto
                  );

                  if (!mounted) return;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.orange));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Asistencia Registrada"), backgroundColor: Colors.green));
                    setState(() => _trabajadorSeleccionado = null); // Resetear selección
                  }
                },
                child: const Text("MARCAR ASISTENCIA"),
              ),
            )
          ],
        ),
      ),
    );
  }
}