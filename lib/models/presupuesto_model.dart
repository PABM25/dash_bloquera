import 'package:cloud_firestore/cloud_firestore.dart';
import 'venta_model.dart'; // Importamos para reusar la clase ItemOrden

class Presupuesto {
  final String id;
  final String folio; // Ej: COT-2025-001
  final DateTime fechaEmision;
  final DateTime fechaVencimiento;
  final String cliente;
  final String? rut;
  final String? direccion;
  final double neto;
  final double iva; // 0 en cotizaciones creadas antes de separar el IVA
  final double total; // neto + iva
  final List<ItemOrden> items;

  Presupuesto({
    required this.id,
    required this.folio,
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.cliente,
    this.rut,
    this.direccion,
    double? neto,
    this.iva = 0,
    required this.total,
    required this.items,
  }) : neto = neto ?? total - iva;

  factory Presupuesto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final double total = (data['total'] as num?)?.toDouble() ?? 0;
    final double iva = (data['iva'] as num?)?.toDouble() ?? 0;
    final fechaEmision = (data['fecha_emision'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Presupuesto(
      id: doc.id,
      folio: data['folio'] ?? '',
      fechaEmision: fechaEmision,
      fechaVencimiento: (data['fecha_vencimiento'] as Timestamp?)?.toDate() ?? fechaEmision,
      cliente: data['cliente'] ?? '',
      rut: data['rut'],
      direccion: data['direccion'],
      neto: (data['neto'] as num?)?.toDouble() ?? total - iva,
      iva: iva,
      total: total,
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => ItemOrden.fromMap(item))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'folio': folio,
      'fecha_emision': Timestamp.fromDate(fechaEmision),
      'fecha_vencimiento': Timestamp.fromDate(fechaVencimiento),
      'cliente': cliente,
      'rut': rut,
      'direccion': direccion,
      'neto': neto,
      'iva': iva,
      'total': total,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}