import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // Claro por defecto; el usuario puede cambiar a oscuro desde el menú.
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Por defecto no tenemos acceso al MediaQuery aquí,
      // así que system se evalúa en MaterialApp.
      return false;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
