// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:one_bite/providers/cuisine_provider.dart';
import 'package:one_bite/providers/favorite_provider.dart';
import 'package:one_bite/providers/language_provider.dart';
import 'package:one_bite/providers/reload_provider.dart';
import 'package:one_bite/providers/theme_provider.dart';
import 'package:one_bite/screens/cart_screen.dart';
import 'package:one_bite/screens/cuisine_screen.dart';
import 'package:one_bite/screens/search_screen.dart';
import 'package:one_bite/widgets/cuisine_card.dart';
import 'package:one_bite/widgets/dish_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;
  static const int _initialPage = 10000;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.95,
      initialPage: _initialPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cuisinesAsync = ref.watch(cuisineProvider);
    final favIds = ref.watch(favoritesProvider);
    final locale = ref.watch(languageProvider);
    final mode = ref.watch(themeModeProvider);
    final platformBrightness = MediaQuery.of(context).platformBrightness;
    final isDark =
        mode == ThemeMode.dark ||
            (mode == ThemeMode.system && platformBrightness == Brightness.dark);

    void toggleTheme() => ref.read(themeModeProvider.notifier).state =
    isDark ? ThemeMode.light : ThemeMode.dark;
    void toggleLanguage() {
      final newLang = locale.languageCode == 'en' ? 'hi' : 'en';
      ref.read(languageProvider.notifier).state = Locale(newLang);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        title: Text(
          locale.languageCode == 'en' ? 'OneBite' : 'वन बाइट',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
            onPressed: toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.translate),
            color: isDark ? Colors.white : Colors.black,
            onPressed: toggleLanguage,
          ),
        ],
      ),
      body: cuisinesAsync.when(
        data: (cuisines) {
          final allDishes = cuisines.expand((c) => c.items).toList();
          final topDishes = [...allDishes]
            ..sort((a, b) => b.rating.compareTo(a.rating));
          final favDishes =
          allDishes.where((d) => favIds.contains(d.id)).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(cuisineProvider);
              await Future.delayed(const Duration(seconds: 2));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),


                  // Cuisine carousel
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: cuisines.length * 1000,
                      itemBuilder: (context, index) {
                        final cuisine =
                        cuisines[index % cuisines.length];
                        return CuisineCard(
                          cuisine: cuisine,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CuisineScreen(cuisine: cuisine),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Top Dishes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Top 3 dishes
                  ...topDishes.take(3).map((dish) => DishTile(dish: dish)),


                  // Favorites strip
                  if (favDishes.isNotEmpty) ...[
                    const Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(
                        'Favorites',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: favDishes.length,
                        itemBuilder: (ctx, i) {
                          final d = favDishes[i];
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // navigate to cuisine screen if desired
                                  },
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundImage:
                                    NetworkImage(d.imageUrl),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    d.name,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          final isRetrying = ref.watch(isRetryingProvider);
          if (isRetrying) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Please connect to the internet',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      ref
                          .read(isRetryingProvider.notifier)
                          .state = true;
                      await Future.delayed(const Duration(seconds: 10));
                      ref.invalidate(cuisineProvider);
                      ref.read(isRetryingProvider.notifier).state =
                      false;
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: FloatingActionButton(
              heroTag: 'search',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SearchScreen()),
                );
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.search),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'cart',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CartScreen()),
                );
              },
              child: const Icon(Icons.shopping_cart),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
    );
  }
}
