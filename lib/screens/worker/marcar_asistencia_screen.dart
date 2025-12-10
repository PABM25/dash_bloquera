import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rh_provider.dart'; 
import '../../providers/auth_provider.dart';

class MarcarAsistenciaScreen extends StatefulWidget {
  const MarcarAsistenciaScreen({super.key});

  @override
  State<MarcarAsistenciaScreen> createState() => _MarcarAsistenciaScreenState();
}

class _MarcarAsistenciaScreenState extends State<MarcarAsistenciaScreen> {
  bool _isLoading = false;

  void _registrar(String tipo) async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final rh = Provider.of<RhProvider>(context, listen: false);
      
      final usuario = auth.usuarioActual;
      
      // Validación de seguridad
      if (usuario == null) throw "No hay sesión activa. Intente ingresar nuevamente.";
      if (usuario.uid.isEmpty) throw "Error de identificación de usuario.";

      await rh.registrarAsistencia(
        trabajadorId: usuario.uid, 
        trabajadorNombre: usuario.nombre,
        tipo: tipo, // 'ENTRADA' o 'SALIDA'
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Marca de $tipo registrada exitosamente"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Volver al menú
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al marcar: $e"), 
            backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Control de Asistencia")),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Registrando marca..."),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Muestra la hora actual
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      final now = DateTime.now();
                      return Text(
                        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  Text(
                    "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 50),
                  
                  // Botones grandes de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _botonMarca("ENTRADA", Colors.green, Icons.login),
                      _botonMarca("SALIDA", Colors.red, Icons.logout),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _botonMarca(String tipo, Color color, IconData icon) {
    return InkWell(
      onTap: () => _registrar(tipo),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              tipo, 
              style: TextStyle(
                color: color, 
                fontWeight: FontWeight.bold, 
                fontSize: 18
              )
            ),
          ],
        ),
      ),
    );
  }
}