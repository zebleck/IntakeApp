import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/food_entry.dart';
import '../models/recipe.dart';
import '../screens/recipe_detail_screen.dart';

class FoodEntryTile extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onDelete;
  final ValueChanged<TimeOfDay>? onTimeEdit;
  final ValueChanged<String?>? onCommentEdit;

  const FoodEntryTile({
    super.key,
    required this.entry,
    required this.onDelete,
    this.onTimeEdit,
    this.onCommentEdit,
  });

  String _formatTime() {
    final dt = DateTime.parse(entry.loggedAt);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatQuantity() {
    if (entry.quantity == null) return '';
    final qty = entry.quantity!;
    final display =
        qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
    if (entry.unit != null && entry.unit!.isNotEmpty) {
      return '$display ${entry.unit}';
    }
    return display;
  }

  @override
  Widget build(BuildContext context) {
    final qtyText = _formatQuantity();

    return Dismissible(
      key: ValueKey(entry.id),
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
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onLongPress: () => _showCommentDialog(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(13)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (onTimeEdit == null) return;
                      final dt = DateTime.parse(entry.loggedAt);
                      final picked = await showTimePicker(
                        context: context,
                        initialTime:
                            TimeOfDay(hour: dt.hour, minute: dt.minute),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF667EEA),
                              surface: Color(0xFF1A1F3A),
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        onTimeEdit!(picked);
                      }
                    },
                    child: Text(
                      _formatTime(),
                      style: GoogleFonts.spaceMono(
                        color: Colors.white38,
                        fontSize: 11,
                        decoration: onTimeEdit != null
                            ? TextDecoration.underline
                            : null,
                        decorationColor: Colors.white24,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.name,
                      style: GoogleFonts.spaceMono(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (entry.recipeName != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (entry.recipeId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(
                                recipe: Recipe(
                                  id: entry.recipeId,
                                  name: entry.recipeName!,
                                  createdAt: '',
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.recipeName!,
                          style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (qtyText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
                ],
              ),
              if (entry.comment != null && entry.comment!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 47),
                  child: Text(
                    entry.comment!,
                    style: GoogleFonts.spaceMono(
                      color: Colors.white38,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommentDialog(BuildContext context) {
    if (onCommentEdit == null) return;
    final controller = TextEditingController(text: entry.comment ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text('Note',
            style: GoogleFonts.spaceMono(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'e.g. needed more salt...',
            hintStyle: GoogleFonts.spaceMono(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF667EEA)),
            ),
          ),
        ),
        actions: [
          if (entry.comment != null && entry.comment!.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onCommentEdit!(null);
              },
              child: Text('Remove',
                  style: GoogleFonts.spaceMono(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.spaceMono(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final text = controller.text.trim();
              onCommentEdit!(text.isEmpty ? null : text);
            },
            child: Text('Save',
                style: GoogleFonts.spaceMono(
                    color: const Color(0xFF667EEA))),
          ),
        ],
      ),
    );
  }
}
