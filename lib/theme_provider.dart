import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/enums/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  AppTheme _appTheme;

  ThemeProvider(this._appTheme);

  AppTheme get appTheme => _appTheme;

  Future<void> setAppTheme(AppTheme theme) async {
    _appTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appTheme', theme.index);
  }

  static Color getThemeColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.deepPurple:
        return Colors.deepPurple;
      case AppTheme.teal:
        return Colors.teal;
      case AppTheme.indigo:
        return Colors.indigo;
      case AppTheme.orange:
        return Colors.orange;
    }
  }
}
