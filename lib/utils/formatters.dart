import 'package:intl/intl.dart';

class Formatters {
  // Formato Moneda Chilena: $ 1.500
  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'es_CL', 
      symbol: '\$', 
      decimalDigits: 0
    ).format(amount);
  }

  // Formato Fecha Corta: 25/10/2025
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Formato Fecha con Hora: 25/10/2025 14:30
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
  
  // Formatear RUT (simple)
  static String formatRut(String rut) {
    // Aquí podrías agregar lógica para poner puntos y guión si el input viene limpio
    return rut.toUpperCase(); 
  }
}