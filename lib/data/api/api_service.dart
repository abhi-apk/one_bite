import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:one_bite/data/models/dish.dart';
import 'package:one_bite/data/models/cuisine.dart';
import 'api_constants.dart';

class ApiService {
  Future<List<Cuisine>> fetchCuisineList({int page = 1, int count = 10}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/emulator/interview/get_item_list');

    try {
      final response = await http
          .post(
        url,
        headers: {
          ...ApiConstants.baseHeaders,
          'X-Forward-Proxy-Action': 'get_item_list',
        },
        body: jsonEncode({
          'page': page,
          'count': count,
        }),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['cuisines'] is List) {
          return (decoded['cuisines'] as List)
              .map((c) => Cuisine.fromJson(c))
              .toList();
        } else {
          throw Exception('Invalid data format: cuisines not a list');
        }
      } else {
        throw Exception('Failed to fetch cuisines: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Dish>> fetchItemsByFilter({
    List<String>? cuisineTypes,
    int? minPrice,
    int? maxPrice,
    double? minRating,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/emulator/interview/get_item_by_filter');
    final body = <String, dynamic>{};
    if (cuisineTypes != null) body['cuisine_type'] = cuisineTypes;
    if (minPrice != null && maxPrice != null) {
      body['price_range'] = {
        'min_amount': minPrice,
        'max_amount': maxPrice,
      };
    }
    if (minRating != null) body['min_rating'] = minRating;

    final resp = await http.post(url,
      headers: {...ApiConstants.baseHeaders, 'X-Forward-Proxy-Action':'get_item_by_filter'},
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch filtered dishes: ${resp.statusCode}');
    }

    final decoded = jsonDecode(resp.body);
    final minimalCuisines = decoded['cuisines'] as List;

    // 1) build a flat list of minimal dishes
    final minimalDishes = minimalCuisines.expand((c) {
      final cid = c['cuisine_id'].toString();
      return (c['items'] as List).map((i) {
        final map = Map<String,dynamic>.from(i);
        map['cuisine_id'] = cid;
        return map;
      });
    }).toList();

    // 2) enrich each one by fetching full details (price/rating)
    final enriched = await Future.wait(minimalDishes.map((m) async {
      final idInt = int.parse(m['id'].toString());
      final full = await fetchItemById(idInt);
      // put cuisineId back on full Dish:
      return Dish(
        id: full.id,
        name: full.name,
        imageUrl: full.imageUrl,
        price: full.price,
        rating: full.rating,
        cuisineId: m['cuisine_id'].toString(),
      );
    }));

    // 3) (optional) filter again by rating if needed client-side:
    final postFiltered = enriched.where((d) {
      return (minRating == null || d.rating >= minRating) &&
          (minPrice == null || d.price >= minPrice) &&
          (maxPrice == null || d.price <= maxPrice);
    }).toList();

    // 4) Finally limit the list to, say, 50 items max:
    return postFiltered.take(50).toList();
  }


  Future<Dish> fetchItemById(int itemId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/emulator/interview/get_item_by_id');
    final response = await http.post(
      url,
      headers: {
        ...ApiConstants.baseHeaders,
        'X-Forward-Proxy-Action': 'get_item_by_id',
      },
      body: jsonEncode({'item_id': itemId}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return Dish.fromJson({
        'id': decoded['item_id'],
        'name': decoded['item_name'],
        'price': decoded['item_price'],
        'rating': decoded['item_rating'],
        'image_url': decoded['item_image_url'],
      });
    } else {
      throw Exception('Failed to fetch item with ID $itemId');
    }
  }

  static Future<Map<String, dynamic>> makePayment({
    required double totalAmount,
    required int totalItems,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/emulator/interview/make_payment');

    final totalAmountStr = totalAmount.toStringAsFixed(2);
    final data = items.map((item) {
      final price = item['item_price'] as double;
      final priceStr = (price % 1 == 0)
          ? price.toInt().toString()
          : price.toStringAsFixed(2);
      return {
        'cuisine_id': item['cuisine_id'],
        'item_id': item['item_id'],
        'item_price': priceStr,
        'item_quantity': item['item_quantity'],
      };
    }).toList();

    final payload = {
      "total_amount": totalAmountStr,
      "total_items": totalItems,
      "data": data,
    };

    final response = await http
        .post(
      url,
      headers: {
        ...ApiConstants.baseHeaders,
        'X-Forward-Proxy-Action': 'make_payment',
      },
      body: jsonEncode(payload),
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Payment failed: HTTP ${response.statusCode}');
    }
  }
}
