import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // [IMPORTANTE] Para formatear moneda
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_summary.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/kpi_card.dart';
import '../../utils/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // [IMPORTANTE] Definimos el formateador aquí
    final currencyFormat = NumberFormat.compactCurrency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    // Si prefieres ver los números completos (ej: $ 1.500.000) usa este otro:
    // final currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return Consumer<DashboardProvider>(
      builder: (context, dashboardProv, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Dashboard")),
          drawer: const AppDrawer(),
          backgroundColor: Colors.grey[50], 
          
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: StreamBuilder<DashboardSummary>(
                stream: dashboardProv.summaryStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Resumen Financiero",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Grid de tarjetas KPI
                        GridView.extent(
                          maxCrossAxisExtent: 350,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.5,
                          children: [
                            // Tarjeta INGRESOS
                            KpiCard(
                              title: "Ingresos",
                              // [CORRECCIÓN] Convertimos el número a String formateado
                              value: currencyFormat.format(data.ingresos), 
                              subtitle: "Ir a Ventas",
                              icon: Icons.attach_money,
                              color: AppTheme.primary,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Navegar a detalle de Ingresos"))
                                );
                              },
                            ),
                            
                            // Tarjeta UTILIDAD
                            KpiCard(
                              title: "Utilidad Neta",
                              // [CORRECCIÓN]
                              value: currencyFormat.format(data.utilidad),
                              subtitle: "Ganancia Real",
                              icon: Icons.savings,
                              color: data.utilidad >= 0 ? Colors.green : Colors.red,
                              onTap: () {},
                            ),
                            
                            // Tarjeta POR COBRAR
                            KpiCard(
                              title: "Por Cobrar",
                              // [CORRECCIÓN]
                              value: currencyFormat.format(data.porCobrar),
                              subtitle: "Saldo Pendiente",
                              icon: Icons.money_off,
                              color: AppTheme.kpiOrange,
                              onTap: () {},
                            ),
                            
                            // Tarjeta GASTOS
                            KpiCard(
                              title: "Gastos Totales",
                              // [CORRECCIÓN]
                              value: currencyFormat.format(data.gastos),
                              subtitle: "Ver detalle de gastos",
                              icon: Icons.shopping_bag,
                              color: AppTheme.kpiBlue,
                              onTap: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                        const Text(
                          "Rentabilidad vs Gastos",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // GRÁFICO
                        if (data.ingresos > 0 || data.gastos > 0)
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade200)
                            ),
                            child: Container(
                              height: 350,
                              padding: const EdgeInsets.all(20),
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 50,
                                  sections: [
                                    PieChartSectionData(
                                      color: Colors.green,
                                      value: data.utilidad > 0 ? data.utilidad : 0,
                                      title: "Utilidad\n${(data.utilidad > 0 && data.ingresos > 0) ? ((data.utilidad/data.ingresos)*100).toStringAsFixed(1) : 0}%",
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      color: AppTheme.primary,
                                      value: data.gastos,
                                      title: "Gastos",
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.pie_chart_outline, size: 60, color: Colors.grey),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Sin datos financieros aún",
                                  style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Realiza tu primera venta o registra un gasto\npara ver las estadísticas.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}