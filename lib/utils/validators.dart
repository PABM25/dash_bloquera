import 'formatters.dart';

class Validators {
  // Campo Requerido
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  // Validar Email
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    final emailRegex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingrese un correo válido';
    }
    return null;
  }

  // Validar Números Positivos
  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    final numValue = Formatters.parseMonto(value);
    if (numValue == null) return 'Debe ser un número';
    if (numValue <= 0) return 'Debe ser mayor a 0';
    return null;
  }

  // Validar enteros >= 0 (stock, cantidades)
  static String? nonNegativeInt(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    final numValue = int.tryParse(value.trim());
    if (numValue == null) return 'Debe ser un número entero';
    if (numValue < 0) return 'No puede ser negativo';
    if (numValue > 10000000) return 'Valor demasiado grande';
    return null;
  }

  // Validar números >= 0 (costos, precios)
  static String? nonNegativeNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Requerido';
    final numValue = Formatters.parseMonto(value);
    if (numValue == null) return 'Debe ser un número';
    if (numValue < 0) return 'No puede ser negativo';
    return null;
  }

  // Campo requerido con largo máximo
  static String? Function(String?) requiredMax(int maxLen) {
    return (String? value) {
      final base = required(value);
      if (base != null) return base;
      if (value!.trim().length > maxLen) return 'Máximo $maxLen caracteres';
      return null;
    };
  }

  // Validar RUT Chileno (Algoritmo Módulo 11)
  static String? rut(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    
    String rutLimpio = value.replaceAll('.', '').replaceAll('-', '').trim().toUpperCase();
    // Cuerpo numérico de 7-8 dígitos y DV numérico o K
    if (!RegExp(r'^\d{7,8}[0-9K]$').hasMatch(rutLimpio)) return 'RUT inválido';

    String cuerpo = rutLimpio.substring(0, rutLimpio.length - 1);
    String dv = rutLimpio.substring(rutLimpio.length - 1);
    
    int suma = 0;
    int multiplicador = 2;

    for (int i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * multiplicador;
      multiplicador++;
      if (multiplicador == 8) multiplicador = 2;
    }

    int resto = suma % 11;
    String dvCalculado;
    
    if (resto == 0) {
      dvCalculado = '0';
    } else if (resto == 1) {
      dvCalculado = 'K';
    } else {
      dvCalculado = (11 - resto).toString();
    }

    if (dvCalculado != dv) {
      return 'RUT inválido';
    }
    
    return null;
  }
}