/// Mirrors the server's strict Structured Outputs recipe schema
/// (functions/src/domain/recipeSchema.ts). Planning estimates are explicitly
/// labeled; the client never invents values when the server returns null.
class RecipeDraft {
  const RecipeDraft({
    required this.schemaVersion,
    required this.status,
    required this.title,
    required this.description,
    required this.originalLanguageCodes,
    required this.outputLanguageCode,
    required this.cuisines,
    required this.courses,
    required this.dietaryTags,
    required this.servings,
    required this.times,
    required this.ingredients,
    required this.steps,
    required this.equipment,
    required this.allergenFlags,
    required this.missingInformation,
    required this.warnings,
    required this.overallConfidence,
  });

  final String schemaVersion;
  final String status; // complete | needs_review | not_a_recipe
  final String? title;
  final String? description;
  final List<String> originalLanguageCodes;
  final String outputLanguageCode;
  final List<String> cuisines;
  final List<String> courses;
  final List<String> dietaryTags;
  final DraftServing? servings;
  final DraftTime times;
  final List<DraftIngredient> ingredients;
  final List<DraftStep> steps;
  final List<String> equipment;
  final List<String> allergenFlags;
  final List<String> missingInformation;
  final List<String> warnings;
  final double overallConfidence;

  factory RecipeDraft.fromMap(Map<String, dynamic> map) => RecipeDraft(
    schemaVersion: map['schemaVersion'] as String? ?? '1.0.0',
    status: map['status'] as String? ?? 'needs_review',
    title: map['title'] as String?,
    description: map['description'] as String?,
    originalLanguageCodes: ((map['originalLanguageCodes'] as List?) ?? [])
        .cast<String>(),
    outputLanguageCode: map['outputLanguageCode'] as String? ?? 'en',
    cuisines: ((map['cuisines'] as List?) ?? []).cast<String>(),
    courses: ((map['courses'] as List?) ?? []).cast<String>(),
    dietaryTags: ((map['dietaryTags'] as List?) ?? []).cast<String>(),
    servings: map['servings'] == null
        ? null
        : DraftServing.fromMap(
            Map<String, dynamic>.from(map['servings'] as Map),
          ),
    times: DraftTime.fromMap(
      Map<String, dynamic>.from(map['times'] as Map? ?? {}),
    ),
    ingredients: ((map['ingredients'] as List?) ?? [])
        .map(
          (e) => DraftIngredient.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    steps:
        ((map['steps'] as List?) ?? [])
            .map((e) => DraftStep.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
    equipment: ((map['equipment'] as List?) ?? []).cast<String>(),
    allergenFlags: ((map['allergenFlags'] as List?) ?? []).cast<String>(),
    missingInformation: ((map['missingInformation'] as List?) ?? [])
        .cast<String>(),
    warnings: ((map['warnings'] as List?) ?? []).cast<String>(),
    overallConfidence: (map['overallConfidence'] as num?)?.toDouble() ?? 0.0,
  );
}

class DraftServing {
  const DraftServing({
    required this.quantity,
    required this.label,
    required this.confidence,
    this.isEstimated = false,
    this.estimateReason,
  });
  final double? quantity;
  final String? label;
  final double confidence;
  final bool isEstimated;
  final String? estimateReason;

  String get displayLabel {
    if (quantity == null) return 'Servings not available';
    final amount = quantity! == quantity!.roundToDouble()
        ? quantity!.toInt().toString()
        : quantity.toString();
    return '$amount servings${isEstimated ? ' · estimated' : ''}';
  }

  Map<String, dynamic> toMap() => {
    'quantity': quantity,
    'label': label,
    'confidence': confidence,
    'isEstimated': isEstimated,
    'estimateReason': estimateReason,
  };

  factory DraftServing.fromMap(Map<String, dynamic> map) => DraftServing(
    quantity: (map['quantity'] as num?)?.toDouble(),
    label: map['label'] as String?,
    confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    isEstimated: map['isEstimated'] as bool? ?? false,
    estimateReason: map['estimateReason'] as String?,
  );
}

class DraftTime {
  const DraftTime({
    required this.prepMinutes,
    required this.cookMinutes,
    required this.totalMinutes,
    required this.confidence,
    this.estimatedFields = const [],
    this.estimateReason,
  });
  final int? prepMinutes;
  final int? cookMinutes;
  final int? totalMinutes;
  final double confidence;
  final List<String> estimatedFields;
  final String? estimateReason;

  bool get isTotalEstimated => estimatedFields.contains('totalMinutes');

  String get displayLabel => totalMinutes == null
      ? 'Time not available'
      : '$totalMinutes min${isTotalEstimated ? ' · estimated' : ''}';

  Map<String, dynamic> toMap() => {
    'prepMinutes': prepMinutes,
    'cookMinutes': cookMinutes,
    'totalMinutes': totalMinutes,
    'confidence': confidence,
    'estimatedFields': estimatedFields,
    'estimateReason': estimateReason,
  };

  factory DraftTime.fromMap(Map<String, dynamic> map) => DraftTime(
    prepMinutes: (map['prepMinutes'] as num?)?.toInt(),
    cookMinutes: (map['cookMinutes'] as num?)?.toInt(),
    totalMinutes: (map['totalMinutes'] as num?)?.toInt(),
    confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    estimatedFields: ((map['estimatedFields'] as List?) ?? []).cast<String>(),
    estimateReason: map['estimateReason'] as String?,
  );
}

class DraftIngredient {
  const DraftIngredient({
    required this.id,
    required this.group,
    required this.name,
    required this.quantity,
    required this.quantityText,
    required this.unit,
    required this.originalText,
    required this.preparation,
    required this.optional,
    required this.confidence,
  });

  final String id;
  final String? group;
  final String name;
  final double? quantity;
  final String? quantityText;
  final String? unit;
  final String? originalText;
  final String? preparation;
  final bool optional;
  final double confidence;

  /// Display text: prefers a known numeric quantity+unit, falls back to the
  /// model's vague-quantity text (e.g. "as needed"), never fabricates one.
  String get displayAmount {
    if (quantity != null) {
      final unitText = unit ?? '';
      return '$quantity $unitText'.trim();
    }
    return quantityText ?? '';
  }

  factory DraftIngredient.fromMap(Map<String, dynamic> map) => DraftIngredient(
    id: map['id'] as String? ?? '',
    group: map['group'] as String?,
    name: map['name'] as String? ?? '',
    quantity: (map['quantity'] as num?)?.toDouble(),
    quantityText: map['quantityText'] as String?,
    unit: map['unit'] as String?,
    originalText: map['originalText'] as String?,
    preparation: map['preparation'] as String?,
    optional: map['optional'] as bool? ?? false,
    confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
  );
}

class DraftStep {
  const DraftStep({
    required this.order,
    required this.instruction,
    required this.durationSeconds,
    required this.ingredientIds,
    required this.equipment,
    required this.confidence,
  });

  final int order;
  final String instruction;
  final int? durationSeconds;
  final List<String> ingredientIds;
  final List<String> equipment;
  final double confidence;

  factory DraftStep.fromMap(Map<String, dynamic> map) => DraftStep(
    order: (map['order'] as num?)?.toInt() ?? 0,
    instruction: map['instruction'] as String? ?? '',
    durationSeconds: (map['durationSeconds'] as num?)?.toInt(),
    ingredientIds: ((map['ingredientIds'] as List?) ?? []).cast<String>(),
    equipment: ((map['equipment'] as List?) ?? []).cast<String>(),
    confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
  );
}
