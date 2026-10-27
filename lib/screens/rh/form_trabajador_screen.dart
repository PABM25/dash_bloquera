import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rh_provider.dart';
import '../../models/trabajador_model.dart';
import '../../utils/validators.dart';
import '../../utils/background_write.dart';
import '../../utils/formatters.dart';
import '../../core/failure.dart';

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
  String _tipoPago = Trabajador.pagoPorDia;

  bool get _porProduccion => _tipoPago == Trabajador.pagoPorProduccion;

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
      _tipoPago = widget.trabajador!.tipoPago;
    }
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final t = Trabajador(
      id: widget.trabajador?.id ?? '',
      nombre: _nombreCtrl.text.trim(),
      rut: _rutCtrl.text.trim(),
      cargo: _cargoCtrl.text.trim(),
      // El validador garantiza que el salario es un número válido (si se
      // paga por producción el campo es opcional).
      salarioPorDia: Formatters.parseMonto(_salarioCtrl.text) ?? 0,
      tipoProyecto: _tipoProyecto,
      tipoPago: _tipoPago,
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
              DropdownButtonFormField<String>(
                initialValue: _tipoPago,
                decoration: const InputDecoration(labelText: "Forma de pago"),
                items: const [
                  DropdownMenuItem(value: Trabajador.pagoPorDia, child: Text("Por día trabajado (asistencia)")),
                  DropdownMenuItem(
                    value: Trabajador.pagoPorProduccion,
                    child: Text("Por unidad fabricada (bloquero)"),
                  ),
                ],
                onChanged: (val) => setState(() => _tipoPago = val!),
              ),
              const SizedBox(height: 10),
              if (_porProduccion)
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline),
                  title: Text(
                    "El pago por unidad se define en cada producto de Inventario (campo \"Pago al bloquero por unidad\").",
                  ),
                )
              else
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
              if (widget.trabajador != null && _porProduccion) ...[
                const Divider(height: 40),
                _AccesoApp(trabajadorId: widget.trabajador!.id),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


/// Cuenta de la app del trabajador: solo puede registrar su producción.
/// Escucha la ficha en vivo para reflejar el acceso recién creado o quitado.
class _AccesoApp extends StatelessWidget {
  final String trabajadorId;

  const _AccesoApp({required this.trabajadorId});

  @override
  Widget build(BuildContext context) {
    final rh = context.read<RhProvider>();
    return StreamBuilder<List<Trabajador>>(
      stream: rh.trabajadoresStream,
      builder: (context, snap) {
        final t = snap.data?.where((t) => t.id == trabajadorId).firstOrNull;
        if (t == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Acceso a la app", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              "Con su cuenta solo puede escanear el QR de los productos, registrar las unidades que fabricó y ver lo que lleva ganado.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (t.uid == null)
              OutlinedButton.icon(
                onPressed: () => _crearAcceso(context, rh, t),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text("CREAR ACCESO"),
              )
            else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(t.accesoActivo ? Icons.verified_user : Icons.block,
                    color: t.accesoActivo ? Colors.green : Colors.grey),
                title: Text(t.email ?? 'Cuenta creada'),
                subtitle: Text(t.accesoActivo ? "Acceso activo" : "Acceso desactivado"),
              ),
              OutlinedButton(
                onPressed: () => guardarEnSegundoPlano(
                  ScaffoldMessenger.of(context),
                  rh.setAccesoActivo(t, !t.accesoActivo),
                  mensajeError: "No se pudo cambiar el acceso.",
                ),
                child: Text(t.accesoActivo ? "QUITAR ACCESO" : "DEVOLVER ACCESO"),
              ),
            ],
          ],
        );
      },
    );
  }

  void _crearAcceso(BuildContext context, RhProvider rh, Trabajador t) {
    final emailCtrl = TextEditingController(text: t.email ?? '');
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        var creando = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text("Crear acceso para ${t.nombre}"),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? "Email inválido" : null,
                  ),
                  TextFormField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      labelText: "Contraseña",
                      helperText: "Mínimo 6 caracteres. Entrégasela al trabajador.",
                    ),
                    validator: (v) => (v == null || v.length < 6) ? "Mínimo 6 caracteres" : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: creando ? null : () => Navigator.pop(ctx), child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: creando
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setState(() => creando = true);
                        try {
                          // Se espera: crear la cuenta requiere conexión.
                          await rh.crearAccesoBloquero(t, emailCtrl.text, passCtrl.text);
                          if (ctx.mounted) Navigator.pop(ctx);
                          messenger.showSnackBar(const SnackBar(
                            content: Text("Acceso creado"),
                            backgroundColor: Colors.green,
                          ));
                        } catch (e) {
                          setState(() => creando = false);
                          messenger.showSnackBar(SnackBar(
                            content: Text(e is Failure ? e.message : "No se pudo crear el acceso."),
                            backgroundColor: Colors.red,
                          ));
                        }
                      },
                child: creando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Crear"),
              ),
            ],
          ),
        );
      },
    );
  }
}
