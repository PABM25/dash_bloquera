import 'dart:async';
import '../models/proveedor_model.dart';
import 'mock_data.dart';

class MockProveedoresRepository {
  final _controller = StreamController<List<Proveedor>>.broadcast();

  MockProveedoresRepository() {
    _controller.add(MockData.proveedores);
  }

  Stream<List<Proveedor>> get proveedoresStream => _controller.stream;
}
