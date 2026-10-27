import 'package:intl/intl.dart';

class Formatters {
  // Formato Moneda Chilena: $1.500. El locale es_CL por sí solo pone el
  // símbolo al final ("1.500 $"); el patrón lo deja adelante.
  static final NumberFormat clp = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
    customPattern: '¤#,##0',
  );

  static String formatCurrency(double amount) => clp.format(amount);

  // Formato compacto para tarjetas: $1,5 M
  static String formatCurrencyCompact(double amount) {
    final texto = NumberFormat.compact(locale: 'es_CL').format(amount.abs());
    return amount < 0 ? '-\$$texto' : '\$$texto';
  }

  // Formato Fecha Corta: 25/10/2025
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Formato Fecha con Hora: 25/10/2025 14:30
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
  
  // Interpreta montos escritos en formato chileno: el punto separa miles y la
  // coma decimales ("15.000" -> 15000, "1.500,5" -> 1500.5). Antes "15.000"
  // se leía como 15. Devuelve null si no es un número.
  static double? parseMonto(String texto) {
    final limpio = texto.trim().replaceAll(RegExp(r'[\s$]'), '').replaceAll('.', '').replaceAll(',', '.');
    final valor = double.tryParse(limpio);
    return (valor != null && valor.isFinite) ? valor : null;
  }

  // Valor inicial de un campo de monto, compatible con parseMonto
  // (1500.0 -> "1500", 1500.5 -> "1500,5").
  static String montoParaEditar(double monto) {
    return monto == monto.roundToDouble()
        ? monto.toStringAsFixed(0)
        : monto.toString().replaceAll('.', ',');
  }
}