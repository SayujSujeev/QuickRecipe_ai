import 'package:cooksense/core/widgets/recipe_planning_summary.dart';
import 'package:cooksense/data/models/meal_recipe.dart';
import 'package:cooksense/data/models/recipe_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const servings = DraftServing(
  quantity: 3,
  label: null,
  confidence: 0.65,
  isEstimated: true,
  estimateReason: 'Based on the ingredient quantities.',
);
const times = DraftTime(
  prepMinutes: 10,
  cookMinutes: 20,
  totalMinutes: 30,
  confidence: 0.65,
  estimatedFields: ['prepMinutes', 'totalMinutes'],
  estimateReason: 'Allows time for chopping and mixing.',
);

void main() {
  test('estimate values and labels survive cookbook serialization', () {
    final meal = MealRecipe.fromFirestore('recipe-1', {
      'title': 'Garlic chicken',
      'imageUrl': 'https://example.com/dish.jpg',
      'servings': servings.toMap(),
      'times': times.toMap(),
    });
    final reloaded = MealRecipe.fromFirestore(meal.id, meal.toFirestore());
    expect(reloaded.servings!.displayLabel, '3 servings · estimated');
    expect(reloaded.times!.displayLabel, '30 min · estimated');
    expect(reloaded.servings!.estimateReason, servings.estimateReason);
    expect(reloaded.times!.estimatedFields, ['prepMinutes', 'totalMinutes']);
    expect(reloaded.imageUrl, 'https://example.com/dish.jpg');
  });

  test('legacy values are never relabeled as estimates', () {
    final serving = DraftServing.fromMap({'quantity': 2, 'confidence': 0.9});
    final time = DraftTime.fromMap({'totalMinutes': 18, 'confidence': 0.9});
    expect(serving.displayLabel, '2 servings');
    expect(serving.isEstimated, isFalse);
    expect(time.displayLabel, '18 min');
    expect(time.estimatedFields, isEmpty);
    expect(MealRecipe.fromFirestore('legacy', {}).servings, isNull);
  });

  testWidgets(
    'shows clear estimate labels and keeps the known cooking time unmarked',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RecipePlanningSummary(servings: servings, times: times),
          ),
        ),
      );
      expect(find.text('3 servings · estimated'), findsOneWidget);
      expect(find.text('30 min · estimated'), findsOneWidget);
      expect(
        find.text('Prep: 10 min (estimated) · Cook: 20 min'),
        findsOneWidget,
      );
      expect(find.textContaining('AI estimate:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing evidence does not generate made-up default values', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RecipePlanningSummary())),
    );
    expect(find.text('Servings not available'), findsOneWidget);
    expect(find.text('Time not available'), findsOneWidget);
    expect(find.textContaining('estimated'), findsNothing);
  });

  testWidgets('fits a narrow phone with larger text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const SizedBox(
              width: 280,
              child: RecipePlanningSummary(servings: servings, times: times),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
