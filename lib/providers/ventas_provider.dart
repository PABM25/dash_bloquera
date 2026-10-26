import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/venta_model.dart';
import '../repositories/ventas_repository.dart';

class VentasProvider with ChangeNotifier {
  final VentasRepository _repository = VentasRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<Venta> _ventas = [];
  List<Venta> get ventas => _ventas;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  DocumentSnapshot? _lastDoc;

  StreamSubscription<User?>? _authSub;

  VentasProvider() {
    // Carga solo con sesión activa y descarta los datos del usuario anterior al salir.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _ventas.clear();
        _lastDoc = null;
        _hasMore = true;
        notifyListeners();
      } else {
        fetchVentas(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> fetchVentas({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _ventas.clear();
      _lastDoc = null;
      _hasMore = true;
    }

    if (!_hasMore) return;

    _setLoading(true);

    try {
      final result = await _repository.getVentasPaginadas(
        startAfter: _lastDoc,
        limit: 20,
      );

      final List<Venta> nuevasVentas = result['ventas'] as List<Venta>;
      final DocumentSnapshot? lastDoc = result['lastDoc'] as DocumentSnapshot?;

      if (nuevasVentas.length < 20) {
        _hasMore = false;
      }

      if (nuevasVentas.isNotEmpty) {
        _ventas.addAll(nuevasVentas);
        _lastDoc = lastDoc;
      }
    } catch (e) {
      debugPrint("Error fetching ventas: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Mantener stream inicial para partes de la app que aún dependen de ello (ej. exportación)
  Stream<List<Venta>> get ventasStream => _repository.getVentasStream(limit: 100);

  Future<void> crearVenta({
    required String cliente,
    String? rut,
    String? direccion,
    required List<ItemOrden> items,
    required DateTime fecha, // Parámetro requerido nuevo
  }) async {
    _setLoading(true);
    try {
      await _repository.crearVentaTransaccion(
        cliente: cliente,
        rut: rut,
        direccion: direccion,
        items: items,
        fecha: fecha, // Pasando la fecha al repo
      );
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // El monto pagado y el total se leen en una transacción en el repositorio,
  // nunca desde el estado local (evita perder abonos concurrentes).
  Future<void> registrarPago(String ventaId, double montoAbono) async {
    await _repository.registrarPago(ventaId, montoAbono);
    notifyListeners();
  }

  Future<void> marcarEntrega(String ventaId, String nuevoEstado) async {
    await FirebaseFirestore.instance.collection('ventas').doc(ventaId).update({'estado_entrega': nuevoEstado});
    // Actualizamos localmente si lo encontramos
    final index = _ventas.indexWhere((v) => v.id == ventaId);
    if (index != -1) {
      final old = _ventas[index];
      _ventas[index] = Venta(
        id: old.id, folio: old.folio, fecha: old.fecha, cliente: old.cliente, rut: old.rut, direccion: old.direccion,
        total: old.total, totalCosto: old.totalCosto, totalUtilidad: old.totalUtilidad, estadoPago: old.estadoPago,
        montoPagado: old.montoPagado, items: old.items, estadoEntrega: nuevoEstado
      );
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
