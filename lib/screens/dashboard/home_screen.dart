import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // [IMPORTANTE] Para formatear moneda
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_summary.dart';
import '../../widgets/kpi_card.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<DashboardSummary> _summary;

  @override
  void initState() {
    super.initState();
    _summary = context.read<DashboardProvider>().fetchSummary();
    // Al volver al Dashboard desde otra sección, se recargan los totales.
    homeVisits.addListener(_refresh);
  }

  @override
  void dispose() {
    homeVisits.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final future = context.read<DashboardProvider>().fetchSummary();
    setState(() => _summary = future);
    try {
      await future;
    } catch (_) {
      // El error se muestra en el FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    // [IMPORTANTE] Definimos el formateador aquí
    final currencyFormat = NumberFormat.compactCurrency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    // Si prefieres ver los números completos (ej: $ 1.500.000) usa este otro:
    // final currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return Scaffold(
          appBar: AppBar(
            leading: ShellScope.menuButton(context),
            title: const Text("Dashboard"),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
                onPressed: _refresh,
              ),
            ],
          ),

          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: FutureBuilder<DashboardSummary>(
                future: _summary,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint("Dashboard error: ${snapshot.error}");
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("No se pudieron cargar los datos."),
                          const SizedBox(height: 12),
                          OutlinedButton(onPressed: _refresh, child: const Text("Reintentar")),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!;

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          title: "Resumen Financiero",
                          subtitle: "Ingresos, utilidad y saldos de tu negocio",
                        ),
                        const SizedBox(height: 16),

                        // Grid de tarjetas KPI (Responsivo)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Ajustamos número de columnas según el ancho disponible
                            int crossAxisCount = 1;
                            if (constraints.maxWidth > 800) {
                              crossAxisCount = 4;
                            } else if (constraints.maxWidth > 500) {
                              crossAxisCount = 2;
                            }

                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.5,
                              children: [
                            // Tarjeta INGRESOS
                            KpiCard(
                              title: "Ingresos (neto)",
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
                              color: data.utilidad >= 0 ? AppTheme.kpiGreen : AppTheme.brandRed,
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
                            );
                          }
                        ),

                        const SizedBox(height: 40),
                        const _SectionTitle(
                          title: "Rentabilidad vs Gastos",
                          subtitle: "Distribución de tus ingresos",
                        ),
                        const SizedBox(height: 16),

                        // GRÁFICO
                        if (data.ingresos > 0 || data.gastos > 0)
                          Card(
                            margin: EdgeInsets.zero,
                            child: Container(
                              height: 350,
                              padding: const EdgeInsets.all(20),
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 60,
                                  sections: [
                                    PieChartSectionData(
                                      color: AppTheme.kpiGreen,
                                      value: data.utilidad > 0 ? data.utilidad : 0,
                                      title: "Utilidad\n${(data.utilidad > 0 && data.ingresos > 0) ? ((data.utilidad/data.ingresos)*100).toStringAsFixed(1) : 0}%",
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      color: AppTheme.brandRed,
                                      value: data.gastos,
                                      title: "Gastos",
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
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
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                                  ),
                                  child: const Icon(Icons.pie_chart_outline, size: 32, color: AppTheme.primary),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Sin datos financieros aún",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Realiza tu primera venta o registra un gasto\npara ver las estadísticas.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          
                        const SizedBox(height: 40),
                      ],
                    ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
