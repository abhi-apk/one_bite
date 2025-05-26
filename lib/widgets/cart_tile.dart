import 'package:flutter/material.dart';
import 'package:one_bite/providers/cart_provider.dart';

class CartTile extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onRemove;

  const CartTile({super.key, required this.cartItem, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(cartItem.dish.imageUrl, width: 50),
      title: Text(cartItem.dish.name),
      subtitle: Text('${cartItem.quantity} x ₹${cartItem.dish.price.toStringAsFixed(2)}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onRemove,
      ),
    );
  }
}
