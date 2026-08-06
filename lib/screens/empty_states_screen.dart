import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/kitchen_header.dart';
import 'import_recipe_screen.dart';
import 'library_screen.dart';
import 'shopping_list_screen.dart';

class EmptyStatesScreen extends StatelessWidget {
  const EmptyStatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ImportRecipeScreen()),
          );
        },
        backgroundColor: AppColors.terracotta,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          children: [
            KitchenHeader(showBack: Navigator.of(context).canPop()),
            const SizedBox(height: 8),
            Text(
              'Empty States',
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reference patterns for quiet moments in the kitchen.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            _EmptyCard(
              number: '1',
              image:
                  'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800&q=80',
              title: 'Your library is empty',
              body:
                  "It looks like you haven't saved any recipes yet. Start building your personal cookbook by exploring our curated collections.",
              primaryLabel: 'Explore Recipes',
              primaryIcon: Icons.arrow_forward,
              onPrimary: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LibraryScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _EmptyCard(
              number: '2',
              image:
                  'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80',
              title: 'Nothing to buy yet',
              body:
                  'Your grocery list is clear. Add ingredients directly from your favorite recipes or manually enter items for your next run.',
              outlined: true,
              primaryLabel: '+ Add Items',
              onPrimary: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ShoppingListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _EmptyCard(
              number: '3',
              image:
                  'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&q=80',
              title: 'Save recipes from social',
              body:
                  'Paste a link from Instagram, TikTok, or YouTube, and our AI will instantly convert it into a structured recipe for your collection.',
              primaryLabel: 'Import First Recipe',
              onPrimary: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ImportRecipeScreen(),
                  ),
                );
              },
              secondaryLabel: 'How it works',
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.number,
    required this.image,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon,
    this.outlined = false,
    this.secondaryLabel,
  });

  final String number;
  final String image;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final IconData? primaryIcon;
  final bool outlined;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  image,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(height: 140, color: AppColors.searchFill),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: outlined
                    ? OutlinedButton(
                        onPressed: onPrimary,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.terracotta,
                          side: const BorderSide(color: AppColors.terracotta),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          primaryLabel,
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: onPrimary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              primaryLabel,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (primaryIcon != null) ...[
                              const SizedBox(width: 6),
                              Icon(primaryIcon, size: 18),
                            ],
                          ],
                        ),
                      ),
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(secondaryLabel!),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: -8,
          left: 12,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.terracotta,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
