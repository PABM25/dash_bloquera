import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/finanzas_provider.dart';
import '../../models/gasto_model.dart';
import '../../utils/validators.dart';

class FormGastoScreen extends StatefulWidget {
  const FormGastoScreen({super.key});

  @override
  State<FormGastoScreen> createState() => _FormGastoScreenState();
}

class _FormGastoScreenState extends State<FormGastoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  String _categoria = 'OTRO';
  final String _tipoProyecto = 'CONSTRUCTORA';
  DateTime _fecha = DateTime.now();

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final g = Gasto(
      id: '',
      fecha: _fecha,
      categoria: _categoria,
      descripcion: _descCtrl.text,
      monto: double.parse(_montoCtrl.text),
      tipoProyecto: _tipoProyecto,
    );

    Provider.of<FinanzasProvider>(context, listen: false).addGasto(g);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Gasto")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: "Descripción"),
                validator: Validators.required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(
                  labelText: "Monto",
                  prefixText: "\$ ",
                ),
                keyboardType: TextInputType.number,
                validator: Validators.positiveNumber,
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(labelText: "Categoría"),
                items: const [
                  DropdownMenuItem(
                    value: 'MATERIAL',
                    child: Text("Materiales"),
                  ),
                  DropdownMenuItem(
                    value: 'TRANSPORTE',
                    child: Text("Transporte"),
                  ),
                  DropdownMenuItem(
                    value: 'MAQUINARIA',
                    child: Text("Maquinaria"),
                  ),
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text("Administrativo"),
                  ),
                  DropdownMenuItem(value: 'OTRO', child: Text("Otro")),
                ],
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 10),

              ListTile(
                title: const Text("Fecha del Gasto"),
                subtitle: Text("${_fecha.day}/${_fecha.month}/${_fecha.year}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _fecha,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _fecha = d);
                },
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardar,
                  child: const Text("GUARDAR GASTO"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
