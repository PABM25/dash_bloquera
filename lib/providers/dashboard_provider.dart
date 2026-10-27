import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/dashboard_summary.dart';

class DashboardProvider {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Los totales se calculan en el servidor con consultas de agregación:
  // se descargan 3 resultados en lugar de todas las ventas y gastos.
  //
  // Criterio de utilidad: ventas netas − costo de lo vendido − gastos
  // operativos. Las compras de inventario (gastos con 'referenciaId') NO se
  // restan, porque su costo ya entra como 'total_costo' al venderse.
  Future<DashboardSummary> fetchSummary() async {
    final stopwatch = Stopwatch()..start();
    try {
      final results = await Future.wait([
        _db
            .collection('ventas')
            .aggregate(sum('total'), sum('iva'), sum('monto_pagado'), sum('total_costo'))
            .get(),
        _db.collection('gastos').aggregate(sum('monto')).get(),
        _db
            .collection('gastos')
            .where('referenciaId', isNull: false)
            .aggregate(sum('monto'))
            .get(),
      ]);
      final ventas = results[0];
      final gastos = results[1];
      final compras = results[2];

      return _summary(
        total: ventas.getSum('total') ?? 0,
        iva: ventas.getSum('iva') ?? 0,
        pagado: ventas.getSum('monto_pagado') ?? 0,
        costoTotal: ventas.getSum('total_costo') ?? 0,
        totalGastos: gastos.getSum('monto') ?? 0,
        gastosCompras: compras.getSum('monto') ?? 0,
      );
    } catch (e) {
      // Si la agregación falla (sin red, permisos, etc.) se calcula leyendo
      // los documentos; get() usa la caché local automáticamente sin conexión.
      debugPrint("Dashboard aggregate falló ($e); calculando con lectura de documentos");
      return await _summaryFromDocs();
    } finally {
      debugPrint("Dashboard cargado en ${stopwatch.elapsedMilliseconds} ms");
    }
  }

  Future<DashboardSummary> _summaryFromDocs() async {
    final ventasSnap = await _db.collection('ventas').get();
    final gastosSnap = await _db.collection('gastos').get();

    double total = 0;
    double iva = 0;
    double pagado = 0;
    double costoTotal = 0;
    for (final doc in ventasSnap.docs) {
      final data = doc.data();
      total += (data['total'] as num?)?.toDouble() ?? 0;
      iva += (data['iva'] as num?)?.toDouble() ?? 0;
      pagado += (data['monto_pagado'] as num?)?.toDouble() ?? 0;
      costoTotal += (data['total_costo'] as num?)?.toDouble() ?? 0;
    }
    double totalGastos = 0;
    double gastosCompras = 0;
    for (final doc in gastosSnap.docs) {
      final data = doc.data();
      final monto = (data['monto'] as num?)?.toDouble() ?? 0;
      totalGastos += monto;
      if (data['referenciaId'] != null) gastosCompras += monto;
    }

    return _summary(
      total: total,
      iva: iva,
      pagado: pagado,
      costoTotal: costoTotal,
      totalGastos: totalGastos,
      gastosCompras: gastosCompras,
    );
  }

  DashboardSummary _summary({
    required double total,
    required double iva,
    required double pagado,
    required double costoTotal,
    required double totalGastos,
    required double gastosCompras,
  }) {
    // Las ventas antiguas no tienen 'iva' (suma 0): su total ya era neto.
    final ingresosNetos = total - iva;
    return DashboardSummary(
      ingresos: ingresosNetos,
      gastos: totalGastos,
      utilidad: (ingresosNetos - costoTotal) - (totalGastos - gastosCompras),
      // Lo que se cobra al cliente es el total con IVA.
      porCobrar: total - pagado,
    );
  }
}
