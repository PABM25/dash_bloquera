import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para validar números
import 'package:intl/intl.dart'; // Para formato de moneda y fecha
import 'package:provider/provider.dart';
import '../../models/producto_modelo.dart';
import '../../models/venta_model.dart';
import '../../providers/inventario_provider.dart';
import '../../providers/ventas_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/ticket_preview.dart';

class CrearVentaScreen extends StatefulWidget {
  const CrearVentaScreen({super.key});

  @override
  State<CrearVentaScreen> createState() => _CrearVentaScreenState();
}

class _CrearVentaScreenState extends State<CrearVentaScreen> {
  // Clave global para validar el formulario
  final _formKey = GlobalKey<FormState>(); 

  final _clienteCtrl = TextEditingController();
  final _rutCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  
  DateTime _fechaVenta = DateTime.now();
  List<ItemOrden> carrito = [];

  // Formateadores (CLP y Fecha)
  final currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
  final dateFormat = DateFormat('dd/MM/yyyy');

  double get totalVenta => carrito.fold(0, (sum, item) => sum + item.totalLinea);

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaVenta,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _fechaVenta = picked;
      });
    }
  }

  void _mostrarSelector() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Consumer<InventarioProvider>(
        builder: (context, provider, _) => StreamBuilder<List<Producto>>(
          stream: provider.productosStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final productos = snapshot.data!;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Seleccione un producto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final p = productos[index];
                      return ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(p.nombre),
                        subtitle: Text("Stock actual: ${p.stock}", 
                          style: TextStyle(color: p.stock > 0 ? Colors.green : Colors.red)
                        ),
                        enabled: p.stock > 0,
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
    // [CAMBIO] Campo precio inicia VACÍO, sin sugerencias.
    final precioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Column(
          children: [
            Text("Agregar ${p.nombre}", textAlign: TextAlign.center),
            Text("Stock disponible: ${p.stock}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cantCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Cantidad",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Precio Unitario",
                prefixText: "\$ ",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                // Sin helperText de sugerencia
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              int cant = int.tryParse(cantCtrl.text) ?? 0;
              double precio = double.tryParse(precioCtrl.text) ?? 0;

              // Validar Stock
              if (cant > p.stock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: Solo tienes ${p.stock} unidades en inventario")),
                );
                return;
              }

              if (cant > 0 && precio > 0) {
                if (mounted) {
                  setState(() {
                    carrito.add(
                      ItemOrden(
                        productoId: p.id,
                        nombre: p.nombre,
                        cantidad: cant,
                        precioUnitario: precio, 
                        totalLinea: precio * cant,
                      ),
                    );
                  });
                }
                Navigator.pop(ctx);
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ingrese cantidad y precio válidos")),
                );
              }
            },
            child: const Text("Agregar al Carrito"),
          ),
        ],
      ),
    );
  }

  void _guardar() async {
    // 1. Validar formulario
    if (!_formKey.currentState!.validate()) {
      return; 
    }
    if (carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe agregar al menos un producto al carrito")),
      );
      return;
    }

    // 2. Mostrar Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final provider = Provider.of<VentasProvider>(context, listen: false);

    try {
      await provider.crearVenta(
        cliente: _clienteCtrl.text,
        rut: _rutCtrl.text,
        direccion: _direccionCtrl.text,
        items: carrito,
        fecha: _fechaVenta, 
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Venta creada exitosamente"), backgroundColor: Colors.green),
      );

      if (mounted) Navigator.pop(context); // Cerrar pantalla

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      String errorMsg = "Ocurrió un error inesperado";
      if (e.toString().contains("STOCK_INSUFICIENTE")) {
        errorMsg = "Stock insuficiente para uno de los productos.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Venta")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          
          Widget formSection = _buildForm();
          
          Widget ticketSection = TicketPreview(
            cliente: _clienteCtrl.text,
            rut: _rutCtrl.text,
            direccion: _direccionCtrl.text,
            items: carrito,
            total: totalVenta,
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: formSection)),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text("VISTA PREVIA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 10),
                        ticketSection,
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  formSection,
                  const Divider(height: 40),
                  const Text("VISTA PREVIA", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  ticketSection,
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Tarjeta de Datos del Cliente
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Información del Cliente", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _clienteCtrl,
                    decoration: const InputDecoration(labelText: "Nombre Cliente *", prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => v!.isEmpty ? 'El nombre es obligatorio' : null,
                    onChanged: (v) => setState((){}),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rutCtrl,
                          decoration: const InputDecoration(labelText: "RUT / DNI", prefixIcon: Icon(Icons.badge_outlined)),
                          onChanged: (v) => setState((){}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: _seleccionarFecha,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: "Fecha",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(dateFormat.format(_fechaVenta)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _direccionCtrl,
                    decoration: const InputDecoration(labelText: "Dirección", prefixIcon: Icon(Icons.location_on_outlined)),
                    onChanged: (v) => setState((){}),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 25),
          
          // Encabezado Productos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Productos (${carrito.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              FilledButton.icon(
                onPressed: _mostrarSelector,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("AGREGAR"),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ],
          ),
          
          const SizedBox(height: 10),

          // Lista de Carrito Mejorada
          if (carrito.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: const Column(
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("El carrito está vacío", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: carrito.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = carrito[index];
                return Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text("${item.cantidad}", style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("${currencyFormat.format(item.precioUnitario)} c/u"),
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
              },
            ),

          const SizedBox(height: 30),
          
          // Botón Finalizar
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kpiGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("FINALIZAR VENTA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 15),
                  Container(width: 1, height: 20, color: Colors.white54),
                  const SizedBox(width: 15),
                  Text(currencyFormat.format(totalVenta), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}