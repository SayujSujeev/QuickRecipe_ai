/// Profile info collected during the post-signup setup wizard.
/// Used both for the signed-in user and for any family members they add.
class PersonProfile {
  PersonProfile({
    this.name = '',
    this.age = 28,
    this.heightCm = 170,
    this.weightKg = 65,
    this.sex = 'Male',
    this.activityLevel,
    this.goal,
    Set<String>? cuisines,
    this.cookingStyle,
  }) : cuisines = cuisines ?? <String>{};

  String name;
  int age;
  int heightCm;
  int weightKg;
  String sex;
  String? activityLevel;
  String? goal;
  Set<String> cuisines;
  String? cookingStyle;

  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
}
