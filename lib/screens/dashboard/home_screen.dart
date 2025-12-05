import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_summary.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/kpi_card.dart';
import '../../utils/app_theme.dart';
// Importa tus otras pantallas aquí si quieres navegar, por ejemplo:
// import '../ventas/lista_ventas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer del DashboardProvider
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProv, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Dashboard")),
          drawer: const AppDrawer(),
          backgroundColor: Colors.grey[50], // Fondo suave para resaltar las tarjetas
          
          // 1. CENTRADO Y LÍMITE DE ANCHO (Mejora Web)
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

                        // 2. GRID INTELIGENTE (Mejora Responsive)
                        GridView.extent(
                          maxCrossAxisExtent: 350, // Las tarjetas tendrán máximo 350px de ancho
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.5,
                          children: [
                            // Tarjeta INGRESOS
                            KpiCard(
                              title: "Ingresos",
                              value: data.ingresos,
                              subtitle: "Ir a Ventas",
                              icon: Icons.attach_money,
                              color: AppTheme.primary,
                              onTap: () {
                                // Ejemplo de navegación:
                                // Navigator.push(context, MaterialPageRoute(builder: (_) => const ListaVentasScreen()));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Navegar a detalle de Ingresos"))
                                );
                              },
                            ),
                            
                            // Tarjeta UTILIDAD
                            KpiCard(
                              title: "Utilidad Neta",
                              value: data.utilidad,
                              subtitle: "Ganancia Real",
                              icon: Icons.savings,
                              color: data.utilidad >= 0 ? Colors.green : Colors.red,
                              onTap: () {
                                // Acción al tocar
                              },
                            ),
                            
                            // Tarjeta POR COBRAR
                            KpiCard(
                              title: "Por Cobrar",
                              value: data.porCobrar,
                              subtitle: "Saldo Pendiente",
                              icon: Icons.money_off,
                              color: AppTheme.kpiOrange,
                              onTap: () {},
                            ),
                            
                            // Tarjeta GASTOS
                            KpiCard(
                              title: "Gastos Totales",
                              value: data.gastos,
                              subtitle: "Ver detalle de gastos",
                              icon: Icons.shopping_bag,
                              color: AppTheme.kpiBlue,
                              onTap: () {
                                // Navegar a pantalla de gastos
                              },
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

                        // 3. GRÁFICO (Con manejo de estado vacío corregido)
                        if (data.ingresos > 0 || data.gastos > 0)
                          Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          // Corrección del error "const Container"
                          Container(
                            height: 200,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart, size: 50, color: Colors.grey),
                                SizedBox(height: 10),
                                Text(
                                  "Aún no hay suficientes datos para generar el gráfico",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          
                        const SizedBox(height: 40), // Espacio final
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