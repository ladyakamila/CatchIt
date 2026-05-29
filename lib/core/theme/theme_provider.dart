import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Ini adalah generator provider versi Riverpod terbaru
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.system; // Tema default awal mengikuti sistem HP
  }

  // Fungsi untuk mengubah tema ke Light, Dark, atau System
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

// Ini provider yang akan dipanggil di app.dart nanti
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});