import 'package:rxdart/rxdart.dart';
import 'finanzas_provider.dart';
import 'ventas_provider.dart';
import '../models/dashboard_summary.dart';

class DashboardProvider {
  final VentasProvider _ventasProvider;
  final FinanzasProvider _finanzasProvider;

  DashboardProvider(this._ventasProvider, this._finanzasProvider);

  // Combina ambos streams y calcula solo cuando cambian los datos
  Stream<DashboardSummary> get summaryStream {
    return Rx.combineLatest2(
      _ventasProvider.ventasStream,
      _finanzasProvider.gastosStream,
      (ventas, gastos) {
        double ingresos = 0;
        double pagado = 0;
        double costoTotal = 0;

        for (var v in ventas) {
          ingresos += v.total;
          pagado += v.montoPagado;
          costoTotal += v.totalCosto;
        }

        double totalGastos = gastos.fold(0, (sum, g) => sum + g.monto);

        return DashboardSummary(
          ingresos: ingresos,
          gastos: totalGastos,
          utilidad: (ingresos - costoTotal) - totalGastos,
          porCobrar: ingresos - pagado,
        );
      },
    );
  }
}
