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
      // Convertir a CSV usando la librería `csv`
      String csvData = const csv_pkg.CsvEncoder(fieldDelimiter: ';').convert(rows);

      // Usar un directorio temporal seguro y garantizado
      final directory = await getTemporaryDirectory();
      final String path = '${directory.path}/$fileName.csv';
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
