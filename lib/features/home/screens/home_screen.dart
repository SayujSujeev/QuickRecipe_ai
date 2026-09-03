import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/recipe_repository.dart';
import '../../../core/services/user_profile_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/nutrition_calculator.dart';
import '../../../core/widgets/daily_goal_card.dart';
import '../../../core/widgets/recipe_cards.dart';
import '../../../data/models/meal_recipe.dart';
import '../../recipes/screens/recipe_detail_screen.dart';
import '../../recipes/screens/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<DailyTargets?> _targets = _loadTargets();

  Future<DailyTargets?> _loadTargets() {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return Future.value(null);
    return UserProfileService.instance.fetchDailyTargets(uid);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<MealRecipe>>(
        stream: RecipeRepository.instance.watchRecipes(),
        builder: (context, snapshot) {
          final recipes = snapshot.data ?? const <MealRecipe>[];
          final loading = snapshot.connectionState == ConnectionState.waiting;

          final trending = recipes.take(8).toList();
          final proteinPicks =
              recipes.where((r) => r.nutrition != null).toList()..sort(
                (a, b) => b.nutrition!.proteinGPerServing.compareTo(
                  a.nutrition!.proteinGPerServing,
                ),
              );
          final recommended = recipes.skip(8).take(5).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: FutureBuilder<DailyTargets?>(
                  future: _targets,
                  builder: (context, snap) {
                    return DailyGoalCard(targets: snap.data);
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
              SliverToBoxAdapter(
                child: _sectionHeader(
                  context,
                  'Trending Recipes',
                  onSeeAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              if (!loading && trending.isEmpty)
                SliverToBoxAdapter(child: _emptyLibraryNotice(context))
              else
                SliverToBoxAdapter(child: _trendingList(context, trending)),
              if (proteinPicks.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                SliverToBoxAdapter(child: _proteinHeader()),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: _proteinList(context, proteinPicks.take(8).toList()),
                ),
              ],
              if (recommended.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'More to try',
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final recipe = recommended[index];
                      return RecommendedTile(
                        recipe: recipe,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipeDetailScreen(mealRecipe: recipe),
                            ),
                          );
                        },
                      );
                    }, childCount: recommended.length),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final rawName = user?.displayName?.trim();
    final name = (rawName != null && rawName.isNotEmpty)
        ? rawName.split(' ').first
        : (user?.email?.split('@').first ?? 'Chef');
    final photoUrl = user?.photoURL;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(
                  photoUrl ??
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Good morning, $name',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.terracotta,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _proteinHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hit your protein goal',
            style: GoogleFonts.fraunces(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your highest-protein imported recipes',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyLibraryNotice(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.progressTrack),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_download_outlined,
              size: 30,
              color: AppColors.terracotta,
            ),
            const SizedBox(height: 10),
            Text(
              'No recipes yet',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Head to Profile > Import Recipes to fill your feed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendingList(BuildContext context, List<MealRecipe> recipes) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: recipes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(mealRecipe: recipe),
                ),
              );
            },
            child: TrendingRecipeCard(recipe: recipe),
          );
        },
      ),
    );
  }

  Widget _proteinList(BuildContext context, List<MealRecipe> recipes) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: recipes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(mealRecipe: recipe),
                ),
              );
            },
            child: ProteinRecipeCard(recipe: recipe),
          );
        },
      ),
    );
  }
}
