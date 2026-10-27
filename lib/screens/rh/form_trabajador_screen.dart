import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rh_provider.dart';
import '../../models/trabajador_model.dart';
import '../../utils/validators.dart';
import '../../utils/background_write.dart';
import '../../utils/formatters.dart';

class FormTrabajadorScreen extends StatefulWidget {
  final Trabajador? trabajador;
  const FormTrabajadorScreen({super.key, this.trabajador});

  @override
  State<FormTrabajadorScreen> createState() => _FormTrabajadorScreenState();
}

class _FormTrabajadorScreenState extends State<FormTrabajadorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _rutCtrl;
  late TextEditingController _cargoCtrl;
  late TextEditingController _salarioCtrl;
  String _tipoProyecto = 'CONSTRUCTORA';

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.trabajador?.nombre ?? '');
    _rutCtrl = TextEditingController(text: widget.trabajador?.rut ?? '');
    _cargoCtrl = TextEditingController(text: widget.trabajador?.cargo ?? '');
    _salarioCtrl = TextEditingController(
      text: widget.trabajador?.salarioPorDia.toStringAsFixed(0) ?? '',
    );
    if (widget.trabajador != null) {
      _tipoProyecto = widget.trabajador!.tipoProyecto;
    }
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final t = Trabajador(
      id: widget.trabajador?.id ?? '',
      nombre: _nombreCtrl.text.trim(),
      rut: _rutCtrl.text.trim(),
      cargo: _cargoCtrl.text.trim(),
      // El validador garantiza que el salario es un número válido.
      salarioPorDia: Formatters.parseMonto(_salarioCtrl.text)!,
      tipoProyecto: _tipoProyecto,
      // El formulario no edita estos campos: se conservan (antes se borraban).
      email: widget.trabajador?.email,
      telefono: widget.trabajador?.telefono,
    );

    guardarEnSegundoPlano(
      ScaffoldMessenger.of(context),
      Provider.of<RhProvider>(context, listen: false).saveTrabajador(t),
      mensajeError: "No se pudo guardar el trabajador.",
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.trabajador == null ? "Nuevo Trabajador" : "Editar Trabajador",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                initialValue: _tipoProyecto,
                decoration: const InputDecoration(
                  labelText: "Proyecto Asignado",
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'CONSTRUCTORA',
                    child: Text("Constructora"),
                  ),
                  DropdownMenuItem(value: 'BLOQUERA', child: Text("Bloquera")),
                ],
                onChanged: (val) => setState(() => _tipoProyecto = val!),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardar,
                  child: const Text("GUARDAR"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
