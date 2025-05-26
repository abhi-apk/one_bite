// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current ThemeMode (light/dark/system).
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

void toggleTheme(WidgetRef ref) {
  final mode = ref.read(themeModeProvider);
  ref.read(themeModeProvider.notifier).state =
  (mode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
}
