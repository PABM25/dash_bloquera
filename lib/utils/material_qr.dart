import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/producto_modelo.dart';
import 'pdf_generator.dart';

/// QR de materiales. Cada producto del Inventario tiene su QR, así que para
/// agregar un material nuevo basta con crearlo en Inventario (sin tocar código).
class MaterialQr {
  static const String _prefijo = 'VGMAT:';

  /// Materiales que se ofrecen crear si aún no existen en Inventario.
  static const List<String> materialesBase = [
    'Cemento',
    'Bloques de 14',
    'Bloquetas de 9',
    'Pilares',
    'Cadenas',
  ];

  /// Contenido del QR: identifica el producto por su ID (no cambia aunque
  /// se renombre el material).
  static String payload(Producto producto) => '$_prefijo${producto.id}';

  /// Devuelve el ID del producto si el texto escaneado es un QR de material.
  static String? productoIdDesde(String raw) {
    final value = raw.trim();
    if (!value.startsWith(_prefijo)) return null;
    final id = value.substring(_prefijo.length);
    // Solo IDs de documento válidos: un "/" apuntaría a otra ruta de Firestore.
    return _idValido.hasMatch(id) ? id : null;
  }

  static final RegExp _idValido = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  static String normalizar(String nombre) => nombre.trim().toLowerCase();

  /// Materiales base que todavía no están en el inventario.
  static List<String> faltantes(List<Producto> productos) {
    final existentes = productos.map((p) => normalizar(p.nombre)).toSet();
    return materialesBase.where((m) => !existentes.contains(normalizar(m))).toList();
  }

  // ==========================================
  // ETIQUETAS A4: 3 columnas x 7 filas = 21 por hoja (63,5 x 38,1 mm)
  // ==========================================
  static const int porHoja = 21;

  /// Genera la hoja de etiquetas. [imprimir] abre el diálogo de impresión;
  /// si es false, descarga/comparte el PDF.
  static Future<void> generarEtiquetas(
    List<Producto> productos, {
    int copias = 1,
    bool imprimir = true,
    VoidCallback? onGenerated,
  }) async {
    final etiquetas = <(String, String)>[
      for (final p in productos)
        for (var i = 0; i < copias; i++) (p.nombre, payload(p)),
    ];

    final stopwatch = Stopwatch()..start();
    final logo = await PdfGenerator.loadLogo();
    final bytes = await compute(_etiquetasPdf, (etiquetas, logo));
    debugPrint("Etiquetas QR generadas en ${stopwatch.elapsedMilliseconds} ms");
    onGenerated?.call();

    if (imprimir) {
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'Etiquetas_QR');
    } else {
      await Printing.sharePdf(bytes: bytes, filename: 'Etiquetas_QR.pdf');
    }
  }

  static Future<Uint8List> _etiquetasPdf((List<(String, String)>, Uint8List) args) async {
    final (etiquetas, logoBytes) = args;
    final logo = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;
    final doc = pw.Document();

    const double labelW = 63.5 * PdfPageFormat.mm;
    const double labelH = 38.1 * PdfPageFormat.mm;
    const double gapX = 2.54 * PdfPageFormat.mm;

    for (var start = 0; start < etiquetas.length; start += porHoja) {
      final hoja = etiquetas.sublist(start, (start + porHoja).clamp(0, etiquetas.length));
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.only(
            top: 15.15 * PdfPageFormat.mm,
            left: 7.2 * PdfPageFormat.mm,
          ),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var fila = 0; fila < 7; fila++)
                  pw.Row(
                    children: [
                      for (var col = 0; col < 3; col++) ...[
                        if (col > 0) pw.SizedBox(width: gapX),
                        pw.SizedBox(
                          width: labelW,
                          height: labelH,
                          child: fila * 3 + col < hoja.length
                              ? _etiqueta(hoja[fila * 3 + col], logo)
                              : pw.SizedBox(),
                        ),
                      ],
                    ],
                  ),
              ],
            );
          },
        ),
      );
    }
    return doc.save();
  }

  static pw.Widget _etiqueta((String, String) etiqueta, pw.MemoryImage? logo) {
    final (nombre, data) = etiqueta;
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3 * PdfPageFormat.mm),
      child: pw.Row(
        children: [
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium),
            data: data,
            width: 30 * PdfPageFormat.mm,
            height: 30 * PdfPageFormat.mm,
          ),
          pw.SizedBox(width: 3 * PdfPageFormat.mm),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (logo != null)
                  pw.Container(height: 8 * PdfPageFormat.mm, child: pw.Image(logo)),
                pw.SizedBox(height: 2),
                pw.Text(
                  nombre,
                  maxLines: 3,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  "Construcciones V & G",
                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
