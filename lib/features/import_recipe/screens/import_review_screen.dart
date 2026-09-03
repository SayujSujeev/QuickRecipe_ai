import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/recipe_import_error.dart';
import '../../../core/services/recipe_import_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/kitchen_app_bar.dart';
import '../../../core/widgets/recipe_planning_summary.dart';
import '../../../data/models/meal_recipe.dart';
import '../../../data/models/recipe_draft.dart';
import '../../../data/models/recipe_import_job.dart';
import '../../recipes/screens/recipe_detail_screen.dart';

const _lowConfidenceThreshold = 0.6;

/// Draft review/edit screen: the user corrects ingredients, quantities,
/// units, servings, times, temperatures, and steps before anything is
/// saved to their cookbook. Low-confidence and missing values are marked
/// so they're never mistaken for verified facts.
class ImportReviewScreen extends StatefulWidget {
  const ImportReviewScreen({
    super.key,
    required this.jobId,
    required this.draftId,
  });

  final String jobId;
  final String draftId;

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  bool _approving = false;

  Future<void> _editIngredient(DraftIngredient ingredient, int index) async {
    final nameController = TextEditingController(text: ingredient.name);
    final quantityController = TextEditingController(
      text: ingredient.quantity?.toString() ?? '',
    );
    final unitController = TextEditingController(text: ingredient.unit ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit ingredient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    final quantity = double.tryParse(quantityController.text.trim());
    await RecipeImportService.instance.updateDraft(widget.jobId, [
      MapEntry('ingredients[$index].name', nameController.text.trim()),
      MapEntry('ingredients[$index].quantity', quantity),
      MapEntry(
        'ingredients[$index].unit',
        unitController.text.trim().isEmpty ? null : unitController.text.trim(),
      ),
    ]);
  }

  Future<void> _editStep(DraftStep step, int index) async {
    final controller = TextEditingController(text: step.instruction);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit step ${step.order}'),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;

    await RecipeImportService.instance.updateDraft(widget.jobId, [
      MapEntry('steps[$index].instruction', controller.text.trim()),
    ]);
  }

  Future<void> _approve(RecipeDraft draft, String? thumbnailUrl) async {
    setState(() => _approving = true);
    try {
      final recipeId = await RecipeImportService.instance.approve(widget.jobId);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            mealRecipe: _toMealRecipe(recipeId, draft, thumbnailUrl),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(recipeImportErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KitchenAppBar(title: 'Review Recipe'),
      body: StreamBuilder<RecipeDraftDocument?>(
        stream: RecipeImportService.instance.watchDraft(widget.draftId),
        builder: (context, snapshot) {
          final doc = snapshot.data;
          if (doc == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final draft = doc.draft;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (doc.thumbnailUrl != null && doc.thumbnailUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    doc.thumbnailUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _ThumbnailUnavailable(),
                  ),
                ),
                const SizedBox(height: 18),
              ] else ...[
                const _ThumbnailUnavailable(),
                const SizedBox(height: 18),
              ],
              if (draft.status == 'needs_review')
                _Banner(
                  icon: Icons.info_outline,
                  text: 'A few details need your review before saving.',
                ),
              if (draft.missingInformation.isNotEmpty)
                _Banner(
                  icon: Icons.help_outline,
                  text: 'Missing: ${draft.missingInformation.join(', ')}',
                ),
              const SizedBox(height: 12),
              Text(
                draft.title ?? 'Untitled Recipe',
                style: GoogleFonts.fraunces(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (draft.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  draft.description!,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              RecipePlanningSummary(
                servings: draft.servings,
                times: draft.times,
              ),
              const SizedBox(height: 24),
              _SectionHeader('Ingredients'),
              ...draft.ingredients.asMap().entries.map(
                (entry) => _IngredientRow(
                  ingredient: entry.value,
                  onTap: () => _editIngredient(entry.value, entry.key),
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader('Steps'),
              ...draft.steps.asMap().entries.map(
                (entry) => _StepRow(
                  step: entry.value,
                  onTap: () => _editStep(entry.value, entry.key),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _approving
                      ? null
                      : () => _approve(draft, doc.thumbnailUrl),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(_approving ? 'Saving…' : 'Save to Cookbook'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

MealRecipe _toMealRecipe(
  String recipeId,
  RecipeDraft draft,
  String? thumbnailUrl,
) => MealRecipe(
  id: recipeId,
  title: draft.title ?? 'Untitled Recipe',
  imageUrl: thumbnailUrl ?? '',
  instructions: draft.steps.map((s) => s.instruction).join('\n'),
  ingredients: draft.ingredients
      .map((i) => RecipeIngredient(name: i.name, measure: i.displayAmount))
      .toList(),
  category: draft.courses.isNotEmpty ? draft.courses.first : null,
  area: draft.cuisines.isNotEmpty ? draft.cuisines.first : null,
  tags: [...draft.cuisines, ...draft.courses, ...draft.dietaryTags],
  servings: draft.servings,
  times: draft.times,
);

class _ThumbnailUnavailable extends StatelessWidget {
  const _ThumbnailUnavailable();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.searchFill,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      children: [
        Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'No preview image is available from this link.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.badgePeach,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.terracottaDark, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.terracottaDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient, required this.onTap});
  final DraftIngredient ingredient;
  final VoidCallback onTap;

  bool get _lowConfidence => ingredient.confidence < _lowConfidenceThreshold;
  bool get _unknownQuantity =>
      ingredient.quantity == null && ingredient.quantityText == null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ingredient.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  _unknownQuantity
                      ? 'amount unknown'
                      : ingredient.displayAmount,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _unknownQuantity || _lowConfidence
                        ? AppColors.terracottaDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.onTap});
  final DraftStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step.order}.',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    color: AppColors.terracotta,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.instruction,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
