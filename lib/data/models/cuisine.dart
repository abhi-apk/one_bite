import 'package:one_bite/data/models/dish.dart';

class Cuisine {
  final String cuisineId;
  final String cuisineName;
  final String cuisineImageUrl;
  final List<Dish> items;

  Cuisine({
    required this.cuisineId,
    required this.cuisineName,
    required this.cuisineImageUrl,
    required this.items,
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) {
    final cuisineId = json['cuisine_id'].toString();
    return Cuisine(
      cuisineId: cuisineId,
      cuisineName: json['cuisine_name'],
      cuisineImageUrl: json['cuisine_image_url'],
      items: (json['items'] as List)
          .map((e) => Dish.fromJson({...e, 'cuisine_id': cuisineId}))
          .toList(),
    );
  }

}
