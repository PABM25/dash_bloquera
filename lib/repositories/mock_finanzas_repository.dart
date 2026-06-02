import 'dart:async';
import '../models/gasto_model.dart';
import 'mock_data.dart';

class MockFinanzasRepository {
  final _controller = StreamController<List<Gasto>>.broadcast();

  MockFinanzasRepository() {
    _controller.add(MockData.gastos);
  }

  Stream<List<Gasto>> get gastosStream => _controller.stream;
}
