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

  Future<void> reponerStock(Producto p, int cantidad) async {
    await _repository.agregarStock(p.id, p.nombre, cantidad);
    notifyListeners();
  }

  // Método limpiado: Ahora solo delega al repositorio
  Future<void> registrarProduccionBloquero({
    required Producto producto,
    required int cantidad,
    required DateTime fecha,
  }) async {
    await _repository.registrarProduccionBloquero(
      productoId: producto.id,
      productoNombre: producto.nombre,
      cantidad: cantidad,
      fecha: fecha,
    );
    notifyListeners();
  }
}