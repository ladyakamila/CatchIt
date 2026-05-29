import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart'; // 1. Jalurnya sudah diperbaiki ke dalam folder core/theme

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Namanya disesuaikan dengan provider baru: themeProvider
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'CatchIt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // 3. Kita arahkan darkTheme ke bawaan Flutter dulu, atau jika temanmu punya AppTheme.darkTheme silakan diganti nanti
      darkTheme: ThemeData.dark(), 
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}