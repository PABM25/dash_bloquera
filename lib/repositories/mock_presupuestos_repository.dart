import 'dart:async';
import '../models/presupuesto_model.dart';

class MockPresupuestosRepository {
  final _controller = StreamController<List<Presupuesto>>.broadcast();

  MockPresupuestosRepository() {
    _controller.add([]);
  }

  Stream<List<Presupuesto>> get presupuestosStream => _controller.stream;
}
