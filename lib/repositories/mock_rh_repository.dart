import 'dart:async';
import '../models/trabajador_model.dart';
import 'mock_data.dart';

class MockRhRepository {
  final _controller = StreamController<List<Trabajador>>.broadcast();

  MockRhRepository() {
    _controller.add(MockData.trabajadores);
  }

  Stream<List<Trabajador>> get trabajadoresStream => _controller.stream;

  Future<String?> registrarAsistencia(String trabajadorId, String nombre, DateTime fecha, String tipoProyecto) async {
    return null;
  }
}
