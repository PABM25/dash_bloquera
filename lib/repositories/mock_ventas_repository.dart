import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/venta_model.dart';
import 'mock_data.dart';
import 'ventas_repository.dart';

class MockVentasRepository extends VentasRepository {
  final _controller = StreamController<List<Venta>>.broadcast();

  MockVentasRepository() {
    _controller.add(MockData.ventas);
  }

  @override
  Stream<List<Venta>> getVentasStream({int limit = 100}) {
    return _controller.stream;
  }

  @override
  Future<Map<String, dynamic>> getVentasPaginadas({int limit = 20, DocumentSnapshot? startAfter}) async {
    return {
      'ventas': MockData.ventas,
      'lastDoc': null,
    };
  }

  @override
  Future<void> registrarPago(String ventaId, double monto, double pagadoActual, double total) async {
    // No-op for demo
  }

  Future<void> marcarEntrega(String ventaId, String nuevoEstado) async {
    // No-op for demo
  }
}
