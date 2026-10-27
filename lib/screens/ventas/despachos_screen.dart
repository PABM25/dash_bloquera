import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/venta_model.dart';
import '../../providers/ventas_provider.dart';
import '../../utils/background_write.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/loading_dialog.dart';

class DespachosScreen extends StatelessWidget {
  const DespachosScreen({super.key});

  // Migración única para ventas creadas antes de guardar 'estado_entrega'.
  Future<void> _completarVentasAntiguas(BuildContext context) async {
    final provider = context.read<VentasProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Incluir ventas antiguas"),
        content: const Text(
          "Las ventas registradas antes de esta versión se marcarán como "
          "despacho PENDIENTE para que aparezcan aquí. Solo es necesario hacerlo una vez.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Continuar")),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    await runWithLoading(
      context,
      message: 'Actualizando ventas…',
      errorMessage: 'No se pudieron actualizar las ventas. Se requiere conexión.',
      (close) async {
        final cantidad = await provider.completarEstadoEntregaAntiguo();
        messenger.showSnackBar(SnackBar(
          content: Text(cantidad == 0
              ? "Todas las ventas ya estaban actualizadas."
              : "$cantidad ventas antiguas actualizadas."),
        ));
      },
    );
  }

  void _entregar(BuildContext context, VentasProvider provider, Venta v) {
    final messenger = ScaffoldMessenger.of(context);
    // Con la caché offline la venta sale de la lista al instante.
    guardarEnSegundoPlano(
      messenger,
      provider.marcarEntrega(v.id, "ENTREGADO"),
      mensajeError: "No se pudo marcar ${v.folio} como entregado.",
    );
    messenger.showSnackBar(SnackBar(content: Text("${v.folio} marcado como entregado")));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<VentasProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: ShellScope.menuButton(context),
        title: const Text('Despachos Pendientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Incluir ventas antiguas',
            onPressed: () => _completarVentasAntiguas(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Venta>>(
        stream: provider.despachosPendientesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("No se pudieron cargar los despachos."));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final despachos = snapshot.data!;

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
                  subtitle: Text(v.direccion?.isNotEmpty == true ? v.direccion! : "Sin dirección"),
                  trailing: ElevatedButton(
                    onPressed: () => _entregar(context, provider, v),
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
