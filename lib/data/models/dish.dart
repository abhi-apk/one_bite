class Dish {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double rating;
  final String cuisineId;

  Dish({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.cuisineId,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'].toString(),
      name: json['name'],
      imageUrl: json['image_url'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      cuisineId: json['cuisine_id'].toString(), // ✅ NEW
    );
  }
}
