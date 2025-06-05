// lib/widgets/dish_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_bite/data/models/dish.dart';
import 'package:one_bite/providers/cart_provider.dart';
import 'package:one_bite/providers/favorite_provider.dart';
import 'package:one_bite/providers/language_provider.dart';

class DishTile extends ConsumerWidget {
  final Dish dish;

  const DishTile({super.key, required this.dish});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartItem = cart[dish.id];
    final count = cartItem?.quantity ?? 0;

    final favs = ref.watch(favoritesProvider);
    final favNotifier = ref.read(favoritesProvider.notifier);
    final isFav = favs.contains(dish.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors for light/dark mode
    final addButtonBg = Colors.orange;
    final addButtonFg = isDark ? Colors.black : Colors.white;
    final selectorBg = isDark ? Colors.grey[900]! : Colors.orange.shade50;
    final selectorBorder = Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Image.network(dish.imageUrl, width: 60, fit: BoxFit.cover),
        title: Text(dish.name),
        subtitle: Text(
          '₹${dish.price.toStringAsFixed(2)}  •  ⭐ ${dish.rating}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : null,
              ),
              onPressed: () => favNotifier.toggle(dish.id),
            ),
            if (count == 0)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: addButtonBg,
                  foregroundColor: addButtonFg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => cartNotifier.addItem(dish),
                child: Text(
                  ref.watch(languageProvider).languageCode == 'hi'
                      ? 'जोड़ें'
                      : 'Add',
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: selectorBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selectorBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, size: 18, color: addButtonBg),
                      onPressed: () {
                        if (count > 1) {
                          cartNotifier.updateQuantity(dish.id, count - 1);
                        } else {
                          cartNotifier.removeItem(dish.id);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, size: 18, color: addButtonBg),
                      onPressed: () => cartNotifier.addItem(dish),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
