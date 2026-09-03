import 'recipe_draft.dart';

/// A recipe sourced from TheMealDB or a social import, stored in Firestore's `recipes`
/// collection (doc id = TheMealDB `idMeal`, so re-imports just refresh it).
class MealRecipe {
  const MealRecipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.instructions,
    required this.ingredients,
    this.category,
    this.area,
    this.tags = const [],
    this.source,
    this.youtube,
    this.nutrition,
    this.servings,
    this.times,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String instructions;
  final List<RecipeIngredient> ingredients;
  final String? category;
  final String? area;
  final List<String> tags;
  final String? source;
  final String? youtube;

  /// AI-estimated macros, filled in separately after import (see
  /// MacroEstimatorService). Null until that backfill has run for this doc.
  final RecipeNutrition? nutrition;
  final DraftServing? servings;
  final DraftTime? times;

  /// Instructions split into individual steps for the cooking-steps UI.
  /// TheMealDB returns instructions as free text, usually newline separated.
  List<String> get instructionSteps => instructions
      .split(RegExp(r'\r?\n+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  factory MealRecipe.fromMealDbJson(Map<String, dynamic> json) {
    final ingredients = <RecipeIngredient>[];
    for (var i = 1; i <= 20; i++) {
      final name = (json['strIngredient$i'] as String?)?.trim();
      final measure = (json['strMeasure$i'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        ingredients.add(RecipeIngredient(name: name, measure: measure ?? ''));
      }
    }

    final tagsRaw = json['strTags'] as String?;
    final tags = (tagsRaw == null || tagsRaw.isEmpty)
        ? const <String>[]
        : tagsRaw
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();

    return MealRecipe(
      id: json['idMeal'] as String,
      title: (json['strMeal'] as String?)?.trim() ?? 'Untitled Recipe',
      imageUrl: json['strMealThumb'] as String? ?? '',
      instructions: (json['strInstructions'] as String? ?? '').trim(),
      ingredients: ingredients,
      category: json['strCategory'] as String?,
      area: json['strArea'] as String?,
      tags: tags,
      source: json['strSource'] as String?,
      youtube: json['strYoutube'] as String?,
    );
  }

  factory MealRecipe.fromFirestore(String id, Map<String, dynamic> data) {
    return MealRecipe(
      id: id,
      title: data['title'] as String? ?? 'Untitled Recipe',
      imageUrl: data['imageUrl'] as String? ?? '',
      instructions: data['instructions'] as String? ?? '',
      ingredients: ((data['ingredients'] as List?) ?? [])
          .map(
            (e) =>
                RecipeIngredient.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      category: data['category'] as String?,
      area: data['area'] as String?,
      tags: ((data['tags'] as List?) ?? []).cast<String>(),
      source: data['source'] as String?,
      youtube: data['youtube'] as String?,
      servings: data['servings'] is Map
          ? DraftServing.fromMap(
              Map<String, dynamic>.from(data['servings'] as Map),
            )
          : null,
      times: data['times'] is Map
          ? DraftTime.fromMap(Map<String, dynamic>.from(data['times'] as Map))
          : null,
      nutrition: data['nutrition'] == null
          ? null
          : RecipeNutrition.fromMap(
              Map<String, dynamic>.from(data['nutrition'] as Map),
            ),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'mealDbId': id,
    'title': title,
    'imageUrl': imageUrl,
    'instructions': instructions,
    'ingredients': ingredients.map((e) => e.toMap()).toList(),
    'category': category,
    'area': area,
    'tags': tags,
    'source': source,
    'youtube': youtube,
    if (servings != null) 'servings': servings!.toMap(),
    if (times != null) 'times': times!.toMap(),
  };
}

/// AI-estimated per-recipe macros (whole recipe, not per serving —
/// [servings] tells you how to divide it for a single portion).
class RecipeNutrition {
  const RecipeNutrition({
    required this.servings,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
  });

  final int servings;
  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatsG;

  int get kcalPerServing => servings > 0 ? (kcal / servings).round() : kcal;
  int get proteinGPerServing =>
      servings > 0 ? (proteinG / servings).round() : proteinG;
  int get carbsGPerServing =>
      servings > 0 ? (carbsG / servings).round() : carbsG;
  int get fatsGPerServing => servings > 0 ? (fatsG / servings).round() : fatsG;

  Map<String, dynamic> toMap() => {
    'servings': servings,
    'kcal': kcal,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatsG': fatsG,
  };

  factory RecipeNutrition.fromMap(Map<String, dynamic> map) => RecipeNutrition(
    servings: (map['servings'] as num?)?.toInt() ?? 1,
    kcal: (map['kcal'] as num?)?.toInt() ?? 0,
    proteinG: (map['proteinG'] as num?)?.toInt() ?? 0,
    carbsG: (map['carbsG'] as num?)?.toInt() ?? 0,
    fatsG: (map['fatsG'] as num?)?.toInt() ?? 0,
  );
}

class RecipeIngredient {
  const RecipeIngredient({required this.name, required this.measure});

  final String name;
  final String measure;

  Map<String, dynamic> toMap() => {'name': name, 'measure': measure};

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) =>
      RecipeIngredient(
        name: map['name'] as String? ?? '',
        measure: map['measure'] as String? ?? '',
      );
}
