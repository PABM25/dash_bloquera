import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/presupuesto_model.dart';
import '../models/venta_model.dart'; // Para ItemOrden y TotalesOrden

class PresupuestosProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Crea un presupuesto con transacción para el Folio. Devuelve el presupuesto
  // guardado (con su folio real) para poder generar el PDF.
  Future<Presupuesto> crearPresupuesto({
    required String cliente,
    String? rut,
    String? direccion,
    required List<ItemOrden> items,
    required DateTime fechaEmision,
    required double tasaIva,
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

        final int nextId =
            ((snapshot.data()?['presupuestos_count'] as num?)?.toInt() ?? 0) + 1;

        // Formato: COT-2025-0001 (año de la fecha de emisión, como en ventas)
        final folio = "COT-${fechaEmision.year}-${nextId.toString().padLeft(4, '0')}";

        // 2. Calcular Totales (precios netos + IVA)
        final totales = TotalesOrden.calcular(items, tasaIva);

        // 3. Crear Referencia de Documento
        final nuevoPresupuestoRef = _firestore.collection('presupuestos').doc();

        final presupuesto = Presupuesto(
          id: nuevoPresupuestoRef.id,
          folio: folio,
          fechaEmision: fechaEmision,
          fechaVencimiento: fechaEmision.add(Duration(days: diasValidez)),
          cliente: cliente,
          rut: rut,
          direccion: direccion,
          neto: totales.neto,
          iva: totales.iva,
          total: totales.total,
          items: items,
        );

        // 4. Escribir Datos
        transaction.set(nuevoPresupuestoRef, {
          ...presupuesto.toFirestore(),
          'tasa_iva': tasaIva,
          'created_at': FieldValue.serverTimestamp(),
        });

        // 5. Actualizar Correlativo
        transaction.set(docRef, {'presupuestos_count': nextId}, SetOptions(merge: true));

        return presupuesto;
      });
    } catch (e) {
      if (e is FirebaseException && e.code == 'unavailable') {
        throw Exception("No hay conexión a Internet. Las cotizaciones requieren red para generar su número de folio.");
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
