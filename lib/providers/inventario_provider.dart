import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- ESTA FALTABA
import 'package:firebase_auth/firebase_auth.dart';
import '../models/producto_modelo.dart';
import '../repositories/inventario_repository.dart';

class InventarioProvider with ChangeNotifier {
  final InventarioRepository _repository = InventarioRepository();

  Stream<List<Producto>> get productosStream =>
      _repository.getProductosStream();

  Future<void> addProducto(
    String nombre,
    int stock,
    double costo,
    String desc,
  ) async {
    await _repository.agregarProducto(nombre, stock, costo, desc);
    notifyListeners();
  }

  Future<void> updateProducto(Producto producto) async {
    await _repository.updateProducto(producto);
    notifyListeners();
  }

  Future<void> deleteProducto(String id) async {
    await _repository.deleteProducto(id);
    notifyListeners();
  }

  // Nuevo método para reponer stock (usar en futura pantalla de Kardex o detalle)
  Future<void> reponerStock(Producto p, int cantidad) async {
    await _repository.agregarStock(p.id, p.nombre, cantidad);
    notifyListeners();
  }

  // Método para el Bloquero: Aumenta stock, registra en kardex y crea registro para nómina
  Future<void> registrarProduccionBloquero({
    required Producto producto,
    required int cantidad,
    required DateTime fecha,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw "Usuario no identificado";

    final batch = FirebaseFirestore.instance.batch();

    // 1. Referencia al Producto para actualizar Stock
    final prodRef = FirebaseFirestore.instance.collection('productos').doc(producto.id);
    
    // 2. Referencia al nuevo Registro de Producción (Para Salario)
    final prodRecordRef = FirebaseFirestore.instance.collection('registros_produccion').doc();
    
    // 3. Referencia al Movimiento de Inventario (Kardex)
    final kardexRef = FirebaseFirestore.instance.collection('movimientos_inventario').doc();

    // OPERACIÓN A: Incrementar Stock
    batch.update(prodRef, {
      'stock': FieldValue.increment(cantidad),
    });

    // OPERACIÓN B: Guardar registro para cálculo de salario
    batch.set(prodRecordRef, {
      'trabajadorId': user.uid,
      'trabajadorNombre': user.displayName ?? 'Trabajador',
      'productoId': producto.id,
      'productoNombre': producto.nombre,
      'cantidad': cantidad,
      'fecha': Timestamp.fromDate(fecha),
      'pagoProcesado': false, // Para saber si ya se le pagó por esto
    });

    // OPERACIÓN C: Registrar en Kardex
    batch.set(kardexRef, {
      'productoId': producto.id,
      'productoNombre': producto.nombre,
      'cantidad': cantidad,
      'tipo': 'ENTRADA',
      'motivo': 'PRODUCCION_INTERNA',
      'fecha': FieldValue.serverTimestamp(),
      'usuarioId': user.uid,
    });

    await batch.commit();
    notifyListeners(); // Notificar cambios a la UI
  }
}