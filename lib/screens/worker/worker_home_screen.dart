// Archivo: lib/screens/worker/worker_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; 
import 'registrar_produccion_screen.dart';
import 'marcar_asistencia_screen.dart';
import '../ventas/crear_venta_screen.dart'; 

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos el provider
    final authProvider = Provider.of<AuthProvider>(context);
    
    // 2. Obtenemos el usuario de Firebase Auth (para el nombre)
    final user = authProvider.currentUser; 
    
    // 3. Obtenemos el ROL desde la variable del provider (que viene de Firestore)
    //    Si es nulo, asumimos 'TRABAJADOR' por seguridad.
    final String rol = authProvider.role ?? 'TRABAJADOR'; 

    final String nombre = user?.displayName ?? 'Trabajador';

    return Scaffold(
      appBar: AppBar(
        title: Text("Panel de $nombre"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- BOTÓN COMÚN: ASISTENCIA ---
            _buildBigButton(
              context,
              icon: Icons.access_time,
              label: "MARCAR ASISTENCIA",
              color: Colors.blue.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarcarAsistenciaScreen()),
              ),
            ),
            const SizedBox(height: 20),
            
            // --- MENÚ PARA BLOQUEROS ---
            if (rol.toUpperCase() == 'BLOQUERO' || rol.toUpperCase() == 'ADMIN') 
              _buildBigButton(
                context,
                icon: Icons.grid_view,
                label: "REGISTRAR PRODUCCIÓN\n(Entregar Bloques)",
                color: Colors.orange.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegistrarProduccionScreen()),
                ),
              ),

            // --- MENÚ PARA VENDEDORES ---
            if (rol.toUpperCase() == 'VENDEDOR' || rol.toUpperCase() == 'ADMIN') ...[
              const SizedBox(height: 20),
              _buildBigButton(
                context,
                icon: Icons.point_of_sale,
                label: "NUEVA VENTA",
                color: Colors.green.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearVentaScreen()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBigButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return SizedBox(
      height: 100,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        icon: Icon(icon, size: 40),
        label: Text(label, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
        onPressed: onTap,
      ),
    );
  }
}