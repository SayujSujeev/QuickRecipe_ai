import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/meal_recipe.dart';

/// Thin client for TheMealDB's free public API
/// (https://www.themealdb.com/api.php).
class MealDbService {
  MealDbService._();
  static final MealDbService instance = MealDbService._();

  static const _base = 'https://www.themealdb.com/api/json/v1/1';

  Future<Map<String, dynamic>> _getJson(String path) async {
    final res = await http.get(Uri.parse('$_base/$path'));
    if (res.statusCode != 200) {
      throw Exception('TheMealDB request failed (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<String>> fetchCategoryNames() async {
    final body = await _getJson('list.php?c=list');
    final list = (body['meals'] as List?) ?? [];
    return list
        .map((e) => (e as Map<String, dynamic>)['strCategory'] as String)
        .toList();
  }

  Future<List<String>> fetchMealIdsByCategory(
    String category, {
    int limit = 10,
  }) async {
    final body = await _getJson(
      'filter.php?c=${Uri.encodeQueryComponent(category)}',
    );
    final list = (body['meals'] as List?) ?? [];
    return list
        .take(limit)
        .map((e) => (e as Map<String, dynamic>)['idMeal'] as String)
        .toList();
  }

  Future<MealRecipe?> fetchMealById(String id) async {
    final body = await _getJson('lookup.php?i=$id');
    final meals = body['meals'] as List?;
    if (meals == null || meals.isEmpty) return null;
    return MealRecipe.fromMealDbJson(meals.first as Map<String, dynamic>);
  }

  Future<MealRecipe> fetchRandomMeal() async {
    final body = await _getJson('random.php');
    final meals = body['meals'] as List;
    return MealRecipe.fromMealDbJson(meals.first as Map<String, dynamic>);
  }
}
