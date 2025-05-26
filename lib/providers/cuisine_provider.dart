import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cuisine.dart';
import '../data/api/api_service.dart';

final cuisineProvider = FutureProvider<List<Cuisine>>((ref) async {
  final api = ApiService();
  return await api.fetchCuisineList();
});
