import 'package:flutter_test/flutter_test.dart';
import 'package:cooksense/data/models/recipe_draft.dart';
import 'package:cooksense/data/models/recipe_import_job.dart';

Map<String, dynamic> _fixtureDraftMap() => {
      'schemaVersion': '1.0.0',
      'status': 'complete',
      'title': 'Garlic Butter Shrimp',
      'description': null,
      'originalLanguageCodes': ['en'],
      'outputLanguageCode': 'en',
      'cuisines': ['American'],
      'courses': ['dinner'],
      'dietaryTags': [],
      'servings': {'quantity': 2, 'label': null, 'confidence': 0.9},
      'times': {
        'prepMinutes': 10,
        'cookMinutes': 8,
        'totalMinutes': 18,
        'confidence': 0.85,
      },
      'ingredients': [
        {
          'id': 'ing_1',
          'group': null,
          'name': 'shrimp',
          'quantity': 450,
          'quantityText': null,
          'unit': 'g',
          'originalText': '1 lb shrimp',
          'preparation': 'peeled',
          'optional': false,
          'confidence': 0.9,
        },
        {
          'id': 'ing_2',
          'group': null,
          'name': 'butter',
          'quantity': null,
          'quantityText': 'a knob',
          'unit': null,
          'originalText': 'a knob of butter',
          'preparation': null,
          'optional': false,
          'confidence': 0.55,
        },
      ],
      'steps': [
        {
          'order': 2,
          'instruction': 'Add shrimp and cook.',
          'durationSeconds': 360,
          'ingredientIds': ['ing_1'],
          'equipment': ['pan'],
          'confidence': 0.85,
        },
        {
          'order': 1,
          'instruction': 'Melt butter.',
          'durationSeconds': null,
          'ingredientIds': ['ing_2'],
          'equipment': ['pan'],
          'confidence': 0.8,
        },
      ],
      'equipment': ['pan'],
      'allergenFlags': ['shellfish'],
      'missingInformation': [],
      'warnings': [],
      'overallConfidence': 0.85,
    };

void main() {
  group('RecipeDraft.fromMap', () {
    test('parses a well-formed draft', () {
      final draft = RecipeDraft.fromMap(_fixtureDraftMap());
      expect(draft.title, 'Garlic Butter Shrimp');
      expect(draft.ingredients, hasLength(2));
      expect(draft.overallConfidence, 0.85);
    });

    test('sorts steps by order regardless of input order', () {
      final draft = RecipeDraft.fromMap(_fixtureDraftMap());
      expect(draft.steps.map((s) => s.order).toList(), [1, 2]);
      expect(draft.steps.first.instruction, 'Melt butter.');
    });

    test('never invents a title when null', () {
      final map = _fixtureDraftMap()..['title'] = null;
      final draft = RecipeDraft.fromMap(map);
      expect(draft.title, isNull);
    });

    test('handles a null servings object', () {
      final map = _fixtureDraftMap()..['servings'] = null;
      final draft = RecipeDraft.fromMap(map);
      expect(draft.servings, isNull);
    });
  });

  group('DraftIngredient.displayAmount', () {
    test('prefers quantity+unit when known', () {
      final draft = RecipeDraft.fromMap(_fixtureDraftMap());
      expect(draft.ingredients[0].displayAmount, '450.0 g');
    });

    test('falls back to quantityText for vague amounts, never a fabricated number', () {
      final draft = RecipeDraft.fromMap(_fixtureDraftMap());
      expect(draft.ingredients[1].displayAmount, 'a knob');
    });
  });

  group('RecipeImportJob state helpers', () {
    test('isRecoverable is true only for awaiting_user_upload', () {
      final job = RecipeImportJob.fromMap({'state': 'awaiting_user_upload'});
      expect(job.isRecoverable, isTrue);
      expect(RecipeImportJob.fromMap({'state': 'queued'}).isRecoverable, isFalse);
    });

    test('isReadyForReview covers both needs_review and completed', () {
      expect(RecipeImportJob.fromMap({'state': 'needs_review'}).isReadyForReview, isTrue);
      expect(RecipeImportJob.fromMap({'state': 'completed'}).isReadyForReview, isTrue);
      expect(RecipeImportJob.fromMap({'state': 'analyzing'}).isReadyForReview, isFalse);
    });
  });
}
