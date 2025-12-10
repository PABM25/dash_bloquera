import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/venta_model.dart';
import '../../providers/ventas_provider.dart';
import '../../utils/pdf_generator.dart';
import '../../utils/formatters.dart';
import '../../providers/auth_provider.dart'; // [1] IMPORTANTE: Agregado para detectar rol

class DetalleVentaScreen extends StatelessWidget {
  final String ventaId;
  final Venta ventaInicial;

  DetalleVentaScreen({super.key, required this.ventaInicial})
      : ventaId = ventaInicial.id;

  @override
  Widget build(BuildContext context) {
    // [2] DETECTAR SI ES DEMO
    final authProvider = Provider.of<AuthProvider>(context);
    final bool esSoloLectura = authProvider.role == 'demo';

    final Stream<DocumentSnapshot> ventaStream = FirebaseFirestore.instance
        .collection('ventas')
        .doc(ventaId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: ventaStream,
      builder: (context, snapshot) {
        Venta venta = ventaInicial;
        if (snapshot.hasData && snapshot.data!.exists) {
          venta = Venta.fromFirestore(snapshot.data!);
        }

        double saldoPendiente = venta.total - venta.montoPagado;
        Color estadoColor = venta.estadoPago == 'PAGADA'
            ? Colors.green
            : (venta.estadoPago == 'ABONADA' ? Colors.orange : Colors.red);

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
                    const Text("Seleccionar formato",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ListTile(
                      leading:
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: const Text("Descargar Factura A4 (PDF)"),
                      onTap: () {
                        Navigator.pop(ctx);
                        PdfGenerator().generateInvoiceA4(venta);
                      },
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.receipt_long, color: Colors.black),
                      title: const Text("Imprimir Ticket (80mm)"),
                      onTap: () {
                        Navigator.pop(ctx);
                        PdfGenerator().generateTicket80mm(venta);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }

        void registrarPago() {
          TextEditingController montoCtrl = TextEditingController(
              text: saldoPendiente.toStringAsFixed(0));
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Registrar Pago"),
              content: TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Monto", prefixText: "\$ "),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () {
                    double monto = double.tryParse(montoCtrl.text) ?? 0;
                    if (monto > 0) {
                      Provider.of<VentasProvider>(context, listen: false)
                          .registrarPago(venta.id, monto, venta.montoPagado,
                              venta.total);
                      Navigator.pop(ctx);
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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
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
                              Text("TOTAL",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600])),
                              Text(Formatters.formatCurrency(venta.total),
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                // Nota: Si usas Flutter antiguo usa withOpacity
                                // Si es muy nuevo usa withValues, aquí dejo withOpacity por compatibilidad
                                color: estadoColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(venta.estadoPago,
                                style: TextStyle(
                                    color: estadoColor,
                                    fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Pagado:", style: TextStyle(fontSize: 16)),
                          Text(Formatters.formatCurrency(venta.montoPagado),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Pendiente:",
                              style: TextStyle(fontSize: 16)),
                          Text(Formatters.formatCurrency(saldoPendiente),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700])),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Detalle de Productos",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...venta.items.map((item) => Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          "${item.cantidad} x ${Formatters.formatCurrency(item.precioUnitario)}"),
                      trailing: Text(
                          Formatters.formatCurrency(item.totalLinea),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  )),
              const SizedBox(height: 40),
              Row(
                children: [
                  // [3] CONDICIÓN MODIFICADA: Si hay saldo Y NO ES DEMO, muestra botón Pagar
                  if (saldoPendiente > 0 && !esSoloLectura)
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
                  if (saldoPendiente > 0 && !esSoloLectura)
                    const SizedBox(width: 10),

                  // El botón de imprimir siempre visible (no modifica datos)
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
        );
      },
    );
  }
}