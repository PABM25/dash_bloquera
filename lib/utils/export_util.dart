import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart' as csv_pkg;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ExportUtil {
  /// Exporta una lista de listas a un archivo CSV y abre el diálogo de compartir.
  /// En Web descarga el archivo directamente. [onGenerated] se llama cuando el
  /// archivo ya está armado (para cerrar un indicador de carga).
  static Future<void> exportToCSV(
    BuildContext context,
    List<List<dynamic>> rows,
    String fileName, {
    VoidCallback? onGenerated,
  }) async {
    try {
      // Convertir a CSV usando la librería `csv`, neutralizando fórmulas
      final safeRows = rows.map((r) => r.map(_sanitizeCell).toList()).toList();
      String csvData = const csv_pkg.CsvEncoder(fieldDelimiter: ';').convert(safeRows);
      final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

      // Web no tiene sistema de archivos (dart:io): se descarga en el navegador.
      if (kIsWeb) {
        final bytes = Uint8List.fromList(utf8.encode('﻿$csvData'));
        onGenerated?.call();
        await XFile.fromData(bytes, mimeType: 'text/csv', name: '$safeName.csv').saveTo('$safeName.csv');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte descargado.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Usar un directorio temporal seguro y garantizado
      final directory = await getTemporaryDirectory();
      final String path = '${directory.path}/$safeName.csv';
      final File file = File(path);

      // Guardamos el archivo (Agregamos BOM para compatibilidad con Excel UTF-8)
      await file.writeAsString('﻿$csvData');
      onGenerated?.call();

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
