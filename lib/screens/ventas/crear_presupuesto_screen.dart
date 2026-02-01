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

  // --- OPCIÓN 1: SELECCIONAR PRODUCTO DE INVENTARIO ---
  void _mostrarSelectorProducto() {
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
                  child: Text("Seleccione Material / Producto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          _dialogoCantidadProducto(p);
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

  void _dialogoCantidadProducto(Producto p) {
    final cantCtrl = TextEditingController(text: "1");
    final precioCtrl = TextEditingController(); 

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Agregar ${p.nombre}"),
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
                _agregarAlCarrito(
                  id: p.id,
                  nombre: p.nombre,
                  cantidad: cant,
                  precio: precio
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }

  // --- OPCIÓN 2: AGREGAR SERVICIO / MANO DE OBRA ---
  void _dialogoServicioManual() {
    final descripcionCtrl = TextEditingController();
    final precioTotalCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Agregar Mano de Obra / Servicio"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descripcionCtrl,
              decoration: const InputDecoration(
                labelText: "Descripción del trabajo",
                hintText: "Ej: Cierre perimetral 20 mts",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: precioTotalCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Valor Total del Servicio", 
                prefixText: "\$ ", 
                border: OutlineInputBorder()
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton.icon(
            icon: const Icon(Icons.handyman),
            label: const Text("Agregar Servicio"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
            onPressed: () {
              String desc = descripcionCtrl.text.trim();
              double precio = double.tryParse(precioTotalCtrl.text) ?? 0;

              if (desc.isNotEmpty && precio > 0) {
                _agregarAlCarrito(
                  id: 'SERVICIO_${DateTime.now().millisecondsSinceEpoch}',
                  nombre: desc,
                  cantidad: 1, 
                  precio: precio
                );
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  void _agregarAlCarrito({required String id, required String nombre, required int cantidad, required double precio}) {
    if (mounted) {
      setState(() {
        carrito.add(ItemOrden(
          productoId: id,
          nombre: nombre,
          cantidad: cantidad,
          precioUnitario: precio,
          totalLinea: precio * cantidad,
        ));
      });
    }
  }

  // --- FUNCIÓN GUARDAR CORREGIDA ---
  void _guardarPresupuesto() async {
    if (!_formKey.currentState!.validate()) return;
    if (carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agregue al menos un ítem")));
      return;
    }

    // 1. Mostrar diálogo de carga
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator())
    );

    try {
      final provider = Provider.of<PresupuestosProvider>(context, listen: false);
      
      // 2. Operación asíncrona (guardar en Firebase)
      await provider.crearPresupuesto(
        cliente: _clienteCtrl.text,
        rut: _rutCtrl.text,
        direccion: _direccionCtrl.text,
        items: carrito,
        fechaEmision: _fechaEmision,
      );

      // 3. Verificar si la pantalla sigue activa
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar el Loading

      // 4. Mostrar diálogo de Éxito / PDF
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("¡Cotización Creada!"),
          content: const Text("¿Deseas generar el PDF ahora?"),
          actions: [
            TextButton(
              onPressed: () {
                // Cerrar todo usando el contexto principal que es seguro si 'mounted' es true
                Navigator.of(context).pop(); // Cierra Dialog
                Navigator.of(context).pop(); // Cierra Pantalla
              },
              child: const Text("Salir"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Descargar PDF"),
              onPressed: () async {
                final tempPresupuesto = Presupuesto(
                  id: 'temp', 
                  folio: 'NUEVO',
                  fechaEmision: _fechaEmision,
                  fechaVencimiento: _fechaEmision.add(const Duration(days: 15)),
                  cliente: _clienteCtrl.text,
                  rut: _rutCtrl.text,
                  direccion: _direccionCtrl.text,
                  total: totalVenta,
                  items: carrito
                );
                
                // Generar PDF (async)
                await PdfGenerator.generatePresupuestoA4(tempPresupuesto);
                
                // CORRECCIÓN FINAL:
                // Solo usamos 'mounted' (que protege a 'context').
                // No usamos el contexto del diálogo ('ctx') para evitar el error del linter.
                // Al llamar pop() sobre el Navigator principal, cerramos el diálogo (ruta superior)
                // y luego la pantalla.
                
                if (!mounted) return;
                
                Navigator.of(context).pop(); // Cierra Diálogo
                Navigator.of(context).pop(); // Cierra Pantalla
              },
            ),
          ],
        ),
      );

    } catch (e) {
      if (mounted) {
        // Si hay error, intentamos cerrar el loading
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
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

              // BOTONES DE ACCIÓN (PRODUCTO vs SERVICIO)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _mostrarSelectorProducto,
                      icon: const Icon(Icons.inventory_2),
                      label: const Text("AGREGAR\nPRODUCTO", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _dialogoServicioManual,
                      icon: const Icon(Icons.handyman),
                      label: const Text("AGREGAR\nSERVICIO", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // Título Items
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Detalle (${carrito.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              ),

              const SizedBox(height: 5),

              // Lista de Items
              if (carrito.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!)
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.post_add, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("Agregue productos o mano de obra", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                ...carrito.map((item) {
                  final bool esServicio = item.productoId.startsWith('SERVICIO_');
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: esServicio ? Colors.orange[100] : Colors.blueGrey[100],
                        child: Icon(
                          esServicio ? Icons.handyman : Icons.inventory_2, 
                          color: esServicio ? Colors.orange[800] : Colors.blueGrey, 
                          size: 20
                        ),
                      ),
                      title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        esServicio 
                        ? "Servicio Global" 
                        : "${item.cantidad} unidades x ${currencyFormat.format(item.precioUnitario)}"
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currencyFormat.format(item.totalLinea), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => carrito.remove(item)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 30),
              
              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _guardarPresupuesto,
                  icon: const Icon(Icons.save),
                  label: Text("FINALIZAR COTIZACIÓN  •  ${currencyFormat.format(totalVenta)}", style: const TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700], 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}