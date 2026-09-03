class Recipe {
  const Recipe({
    required this.title,
    required this.imageUrl,
    this.rating,
    this.mins,
    this.kcal,
    this.proteinG,
    this.prepLabel,
    this.tags,
    this.difficulty,
    this.badge,
    this.badgeIcon,
  });

  final String title;
  final String imageUrl;
  final double? rating;
  final int? mins;
  final int? kcal;
  final int? proteinG;
  final String? prepLabel;
  final String? tags;
  final String? difficulty;
  final String? badge;
  final String? badgeIcon; // bolt | leaf | star
}

class CategoryItem {
  const CategoryItem({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;
}

class SeasonalPick {
  const SeasonalPick({
    required this.title,
    required this.countLabel,
    required this.imageUrl,
  });

  final String title;
  final String countLabel;
  final String imageUrl;
}

class Ingredient {
  const Ingredient({required this.name, required this.amount});

  final String name;
  final String amount;
}

class CookingStep {
  const CookingStep({required this.instruction, this.timerSeconds});

  final String instruction;
  final int? timerSeconds;
}

const categories = [
  CategoryItem(
    name: 'Breakfast',
    imageUrl:
        'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&q=80',
  ),
  CategoryItem(
    name: 'Lunch',
    imageUrl:
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=80',
  ),
  CategoryItem(
    name: 'Dinner',
    imageUrl:
        'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=600&q=80',
  ),
  CategoryItem(
    name: 'Snacks',
    imageUrl:
        'https://images.unsplash.com/photo-1621939514649-280e2ee25f60?w=600&q=80',
  ),
  CategoryItem(
    name: 'High-Protein',
    imageUrl:
        'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=600&q=80',
  ),
  CategoryItem(
    name: 'Vegetarian',
    imageUrl:
        'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=600&q=80',
  ),
  CategoryItem(
    name: 'Quick Meals',
    imageUrl:
        'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=600&q=80',
  ),
  CategoryItem(
    name: 'Desserts',
    imageUrl:
        'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600&q=80',
  ),
];

const seasonalPicks = [
  SeasonalPick(
    title: 'Fall Comforts',
    countLabel: '24 Recipes',
    imageUrl:
        'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?w=300&q=80',
  ),
  SeasonalPick(
    title: 'Summer Fresh',
    countLabel: '18 Recipes',
    imageUrl:
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=300&q=80',
  ),
  SeasonalPick(
    title: 'Winter Warmers',
    countLabel: '21 Recipes',
    imageUrl:
        'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=300&q=80',
  ),
];

const searchRecipes = [
  Recipe(
    title: 'Honey Garlic Chicken',
    imageUrl:
        'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=900&q=80',
    mins: 25,
    kcal: 450,
    difficulty: 'Easy',
    badge: 'High Protein',
    badgeIcon: 'bolt',
  ),
  Recipe(
    title: 'Lemon Herb Chicken',
    imageUrl:
        'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=900&q=80',
    mins: 30,
    kcal: 380,
    difficulty: 'Quick',
    badge: 'Low Carb',
    badgeIcon: 'leaf',
  ),
  Recipe(
    title: 'Crispy Chicken Thighs',
    imageUrl:
        'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=900&q=80',
    mins: 40,
    kcal: 520,
    difficulty: 'Medium',
    badge: 'Best Rated',
    badgeIcon: 'star',
  ),
];

const harvestBowl = Recipe(
  title: 'Roasted Vegetable Harvest Bowl',
  imageUrl:
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=1000&q=80',
  mins: 25,
  kcal: 420,
  difficulty: 'Easy',
);

const harvestIngredients = [
  Ingredient(name: 'Fresh Tuscan Kale', amount: '2 cups'),
  Ingredient(name: 'Sweet Potato (Cubed)', amount: '1 medium'),
  Ingredient(name: 'Canned Chickpeas', amount: '15 oz'),
  Ingredient(name: 'Tahini Paste', amount: '3 tbsp'),
  Ingredient(name: 'Extra Virgin Olive Oil', amount: '2 tbsp'),
  Ingredient(name: 'Lemon Juice', amount: '1 tbsp'),
  Ingredient(name: 'Garlic Clove', amount: '1'),
];

const cookingSteps = [
  CookingStep(
    instruction: 'Preheat the oven to 425°F and line a baking sheet.',
  ),
  CookingStep(
    instruction:
        'Whisk together the olive oil, lemon juice, and tahini until smooth.',
    timerSeconds: 300,
  ),
  CookingStep(
    instruction: 'Toss sweet potato cubes with oil, salt, and pepper.',
  ),
  CookingStep(
    instruction: 'Roast sweet potatoes until tender and golden at the edges.',
    timerSeconds: 1200,
  ),
  CookingStep(
    instruction: 'Warm chickpeas in a skillet with a pinch of spices.',
    timerSeconds: 300,
  ),
  CookingStep(
    instruction: 'Massage kale with a drop of oil until soft and glossy.',
  ),
  CookingStep(
    instruction: 'Assemble bowls with kale, potatoes, and chickpeas.',
  ),
  CookingStep(instruction: 'Drizzle with tahini sauce and serve warm.'),
];
