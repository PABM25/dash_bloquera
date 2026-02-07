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
import '../../utils/app_theme.dart'; // IMPORTANTE: Importamos tu tema

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
      // Usamos el tema para el selector de fecha
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary, 
              onPrimary: Colors.white, 
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _fechaEmision = picked);
    }
  }

  // --- OPCIÓN 1: SELECCIONAR PRODUCTO DE INVENTARIO ---
  void _mostrarSelectorProducto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer<InventarioProvider>(
        builder: (context, provider, _) => StreamBuilder<List<Producto>>(
          stream: provider.productosStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final productos = snapshot.data!;
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 15, bottom: 15),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
                Text("Seleccione Producto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: productos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = productos[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Icon(Icons.inventory_2_outlined, color: AppTheme.primary),
                        ),
                        title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
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
        title: const Text("Mano de Obra / Servicio"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descripcionCtrl,
              decoration: const InputDecoration(
                labelText: "Descripción",
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
                labelText: "Valor Total", 
                prefixText: "\$ ", 
                border: OutlineInputBorder()
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.handyman),
            label: const Text("Agregar"),
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

  // ===========================================================================
  // FUNCIÓN GUARDAR SEGURA
  // ===========================================================================
  void _guardarPresupuesto() async {
    if (!_formKey.currentState!.validate()) return;
    if (carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agregue al menos un ítem")));
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<PresupuestosProvider>(context, listen: false);

    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator())
    );

    try {
      await provider.crearPresupuesto(
        cliente: _clienteCtrl.text,
        rut: _rutCtrl.text,
        direccion: _direccionCtrl.text,
        items: carrito,
        fechaEmision: _fechaEmision,
      );

      navigator.pop(); // Cierra loading

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text("¡Cotización Creada!"),
            ],
          ),
          content: const Text("El presupuesto se ha guardado correctamente.\n¿Deseas generar el PDF ahora?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
                navigator.pop(); 
              },
              child: const Text("Salir", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Descargar PDF"),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () async {
                final dialogNavigator = Navigator.of(dialogContext);

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
                
                await PdfGenerator.generatePresupuestoA4(tempPresupuesto);
                
                dialogNavigator.pop(); 
                navigator.pop();       
              },
            ),
          ],
        ),
      );

    } catch (e) {
      navigator.pop(); 
      scaffoldMessenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nueva Cotización", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary, // USAMOS EL COLOR DEL TEMA
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Datos Cliente
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Datos del Cliente", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _clienteCtrl,
                              decoration: const InputDecoration(labelText: "Nombre / Razón Social *", prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 15),
                            Row(children: [
                              Expanded(child: TextFormField(controller: _rutCtrl, decoration: const InputDecoration(labelText: "RUT", prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder()))),
                              const SizedBox(width: 15),
                              Expanded(child: InkWell(
                                onTap: _seleccionarFecha,
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: "Fecha Emisión", border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today_outlined)),
                                  child: Text(dateFormat.format(_fechaEmision)),
                                ),
                              )),
                            ]),
                            const SizedBox(height: 15),
                            TextFormField(controller: _direccionCtrl, decoration: const InputDecoration(labelText: "Dirección", prefixIcon: Icon(Icons.location_on_outlined), border: OutlineInputBorder())),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
            
                    // BOTONES DE ACCIÓN
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _mostrarSelectorProducto,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text("AGREGAR\nPRODUCTO", textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: AppTheme.primary, // COLOR TEMA
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _dialogoServicioManual,
                            icon: const Icon(Icons.handyman_outlined),
                            label: const Text("AGREGAR\nSERVICIO", textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.orange[800], // Mantenemos Naranja para diferenciar
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Título Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Detalle del Presupuesto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                          child: Text("${carrito.length} ítems", style: const TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
            
                    const SizedBox(height: 10),
            
                    // Lista de Items
                    if (carrito.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid)
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.post_add, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text("No hay ítems agregados", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                          ],
                        ),
                      )
                    else
                      ...carrito.map((item) {
                        final bool esServicio = item.productoId.startsWith('SERVICIO_');
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            leading: CircleAvatar(
                              backgroundColor: esServicio ? Colors.orange[50] : AppTheme.primary.withOpacity(0.1),
                              child: Icon(
                                esServicio ? Icons.handyman : Icons.inventory_2, 
                                color: esServicio ? Colors.orange[800] : AppTheme.primary, 
                                size: 22
                              ),
                            ),
                            title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              esServicio 
                              ? "Servicio Global" 
                              : "${item.cantidad} x ${currencyFormat.format(item.precioUnitario)}"
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(currencyFormat.format(item.totalLinea), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => setState(() => carrito.remove(item)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    
                    const SizedBox(height: 80), // Espacio para el botón flotante inferior
                  ],
                ),
              ),
            ),
          ),
          
          // BARRA INFERIOR DE TOTAL Y ACCIÓN
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("TOTAL ESTIMADO", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(currencyFormat.format(totalVenta), style: TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _guardarPresupuesto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700], 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: const Row(
                      children: [
                        Text("FINALIZAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 10),
                        Icon(Icons.check_circle_outline)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}