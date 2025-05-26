// lib/providers/loading_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isRetryingProvider = StateProvider<bool>((ref) => false);
