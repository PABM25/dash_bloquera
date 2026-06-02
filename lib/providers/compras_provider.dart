import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/compra_model.dart';
import '../providers/inventario_provider.dart';

class ComprasProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ComprasProvider(InventarioProvider invProvider);

  Stream<List<Compra>> get comprasStream {
    return _db.collection('compras').orderBy('fecha', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Compra.fromFirestore(doc)).toList();
    });
  }

  Future<void> registrarCompra({
    required String proveedorId,
    required String proveedorNombre,
    required List<CompraItem> items,
    required double total,
    required DateTime fecha,
  }) async {
    // 1. Guardar Compra
    final docRef = _db.collection('compras').doc();
    final String folio = "COM-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

    final compra = Compra(
      id: docRef.id,
      folio: folio,
      proveedorId: proveedorId,
      proveedorNombre: proveedorNombre,
      fecha: fecha,
      total: total,
      items: items,
    );

    await docRef.set(compra.toFirestore());

    // 2. Sumar al Inventario y registrar como gasto (Opcional, en este caso solo sumaremos stock directamente)
    for (var item in items) {
       // Buscar producto y actualizar su stock (reutilizando métodos de InventarioProvider si existen o haciendolo directo)
       // Para hacerlo seguro por transacciones de Firestore, lo haremos directo aqui:
       final pRef = _db.collection('productos').doc(item.productoId);
       await _db.runTransaction((transaction) async {
         final snapshot = await transaction.get(pRef);
         if (snapshot.exists) {
           final stockActual = snapshot.data()?['stock'] ?? 0;
           transaction.update(pRef, {'stock': stockActual + item.cantidad});
         }
       });
       // Opcional: También podrías actualizar el precio de costo del producto si el costo de compra varió.
    }

    // 3. Opcionalmente registrar como Gasto de Operación
    await _db.collection('gastos').add({
      'concepto': 'Compra $folio a $proveedorNombre',
      'monto': total,
      'categoria': 'Compras de Inventario',
      'fecha': Timestamp.fromDate(fecha),
      'referenciaId': docRef.id,
    });

    notifyListeners();
  }
}
