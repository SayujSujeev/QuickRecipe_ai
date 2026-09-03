import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/meal_recipe.dart';
import 'meal_db_service.dart';

typedef ImportProgress = void Function(int completed, int total);

/// Firestore-backed store of recipes imported from TheMealDB.
///
/// Schema: recipes/{mealDbId}
///   mealDbId, title, imageUrl, instructions, ingredients: [{name, measure}],
///   category, area, tags: [...], source, youtube, importedAt
///
/// Docs are keyed by TheMealDB's own id so importing the same recipe twice
/// just refreshes it in place instead of duplicating it.
class RecipeRepository {
  RecipeRepository._();
  static final RecipeRepository instance = RecipeRepository._();

  static const _fetchConcurrency = 8;

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _recipes =>
      _db.collection('recipes');

  Stream<List<MealRecipe>> watchRecipes({int limit = 200}) {
    return _recipes
        .orderBy('importedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MealRecipe.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<List<MealRecipe>> fetchAll({int limit = 200}) async {
    final snap = await _recipes
        .orderBy('importedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => MealRecipe.fromFirestore(d.id, d.data()))
        .toList();
  }

  /// Merges AI-estimated macros into an existing recipe doc.
  Future<void> updateNutrition(String recipeId, RecipeNutrition nutrition) {
    return _recipes.doc(recipeId).set({
      'nutrition': nutrition.toMap(),
    }, SetOptions(merge: true));
  }

  Map<String, dynamic> _docFor(MealRecipe meal) => {
    ...meal.toFirestore(),
    'importedAt': FieldValue.serverTimestamp(),
  };

  /// Pulls up to [limit] recipes from a TheMealDB category (e.g. "Seafood")
  /// and upserts them into Firestore, fetching in parallel batches and
  /// writing in a Firestore batch per chunk so large imports (e.g. 100) stay
  /// fast. Returns how many were imported.
  Future<int> importFromCategory(
    String category, {
    int limit = 10,
    ImportProgress? onProgress,
  }) async {
    final ids = await MealDbService.instance.fetchMealIdsByCategory(
      category,
      limit: limit,
    );

    var completed = 0;
    var imported = 0;
    for (var i = 0; i < ids.length; i += _fetchConcurrency) {
      final chunk = ids.sublist(i, math.min(i + _fetchConcurrency, ids.length));
      final meals = await Future.wait(
        chunk.map((id) => MealDbService.instance.fetchMealById(id)),
      );

      final batch = _db.batch();
      for (final meal in meals) {
        completed++;
        if (meal != null) {
          batch.set(
            _recipes.doc(meal.id),
            _docFor(meal),
            SetOptions(merge: true),
          );
          imported++;
        }
        onProgress?.call(completed, ids.length);
      }
      await batch.commit();
    }
    return imported;
  }

  /// Pulls up to [count] distinct random recipes from TheMealDB and upserts
  /// them. TheMealDB's free tier only has a few hundred recipes total, so
  /// with a large [count] you may get fewer than requested once the
  /// available pool is exhausted.
  Future<int> importRandom({int count = 10, ImportProgress? onProgress}) async {
    final seen = <String>{};
    var imported = 0;
    var attempts = 0;
    final maxAttempts = count * 5;

    while (imported < count && attempts < maxAttempts) {
      final batchTarget = math.min(_fetchConcurrency, count - imported);
      final results = await Future.wait(
        List.generate(
          batchTarget,
          (_) => MealDbService.instance.fetchRandomMeal(),
        ),
      );
      attempts += batchTarget;

      final batch = _db.batch();
      var wroteAny = false;
      for (final meal in results) {
        if (!seen.add(meal.id)) continue;
        batch.set(
          _recipes.doc(meal.id),
          _docFor(meal),
          SetOptions(merge: true),
        );
        imported++;
        wroteAny = true;
        onProgress?.call(imported, count);
      }
      if (wroteAny) await batch.commit();
    }
    return imported;
  }
}
