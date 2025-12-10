import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inventario_provider.dart';
import '../../providers/auth_provider.dart'; // IMPORTANTE
import '../../models/producto_modelo.dart';
import 'form_producto_screen.dart';

class ListaProductosScreen extends StatelessWidget {
  const ListaProductosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    // 1. Detectar Rol
    final authProvider = Provider.of<AuthProvider>(context);
    final bool esSoloLectura = authProvider.role == 'demo';

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario Maestro')),
      // 2. Ocultar FAB
      floatingActionButton: esSoloLectura ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FormProductoScreen())),
        icon: const Icon(Icons.add),
        label: const Text("Nuevo Producto"),
      ),
      body: Consumer<InventarioProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<Producto>>(
            stream: provider.productosStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final productos = snapshot.data!;
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: productos.length,
                itemBuilder: (context, index) {
                  final prod = productos[index];
                  return ListTile(
                    title: Text(prod.nombre),
                    subtitle: Text("Stock: ${prod.stock} | ${currency.format(prod.precioCosto)}"),
                    // 3. Bloquear menú de acciones
                    trailing: esSoloLectura 
                      ? const Icon(Icons.lock_outline, color: Colors.grey)
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => provider.deleteProducto(prod.id),
                        ),
                    onTap: esSoloLectura ? null : () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FormProductoScreen(producto: prod)));
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