import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rh_provider.dart';
import '../../providers/finanzas_provider.dart';
import '../../models/trabajador_model.dart';
import '../../models/registro_produccion_model.dart';
import '../../providers/produccion_provider.dart';
import '../../utils/background_write.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_shell.dart';

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
    if (_fin.isBefore(_inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La fecha 'Hasta' debe ser posterior a 'Desde'")));
      return;
    }

    final provider = Provider.of<RhProvider>(context, listen: false);
    try {
      final Map<String, dynamic> res;
      if (_trabajadorObjeto!.pagaPorProduccion) {
        final registros = await provider.registrosProduccion(_trabajadorIdSeleccionado!, _inicio, _fin);
        res = {
          'registros': registros,
          'unidades': registros.fold<int>(0, (acc, r) => acc + r.cantidad),
          'total': registros.fold<double>(0, (acc, r) => acc + r.monto),
        };
      } else {
        res = await provider.calcularSalario(
          _trabajadorIdSeleccionado!,
          _trabajadorObjeto!.salarioPorDia,
          _inicio,
          _fin
        );
      }
      if (!mounted) return;
      setState(() => _resultado = res);
    } catch (e) {
      debugPrint("Calcular salario: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo calcular el salario. Revisa la conexión."), backgroundColor: Colors.red));
    }
  }

  Map<String, dynamic>? _resultado;
  bool _pagando = false; // Evita registrar el mismo pago dos veces

  void _pagar() async {
    if (_pagando || _resultado == null || _trabajadorObjeto == null) return;
    setState(() => _pagando = true);

    final finanzas = Provider.of<FinanzasProvider>(context, listen: false);
    try {
      await finanzas.registrarPagoSalario(
        _trabajadorObjeto!.nombre,
        _resultado!['total'],
        _inicio,
        _fin,
        tipoProyecto: _trabajadorObjeto!.tipoProyecto,
      );
    } catch (e) {
      debugPrint("Registrar pago salario: $e");
      if (!mounted) return;
      setState(() => _pagando = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo registrar el pago."), backgroundColor: Colors.red));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pago registrado en Finanzas"), backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: ShellScope.menuButton(context), title: const Text("Calcular Salarios")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Selectores de Fecha
            Row(
              children: [
                // Cambiar el rango invalida el cálculo anterior (no pagar con datos viejos).
                Expanded(child: _dateBtn("Desde", _inicio, (d) => setState(() { _inicio = d; _resultado = null; }))),
                const SizedBox(width: 10),
                Expanded(child: _dateBtn("Hasta", _fin, (d) => setState(() { _fin = d; _resultado = null; }))),
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
              if (_resultado!['registros'] != null)
                ..._detalleProduccion(_resultado!['registros'] as List<RegistroProduccion>)
              else
                Text("Días Trabajados: ${_resultado!['dias']}", style: const TextStyle(fontSize: 18)),
              Text("Total a Pagar: ${Formatters.formatCurrency(_resultado!['total'])}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pagando ? null : _pagar,
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

  /// Resumen por producto y lista de registros (con opción de anular).
  List<Widget> _detalleProduccion(List<RegistroProduccion> registros) {
    final porProducto = <String, (int, double)>{};
    for (final r in registros) {
      final (int u, double m) = porProducto[r.productoNombre] ?? (0, 0.0);
      porProducto[r.productoNombre] = (u + r.cantidad, m + r.monto);
    }
    return [
      Text("Unidades fabricadas: ${_resultado!['unidades']}", style: const TextStyle(fontSize: 18)),
      for (final e in porProducto.entries)
        Text("${e.key}: ${e.value.$1} u. = ${Formatters.formatCurrency(e.value.$2)}"),
      if (registros.isNotEmpty)
        ExpansionTile(
          title: Text("Ver ${registros.length} registros"),
          children: [
            for (final r in registros)
              ListTile(
                dense: true,
                title: Text("${r.cantidad} × ${r.productoNombre}"),
                subtitle: Text(Formatters.formatDate(r.fecha)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Formatters.formatCurrency(r.monto)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: "Anular registro",
                      onPressed: () => _confirmarAnular(r),
                    ),
                  ],
                ),
              ),
          ],
        ),
    ];
  }

  void _confirmarAnular(RegistroProduccion r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Anular registro"),
        content: Text(
          "Se borrará el registro de ${r.cantidad} × ${r.productoNombre} y se descontarán "
          "esas ${r.cantidad} unidades del stock. ¿Continuar?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              guardarEnSegundoPlano(
                ScaffoldMessenger.of(context),
                context.read<ProduccionProvider>().anularRegistro(r),
                mensajeError: "No se pudo anular el registro (¿el stock quedaría negativo?).",
              );
              _calcular();
            },
            child: const Text("Anular", style: TextStyle(color: Colors.red)),
          ),
        ],
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