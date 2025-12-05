import 'package:flutter/material.dart';

class AppTheme {
  // Colores extraídos de style.css
  static const Color primary = Color(0xFFBF2642); // Rojo principal
  static const Color primaryDark = Color(0xFFA62139); // Rojo oscuro (hover)
  static const Color accent = Color(0xFFF2A81D); // Amarillo/Naranja acento

  // Colores de estado (KPI cards)
  static const Color kpiBlue = Color(0xff0dcaf0); // Cyan
  static const Color kpiGreen = Color(0xFF28A745); // Verde éxito
  static const Color kpiOrange = Color(0xFFFD7E14); // Naranja alerta

  // Tema Global de la App
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        prefixIconColor: primary,
        labelStyle: const TextStyle(color: Colors.black87),
      ),
    );
  }
}
