import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/venta_model.dart';
import 'formatters.dart';

class PdfGenerator {
  
  // Carga el logo desde los assets
  Future<Uint8List> _loadLogo() async {
    try {
      final byteData = await rootBundle.load('assets/images/Logo.png');
      return byteData.buffer.asUint8List();
    } catch (e) {
      return Uint8List(0);
    }
  }

  // ==========================================
  // OPCIÓN 1: DISEÑO A4 (FACTURA ELEGANTE)
  // ==========================================
  Future<void> generateInvoiceA4(Venta venta) async {
    final doc = pw.Document();
    final logoBytes = await _loadLogo();
    final logoImage = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;
    
    // COLORES SÓLIDOS (Sin transparencias para evitar errores)
    final PdfColor primaryColor = PdfColor.fromHex('#FF6B6B'); 
    final PdfColor accentColor = PdfColor.fromHex('#EEEEEE'); 
    final PdfColor lightColor = PdfColor.fromHex('#F9F9F9'); 

    final double saldo = venta.total - venta.montoPagado;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero, // Solución al error de EdgeInsets
        
        // FOOTER ROJO EN TODAS LAS PÁGINAS
        footer: (pw.Context context) {
          return pw.Container(
            color: primaryColor,
            height: 50,
            padding: const pw.EdgeInsets.symmetric(horizontal: 30),
            alignment: pw.Alignment.center,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Vilaco 301, Toconao", style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                pw.Text("Construcciones V & G", style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
              ],
            ),
          );
        },

        build: (pw.Context context) {
          return [
            // --- HEADER ---
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 40, left: 40, right: 40, bottom: 20),
              child: pw.Column(
                children: [
                  // Fila Superior: Logo y Datos Empresa
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Logo
                      if (logoImage != null)
                        pw.Container(
                          height: 80,
                          width: 80,
                          margin: const pw.EdgeInsets.only(right: 20),
                          child: pw.Image(logoImage),
                        ),
                      
                      // Datos de la Empresa (FIJOS)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("CONSTRUCCIONES V & G", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.Text("LIZ CASTILLO GARCIA SPA", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.Text("RUT: 77.858.577-4", style: const pw.TextStyle(fontSize: 12)),
                          pw.Text("Dirección: Vilaco 301, Toconao", style: const pw.TextStyle(fontSize: 12)),
                          pw.Text("Teléfono: +56 9 52341652", style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  
                  pw.SizedBox(height: 20),
                  pw.Divider(color: primaryColor),
                  pw.SizedBox(height: 20),

                  // Fila Datos Venta y Cliente
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Datos del Cliente
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("FACTURAR A:", style: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold)),
                          pw.Text(venta.cliente, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          if (venta.rut != null) pw.Text("RUT: ${venta.rut}"),
                          if (venta.direccion != null) pw.Container(width: 200, child: pw.Text("Dir: ${venta.direccion}")),
                        ],
                      ),

                      // Datos del Comprobante
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("N° FOLIO", style: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold)),
                          pw.Text(venta.folio, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          pw.SizedBox(height: 5),
                          pw.Text("FECHA EMISIÓN", style: pw.TextStyle(color: primaryColor, fontWeight: pw.FontWeight.bold)),
                          pw.Text(Formatters.formatDate(venta.fecha)),
                        ],
                      )
                    ],
                  ),
                  
                  pw.SizedBox(height: 30),

                  // --- TABLA DE PRODUCTOS ---
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1), // Cantidad
                      1: const pw.FlexColumnWidth(4), // Producto
                      2: const pw.FlexColumnWidth(2), // Precio
                      3: const pw.FlexColumnWidth(2), // Total
                    },
                    children: [
                      // Encabezados
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: accentColor),
                        children: [
                          _cell("CANT", align: pw.TextAlign.center, isHeader: true),
                          _cell("PRODUCTO", isHeader: true),
                          _cell("PRECIO", align: pw.TextAlign.right, isHeader: true),
                          _cell("TOTAL", align: pw.TextAlign.right, isHeader: true),
                        ],
                      ),
                      // Filas de datos
                      ...venta.items.map((item) => pw.TableRow(
                        children: [
                          _cell(item.cantidad.toString(), align: pw.TextAlign.center),
                          _cell(item.nombre),
                          _cell(Formatters.formatCurrency(item.precioUnitario), align: pw.TextAlign.right),
                          _cell(Formatters.formatCurrency(item.totalLinea), align: pw.TextAlign.right),
                        ],
                      )),
                    ],
                  ),
                  
                  // Totales
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          _buildTotalRow("Subtotal:", venta.total),
                          _buildTotalRow("Abonado:", venta.montoPagado),
                          pw.SizedBox(height: 5),
                          pw.Container(
                            color: primaryColor,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: pw.Text(
                              "PENDIENTE: ${Formatters.formatCurrency(saldo)}",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.white),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),

                  pw.SizedBox(height: 40),
                  
                  // DISCLAIMER GIGANTE
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      color: lightColor
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        "DOCUMENTO DE USO INTERNO - NO VÁLIDO COMO FACTURA O BOLETA FISCAL",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, 
                          fontSize: 10, 
                          color: PdfColors.grey700
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Muestra la vista previa
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Comprobante_${venta.folio}',
    );
  }

  // ==========================================
  // OPCIÓN 2: DISEÑO TICKET (80MM TÉRMICO)
  // ==========================================
  Future<void> generateTicket80mm(Venta venta) async {
    final doc = pw.Document();
    
    // CARGAMOS EL LOGO TAMBIÉN AQUÍ
    final logoBytes = await _loadLogo();
    final logoImage = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;

    final double saldo = venta.total - venta.montoPagado;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo centrado y pequeño para el ticket
              if (logoImage != null)
                pw.Center(
                  child: pw.Container(
                    height: 50, 
                    width: 50,
                    margin: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Image(logoImage),
                  ),
                ),

              // DATOS FIJOS DE LA EMPRESA
              pw.Center(child: pw.Text("CONSTRUCCIONES V & G", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12), textAlign: pw.TextAlign.center)),
              pw.Center(child: pw.Text("LIZ CASTILLO GARCIA SPA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.center)),
              pw.Center(child: pw.Text("RUT: 77.858.577-4", style: const pw.TextStyle(fontSize: 9))),
              pw.Center(child: pw.Text("Vilaco 301, Toconao", style: const pw.TextStyle(fontSize: 9))),
              pw.Center(child: pw.Text("Tel: +56 9 52341652", style: const pw.TextStyle(fontSize: 9))),
              
              pw.Divider(),
              
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Folio: ${venta.folio}", style: const pw.TextStyle(fontSize: 10)),
                pw.Text(Formatters.formatDate(venta.fecha), style: const pw.TextStyle(fontSize: 10)),
              ]),
              pw.SizedBox(height: 5),
              pw.Text("Cliente: ${venta.cliente}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              
              pw.Divider(),

              // Items del Ticket
              ...venta.items.map((item) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 20, child: pw.Text("${item.cantidad}x", style: const pw.TextStyle(fontSize: 10))),
                    pw.Expanded(child: pw.Text(item.nombre, style: const pw.TextStyle(fontSize: 10))),
                    pw.Text(Formatters.formatCurrency(item.totalLinea), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              )),
              
              pw.Container(
                // Draw a dashed divider using a bottom border since pw.Divider doesn't accept a 'style' parameter
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 0.5, style: pw.BorderStyle.dashed),
                  ),
                ),
              ),

              // Totales Ticket
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.Text(Formatters.formatCurrency(venta.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ]),
              pw.SizedBox(height: 5),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Abonado:", style: const pw.TextStyle(fontSize: 10)),
                pw.Text(Formatters.formatCurrency(venta.montoPagado), style: const pw.TextStyle(fontSize: 10)),
              ]),
              pw.SizedBox(height: 2),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("PENDIENTE:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text(Formatters.formatCurrency(saldo), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ]),

              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("*** NO VALIDO COMO FACTURA ***", style: const pw.TextStyle(fontSize: 8))),
              pw.Center(child: pw.Text("Gracias por su preferencia", style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Ticket_${venta.folio}',
    );
  }

  // --- Widgets Auxiliares ---

  pw.Widget _cell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 10,
        ),
      ),
    );
  }

  pw.Widget _buildTotalRow(String label, double amount) {
    return pw.Container(
      width: 200,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(Formatters.formatCurrency(amount), style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}