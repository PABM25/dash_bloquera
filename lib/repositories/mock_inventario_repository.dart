import 'dart:async';
import '../models/producto_modelo.dart';
import 'mock_data.dart';
import 'inventario_repository.dart';

class MockInventarioRepository extends InventarioRepository {
  final _controller = StreamController<List<Producto>>.broadcast();

  MockInventarioRepository() {
    _controller.add(MockData.productos);
  }

  @override
  Stream<List<Producto>> getProductosStream() {
    return _controller.stream;
  }

  @override
  Future<void> agregarProducto(String nombre, int stock, double costo, String desc, String? barcode) async {
    // No-op for demo
  }

  @override
  Future<void> updateProducto(Producto producto) async {
    // No-op for demo
  }

  @override
  Future<void> deleteProducto(String id) async {
    // No-op for demo
  }

  @override
  Future<Producto?> getProductoByBarcode(String barcode) async {
    try {
      return MockData.productos.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> agregarStock(String productoId, String nombre, int cantidad) async {
    // No-op for demo
  }

  @override
  Future<void> registrarProduccionBloquero({
    required String productoId,
    required String productoNombre,
    required int cantidad,
    required DateTime fecha,
  }) async {
    // No-op for demo
  }
}
