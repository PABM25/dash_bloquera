import 'dart:io';
import 'package:csv/csv.dart' as csv_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ExportUtil {
  /// Exporta una lista de listas a un archivo CSV y abre el diálogo de compartir.
  static Future<void> exportToCSV(
    BuildContext context,
    List<List<dynamic>> rows,
    String fileName,
  ) async {
    try {
      // Convertir a CSV usando la librería `csv`, neutralizando fórmulas
      final safeRows = rows.map((r) => r.map(_sanitizeCell).toList()).toList();
      String csvData = const csv_pkg.CsvEncoder(fieldDelimiter: ';').convert(safeRows);

      // Usar un directorio temporal seguro y garantizado
      final directory = await getTemporaryDirectory();
      final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final String path = '${directory.path}/$safeName.csv';
      final File file = File(path);

      // Guardamos el archivo (Agregamos BOM para compatibilidad con Excel UTF-8)
      await file.writeAsString('\uFEFF$csvData');

      // Compartir o guardar usando la API nativa del SO
      // Esto evita problemas de permisos de Scoped Storage en Android 11+
      // ignore: deprecated_member_use
      final result = await Share.shareXFiles([XFile(path)]);

      if (context.mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte exportado correctamente.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Export CSV error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo exportar el reporte.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Evita inyección de fórmulas (CSV injection): un texto que empiece con
  /// = + - @ o tabulador/retorno se ejecutaría como fórmula en Excel.
  static dynamic _sanitizeCell(dynamic value) {
    if (value is! String || value.isEmpty) return value;
    const peligrosos = ['=', '+', '-', '@', '\t', '\r'];
    return peligrosos.contains(value[0]) ? "'$value" : value;
  }
}
