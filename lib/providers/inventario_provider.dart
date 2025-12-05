import 'package:flutter/foundation.dart';
import '../models/producto_modelo.dart';
import '../repositories/inventario_repository.dart';

class InventarioProvider with ChangeNotifier {
  final InventarioRepository _repository = InventarioRepository();

  Stream<List<Producto>> get productosStream =>
      _repository.getProductosStream();

  Future<void> addProducto(
    String nombre,
    int stock,
    double costo,
    String desc,
  ) async {
    await _repository.agregarProducto(nombre, stock, costo, desc);
    notifyListeners();
  }

  Future<void> updateProducto(Producto producto) async {
    await _repository.updateProducto(producto);
    notifyListeners();
  }

  Future<void> deleteProducto(String id) async {
    await _repository.deleteProducto(id);
    notifyListeners();
  }

  // Nuevo método para reponer stock (usar en futura pantalla de Kardex o detalle)
  Future<void> reponerStock(Producto p, int cantidad) async {
    await _repository.agregarStock(p.id, p.nombre, cantidad);
    notifyListeners();
  }
}
