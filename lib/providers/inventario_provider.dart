import 'package:flutter/foundation.dart';
import '../models/producto_modelo.dart';
import '../repositories/inventario_repository.dart';
import '../utils/shared_stream.dart';

class InventarioProvider with ChangeNotifier {
  final InventarioRepository _repository = InventarioRepository();

  // Una sola consulta compartida por todas las pantallas (ver SharedStream).
  late final SharedStream<List<Producto>> _productos =
      SharedStream(_repository.getProductosStream);

  Stream<List<Producto>> get productosStream => _productos.stream;

  Future<void> addProducto(
    String nombre,
    int stock,
    double costo,
    String desc,
    String? barcode,
  ) async {
    await _repository.agregarProducto(nombre, stock, costo, desc, barcode);
    notifyListeners();
  }

  Future<void> updateProducto(Producto producto, {int ajusteStock = 0}) async {
    await _repository.updateProducto(producto, ajusteStock: ajusteStock);
    notifyListeners();
  }

  Future<void> deleteProducto(String id) async {
    await _repository.deleteProducto(id);
    notifyListeners();
  }

  Future<Producto?> buscarProductoPorBarcode(String barcode) async {
    return await _repository.getProductoByBarcode(barcode);
  }

  Future<Producto?> buscarProductoPorId(String id) async {
    return await _repository.getProductoById(id);
  }

  Future<int> registrarMovimientoQr(Producto p, int cantidad, {required bool esEntrada}) async {
    final nuevoStock = await _repository.registrarMovimientoQr(
      productoId: p.id,
      cantidad: cantidad,
      esEntrada: esEntrada,
    );
    notifyListeners();
    return nuevoStock;
  }

  Future<void> reponerStock(Producto p, int cantidad) async {
    await _repository.agregarStock(p.id, p.nombre, cantidad);
    notifyListeners();
  }
}
