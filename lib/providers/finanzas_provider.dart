import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/gasto_model.dart';

class FinanzasProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Gasto>> get gastosStream {
    return _db.collection('gastos').orderBy('fecha', descending: true).snapshots().map(
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
  Future<void> registrarPagoSalario(String nombreTrabajador, double monto, DateTime inicio, DateTime fin) async {
    await addGasto(Gasto(
      id: '',
      fecha: DateTime.now(),
      categoria: 'SALARIO',
      descripcion: 'Pago salario a $nombreTrabajador (${inicio.day}/${inicio.month} - ${fin.day}/${fin.month})',
      monto: monto,
      tipoProyecto: 'CONSTRUCTORA', // O pasarlo como parámetro
    ));
  }
}