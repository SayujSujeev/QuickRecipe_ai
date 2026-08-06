import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/floating_nav_bar.dart';
import 'ai_chat_screen.dart';
import 'family_members_screen.dart';
import 'home_screen.dart';
import 'import_recipe_screen.dart';
import 'meals_dashboard_screen.dart';
import 'nutrition_trends_screen.dart';
import 'profile_screen.dart';
import 'shopping_list_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              MealsDashboardScreen(),
              ShoppingListScreen(),
              FamilyMembersScreen(),
              ProfileScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
          if (_index == 0)
            Positioned(
              right: 28,
              bottom: 100,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ImportRecipeScreen(),
                    ),
                  );
                },
                backgroundColor: AppColors.terracotta,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          if (_index == 1)
            Positioned(
              left: 20,
              bottom: 100,
              child: Row(
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'ai_chat_fab',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AiChatScreen(),
                        ),
                      );
                    },
                    backgroundColor: AppColors.sage,
                    foregroundColor: AppColors.terracottaDark,
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('AI'),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.extended(
                    heroTag: 'trends_fab',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NutritionTrendsScreen(),
                        ),
                      );
                    },
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.terracottaDark,
                    icon: const Icon(Icons.bar_chart_rounded),
                    label: const Text('Trends'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
