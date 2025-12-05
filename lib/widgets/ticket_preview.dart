import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/venta_model.dart';
import '../utils/formatters.dart';

class TicketPreview extends StatelessWidget {
  final String cliente;
  final String rut;
  final String direccion;
  final List<ItemOrden> items;
  final double total;

  const TicketPreview({
    super.key,
    required this.cliente,
    required this.rut,
    required this.direccion,
    required this.items,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    // Estilos para simular impresión térmica
    const textStyle = TextStyle(
      fontSize: 10,
      color: Colors.black,
      fontFamily: 'Courier',
    );
    const boldStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontFamily: 'Courier',
    );

    return Container(
      width: 350, // Ancho fijo simulando papel de 80mm
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cabecera
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 10),
                child: Image.asset(
                  'assets/images/Logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.store, size: 40),
                ),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CONSTRUCCIONES V & G", style: boldStyle),
                    Text("LIZ CASTILLO GARCIA SPA", style: textStyle),
                    Text("RUT: 77.858.577-4", style: textStyle),
                    Text("Vilaco 301, Toconao", style: textStyle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.black, thickness: 1),

          // 2. Datos Cliente
          _infoRow(
            "Fecha:",
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
            boldStyle,
            textStyle,
          ),
          _infoRow(
            "Cliente:",
            cliente.isEmpty ? "---" : cliente,
            boldStyle,
            textStyle,
          ),
          _infoRow("RUT:", rut.isEmpty ? "---" : rut, boldStyle, textStyle),

          const SizedBox(height: 10),

          // 3. Tabla estilo Django (Bordes Negros)
          Table(
            border: TableBorder.all(color: Colors.black, width: 0.5),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            children: [
              // Cabecera Gris
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade300),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: Text("Prod", style: boldStyle),
                  ),
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      "Cant",
                      style: boldStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      "Precio",
                      style: boldStyle,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      "Total",
                      style: boldStyle,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              // Items
              ...items.map(
                (item) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(item.nombre, style: textStyle),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        item.cantidad.toString(),
                        style: textStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        Formatters.formatCurrency(item.precioUnitario),
                        style: textStyle,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        Formatters.formatCurrency(item.totalLinea),
                        style: textStyle,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: Colors.black, thickness: 1),

          // 4. Total
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "TOTAL: ${Formatters.formatCurrency(total)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text("¡Gracias por su compra!", style: textStyle),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    TextStyle labelStyle,
    TextStyle valStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: labelStyle)),
          Expanded(child: Text(value, style: valStyle)),
        ],
      ),
    );
  }
}
