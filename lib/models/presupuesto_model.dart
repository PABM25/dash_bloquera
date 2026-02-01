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
  final double total;
  final List<ItemOrden> items;

  Presupuesto({
    required this.id,
    required this.folio,
    required this.fechaEmision,
    required this.fechaVencimiento,
    required this.cliente,
    this.rut,
    this.direccion,
    required this.total,
    required this.items,
  });

  factory Presupuesto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Presupuesto(
      id: doc.id,
      folio: data['folio'] ?? '',
      fechaEmision: (data['fecha_emision'] as Timestamp).toDate(),
      fechaVencimiento: (data['fecha_vencimiento'] as Timestamp).toDate(),
      cliente: data['cliente'] ?? '',
      rut: data['rut'],
      direccion: data['direccion'],
      total: (data['total'] ?? 0).toDouble(),
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
      'total': total,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}