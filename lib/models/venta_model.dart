import 'package:cloud_firestore/cloud_firestore.dart';

class ItemOrden {
  final String productoId;
  final String nombre; // Guardamos el nombre por si el producto se borra después
  final int cantidad;
  final double precioUnitario;
  final double totalLinea;

  ItemOrden({
    required this.productoId,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.totalLinea,
  });

  factory ItemOrden.fromMap(Map<String, dynamic> map) {
    return ItemOrden(
      productoId: map['productoId'] ?? '',
      nombre: map['nombre'] ?? '',
      cantidad: map['cantidad'] ?? 0,
      precioUnitario: (map['precio_unitario'] ?? 0).toDouble(),
      totalLinea: (map['total_linea'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'total_linea': totalLinea,
    };
  }
}

class Venta {
  final String id;
  final String folio; // Ej: OC-2025-0001
  final DateTime fecha;
  final String cliente;
  final String? rut;
  final String? direccion;
  final double total;
  final double totalCosto; // Para calcular utilidad
  final double totalUtilidad;
  final String estadoPago; // PENDIENTE, ABONADA, PAGADA
  final double montoPagado;
  final List<ItemOrden> items;

  Venta({
    required this.id,
    required this.folio,
    required this.fecha,
    required this.cliente,
    this.rut,
    this.direccion,
    required this.total,
    required this.totalCosto,
    required this.totalUtilidad,
    required this.estadoPago,
    required this.montoPagado,
    required this.items,
  });

  factory Venta.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Venta(
      id: doc.id,
      folio: data['folio'] ?? '',
      // Manejo seguro de fechas desde Firestore
      fecha: (data['fecha'] as Timestamp).toDate(),
      cliente: data['cliente'] ?? '',
      rut: data['rut'],
      direccion: data['direccion'],
      total: (data['total'] ?? 0).toDouble(),
      totalCosto: (data['total_costo'] ?? 0).toDouble(),
      totalUtilidad: (data['total_utilidad'] ?? 0).toDouble(),
      estadoPago: data['estado_pago'] ?? 'PENDIENTE',
      montoPagado: (data['monto_pagado'] ?? 0).toDouble(),
      // Convertir la lista de mapas a lista de objetos ItemOrden
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => ItemOrden.fromMap(item))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'folio': folio,
      'fecha': Timestamp.fromDate(fecha),
      'cliente': cliente,
      'rut': rut,
      'direccion': direccion,
      'total': total,
      'total_costo': totalCosto,
      'total_utilidad': totalUtilidad,
      'estado_pago': estadoPago,
      'monto_pagado': montoPagado,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}