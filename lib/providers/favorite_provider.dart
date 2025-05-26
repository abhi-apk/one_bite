import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the set of favorited Dish IDs
class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(): super({});
  void toggle(String dishId) {
    final s = {...state};
    if (s.contains(dishId)) s.remove(dishId);
    else s.add(dishId);
    state = s;
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
        (ref) => FavoritesNotifier()
);
