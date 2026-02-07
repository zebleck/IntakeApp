import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/recipe_ingredient.dart';

class IngredientTile extends StatelessWidget {
  final RecipeIngredient ingredient;
  final VoidCallback onDelete;

  const IngredientTile({
    super.key,
    required this.ingredient,
    required this.onDelete,
  });

  String _formatQuantity() {
    if (ingredient.quantity == null) return '';
    final qty = ingredient.quantity!;
    final display = qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
    if (ingredient.unit != null && ingredient.unit!.isNotEmpty) {
      return '$display ${ingredient.unit}';
    }
    return display;
  }

  @override
  Widget build(BuildContext context) {
    final qtyText = _formatQuantity();

    return Dismissible(
      key: ValueKey(ingredient.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            title: Text('Delete ingredient?',
                style: GoogleFonts.spaceMono(color: Colors.white)),
            content: Text(
              'Remove "${ingredient.name}"?',
              style: GoogleFonts.spaceMono(
                  color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: GoogleFonts.spaceMono(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: GoogleFonts.spaceMono(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(13)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ingredient.name,
                style: GoogleFonts.spaceMono(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            if (qtyText.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  qtyText,
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF667EEA),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
