import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/shopping_item.dart';
import 'animated_checkmark.dart';

class ItemTile extends StatelessWidget {
  final ShoppingItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const ItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  String _formatQuantity() {
    if (item.quantity == null) return '';
    final qty = item.quantity!;
    final display = qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
    if (item.unit != null && item.unit!.isNotEmpty) {
      return '$display ${item.unit}';
    }
    return display;
  }

  @override
  Widget build(BuildContext context) {
    final qtyText = _formatQuantity();

    return Dismissible(
      key: ValueKey(item.id),
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
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      child: AnimatedOpacity(
        opacity: item.isChecked ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(item.isChecked ? 5 : 13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(13)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggle(!item.isChecked);
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: item.isChecked ? 0.0 : 1.0,
                    end: item.isChecked ? 1.0 : 0.0,
                  ),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 1.0 + value * 0.1,
                      child: Transform.rotate(
                        angle: value * 0.1,
                        child: child,
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: item.isChecked
                          ? const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            )
                          : null,
                      border: item.isChecked
                          ? null
                          : Border.all(color: Colors.white38, width: 2),
                    ),
                    child: AnimatedCheckmark(
                      isChecked: item.isChecked,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 14,
                    decoration:
                        item.isChecked ? TextDecoration.lineThrough : null,
                    decorationColor: Colors.white54,
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
      ),
    );
  }
}
