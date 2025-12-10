import 'package:flutter/foundation.dart';
import '../models/venta_model.dart';
import '../repositories/ventas_repository.dart';

class VentasProvider with ChangeNotifier {
  final VentasRepository _repository = VentasRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<Venta>> get ventasStream => _repository.getVentasStream();

  Future<void> crearVenta({
    required String cliente,
    String? rut,
    String? direccion,
    required List<ItemOrden> items,
    required DateTime fecha, // Parámetro requerido nuevo
  }) async {
    _setLoading(true);
    try {
      await _repository.crearVentaTransaccion(
        cliente: cliente,
        rut: rut,
        direccion: direccion,
        items: items,
        fecha: fecha, // Pasando la fecha al repo
      );
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registrarPago(
    String ventaId,
    double montoAbono,
    double pagadoActual,
    double total,
  ) async {
    await _repository.registrarPago(
      ventaId,
      montoAbono,
      pagadoActual, 
      total,
    );
    notifyListeners();
  }

  Future<void> registrarPagoSeguro(Venta venta, double monto) async {
    await registrarPago(
      venta.id,
      monto,
      venta.montoPagado,
      venta.total,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}