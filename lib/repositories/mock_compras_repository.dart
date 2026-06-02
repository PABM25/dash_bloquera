import 'dart:async';
import '../models/compra_model.dart';
import 'mock_data.dart';

class MockComprasRepository {
  final _controller = StreamController<List<Compra>>.broadcast();

  MockComprasRepository() {
    _controller.add(MockData.compras);
  }

  Stream<List<Compra>> get comprasStream => _controller.stream;
}
