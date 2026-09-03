import 'dart:math' as math;

import '../../data/models/meal_recipe.dart';
import 'macro_estimator_service.dart';
import 'recipe_repository.dart';

typedef BackfillProgress = void Function(int completed, int total);

/// Runs macro estimation across the Firestore recipe library and writes the
/// results back onto each recipe doc (see [RecipeRepository.updateNutrition]).
class MacroBackfillService {
  MacroBackfillService._();
  static final MacroBackfillService instance = MacroBackfillService._();

  // Keep this modest — OpenAI rate limits and cost scale with concurrency.
  static const _concurrency = 3;

  /// Estimates macros for every recipe missing them (or all recipes, if
  /// [onlyMissing] is false) and saves the result. Returns how many recipes
  /// were successfully updated; failures for individual recipes are skipped
  /// rather than aborting the whole run.
  Future<int> calculateForAll({
    bool onlyMissing = true,
    BackfillProgress? onProgress,
  }) async {
    final all = await RecipeRepository.instance.fetchAll();
    final targets = onlyMissing
        ? all.where((r) => r.nutrition == null).toList()
        : all;

    var completed = 0;
    var succeeded = 0;
    for (var i = 0; i < targets.length; i += _concurrency) {
      final chunk = targets.sublist(
        i,
        math.min(i + _concurrency, targets.length),
      );
      final results = await Future.wait(chunk.map(_estimateOne));
      for (final ok in results) {
        completed++;
        if (ok) succeeded++;
        onProgress?.call(completed, targets.length);
      }
    }
    return succeeded;
  }

  Future<bool> _estimateOne(MealRecipe recipe) async {
    try {
      final nutrition = await MacroEstimatorService.instance.estimate(recipe);
      await RecipeRepository.instance.updateNutrition(recipe.id, nutrition);
      return true;
    } catch (_) {
      return false;
    }
  }
}
