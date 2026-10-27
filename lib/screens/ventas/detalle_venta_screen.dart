import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/failure.dart';
import '../../models/venta_model.dart';
import '../../providers/ventas_provider.dart';
import '../../utils/pdf_generator.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_dialog.dart';

class DetalleVentaScreen extends StatefulWidget {
  final Venta ventaInicial;

  const DetalleVentaScreen({super.key, required this.ventaInicial});

  @override
  State<DetalleVentaScreen> createState() => _DetalleVentaScreenState();
}

class _DetalleVentaScreenState extends State<DetalleVentaScreen> {
  // Escuchamos cambios en tiempo real por si se paga la venta. Se crea una
  // vez: en build() se volvía a suscribir en cada redibujado.
  late final Stream<DocumentSnapshot> ventaStream = FirebaseFirestore.instance
      .collection('ventas')
      .doc(widget.ventaInicial.id)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final ventaInicial = widget.ventaInicial;

    return StreamBuilder<DocumentSnapshot>(
      stream: ventaStream,
      builder: (context, snapshot) {
        Venta venta = ventaInicial;
        // Si hay datos nuevos en Firestore, actualizamos la vista
        if (snapshot.hasData && snapshot.data!.exists) {
          venta = Venta.fromFirestore(snapshot.data!);
        }

        double saldoPendiente = venta.total - venta.montoPagado;
        
        // Color dinámico según estado
        Color estadoColor;
        switch (venta.estadoPago) {
          case 'PAGADA':
            estadoColor = Colors.green;
            break;
          case 'ABONADA':
            estadoColor = Colors.orange;
            break;
          default:
            estadoColor = Colors.red;
        }

        // Función para mostrar menú de PDF
        void mostrarOpcionesImpresion() {
          showModalBottomSheet(
            context: context,
            builder: (ctx) {
              return Container(
                padding: const EdgeInsets.all(20),
                height: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Seleccionar formato", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: const Text("Descargar Factura A4 (PDF)"),
                      onTap: () {
                        Navigator.pop(ctx);
                        runWithLoading(
                          context,
                          (close) => PdfGenerator.generateInvoiceA4(venta, onGenerated: close),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt_long, color: Colors.black),
                      title: const Text("Imprimir Ticket (80mm)"),
                      onTap: () {
                        Navigator.pop(ctx);
                        runWithLoading(
                          context,
                          (close) => PdfGenerator.generateTicket80mm(venta, onGenerated: close),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }

        // Función para registrar pagos parciales o totales
        void registrarPago() {
           TextEditingController montoCtrl = TextEditingController(text: saldoPendiente.toStringAsFixed(0));
           showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Registrar Pago"),
              content: TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Monto", prefixText: "\$ "),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () async {
                    final monto = Formatters.parseMonto(montoCtrl.text) ?? 0;
                    final messenger = ScaffoldMessenger.of(context);
                    if (monto <= 0) {
                      messenger.showSnackBar(const SnackBar(content: Text("Ingrese un monto mayor a 0")));
                      return;
                    }
                    // Antes el exceso se descartaba sin avisar.
                    if (monto > saldoPendiente) {
                      messenger.showSnackBar(SnackBar(
                        content: Text("El monto supera el saldo pendiente (${Formatters.formatCurrency(saldoPendiente)})"),
                      ));
                      return;
                    }
                    final provider = Provider.of<VentasProvider>(context, listen: false);
                    Navigator.pop(ctx);
                    try {
                      await provider.registrarPago(venta.id, monto);
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(
                        content: Text(e is Failure ? e.message : "No se pudo registrar el pago."),
                        backgroundColor: Colors.red,
                      ));
                    }
                  },
                  child: const Text("Pagar"),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text("Folio: ${venta.folio}")),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tarjeta de Resumen Financiero
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("TOTAL", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                              Text(Formatters.formatCurrency(venta.total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              // Compatibilidad con versiones nuevas de Flutter
                              color: estadoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(venta.estadoPago, style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Pagado:", style: TextStyle(fontSize: 16)),
                          Text(Formatters.formatCurrency(venta.montoPagado), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Pendiente:", style: TextStyle(fontSize: 16)),
                          Text(Formatters.formatCurrency(saldoPendiente), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[700])),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text("Detalle de Productos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              // Lista de Items
              ...venta.items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("${item.cantidad} x ${Formatters.formatCurrency(item.precioUnitario)}"),
                  trailing: Text(Formatters.formatCurrency(item.totalLinea), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              )),

              const SizedBox(height: 40),
              
              // Botones de Acción
              Row(
                children: [
                  // Botón Pagar (Solo si hay saldo pendiente)
                  if (saldoPendiente > 0)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: registrarPago,
                        icon: const Icon(Icons.attach_money),
                        label: const Text("PAGAR"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (saldoPendiente > 0) const SizedBox(width: 10),
                  
                  // Botón Imprimir / PDF
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: mostrarOpcionesImpresion,
                      icon: const Icon(Icons.print),
                      label: const Text("IMPRIMIR / PDF"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.blueGrey[800],
                        foregroundColor: Colors.white,
                      ),
                    ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}