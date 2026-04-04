import 'package:flutter_test/flutter_test.dart';
import 'package:dash_bloquera/models/producto_modelo.dart';

// Definimos un Mock manual simple para simular DocumentSnapshot
class MockDocumentSnapshot {
  final String id;
  final Map<String, dynamic> _data;

  MockDocumentSnapshot(this.id, this._data);

  Map<String, dynamic> data() => _data;
}

// Necesitamos simular el DocumentSnapshot real extendiéndolo, o crear un constructor en Producto
// para pruebas, pero dado que factory fromFirestore espera DocumentSnapshot real, usaremos
// un workaround parseando un Map estandar para las pruebas unitarias principales sin depender de firebase
// Agregaremos un factory fromMap a Producto en la prueba, o testeamos toFirestore.
// Para no modificar el codigo original, testearemos toFirestore() que es determinístico.

void main() {
  group('Producto Model Tests', () {
    test('toFirestore() should return a valid Map', () {
      final producto = Producto(
        id: '123',
        nombre: 'Bloque 15cm',
        stock: 100,
        precioCosto: 15.5,
        descripcion: 'Bloque estandar',
        barcode: '987654321',
      );

      final map = producto.toFirestore();

      expect(map['nombre'], 'Bloque 15cm');
      expect(map['stock'], 100);
      expect(map['precio_costo'], 15.5);
      expect(map['descripcion'], 'Bloque estandar');
      expect(map['barcode'], '987654321');
    });

    test('toFirestore() should handle null optionals properly', () {
      final producto = Producto(
        id: '124',
        nombre: 'Bloque 10cm',
        stock: 50,
        precioCosto: 10.0,
      );

      final map = producto.toFirestore();

      expect(map['nombre'], 'Bloque 10cm');
      expect(map['stock'], 50);
      expect(map['precio_costo'], 10.0);
      expect(map['descripcion'], null);
      expect(map['barcode'], null);
    });
  });
}
