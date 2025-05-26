import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A StateProvider to hold the current Locale (language setting)
final languageProvider = StateProvider<Locale>((ref) => const Locale('en'));

/// Toggle between English and Hindi
void toggleLanguage(WidgetRef ref) {
  final currentLocale = ref.read(languageProvider);
  final newLocale = currentLocale.languageCode == 'en'
      ? const Locale('hi')
      : const Locale('en');
  ref.read(languageProvider.notifier).state = newLocale;
}
