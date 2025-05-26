import 'package:flutter/material.dart';
import 'package:one_bite/data/models/cuisine.dart';

class CuisineCard extends StatelessWidget {
  final Cuisine cuisine;
  final VoidCallback onTap;

  const CuisineCard({super.key, required this.cuisine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                   Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        cuisine.cuisineImageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: Text(
                          cuisine.cuisineName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            //     Image.network(
            //       cuisine.cuisineImageUrl,
            //       fit: BoxFit.cover,
            //       width: double.infinity,
            //     ),
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Text(
            //     cuisine.cuisineName,
            //     style: const TextStyle(
            //       fontWeight: FontWeight.bold,
            //       fontSize: 20,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
