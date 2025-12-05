import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rh_provider.dart';
import '../../providers/finanzas_provider.dart';
import '../../models/trabajador_model.dart';
import '../../utils/formatters.dart';

class CalculoSalarioScreen extends StatefulWidget {
  const CalculoSalarioScreen({super.key});

  @override
  State<CalculoSalarioScreen> createState() => _CalculoSalarioScreenState();
}

class _CalculoSalarioScreenState extends State<CalculoSalarioScreen> {
  DateTime _inicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fin = DateTime.now();
  
  // Guardamos el ID en lugar del objeto completo para evitar el error de "DropdownMenuItem"
  String? _trabajadorIdSeleccionado;
  Trabajador? _trabajadorObjeto; // Para acceder al salario y nombre

  void _calcular() async {
    if (_trabajadorIdSeleccionado == null || _trabajadorObjeto == null) return;
    
    final provider = Provider.of<RhProvider>(context, listen: false);
    final res = await provider.calcularSalario(
      _trabajadorIdSeleccionado!, 
      _trabajadorObjeto!.salarioPorDia, 
      _inicio, 
      _fin
    );
    setState(() => _resultado = res);
  }

  Map<String, dynamic>? _resultado;

  void _pagar() async {
    if (_resultado == null || _trabajadorObjeto == null) return;
    
    final finanzas = Provider.of<FinanzasProvider>(context, listen: false);
    await finanzas.registrarPagoSalario(
      _trabajadorObjeto!.nombre, 
      _resultado!['total'], 
      _inicio, 
      _fin
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pago registrado en Finanzas"), backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calcular Salarios")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Selectores de Fecha
            Row(
              children: [
                Expanded(child: _dateBtn("Desde", _inicio, (d) => setState(() => _inicio = d))),
                const SizedBox(width: 10),
                Expanded(child: _dateBtn("Hasta", _fin, (d) => setState(() => _fin = d))),
              ],
            ),
            const SizedBox(height: 20),
            
            // Selector de Trabajador (CORREGIDO)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Seleccionar Trabajador:", style: TextStyle(fontWeight: FontWeight.bold))
            ),
            Consumer<RhProvider>(
              builder: (context, provider, _) => StreamBuilder<List<Trabajador>>(
                stream: provider.trabajadoresStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  
                  final listaTrabajadores = snapshot.data!;
                  
                  // Verificar si el ID seleccionado sigue existiendo en la lista
                  if (_trabajadorIdSeleccionado != null) {
                    final existe = listaTrabajadores.any((t) => t.id == _trabajadorIdSeleccionado);
                    if (!existe) _trabajadorIdSeleccionado = null;
                  }

                  return DropdownButton<String>(
                    isExpanded: true,
                    value: _trabajadorIdSeleccionado,
                    hint: const Text("Toque para seleccionar"),
                    items: listaTrabajadores.map((t) {
                      return DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(t.nombre),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setState(() {
                        _trabajadorIdSeleccionado = id;
                        _trabajadorObjeto = listaTrabajadores.firstWhere((t) => t.id == id);
                        _resultado = null;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _trabajadorIdSeleccionado == null ? null : _calcular, 
              child: const Text("CALCULAR")
            ),
            
            // Resultados
            if (_resultado != null) ...[
              const Divider(height: 40),
              Text("Días Trabajados: ${_resultado!['dias']}", style: const TextStyle(fontSize: 18)),
              Text("Total a Pagar: ${Formatters.formatCurrency(_resultado!['total'])}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pagar,
                icon: const Icon(Icons.attach_money),
                label: const Text("CONFIRMAR PAGO"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _dateBtn(String label, DateTime date, Function(DateTime) onPick) {
    return OutlinedButton(
      onPressed: () async {
        final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
        if (d != null) onPick(d);
      },
      child: Text("$label: ${Formatters.formatDate(date)}"),
    );
  }
}