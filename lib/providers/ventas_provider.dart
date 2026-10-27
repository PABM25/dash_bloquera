import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/venta_model.dart';
import '../repositories/ventas_repository.dart';
import '../utils/shared_stream.dart';

class VentasProvider with ChangeNotifier {
  final VentasRepository _repository = VentasRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final List<Venta> _ventas = [];
  List<Venta> get ventas => _ventas;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // Error de la última carga (para no mostrar "No hay ventas" cuando falló).
  String? _error;
  String? get error => _error;

  DocumentSnapshot? _lastDoc;

  StreamSubscription<User?>? _authSub;

  // Despachos pendientes: consulta propia, compartida entre pantallas.
  late final SharedStream<List<Venta>> _despachos =
      SharedStream(_repository.getDespachosPendientesStream);
  Stream<List<Venta>> get despachosPendientesStream => _despachos.stream;

  VentasProvider() {
    // Carga solo con sesión activa y descarta los datos del usuario anterior al salir.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _ventas.clear();
        _lastDoc = null;
        _hasMore = true;
        _error = null;
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

    _error = null;
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
      _error = "No se pudieron cargar las ventas.";
    } finally {
      _setLoading(false);
    }
  }

  // Para exportar: una lectura puntual en lugar de abrir una escucha en tiempo real.
  Future<List<Venta>> fetchVentasParaExportar() => _repository.getTodasLasVentas();

  Future<void> crearVenta({
    required String cliente,
    String? rut,
    String? direccion,
    required List<ItemOrden> items,
    required DateTime fecha,
    required double tasaIva,
  }) async {
    _setLoading(true);
    try {
      await _repository.crearVentaTransaccion(
        cliente: cliente,
        rut: rut,
        direccion: direccion,
        items: items,
        fecha: fecha,
        tasaIva: tasaIva,
      );
    } finally {
      _setLoading(false);
    }
    // La venta nueva debe aparecer en la lista sin recargar a mano.
    unawaited(fetchVentas(refresh: true));
  }

  // El monto pagado y el total se leen en una transacción en el repositorio,
  // nunca desde el estado local (evita perder abonos concurrentes).
  Future<void> registrarPago(String ventaId, double montoAbono) async {
    await _repository.registrarPago(ventaId, montoAbono);
    // Refleja el nuevo estado de pago en la lista.
    try {
      final actualizada = await _repository.getVentaById(ventaId);
      if (actualizada != null) _reemplazarLocal(actualizada);
    } catch (e) {
      debugPrint("Refrescar venta tras pago: $e");
    }
  }

  Future<void> marcarEntrega(String ventaId, String nuevoEstado) async {
    await _repository.marcarEntrega(ventaId, nuevoEstado);
    final index = _ventas.indexWhere((v) => v.id == ventaId);
    if (index != -1) {
      _reemplazarLocal(_ventas[index].copyWith(estadoEntrega: nuevoEstado));
    }
  }

  Future<int> completarEstadoEntregaAntiguo() => _repository.completarEstadoEntregaAntiguo();

  void _reemplazarLocal(Venta venta) {
    final index = _ventas.indexWhere((v) => v.id == venta.id);
    if (index == -1) return;
    _ventas[index] = venta;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
