import 'package:flutter_test/flutter_test.dart';
import 'package:dash_bloquera/models/venta_model.dart';

ItemOrden _item(int cantidad, double precio) => ItemOrden(
      productoId: 'p',
      nombre: 'Bloque',
      cantidad: cantidad,
      precioUnitario: precio,
      // totalLinea viene del cliente: no debe influir en el cálculo.
      totalLinea: 999999,
    );

void main() {
  group('TotalesOrden', () {
    test('suma el IVA sobre el neto', () {
      final t = TotalesOrden.calcular([_item(10, 1000), _item(2, 500)], 0.19);
      expect(t.neto, 11000);
      expect(t.iva, 2090);
      expect(t.total, 13090);
    });

    test('redondea el IVA a pesos', () {
      final t = TotalesOrden.calcular([_item(1, 1001)], 0.19); // 190,19
      expect(t.iva, 190);
      expect(t.total, 1191);
    });

    test('tasa 0 deja el total igual al neto', () {
      final t = TotalesOrden.calcular([_item(3, 700)], 0);
      expect(t.iva, 0);
      expect(t.total, t.neto);
    });

    test('sin ítems todo es 0', () {
      final t = TotalesOrden.calcular(const [], 0.19);
      expect(t.total, 0);
    });
  });

  group('Venta', () {
    test('ventas antiguas sin IVA: el neto es el total', () {
      final v = Venta(
        id: '1', folio: 'OC-1', fecha: DateTime(2025), cliente: 'X',
        total: 5000, totalCosto: 3000, totalUtilidad: 2000,
        estadoPago: 'PENDIENTE', montoPagado: 0, items: const [],
      );
      expect(v.iva, 0);
      expect(v.neto, 5000);
    });

    test('copyWith conserva los totales', () {
      final v = Venta(
        id: '1', folio: 'OC-1', fecha: DateTime(2025), cliente: 'X',
        neto: 1000, iva: 190, total: 1190, totalCosto: 600, totalUtilidad: 400,
        estadoPago: 'PAGADA', montoPagado: 1190, items: const [],
      ).copyWith(estadoEntrega: 'ENTREGADO');
      expect(v.estadoEntrega, 'ENTREGADO');
      expect(v.neto, 1000);
      expect(v.iva, 190);
      expect(v.total, 1190);
    });
  });
}
