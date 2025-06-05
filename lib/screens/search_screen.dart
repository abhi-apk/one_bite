import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_bite/data/api/api_service.dart';
import 'package:one_bite/data/models/dish.dart';
import 'package:one_bite/providers/cuisine_provider.dart';
import 'package:one_bite/providers/language_provider.dart';
import 'package:one_bite/providers/theme_provider.dart';
import 'package:one_bite/widgets/dish_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final ApiService _apiService = ApiService();

  final Set<String> selectedCuisines = {};
  double minPrice = 0;
  double maxPrice = 1000;
  int minRating = 3;

  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  bool isLoading = false;
  List<Dish> searchResults = [];

  final TextEditingController minPriceController = TextEditingController(
    text: '0',
  );
  final TextEditingController maxPriceController = TextEditingController(
    text: '1000',
  );

  @override
  void dispose() {
    searchController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      isLoading = true;
      searchResults = [];
    });

    try {
      final results = await _apiService.fetchItemsByFilter(
        cuisineTypes: selectedCuisines.isEmpty
            ? null
            : selectedCuisines.toList(),
        minPrice: minPrice.toInt(),
        maxPrice: maxPrice.toInt(),
        minRating: minRating.toDouble(),
      );

      var limited = results.take(50);
      // then filter by name query, if any
      if (searchQuery.isNotEmpty) {
        limited = limited.where(
          (d) => d.name.toLowerCase().contains(searchQuery),
        );
      }

      setState(() {
        searchResults = limited.toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuisinesAsync = ref.watch(cuisineProvider);

    return cuisinesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading cuisines')),
      data: (cuisines) {
        // use the live list of cuisine names
        final allCuisines = cuisines.map((c) => c.cuisineName).toList();

        final locale = ref.watch(languageProvider);
        final mode = ref.watch(themeModeProvider);
        final platformBrightness = MediaQuery.of(context).platformBrightness;
        final isDark =
            mode == ThemeMode.dark ||
            (mode == ThemeMode.system && platformBrightness == Brightness.dark);

        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                locale.languageCode == 'en' ? 'Search Dishes' : 'डिश खोजें',
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: locale.languageCode == 'en'
                              ? 'Search by name'
                              : 'नाम से खोजें',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(
                          () => searchQuery = v.trim().toLowerCase(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: allCuisines.map((cuisine) {
                          final selected = selectedCuisines.contains(cuisine);
                          return FilterChip(
                            label: Text(cuisine),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  selectedCuisines.add(cuisine);
                                } else {
                                  selectedCuisines.remove(cuisine);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Flexible(
                            child: TextField(
                              controller: minPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: locale.languageCode == 'en'
                                    ? 'Min Price'
                                    : 'न्यूनतम मूल्य',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null &&
                                    parsed >= 0 &&
                                    parsed <= maxPrice) {
                                  setState(() {
                                    minPrice = parsed;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: TextField(
                              controller: maxPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: locale.languageCode == 'en'
                                    ? 'Max Price'
                                    : 'अधिकतम मूल्य',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null && parsed >= minPrice) {
                                  setState(() {
                                    maxPrice = parsed;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [3, 4, 5].map((rating) {
                          return Expanded(
                            child: RadioListTile<int>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                locale.languageCode == 'en'
                                    ? '$rating stars & above'
                                    : '$rating सितारे और ऊपर',
                              ),
                              value: rating,
                              groupValue: minRating,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    minRating = val;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _performSearch,
                          child: Text(
                            locale.languageCode == 'en' ? 'Search' : 'खोजें',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Expanded(
                  child: searchResults.isEmpty
                      ? Center(
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : const Text('No results'),
                        )
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final dish = searchResults[index];
                            return DishTile(dish: dish);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
