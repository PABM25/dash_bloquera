import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/producto_modelo.dart';
import '../../providers/inventario_provider.dart';
import '../../utils/validators.dart';
import '../../utils/app_theme.dart';
import '../../utils/background_write.dart';
import '../../utils/formatters.dart';

class FormProductoScreen extends StatefulWidget {
  final Producto? producto; // Si es null, estamos creando. Si no, editando.
  const FormProductoScreen({super.key, this.producto});

  @override
  State<FormProductoScreen> createState() => _FormProductoScreenState();
}

class _FormProductoScreenState extends State<FormProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _costoCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _tarifaCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.producto?.nombre ?? '');
    _stockCtrl = TextEditingController(text: widget.producto?.stock.toString() ?? '');
    final costo = widget.producto?.precioCosto;
    _costoCtrl = TextEditingController(text: costo == null ? '' : Formatters.montoParaEditar(costo));
    _descCtrl = TextEditingController(text: widget.producto?.descripcion ?? '');
    _barcodeCtrl = TextEditingController(text: widget.producto?.barcode ?? '');
    final tarifa = widget.producto?.tarifaProduccion;
    _tarifaCtrl = TextEditingController(text: tarifa == null ? '' : Formatters.montoParaEditar(tarifa));
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<InventarioProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final nombre = _nombreCtrl.text.trim();
    // Los validadores del formulario garantizan que estos valores son numéricos.
    final stock = int.parse(_stockCtrl.text.trim());
    final costo = Formatters.parseMonto(_costoCtrl.text)!;
    final desc = _descCtrl.text.trim();
    final barcode = _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim();
    // Vacío o 0 = no se fabrica (el bloquero no puede registrarlo).
    final tarifa = Formatters.parseMonto(_tarifaCtrl.text);
    final tarifaProduccion = (tarifa ?? 0) > 0 ? tarifa : null;

    if (widget.producto == null) {
      guardarEnSegundoPlano(
        messenger,
        provider.addProducto(nombre, stock, costo, desc, barcode,
            tarifaProduccion: tarifaProduccion),
        mensajeError: "No se pudo crear el producto '$nombre'.",
      );
    } else {
      // Crear objeto actualizado manteniendo el ID original
      final actualizado = Producto(
        id: widget.producto!.id,
        nombre: nombre,
        stock: stock,
        precioCosto: costo,
        descripcion: desc,
        barcode: barcode,
        tarifaProduccion: tarifaProduccion,
      );
      // Solo se envía la diferencia de stock para no pisar ventas concurrentes.
      // Si con las ventas recientes el stock quedaría negativo, las reglas lo
      // rechazan y se avisa.
      guardarEnSegundoPlano(
        messenger,
        provider.updateProducto(
          actualizado,
          ajusteStock: stock - widget.producto!.stock,
        ),
        mensajeError: "No se pudo actualizar '$nombre'. Revisa el stock e intenta nuevamente.",
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.producto == null ? "Nuevo Producto" : "Editar Producto")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
                maxLength: 200,
                validator: Validators.requiredMax(200),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(labelText: "Stock"),
                      keyboardType: TextInputType.number,
                      validator: Validators.nonNegativeInt,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _costoCtrl,
                      decoration: const InputDecoration(labelText: "Costo Unitario"),
                      keyboardType: TextInputType.number,
                      validator: Validators.nonNegativeNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: "Descripción (Opcional)"),
                maxLines: 3,
                maxLength: 1000,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _barcodeCtrl,
                decoration: const InputDecoration(
                  labelText: "Código de Barras",
                  prefixIcon: Icon(Icons.qr_code_scanner),
                ),
                maxLength: 100,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tarifaCtrl,
                decoration: const InputDecoration(
                  labelText: "Pago al bloquero por unidad (opcional)",
                  helperText: "Solo para productos que se fabrican. Vacío = no se registra como producción.",
                  helperMaxLines: 2,
                  prefixText: "\$ ",
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? null : Validators.nonNegativeNumber(v),
              ),
              const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _guardar,
                    icon: const Icon(Icons.save),
                    label: const Text("GUARDAR"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}