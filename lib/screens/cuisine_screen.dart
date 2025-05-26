import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_bite/data/api/api_service.dart';
import 'package:one_bite/data/models/dish.dart';
import 'package:one_bite/data/models/cuisine.dart';
import 'package:one_bite/widgets/dish_tile.dart';

class CuisineScreen extends ConsumerStatefulWidget {
  final Cuisine? cuisine;
  final String? cuisineNameFilter;

  const CuisineScreen({super.key, this.cuisine, this.cuisineNameFilter});

  @override
  ConsumerState<CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends ConsumerState<CuisineScreen> {
  late Future<List<Dish>> _dishesFuture;

  @override
  void initState() {
    super.initState();
    if (widget.cuisineNameFilter != null) {
      // Fetch filtered dishes dynamically
      _dishesFuture = ApiService().fetchItemsByFilter(
        cuisineTypes: [widget.cuisineNameFilter!],
      );
    } else if (widget.cuisine != null) {
      // Use dishes from passed cuisine
      _dishesFuture = Future.value(widget.cuisine!.items);
    } else {
      _dishesFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cuisine?.cuisineName ?? widget.cuisineNameFilter ?? 'Cuisine'),
      ),
      body: FutureBuilder<List<Dish>>(
        future: _dishesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final dishes = snapshot.data ?? [];
          if (dishes.isEmpty) {
            return const Center(child: Text('No dishes available.'));
          }
          return ListView.builder(
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final dish = dishes[index];
              return DishTile(dish: dish);
            },
          );
        },
      ),
    );
  }
}
