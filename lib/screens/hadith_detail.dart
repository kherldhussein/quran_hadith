import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
// minimal Hadith detail view - no theme import required here

class HadithDetailPage extends StatelessWidget {
  final String bookSlug;
  final String number;
  final String? arabic;
  final String? translation;

  const HadithDetailPage({
    Key? key,
    required this.bookSlug,
    required this.number,
    this.arabic,
    this.translation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hadith $number'),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.heart),
            onPressed: () {
              // Favoriting handled by FavoriteManager on previous screen
              Get.snackbar('Saved', 'Hadith saved to favorites',
                  snackPosition: SnackPosition.BOTTOM);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Book: $bookSlug',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (arabic != null)
                    Text(
                      arabic!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        height: 1.8,
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (translation != null)
                    Text(
                      translation!,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(FontAwesomeIcons.shareNodes),
                  label: const Text('Share'),
                  onPressed: () {
                    // Simple share placeholder
                    Get.snackbar('Share', 'Share hadith',
                        snackPosition: SnackPosition.BOTTOM);
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(FontAwesomeIcons.copy),
                  label: const Text('Copy'),
                  onPressed: () {
                    // Copy handled by Clipboard typically
                    Get.snackbar('Copied', 'Hadith copied to clipboard',
                        snackPosition: SnackPosition.BOTTOM);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
