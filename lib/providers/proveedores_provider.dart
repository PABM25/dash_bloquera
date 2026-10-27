import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/proveedor_model.dart';
import '../utils/shared_stream.dart';

class ProveedoresProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final SharedStream<List<Proveedor>> _proveedores = SharedStream(
    () => _db.collection('proveedores').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Proveedor.fromFirestore(doc.data(), doc.id)).toList();
    }),
  );

  Stream<List<Proveedor>> get proveedoresStream => _proveedores.stream;

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
