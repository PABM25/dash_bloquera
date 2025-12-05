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
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingrese un correo válido';
    }
    return null;
  }

  // Validar Números Positivos
  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    final numValue = double.tryParse(value);
    if (numValue == null) return 'Debe ser un número';
    if (numValue <= 0) return 'Debe ser mayor a 0';
    return null;
  }

  // Validar RUT Chileno (Algoritmo Módulo 11)
  static String? rut(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    
    String rutLimpio = value.replaceAll('.', '').replaceAll('-', '').toUpperCase();
    if (rutLimpio.length < 2) return 'RUT inválido';

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