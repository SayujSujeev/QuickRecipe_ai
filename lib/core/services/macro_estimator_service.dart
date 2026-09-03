import 'package:cloud_functions/cloud_functions.dart';

import '../../data/models/meal_recipe.dart';

/// Estimates macros for a recipe via the `estimateRecipeMacros` Cloud
/// Function.
///
/// This used to call OpenAI directly from the client with an API key read
/// from a local `.env` bundled as a Flutter asset — that shipped the key
/// inside every release build. The call now runs server-side; the client
/// never holds an OpenAI key.
class MacroEstimatorService {
  MacroEstimatorService._();
  static final MacroEstimatorService instance = MacroEstimatorService._();

  final _functions = FirebaseFunctions.instance;

  Future<RecipeNutrition> estimate(MealRecipe recipe) async {
    final ingredients = recipe.ingredients
        .map((i) => {'name': i.name, 'measure': i.measure})
        .toList();

    final result = await _functions
        .httpsCallable('estimateRecipeMacros')
        .call<Map<String, dynamic>>({
          'recipeId': recipe.id,
          'title': recipe.title,
          'ingredients': ingredients,
          'instructions': recipe.instructions,
        });

    return RecipeNutrition.fromMap(
      Map<String, dynamic>.from(result.data['nutrition'] as Map),
    );
  }
}
