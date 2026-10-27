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
      cantidad: (map['cantidad'] as num?)?.toInt() ?? 0,
      precioUnitario: (map['precio_unitario'] as num?)?.toDouble() ?? 0,
      totalLinea: (map['total_linea'] as num?)?.toDouble() ?? 0,
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

/// Totales de una orden. Los precios unitarios son NETOS y el IVA se suma
/// encima (redondeado a pesos). La misma fórmula se usa en pantalla, en lo
/// que se guarda y en los PDF, para que nunca difieran.
class TotalesOrden {
  final double neto;
  final double iva;
  final double total;

  const TotalesOrden._(this.neto, this.iva, this.total);

  factory TotalesOrden.calcular(Iterable<ItemOrden> items, double tasaIva) {
    final neto = items.fold(0.0, (acc, i) => acc + i.precioUnitario * i.cantidad);
    final iva = (neto * tasaIva).roundToDouble();
    return TotalesOrden._(neto, iva, neto + iva);
  }
}

class Venta {
  final String id;
  final String folio; // Ej: OC-2025-0001
  final DateTime fecha;
  final String cliente;
  final String? rut;
  final String? direccion;
  final double neto;
  final double iva; // 0 en ventas creadas antes de separar el IVA
  final double total; // neto + iva
  final double totalCosto; // Para calcular utilidad
  final double totalUtilidad;
  final String estadoPago; // PENDIENTE, ABONADA, PAGADA
  final double montoPagado;
  final List<ItemOrden> items;
  final String estadoEntrega; // PENDIENTE, ENTREGADO

  Venta({
    required this.id,
    required this.folio,
    required this.fecha,
    required this.cliente,
    this.rut,
    this.direccion,
    double? neto,
    this.iva = 0,
    required this.total,
    required this.totalCosto,
    required this.totalUtilidad,
    required this.estadoPago,
    required this.montoPagado,
    required this.items,
    this.estadoEntrega = 'PENDIENTE',
  }) : neto = neto ?? total - iva;

  factory Venta.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final double total = (data['total'] as num?)?.toDouble() ?? 0;
    final double iva = (data['iva'] as num?)?.toDouble() ?? 0;
    return Venta(
      id: doc.id,
      folio: data['folio'] ?? '',
      // Manejo seguro de fechas desde Firestore
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cliente: data['cliente'] ?? '',
      rut: data['rut'],
      direccion: data['direccion'],
      neto: (data['neto'] as num?)?.toDouble() ?? total - iva,
      iva: iva,
      total: total,
      totalCosto: (data['total_costo'] as num?)?.toDouble() ?? 0,
      totalUtilidad: (data['total_utilidad'] as num?)?.toDouble() ?? 0,
      estadoPago: data['estado_pago'] ?? 'PENDIENTE',
      montoPagado: (data['monto_pagado'] as num?)?.toDouble() ?? 0,
      estadoEntrega: data['estado_entrega'] ?? 'PENDIENTE',
      // Convertir la lista de mapas a lista de objetos ItemOrden
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => ItemOrden.fromMap(item))
          .toList(),
    );
  }

  Venta copyWith({String? estadoEntrega}) {
    return Venta(
      id: id, folio: folio, fecha: fecha, cliente: cliente, rut: rut, direccion: direccion,
      neto: neto, iva: iva, total: total, totalCosto: totalCosto, totalUtilidad: totalUtilidad,
      estadoPago: estadoPago, montoPagado: montoPagado, items: items,
      estadoEntrega: estadoEntrega ?? this.estadoEntrega,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'folio': folio,
      'fecha': Timestamp.fromDate(fecha),
      'cliente': cliente,
      'rut': rut,
      'direccion': direccion,
      'neto': neto,
      'iva': iva,
      'total': total,
      'total_costo': totalCosto,
      'total_utilidad': totalUtilidad,
      'estado_pago': estadoPago,
      'monto_pagado': montoPagado,
      'estado_entrega': estadoEntrega,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }
}