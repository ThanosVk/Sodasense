import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;

  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return themeMode == ThemeMode.dark;
    }
  }

  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyThemes {
  static final darkTheme = ThemeData(
      scaffoldBackgroundColor: Colors.grey.shade900,
      colorScheme: ColorScheme.dark(primary: Colors.cyan),
      appBarTheme: AppBarTheme(
          backgroundColor: Colors.cyan,
          iconTheme: IconThemeData(color: Colors.black),
          foregroundColor: Colors.black),
      cardTheme: CardTheme(color: Colors.grey.shade900),
      listTileTheme: ListTileThemeData(iconColor: Colors.white));

  static final lightTheme = ThemeData(
      primarySwatch: Colors.cyan,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
          backgroundColor: Colors.cyan,
          iconTheme: IconThemeData(color: Colors.black),
          foregroundColor: Colors.black),
      primaryColor: Colors.cyan,
      // iconTheme: IconThemeData(color: Colors.black),
      listTileTheme: ListTileThemeData(iconColor: Colors.black));
}
