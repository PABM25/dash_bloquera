import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/gasto_model.dart';

class FinanzasProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int pageSize = 50;

  // Paginado: la pantalla pide más documentos aumentando el límite.
  Stream<List<Gasto>> gastosStream({int limit = pageSize}) {
    return _db.collection('gastos').orderBy('fecha', descending: true).limit(limit).snapshots().map(
      (snap) => snap.docs.map((doc) => Gasto.fromFirestore(doc)).toList(),
    );
  }

  Future<void> addGasto(Gasto gasto) async {
    await _db.collection('gastos').add(gasto.toFirestore());
  }

  Future<void> deleteGasto(String id) async {
    await _db.collection('gastos').doc(id).delete();
  }
  
  // Método auxiliar para registrar salario como gasto automáticamente
  Future<void> registrarPagoSalario(
    String nombreTrabajador,
    double monto,
    DateTime inicio,
    DateTime fin, {
    required String tipoProyecto, // El proyecto del trabajador
  }) async {
    await addGasto(Gasto(
      id: '',
      fecha: DateTime.now(),
      categoria: 'SALARIO',
      descripcion: 'Pago salario a $nombreTrabajador (${inicio.day}/${inicio.month} - ${fin.day}/${fin.month})',
      monto: monto,
      tipoProyecto: tipoProyecto,
    ));
  }
}