import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  double _taxRate = 0.19; // IVA por defecto
  double get taxRate => _taxRate;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _taxRate = prefs.getDouble('taxRate') ?? 0.19;
    notifyListeners();
  }

  Future<void> setTaxRate(double rate) async {
    _taxRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('taxRate', rate);
    notifyListeners();
  }
}
