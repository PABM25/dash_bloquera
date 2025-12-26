import 'package:flutter/material.dart';
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
  final _clienteCtrl = TextEditingController();
  final _rutCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  
  // Variable para almacenar la fecha seleccionada, por defecto HOY
  DateTime _fechaVenta = DateTime.now();

  List<ItemOrden> carrito = [];
  double get totalVenta =>
      carrito.fold(0, (sum, item) => sum + item.totalLinea);

  // Selector de fecha
  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaVenta,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    // CORRECCIÓN: Verificar si el widget sigue montado antes de usar setState
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
            return ListView.builder(
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final p = productos[index];
                return ListTile(
                  title: Text(p.nombre),
                  subtitle: Text("Stock: ${p.stock}"),
                  enabled: p.stock > 0,
                  onTap: () {
                    Navigator.pop(ctx);
                    _dialogoCantidad(p);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _dialogoCantidad(Producto p) {
    final cantCtrl = TextEditingController(text: "1");
    
    // Sugerimos un precio (Costo + 30%), pero el usuario puede editarlo
    final precioSugerido = (p.precioCosto * 1.3).toStringAsFixed(0);
    final precioCtrl = TextEditingController(text: precioSugerido);

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
              decoration: const InputDecoration(
                labelText: "Cantidad",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            // Campo editable para el precio
            TextField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Precio Unitario",
                prefixText: "\$ ",
                border: OutlineInputBorder(),
                helperText: "Precio sugerido (30%)"
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

              if (cant > 0 && cant <= p.stock && precio > 0) {
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
              }
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }

  void _guardar() async {
    if (carrito.isEmpty || _clienteCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete cliente y agregue productos")),
      );
      return;
    }

    // 1. Mostrar Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final provider = Provider.of<VentasProvider>(context, listen: false);

    try {
      // 2. Operación asíncrona
      await provider.crearVenta(
        cliente: _clienteCtrl.text,
        rut: _rutCtrl.text,
        direccion: _direccionCtrl.text,
        items: carrito,
        fecha: _fechaVenta, 
      );

      // --- CORRECCIÓN CRÍTICA AQUÍ ---
      
      // Si el usuario cerró la app o cambió de pantalla mientras guardaba, detenemos.
      if (!mounted) return;

      // 3. Cerrar PRIMERO el diálogo de carga (pop del loading)
      Navigator.pop(context); 

      // 4. Mostrar el mensaje de éxito AHORA, mientras la pantalla sigue viva
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Venta creada exitosamente"),
          backgroundColor: Colors.green,
        ),
      );

      // 5. Y FINALMENTE cerramos la pantalla de venta
      if (mounted) {
        Navigator.pop(context); 
      }

    } catch (e) {
      // Manejo de errores seguro
      if (!mounted) return;
      
      // Cerrar loading si falló
      Navigator.pop(context); 

      String errorMsg = "Ocurrió un error inesperado";
      if (e.toString().contains("STOCK_INSUFICIENTE")) {
        errorMsg = "Stock insuficiente para uno de los productos.";
      } else if (e.toString().contains("PRODUCTO_NO_EXISTE")) {
        errorMsg = "Un producto seleccionado ya no existe.";
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
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: formSection,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text("VISTA PREVIA", style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Column(
      children: [
        InkWell(
          onTap: _seleccionarFecha,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: "Fecha de Venta",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_month),
            ),
            child: Text(
              "${_fechaVenta.day}/${_fechaVenta.month}/${_fechaVenta.year}",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _clienteCtrl,
          decoration: const InputDecoration(
            labelText: "Cliente",
            border: OutlineInputBorder(),
          ),
          onChanged: (v) { if (mounted) setState(() {}); },
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _rutCtrl,
                decoration: const InputDecoration(
                  labelText: "RUT",
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) { if (mounted) setState(() {}); },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(
                  labelText: "Dirección",
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) { if (mounted) setState(() {}); },
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Productos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _mostrarSelector,
              icon: const Icon(Icons.add),
              label: const Text("AGREGAR"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (carrito.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("No hay productos agregados", style: TextStyle(color: Colors.grey)),
          ),
        ...carrito.map(
          (item) => Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              title: Text(item.nombre),
              subtitle: Text("${item.cantidad} x \$${item.precioUnitario.toStringAsFixed(0)}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => carrito.remove(item)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 18),
            ),
            child: const Text("FINALIZAR VENTA"),
          ),
        ),
      ],
    );
  }
}