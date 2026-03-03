import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final LocalStorageService _localStorage;

  ThemeCubit(this._localStorage) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    final themeIndex = _localStorage.getThemeMode();
    emit(ThemeMode.values[themeIndex]);
  }

  void setTheme(ThemeMode themeMode) {
    _localStorage.saveThemeMode(themeMode.index);
    emit(themeMode);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setTheme(ThemeMode.light);
    } else {
      setTheme(ThemeMode.dark);
    }
  }

  void setSystemTheme() {
    setTheme(ThemeMode.system);
  }
}
