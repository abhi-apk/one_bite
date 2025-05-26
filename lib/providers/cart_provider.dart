import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/dish.dart';

class CartItem {
  final Dish dish;
  final int quantity;
  CartItem({required this.dish, required this.quantity});

  CartItem copyWith({int? quantity}) =>
      CartItem(dish: dish, quantity: quantity ?? this.quantity);
}

class CartNotifier extends StateNotifier<Map<String, CartItem>> {
  CartNotifier() : super({});

  void addItem(Dish dish) {
    if (state.containsKey(dish.id)) {
      state = {
        ...state,
        dish.id: state[dish.id]!.copyWith(quantity: state[dish.id]!.quantity + 1),
      };
    } else {
      state = {...state, dish.id: CartItem(dish: dish, quantity: 1)};
    }
  }

  void removeItem(String id) {
    final newState = {...state};
    newState.remove(id);
    state = newState;
  }

  void updateQuantity(String id, int quantity) {
    if (state.containsKey(id)) {
      if (quantity > 0) {
        state = {
          ...state,
          id: state[id]!.copyWith(quantity: quantity),
        };
      } else {
        removeItem(id); // fallback if quantity goes to 0
      }
    }
  }


  void clear() {
    state = {};
  }

  double get netTotal => state.values.fold(
      0.0, (sum, item) => sum + item.dish.price * item.quantity);

  double get cgst => netTotal * 0.025;
  double get sgst => netTotal * 0.025;
  double get grandTotal => netTotal + cgst + sgst;
}

final cartProvider =
    StateNotifierProvider<CartNotifier, Map<String, CartItem>>((ref) {
  return CartNotifier();
});
