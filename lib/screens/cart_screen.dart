import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_bite/data/api/api_service.dart';
import 'package:one_bite/providers/cart_provider.dart';
import 'package:one_bite/providers/language_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isProcessing = false;

  Future<void> _makePayment(BuildContext context) async {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartMap = ref.read(cartProvider);
    final locale = ref.read(languageProvider);
    final isHindi = locale.languageCode == 'hi';

    setState(() => _isProcessing = true);

    final items = cartMap.values.map((item) {
      return {
        'cuisine_id': item.dish.cuisineId,
        'item_id': item.dish.id,
        'item_price': item.dish.price,
        'item_quantity': item.quantity,
      };
    }).toList();

    final totalAmount = cartNotifier.grandTotal;
    final totalItems = cartMap.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final totalAmountStr = totalAmount.toStringAsFixed(2);

    try {
      final result = await ApiService.makePayment(
        totalAmount: totalAmount,
        totalItems: totalItems,
        items: items,
      );

      final code = result['response_code'] as int? ?? -1;
      final outcome = result['outcome_code'] as int? ?? -1;
      final txnRef = result['txn_ref_no'] as String? ?? 'N/A';
      final msg = result['response_message'] as String? ?? '';

      if (code == 200 && outcome == 200) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(isHindi ? 'ऑर्डर सफल' : 'Order Placed'),
            content: Text(
              isHindi
                  ? 'आपका ऑर्डर सफलतापूर्वक किया गया है।\nऑर्डर आईडी: $txnRef'
                  : 'Your order was placed successfully.\nOrder ID: $txnRef',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isHindi ? 'बंद करें' : 'Close'),
              ),
            ],
          ),
        );

        cartNotifier.clear();
        Navigator.pop(context);
      } else {
        throw Exception(msg.isNotEmpty ? msg : 'Unknown error');
      }
    } catch (e, st) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isHindi ? 'ऑर्डर विफल रहा!' : 'Order failed!')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final locale = ref.watch(languageProvider);
    final isHindi = locale.languageCode == 'hi';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectorBg = isDark ? Colors.grey[900]! : Colors.orange.shade50;
    final selectorBorder = Colors.orange;
    final iconColor = Colors.orange;
    final textColor = isDark ? Colors.white : Colors.black;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(isHindi ? 'कार्ट' : 'Cart')),
        body: Center(
          child: Text(
            isHindi ? 'आपका कार्ट खाली है' : 'Your cart is empty',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final netTotal = cartNotifier.netTotal;
    final cgst = cartNotifier.cgst;
    final sgst = cartNotifier.sgst;
    final grandTotal = cartNotifier.grandTotal;

    return Scaffold(
      appBar: AppBar(title: Text(isHindi ? 'कार्ट' : 'Cart')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: cart.values.map((item) {
                return Dismissible(
                  key: ValueKey(item.dish.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    cartNotifier.removeItem(item.dish.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isHindi
                              ? 'आइटम हटा दिया गया'
                              : 'Item removed from cart',
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: Image.network(item.dish.imageUrl, width: 50),
                    title: Text(
                      item.dish.name,
                      style: TextStyle(color: textColor),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.quantity} x ₹${item.dish.price.toStringAsFixed(2)}',
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 6),
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
                                icon: Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: iconColor,
                                ),
                                onPressed: () {
                                  if (item.quantity > 1) {
                                    cartNotifier.updateQuantity(
                                      item.dish.id,
                                      item.quantity - 1,
                                    );
                                  } else {
                                    cartNotifier.removeItem(item.dish.id);
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add,
                                  size: 18,
                                  color: iconColor,
                                ),
                                onPressed: () {
                                  cartNotifier.addItem(item.dish);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${isHindi ? 'कुल' : 'Subtotal'}: ₹${netTotal.toStringAsFixed(2)}',
                  style: TextStyle(color: textColor),
                ),
                Text(
                  'CGST (2.5%): ₹${cgst.toStringAsFixed(2)}',
                  style: TextStyle(color: textColor),
                ),
                Text(
                  'SGST (2.5%): ₹${sgst.toStringAsFixed(2)}',
                  style: TextStyle(color: textColor),
                ),
                const Divider(),
                Text(
                  '${isHindi ? 'कुल योग' : 'Total'}: ₹${grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () => _makePayment(context),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isHindi ? 'ऑर्डर करें' : 'Place Order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
