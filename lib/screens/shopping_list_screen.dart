import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/add_to_list_sheet.dart';
import 'add_recipes_screen.dart';
import 'my_pantry_screen.dart';

class _ShopItem {
  _ShopItem({
    required this.name,
    required this.meta,
    required this.qty,
    this.checked = false,
  });

  final String name;
  final String meta;
  final String qty;
  bool checked;
}

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _controller = TextEditingController();
  bool _showChecked = true;

  final _produce = [
    _ShopItem(name: 'Heirloom Tomatoes', meta: 'Produce • Fresh', qty: '4 count'),
    _ShopItem(name: 'Baby Spinach', meta: 'Produce • Fresh', qty: '1 bag'),
    _ShopItem(name: 'Lemons', meta: 'Produce • Fresh', qty: '3 count'),
  ];
  final _dairy = [
    _ShopItem(name: 'Whole Milk', meta: 'Dairy • Cold', qty: '1 liter'),
    _ShopItem(name: 'Greek Yogurt', meta: 'Dairy • Cold', qty: '500 g'),
  ];
  final _pantry = [
    _ShopItem(name: 'Olive Oil', meta: 'Pantry • Staple', qty: '1 bottle'),
    _ShopItem(
      name: 'Sea Salt',
      meta: 'Pantry • Staple',
      qty: '1 jar',
      checked: true,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_ShopItem> get _checkedItems => [
        ..._produce,
        ..._dairy,
        ..._pantry,
      ].where((i) => i.checked).toList();

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _produce.insert(
        0,
        _ShopItem(name: text, meta: 'Produce • Fresh', qty: '1'),
      );
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MyPantryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_rounded,
                      color: AppColors.terracotta),
                ),
                Expanded(
                  child: Text(
                    'Shopping List',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.terracotta,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddRecipesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.terracotta),
                ),
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              decoration: BoxDecoration(
                color: AppColors.searchFill,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: AppColors.terracotta),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Add item (e.g., 2 Liters Milk)',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _addItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'ADD',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                _CategoryBlock(
                  icon: Icons.eco_outlined,
                  title: 'Produce',
                  items: _produce.where((i) => !i.checked).toList(),
                  onToggle: (item) => setState(() => item.checked = true),
                ),
                _CategoryBlock(
                  icon: Icons.water_drop_outlined,
                  title: 'Dairy',
                  items: _dairy.where((i) => !i.checked).toList(),
                  onToggle: (item) => setState(() => item.checked = true),
                ),
                _CategoryBlock(
                  icon: Icons.inventory_2_outlined,
                  title: 'Pantry',
                  items: _pantry.where((i) => !i.checked).toList(),
                  onToggle: (item) => setState(() => item.checked = true),
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFE5DFD7)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _showChecked = !_showChecked),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.olive, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Checked (${_checkedItems.length})',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.olive,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _showChecked
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppColors.olive,
                      ),
                    ],
                  ),
                ),
                if (_showChecked) ...[
                  const SizedBox(height: 12),
                  ..._checkedItems.map(
                    (item) => Opacity(
                      opacity: 0.55,
                      child: _ItemRow(
                        item: item,
                        onToggle: () =>
                            setState(() => item.checked = false),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => showAddToListSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add via form'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.terracotta,
                    side: const BorderSide(color: AppColors.terracotta),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.icon,
    required this.title,
    required this.items,
    required this.onToggle,
  });

  final IconData icon;
  final String title;
  final List<_ShopItem> items;
  final ValueChanged<_ShopItem> onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.olive),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.olive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _ItemRow(
                    item: items[i],
                    onToggle: () => onToggle(items[i]),
                  ),
                  if (i < items.length - 1)
                    const Divider(height: 1, color: Color(0xFFF0EBE5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onToggle});

  final _ShopItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(
              item.checked
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: item.checked
                  ? AppColors.olive
                  : AppColors.textMuted,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration: item.checked
                          ? TextDecoration.lineThrough
                          : null,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    item.meta,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.peachBadge,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                item.qty,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.terracottaDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
