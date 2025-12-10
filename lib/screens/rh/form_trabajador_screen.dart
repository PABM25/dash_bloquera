import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rh_provider.dart';
import '../../models/trabajador_model.dart';
import '../../utils/validators.dart';

class FormTrabajadorScreen extends StatefulWidget {
  final Trabajador? trabajador;
  const FormTrabajadorScreen({super.key, this.trabajador});

  @override
  State<FormTrabajadorScreen> createState() => _FormTrabajadorScreenState();
}

class _FormTrabajadorScreenState extends State<FormTrabajadorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores básicos
  late TextEditingController _nombreCtrl;
  late TextEditingController _rutCtrl;
  late TextEditingController _cargoCtrl;
  late TextEditingController _salarioCtrl;
  
  // Controladores de cuenta (Solo para nuevos)
  late TextEditingController _emailCtrl;
  late TextEditingController _passCtrl;
  
  String _tipoProyecto = 'CONSTRUCTORA';
  String _rolSistema = 'TRABAJADOR'; // Rol por defecto
  bool _isLoading = false;

  bool get isEditing => widget.trabajador != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.trabajador?.nombre ?? '');
    _rutCtrl = TextEditingController(text: widget.trabajador?.rut ?? '');
    _cargoCtrl = TextEditingController(text: widget.trabajador?.cargo ?? '');
    _salarioCtrl = TextEditingController(
      text: widget.trabajador?.salarioPorDia.toStringAsFixed(0) ?? '',
    );
    
    // Email solo se carga, no se edita la contraseña de existentes aquí por seguridad
    _emailCtrl = TextEditingController(text: widget.trabajador?.email ?? '');
    _passCtrl = TextEditingController();

    if (isEditing) {
      _tipoProyecto = widget.trabajador!.tipoProyecto;
      // Nota: El rol se guarda en 'users', si quisieras editarlo necesitarías traerlo
      // por ahora asumimos que al editar solo tocas datos de RRHH.
    }
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final rhProvider = Provider.of<RhProvider>(context, listen: false);

      if (isEditing) {
        // --- MODO EDICIÓN (Solo datos RRHH) ---
        final t = Trabajador(
          id: widget.trabajador!.id, // Mantenemos ID
          nombre: _nombreCtrl.text,
          rut: _rutCtrl.text,
          cargo: _cargoCtrl.text,
          salarioPorDia: double.parse(_salarioCtrl.text),
          tipoProyecto: _tipoProyecto,
          email: _emailCtrl.text, // Actualizamos email informativo
        );
        await rhProvider.saveTrabajador(t);
        
      } else {
        // --- MODO CREACIÓN (Usuario + Datos RRHH) ---
        final t = Trabajador(
          id: '', // Se generará en el provider
          nombre: _nombreCtrl.text,
          rut: _rutCtrl.text,
          cargo: _cargoCtrl.text,
          salarioPorDia: double.parse(_salarioCtrl.text),
          tipoProyecto: _tipoProyecto,
          email: _emailCtrl.text,
        );

        await rhProvider.crearTrabajadorConCuenta(
          trabajador: t,
          password: _passCtrl.text,
          rol: _rolSistema,
        );
      }

      if (mounted) Navigator.pop(context);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Trabajador" : "Nuevo Trabajador"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Datos Personales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre Completo"),
                validator: Validators.required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _rutCtrl,
                decoration: const InputDecoration(labelText: "RUT"),
                validator: Validators.rut,
              ),
              
              const SizedBox(height: 20),
              const Text("Datos de Cuenta (Acceso App)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Correo Electrónico (Para Login)"),
                keyboardType: TextInputType.emailAddress,
                // Si edita, no permitimos cambiar email fácilmente para no romper Auth
                readOnly: isEditing, 
                validator: Validators.email,
              ),
              
              // Solo mostramos contraseña y Rol si es NUEVO
              if (!isEditing) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(labelText: "Contraseña"),
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? "Mínimo 6 caracteres" : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _rolSistema,
                  decoration: const InputDecoration(labelText: "Rol en Sistema"),
                  items: const [
                    DropdownMenuItem(value: 'TRABAJADOR', child: Text("Solo Marcar Asistencia")),
                    DropdownMenuItem(value: 'BLOQUERO', child: Text("Bloquero (Registrar Prod.)")),
                    DropdownMenuItem(value: 'VENDEDOR', child: Text("Vendedor")),
                    DropdownMenuItem(value: 'ADMIN', child: Text("Administrador")),
                  ],
                  onChanged: (val) => setState(() => _rolSistema = val!),
                ),
              ],

              const SizedBox(height: 20),
              const Text("Datos Laborales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),

              TextFormField(
                controller: _cargoCtrl,
                decoration: const InputDecoration(labelText: "Cargo"),
                validator: Validators.required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _salarioCtrl,
                decoration: const InputDecoration(
                  labelText: "Salario Diario",
                  prefixText: "\$ ",
                ),
                keyboardType: TextInputType.number,
                validator: Validators.positiveNumber,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _tipoProyecto,
                decoration: const InputDecoration(labelText: "Proyecto Asignado"),
                items: const [
                  DropdownMenuItem(value: 'CONSTRUCTORA', child: Text("Constructora")),
                  DropdownMenuItem(value: 'BLOQUERO', child: Text("Bloquera")),
                ],
                onChanged: (val) => setState(() => _tipoProyecto = val!),
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _guardar,
                      child: Text(isEditing ? "ACTUALIZAR DATOS" : "CREAR USUARIO Y FICHA"),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}