import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/proveedor_model.dart';

import '../repositories/mock_proveedores_repository.dart';

class ProveedoresProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  MockProveedoresRepository? _mockRepo;

  void useMockRepository() {
    _mockRepo = MockProveedoresRepository();
    notifyListeners();
  }

  Stream<List<Proveedor>> get proveedoresStream {
    if (_mockRepo != null) return _mockRepo!.proveedoresStream;
    return _db.collection('proveedores').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Proveedor.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  Future<void> agregarProveedor(String nombre, String rut, String contacto) async {
    await _db.collection('proveedores').add({
      'nombre': nombre,
      'rut': rut,
      'contacto': contacto,
    });
    notifyListeners();
  }

  Future<void> actualizarProveedor(Proveedor prov) async {
    await _db.collection('proveedores').doc(prov.id).update(prov.toFirestore());
    notifyListeners();
  }

  Future<void> eliminarProveedor(String id) async {
    await _db.collection('proveedores').doc(id).delete();
    notifyListeners();
  }
}
