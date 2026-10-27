import 'package:flutter_test/flutter_test.dart';
import 'package:dash_bloquera/utils/formatters.dart';
import 'package:dash_bloquera/utils/material_qr.dart';
import 'package:dash_bloquera/utils/validators.dart';

void main() {
  group('Formatters.parseMonto', () {
    test('el punto separa miles (antes "15.000" se leía como 15)', () {
      expect(Formatters.parseMonto('15.000'), 15000);
      expect(Formatters.parseMonto('1.234.567'), 1234567);
    });

    test('la coma separa decimales', () {
      expect(Formatters.parseMonto('1.500,5'), 1500.5);
    });

    test('ignora espacios y el signo \$', () {
      expect(Formatters.parseMonto(r' $ 2.000 '), 2000);
    });

    test('texto inválido devuelve null', () {
      expect(Formatters.parseMonto('abc'), isNull);
      expect(Formatters.parseMonto(''), isNull);
    });

    test('montoParaEditar es compatible con parseMonto', () {
      for (final v in [0.0, 1500.0, 1500.5, 99999.0]) {
        expect(Formatters.parseMonto(Formatters.montoParaEditar(v)), v);
      }
    });
  });

  group('Formatters.formatCurrency', () {
    test('pesos chilenos con el símbolo adelante', () {
      expect(Formatters.formatCurrency(0), '\$0');
      expect(Formatters.formatCurrency(1500), '\$1.500');
      expect(Formatters.formatCurrency(1234567), '\$1.234.567');
      expect(Formatters.formatCurrency(-2500), '-\$2.500');
    });

    test('compacto para tarjetas', () {
      expect(Formatters.formatCurrencyCompact(0), '\$0');
      expect(Formatters.formatCurrencyCompact(-500), '-\$500');
    });
  });

  group('Validators', () {
    test('positiveNumber acepta miles con punto', () {
      expect(Validators.positiveNumber('15.000'), isNull);
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber(''), isNotNull);
    });

    test('rut valida el dígito verificador', () {
      expect(Validators.rut('11.111.111-1'), isNull);
      expect(Validators.rut('11.111.111-2'), isNotNull);
      expect(Validators.rut('12345678-5'), isNull);
    });

    test('nonNegativeInt rechaza negativos y decimales', () {
      expect(Validators.nonNegativeInt('10'), isNull);
      expect(Validators.nonNegativeInt('-1'), isNotNull);
      expect(Validators.nonNegativeInt('1.5'), isNotNull);
    });
  });

  group('MaterialQr.productoIdDesde', () {
    test('extrae el ID de un QR propio', () {
      expect(MaterialQr.productoIdDesde('VGMAT:abc123'), 'abc123');
    });

    test('rechaza QR ajenos o con rutas', () {
      expect(MaterialQr.productoIdDesde('https://ejemplo.cl'), isNull);
      expect(MaterialQr.productoIdDesde('VGMAT:'), isNull);
      expect(MaterialQr.productoIdDesde('VGMAT:a/b'), isNull);
    });
  });
}
