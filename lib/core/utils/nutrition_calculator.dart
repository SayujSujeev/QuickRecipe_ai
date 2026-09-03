import '../../data/models/person_profile.dart';

class DailyTargets {
  const DailyTargets({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    required this.bmi,
    required this.bmiCategory,
  });

  final int kcal;
  final int proteinG;
  final int carbsG;
  final int fatsG;
  final double bmi;
  final String bmiCategory;

  factory DailyTargets.fromMap(Map<String, dynamic> map) => DailyTargets(
    kcal: (map['kcal'] as num?)?.toInt() ?? 0,
    proteinG: (map['proteinG'] as num?)?.toInt() ?? 0,
    carbsG: (map['carbsG'] as num?)?.toInt() ?? 0,
    fatsG: (map['fatsG'] as num?)?.toInt() ?? 0,
    bmi: (map['bmi'] as num?)?.toDouble() ?? 0,
    bmiCategory: map['bmiCategory'] as String? ?? 'Unknown',
  );
}

/// Standard weight(kg) / height(m)^2 BMI, WHO adult categories.
double calculateBmi({required int heightCm, required int weightKg}) {
  final heightM = heightCm / 100;
  if (heightM <= 0) return 0;
  return weightKg / (heightM * heightM);
}

String categorizeBmi(double bmi) {
  if (bmi <= 0) return 'Unknown';
  if (bmi < 18.5) return 'Underweight';
  if (bmi < 25) return 'Healthy weight';
  if (bmi < 30) return 'Overweight';
  return 'Obese';
}

/// Mifflin-St Jeor BMR, scaled by activity level and nudged by goal.
DailyTargets computeDailyTargets(PersonProfile profile) {
  final bmr = profile.sex == 'Female'
      ? 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age - 161
      : 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age + 5;

  const activityMultipliers = {
    'Sedentary': 1.2,
    'Lightly Active': 1.375,
    'Active': 1.55,
    'Very Active': 1.725,
  };
  final multiplier = activityMultipliers[profile.activityLevel] ?? 1.375;
  var tdee = bmr * multiplier;

  switch (profile.goal) {
    case 'Lose Weight':
      tdee -= 500;
    case 'Build Muscle':
      tdee += 300;
  }
  tdee = tdee.clamp(1200, 4500);

  final proteinPerKg = profile.goal == 'Build Muscle' ? 2.0 : 1.6;
  final proteinG = (profile.weightKg * proteinPerKg).round();
  final proteinKcal = proteinG * 4;
  final fatsKcal = tdee * 0.28;
  final fatsG = (fatsKcal / 9).round();
  final carbsKcal = (tdee - proteinKcal - fatsKcal).clamp(0, tdee);
  final carbsG = (carbsKcal / 4).round();

  final bmi = calculateBmi(
    heightCm: profile.heightCm,
    weightKg: profile.weightKg,
  );

  return DailyTargets(
    kcal: tdee.round(),
    proteinG: proteinG,
    carbsG: carbsG,
    fatsG: fatsG,
    bmi: bmi,
    bmiCategory: categorizeBmi(bmi),
  );
}
