import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema visual: lienzo claro, bordes finos en lugar de sombras,
/// tipografía monocroma y un único acento (azul del logo V&G).
class AppTheme {
  // --- Marca (logo V&G) ---
  static const Color primary = Color(0xFF335BA6); // Azul rey: acento único (links, activos, iconos)
  static const Color primaryDark = Color(0xFF232B55); // Azul marino: relleno del botón principal
  static const Color accent = Color(0xFFF7B52C); // Amarillo sol
  static const Color navy = primaryDark;
  static const Color royalBlue = primary;
  static const Color brandRed = Color(0xFFD9341F); // Rojo del logo
  static const Color turquoise = Color(0xFF2EB5C3);
  static const Color pink = Color(0xFFF08FAE);

  // --- Neutros ---
  static const Color canvas = Color(0xFFFFFFFF); // Fondo de tarjetas y superficies
  static const Color paper = Color(0xFFFAFAFA); // Fondo de página
  static const Color paperMist = Color(0xFFF5F5F5); // Paneles anidados, hover
  static const Color ash = Color(0xFFE5E5E5); // Borde estructural 1px
  static const Color smoke = Color(0xFFD4D4D4); // Borde enfatizado
  static const Color pebble = Color(0xFFC8C8C8); // Borde de controles
  static const Color charcoal = Color(0xFF171717); // Texto principal
  static const Color slate = Color(0xFF404040); // Texto terciario
  static const Color steel = Color(0xFF525252); // Texto secundario, iconos
  static const Color fog = Color(0xFF737373); // Texto atenuado, placeholders
  static const Color silver = Color(0xFFA3A3A3); // Deshabilitado

  // --- Tintes suaves (solo fondos pequeños: badges, ítems activos) ---
  static const Color blueTint = Color(0xFFE8EEF8);
  static const Color mintTint = Color(0xFFDCFCE7);
  static const Color amberTint = Color(0xFFFEF3C7);
  static const Color redTint = Color(0xFFFDE8E5);

  // --- Superficies del tema oscuro (azul marino del logo) ---
  static const Color navyBackground = Color(0xFF141933);
  static const Color navySurface = Color(0xFF1E2547);
  static const Color navyInput = Color(0xFF29315A);
  static const Color navyBorder = Color(0xFF323B66);

  // --- Colores de estado (KPI cards) ---
  static const Color kpiBlue = Color(0xFF138A98); // Turquesa legible sobre blanco
  static const Color kpiGreen = Color(0xFF16A34A); // Verde éxito
  static const Color kpiOrange = Color(0xFFEA580C); // Naranja alerta

  // --- Radios ---
  static const double radiusInput = 6;
  static const double radiusButton = 8;
  static const double radiusCard = 12;
  static const double radiusLargeCard = 16;
  static const double radiusPill = 9999;

  // Sombra mínima: el sistema usa bordes, no elevación
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        )
      ];

  // Anillo de 4px para tarjetas destacadas (hover)
  static List<BoxShadow> get ringShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          spreadRadius: 4,
        )
      ];

  static TextTheme _textTheme(TextTheme base, Color text, Color muted) {
    final t = GoogleFonts.interTextTheme(base).apply(
      bodyColor: text,
      displayColor: text,
    );
    TextStyle? heading(TextStyle? s) =>
        s?.copyWith(fontWeight: FontWeight.w500, letterSpacing: -0.5, color: text);
    return t.copyWith(
      displayLarge: heading(t.displayLarge),
      displayMedium: heading(t.displayMedium),
      displaySmall: heading(t.displaySmall),
      headlineLarge: heading(t.headlineLarge),
      headlineMedium: heading(t.headlineMedium),
      headlineSmall: heading(t.headlineSmall),
      titleLarge: t.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3),
      titleMedium: t.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: t.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 14, height: 1.43),
      bodySmall: t.bodySmall?.copyWith(fontSize: 12, color: muted),
      labelLarge: t.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
      labelSmall: t.labelSmall?.copyWith(fontSize: 11, color: muted),
    );
  }

  // Tema Global de la App (claro por defecto)
  static ThemeData get lightTheme {
    final textTheme = _textTheme(ThemeData.light().textTheme, charcoal, fog);
    return ThemeData(
      useMaterial3: true,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        onPrimary: Colors.white,
        secondary: primaryDark,
        tertiary: turquoise,
        error: brandRed,
        surface: canvas,
        onSurface: charcoal,
        onSurfaceVariant: fog,
        outline: ash,
        outlineVariant: ash,
        surfaceContainerLowest: canvas,
        surfaceContainerLow: paper,
        surfaceContainer: paperMist,
        surfaceContainerHigh: paperMist,
        surfaceContainerHighest: paperMist,
      ),
      scaffoldBackgroundColor: paper,
      dividerTheme: const DividerThemeData(color: ash, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: charcoal,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: ash)),
        iconTheme: const IconThemeData(color: slate, size: 22),
        titleTextStyle: GoogleFonts.inter(
          color: charcoal,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(),
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: steel,
        textColor: charcoal,
        selectedColor: primary,
        selectedTileColor: blueTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
        titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: charcoal),
        subtitleTextStyle: GoogleFonts.inter(fontSize: 13, color: fog),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: canvas,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: ash),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: canvas,
          foregroundColor: charcoal,
          side: const BorderSide(color: ash),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: canvas,
        side: const BorderSide(color: ash),
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: charcoal),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLargeCard),
          side: const BorderSide(color: ash),
        ),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: charcoal),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLargeCard)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: ash),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: charcoal,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: charcoal,
        unselectedLabelColor: fog,
        indicatorColor: primary,
        dividerColor: ash,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : smoke,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: canvas,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: pebble),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: pebble),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primaryDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: brandRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: brandRed, width: 1.5),
        ),
        prefixIconColor: fog,
        suffixIconColor: fog,
        labelStyle: GoogleFonts.inter(color: steel, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: charcoal, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.inter(color: silver, fontSize: 14),
      ),
    );
  }

  // Tema Oscuro de la App
  static ThemeData get darkTheme {
    final textTheme = _textTheme(ThemeData.dark().textTheme, Colors.white, Colors.white60);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primary,
        primary: const Color(0xFF7FA2E0),
        onPrimary: navyBackground,
        secondary: turquoise,
        tertiary: accent,
        error: const Color(0xFFF07A69),
        surface: navySurface,
        outline: navyBorder,
        outlineVariant: navyBorder,
      ),
      scaffoldBackgroundColor: navyBackground,
      dividerTheme: const DividerThemeData(color: navyBorder, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: navySurface,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: navyBorder)),
        iconTheme: const IconThemeData(color: Colors.white70, size: 22),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: navySurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(),
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.white70,
        selectedColor: const Color(0xFF7FA2E0),
        selectedTileColor: const Color(0x297FA2E0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
        titleTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        subtitleTextStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: navySurface,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: navyBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: navyBorder),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: navySurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLargeCard),
          side: const BorderSide(color: navyBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusButton)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navyInput,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: navyBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: navyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: Color(0xFF7FA2E0), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: Color(0xFFF07A69)),
        ),
        prefixIconColor: Colors.white60,
        labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
      ),
    );
  }
}
