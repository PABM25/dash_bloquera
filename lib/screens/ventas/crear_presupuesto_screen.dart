import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/producto_modelo.dart';
import '../../models/venta_model.dart';
import '../../models/presupuesto_model.dart';
import '../../providers/inventario_provider.dart';
import '../../providers/presupuestos_provider.dart';
import '../../utils/pdf_generator.dart';


class CrearPresupuestoScreen extends StatefulWidget {
  const CrearPresupuestoScreen({super.key});

  @override
  State<CrearPresupuestoScreen> createState() => _CrearPresupuestoScreenState();
}

class _CrearPresupuestoScreenState extends State<CrearPresupuestoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteCtrl = TextEditingController();
  final _rutCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  
  DateTime _fechaEmision = DateTime.now();
  List<ItemOrden> carrito = [];
  
  final currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy');

  double get totalVenta => carrito.fold(0, (sum, item) => sum + item.totalLinea);

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaEmision,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && mounted) {
      setState(() => _fechaEmision = picked);
    }
  }

  void _mostrarSelector() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Consumer<InventarioProvider>(
        builder: (context, provider, _) => StreamBuilder<List<Producto>>(
          stream: provider.productosStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final productos = snapshot.data!;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Seleccione Producto para Cotizar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final p = productos[index];
                      return ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(p.nombre),
                        subtitle: Text("Precio Base: \$${p.precioCosto}"), 
                        onTap: () {
                          Navigator.pop(ctx);
                          _dialogoCantidad(p);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _dialogoCantidad(Producto p) {
    final cantCtrl = TextEditingController(text: "1");
    final precioCtrl = TextEditingController(); // Precio libre

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Cotizar ${p.nombre}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cantCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "Cantidad", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "Precio Unitario", prefixText: "\$ ", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              int cant = int.tryParse(cantCtrl.text) ?? 0;
              double precio = double.tryParse(precioCtrl.text) ?? 0;
              if (cant > 0 && precio > 0) {
                if (mounted) {
                  setState(() {
                    carrito.add(ItemOrden(
                      productoId: p.id,
                      nombre: p.nombre,
                      cantidad: cant,
                      precioUnitario: precio,
                      totalLinea: precio * cant,
                    ));
                  });
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }

  void _guardarPresupuesto() async {
    if (!_formKey.currentState!.validate()) return;
    if (carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agregue al menos un producto")));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final provider = Provider.of<PresupuestosProvider>(context, listen: false);
      
      // Creamos el presupuesto
      await provider.crearPresupuesto(
        cliente: _clienteCtrl.text,
        rut: _rutCtrl.text,
        direccion: _direccionCtrl.text,
        items: carrito,
        fechaEmision: _fechaEmision,
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Preguntar si quiere generar PDF
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("¡Cotización Creada!"),
          content: const Text("La cotización se guardó correctamente. ¿Deseas generar el PDF ahora?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Cerrar dialogo
                Navigator.pop(context); // Cerrar pantalla
              },
              child: const Text("Salir"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Descargar PDF"),
              onPressed: () async {
                // Creamos un objeto Presupuesto temporal para el PDF
                // Nota: En una app real, deberías obtener el objeto creado del provider o backend
                final tempPresupuesto = Presupuesto(
                  id: 'temp', 
                  folio: 'NUEVO', // El folio real se generó en backend, aquí es visual
                  fechaEmision: _fechaEmision,
                  fechaVencimiento: _fechaEmision.add(const Duration(days: 15)),
                  cliente: _clienteCtrl.text,
                  rut: _rutCtrl.text,
                  direccion: _direccionCtrl.text,
                  total: totalVenta,
                  items: carrito
                );
                
                await PdfGenerator.generatePresupuestoA4(tempPresupuesto);
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      );

    } catch (e) {
      if(mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nueva Cotización"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Datos Cliente
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _clienteCtrl,
                        decoration: const InputDecoration(labelText: "Cliente *", prefixIcon: Icon(Icons.person)),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: TextFormField(controller: _rutCtrl, decoration: const InputDecoration(labelText: "RUT", prefixIcon: Icon(Icons.badge)))),
                        const SizedBox(width: 10),
                        Expanded(child: InkWell(
                          onTap: _seleccionarFecha,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: "Fecha", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                            child: Text(dateFormat.format(_fechaEmision)),
                          ),
                        )),
                      ]),
                      const SizedBox(height: 10),
                      TextFormField(controller: _direccionCtrl, decoration: const InputDecoration(labelText: "Dirección", prefixIcon: Icon(Icons.location_on))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botón Agregar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Items (${carrito.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  FilledButton.icon(
                    onPressed: _mostrarSelector,
                    icon: const Icon(Icons.add),
                    label: const Text("AGREGAR PRODUCTO"),
                    style: FilledButton.styleFrom(backgroundColor: Colors.blueGrey),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Lista
              if (carrito.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Sin items agregados")))
              else
                ...carrito.map((item) => Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.blueGrey[100], child: Text("${item.cantidad}")),
                    title: Text(item.nombre),
                    subtitle: Text(currencyFormat.format(item.precioUnitario)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currencyFormat.format(item.totalLinea), style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => carrito.remove(item))),
                      ],
                    ),
                  ),
                )),

              const SizedBox(height: 30),
              
              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardarPresupuesto,
                  icon: const Icon(Icons.save),
                  label: Text("GUARDAR COTIZACIÓN  •  ${currencyFormat.format(totalVenta)}"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[800], foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}