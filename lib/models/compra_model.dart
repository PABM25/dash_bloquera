import 'package:cloud_firestore/cloud_firestore.dart';

class CompraItem {
  final String productoId;
  final String nombre;
  final int cantidad;
  final double costoUnitario;
  final double totalLinea;

  CompraItem({
    required this.productoId,
    required this.nombre,
    required this.cantidad,
    required this.costoUnitario,
    required this.totalLinea,
  });

  factory CompraItem.fromMap(Map<String, dynamic> data) {
    return CompraItem(
      productoId: data['productoId'] ?? '',
      nombre: data['nombre'] ?? '',
      cantidad: (data['cantidad'] ?? 0).toInt(),
      costoUnitario: (data['costoUnitario'] ?? 0).toDouble(),
      totalLinea: (data['totalLinea'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'cantidad': cantidad,
      'costoUnitario': costoUnitario,
      'totalLinea': totalLinea,
    };
  }
}

class Compra {
  final String id;
  final String folio;
  final String proveedorId;
  final String proveedorNombre;
  final DateTime fecha;
  final double total;
  final List<CompraItem> items;

  Compra({
    required this.id,
    required this.folio,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.fecha,
    required this.total,
    required this.items,
  });

  factory Compra.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Compra(
      id: doc.id,
      folio: data['folio'] ?? '',
      proveedorId: data['proveedorId'] ?? '',
      proveedorNombre: data['proveedorNombre'] ?? '',
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      total: (data['total'] ?? 0).toDouble(),
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => CompraItem.fromMap(item as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'folio': folio,
      'proveedorId': proveedorId,
      'proveedorNombre': proveedorNombre,
      'fecha': Timestamp.fromDate(fecha),
      'total': total,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}
