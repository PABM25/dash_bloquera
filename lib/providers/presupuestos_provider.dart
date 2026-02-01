import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/presupuesto_model.dart';
import '../models/venta_model.dart'; // Para ItemOrden

class PresupuestosProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Obtener lista de presupuestos en tiempo real
  Stream<List<Presupuesto>> get presupuestosStream {
    return _firestore
        .collection('presupuestos')
        .orderBy('fecha_emision', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Presupuesto.fromFirestore(doc))
            .toList());
  }

  // Crear un nuevo presupuesto con transacción para el Folio
  Future<String> crearPresupuesto({
    required String cliente,
    String? rut,
    String? direccion,
    required List<ItemOrden> items,
    required DateTime fechaEmision,
    int diasValidez = 15,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      return await _firestore.runTransaction((transaction) async {
        // 1. Generar Folio
        // Usamos un documento 'config/correlativos' para llevar la cuenta
        final docRef = _firestore.collection('config').doc('correlativos');
        final snapshot = await transaction.get(docRef);

        int nextId = 1;
        if (snapshot.exists) {
          nextId = (snapshot.data()?['presupuestos_count'] ?? 0) + 1;
        }

        // Formato: COT-2025-0001
        final year = DateTime.now().year;
        final folio = "COT-$year-${nextId.toString().padLeft(4, '0')}";

        // 2. Calcular Total
        final double total = items.fold(0, (sum, item) => sum + item.totalLinea);

        // 3. Crear Referencia de Documento
        final nuevoPresupuestoRef = _firestore.collection('presupuestos').doc();

        // 4. Escribir Datos
        transaction.set(nuevoPresupuestoRef, {
          'folio': folio,
          'fecha_emision': Timestamp.fromDate(fechaEmision),
          'fecha_vencimiento': Timestamp.fromDate(fechaEmision.add(Duration(days: diasValidez))),
          'cliente': cliente,
          'rut': rut,
          'direccion': direccion,
          'total': total,
          'items': items.map((e) => e.toMap()).toList(),
          'created_at': FieldValue.serverTimestamp(),
        });

        // 5. Actualizar Correlativo
        transaction.set(docRef, {'presupuestos_count': nextId}, SetOptions(merge: true));

        return nuevoPresupuestoRef.id;
      });
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}