import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  bool _isBusy = false;
  bool get isbusy => _isBusy;
  bool _isDark = false;
  bool get isDark => _isDark;

  AppState() {
    _loadTheme();
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
    _saveTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDark') ?? false;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
  }

  set isBusy(bool value) {
    if (value != _isBusy) {
      _isBusy = value;
      notifyListeners();
    }
  }

  int _pageIndex = 0;
  int get pageIndex {
    return _pageIndex;
  }

  set setPageIndex(int index) {
    _pageIndex = index;
    notifyListeners();
  }
}
