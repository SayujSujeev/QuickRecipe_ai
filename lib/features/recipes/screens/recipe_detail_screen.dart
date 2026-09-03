import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/recipes.dart';
import '../../../data/models/meal_recipe.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/adjust_servings_sheet.dart';
import 'cooking_step_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    this.recipe = harvestBowl,
    this.mealRecipe,
  });

  final Recipe recipe;

  /// When set, the screen renders real data imported from TheMealDB
  /// instead of the [recipe] mock.
  final MealRecipe? mealRecipe;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _servings = 2;
  int _tab = 0;
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final meal = widget.mealRecipe;
    final title = meal?.title ?? widget.recipe.title;
    final imageUrl = meal?.imageUrl ?? widget.recipe.imageUrl;
    final ingredientItems = meal != null
        ? meal.ingredients.map((i) => (i.name, i.measure)).toList()
        : harvestIngredients.map((i) => (i.name, i.amount)).toList();
    final stepItems = meal != null
        ? meal.instructionSteps
        : cookingSteps.map((s) => s.instruction).toList();

    const overlap = 28.0;
    final heroHeight = 300.0 + top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              clipBehavior: Clip.none,
              slivers: [
                // Hero image + overlapping title card in ONE sliver so
                // the card is not clipped by the scroll viewport.
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(
                        height: heroHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: AppColors.searchFill),
                            ),
                            Positioned(
                              top: top + 8,
                              left: 16,
                              child: _RoundIconButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                            ),
                            Positioned(
                              top: top + 8,
                              right: 16,
                              child: _RoundIconButton(
                                icon: Icons.favorite_border_rounded,
                                iconColor: AppColors.terracotta,
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -overlap),
                        child: Padding(
                          // Keep layout height correct after the visual lift.
                          padding: const EdgeInsets.only(bottom: overlap),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: meal != null
                                      ? [
                                          if (meal.category != null)
                                            _InfoBadge(
                                              icon: Icons.restaurant,
                                              label: meal.category!,
                                              background: AppColors.badgePeach,
                                              foreground: AppColors.terracotta,
                                            ),
                                          if (meal.area != null) ...[
                                            const SizedBox(width: 8),
                                            _InfoBadge(
                                              icon: Icons.public,
                                              label: meal.area!,
                                              background: AppColors.badgeGreen,
                                              foreground: AppColors.protein,
                                            ),
                                          ],
                                        ]
                                      : [
                                          _InfoBadge(
                                            icon: Icons.schedule,
                                            label:
                                                '${widget.recipe.mins ?? 25} mins',
                                            background: AppColors.badgeGreen,
                                            foreground: AppColors.protein,
                                          ),
                                          const SizedBox(width: 8),
                                          _InfoBadge(
                                            icon: Icons.restaurant,
                                            label:
                                                widget.recipe.difficulty ??
                                                'Easy',
                                            background: AppColors.badgePeach,
                                            foreground: AppColors.terracotta,
                                          ),
                                        ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  title,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFECE7E1),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Text(
                                      'Serves: $_servings',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.chipInactive,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          _ServeButton(
                                            icon: Icons.remove,
                                            onTap: () {
                                              if (_servings > 1) {
                                                setState(() => _servings--);
                                              }
                                            },
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: GestureDetector(
                                              onTap: () async {
                                                final result =
                                                    await showAdjustServingsSheet(
                                                      context,
                                                      initialServings:
                                                          _servings,
                                                    );
                                                if (result != null && mounted) {
                                                  setState(
                                                    () => _servings = result,
                                                  );
                                                }
                                              },
                                              child: Text(
                                                '$_servings',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          _ServeButton(
                                            icon: Icons.add,
                                            onTap: () =>
                                                setState(() => _servings++),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: Row(
                      children: [
                        _TabLabel(
                          label: 'Ingredients',
                          selected: _tab == 0,
                          onTap: () => setState(() => _tab = 0),
                        ),
                        const SizedBox(width: 24),
                        _TabLabel(
                          label: 'Steps',
                          selected: _tab == 1,
                          onTap: () => setState(() => _tab = 1),
                        ),
                        const SizedBox(width: 24),
                        _TabLabel(
                          label: 'Nutrition',
                          selected: _tab == 2,
                          onTap: () => setState(() => _tab = 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(height: 1, color: Color(0xFFECE7E1)),
                  ),
                ),
                if (_tab == 0)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = ingredientItems[index];
                        final checked = _checked.contains(index);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (checked) {
                                _checked.remove(index);
                              } else {
                                _checked.add(index);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                Icon(
                                  checked
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 22,
                                  color: checked
                                      ? AppColors.terracotta
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item.$1,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                      decoration: checked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                Text(
                                  item.$2,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: ingredientItems.length),
                    ),
                  )
                else if (_tab == 1)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final step = stepItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.terracotta,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  step,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    height: 1.4,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }, childCount: stepItems.length),
                    ),
                  )
                else if (meal != null && meal.nutrition != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        children: [
                          Text(
                            'Total for $_servings serving${_servings == 1 ? '' : 's'} you selected above',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _NutritionRow(
                            label: 'Calories',
                            value:
                                '${meal.nutrition!.kcalPerServing * _servings} kcal',
                          ),
                          _NutritionRow(
                            label: 'Protein',
                            value:
                                '${meal.nutrition!.proteinGPerServing * _servings} g',
                          ),
                          _NutritionRow(
                            label: 'Carbs',
                            value:
                                '${meal.nutrition!.carbsGPerServing * _servings} g',
                          ),
                          _NutritionRow(
                            label: 'Fat',
                            value:
                                '${meal.nutrition!.fatsGPerServing * _servings} g',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Estimated by AI — treat as approximate.',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (meal != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Nutrition hasn't been calculated for this recipe yet.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        children: [
                          _NutritionRow(label: 'Calories', value: '420 kcal'),
                          _NutritionRow(label: 'Protein', value: '18 g'),
                          _NutritionRow(label: 'Carbs', value: '48 g'),
                          _NutritionRow(label: 'Fat', value: '16 g'),
                          _NutritionRow(label: 'Fiber', value: '12 g'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
            decoration: const BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.terracotta,
                      side: const BorderSide(
                        color: AppColors.terracotta,
                        width: 1.4,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Add to Shopping List',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CookingStepScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Start Cooking',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServeButton extends StatelessWidget {
  const _ServeButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.terracotta : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 2.5,
            width: label.length * 8.0,
            decoration: BoxDecoration(
              color: selected ? AppColors.terracotta : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
