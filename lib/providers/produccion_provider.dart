import 'package:flutter/foundation.dart';
import '../models/producto_modelo.dart';
import '../models/registro_produccion_model.dart';
import '../repositories/produccion_repository.dart';

class ProduccionProvider with ChangeNotifier {
  final ProduccionRepository _repository = ProduccionRepository();

  Future<void> registrarProduccion({
    required Producto producto,
    required int cantidad,
    required String trabajadorId,
    required String trabajadorNombre,
  }) {
    return _repository.registrarProduccion(
      producto: producto,
      cantidad: cantidad,
      trabajadorId: trabajadorId,
      trabajadorNombre: trabajadorNombre,
    );
  }

  Stream<List<Producto>> productosFabricablesStream() =>
      _repository.productosFabricablesStream();

  Stream<List<RegistroProduccion>> misRegistrosStream(DateTime desde) =>
      _repository.misRegistrosStream(desde);

  Future<void> anularRegistro(RegistroProduccion r) => _repository.anularRegistro(r);
}
