import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../db/database.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/recipe_step.dart';
import '../widgets/ingredient_tile.dart';
import '../widgets/step_tile.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/animated_gradient_background.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

enum _InputMode { ingredient, step }

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late String _recipeName;
  late String? _link;
  List<RecipeIngredient> _ingredients = [];
  List<RecipeStep> _steps = [];
  bool _loading = true;
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  _InputMode _inputMode = _InputMode.ingredient;

  @override
  void initState() {
    super.initState();
    _recipeName = widget.recipe.name;
    _link = widget.recipe.link;
    _loadData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ingredients =
        await AppDatabase.instance.getRecipeIngredients(widget.recipe.id!);
    final steps =
        await AppDatabase.instance.getRecipeSteps(widget.recipe.id!);
    setState(() {
      _ingredients = ingredients;
      _steps = steps;
      _loading = false;
    });
  }

  Future<void> _addInput(String input) async {
    if (input.trim().isEmpty) return;
    HapticFeedback.lightImpact();

    if (_inputMode == _InputMode.ingredient) {
      final parsed = _parseIngredientInput(input.trim());
      final ingredient = RecipeIngredient(
        recipeId: widget.recipe.id!,
        name: parsed.name,
        quantity: parsed.quantity,
        unit: parsed.unit,
      );
      await AppDatabase.instance.createRecipeIngredient(ingredient);
    } else {
      final step = RecipeStep(
        recipeId: widget.recipe.id!,
        stepNumber: 0, // auto-incremented by DB method
        instruction: input.trim(),
      );
      await AppDatabase.instance.createRecipeStep(step);
    }

    _inputController.clear();
    _loadData();
  }

  _ParsedIngredient _parseIngredientInput(String input) {
    final regexWithUnit = RegExp(
        r'^(\d+(?:\.\d+)?)\s*(kg|g|ml|l|pcs|oz|lb|cups?|tbsp|tsp)\s+(.+)$',
        caseSensitive: false);
    final matchWithUnit = regexWithUnit.firstMatch(input);
    if (matchWithUnit != null) {
      return _ParsedIngredient(
        name: matchWithUnit.group(3)!,
        quantity: double.parse(matchWithUnit.group(1)!),
        unit: matchWithUnit.group(2)!.toLowerCase(),
      );
    }

    final regexQtyOnly = RegExp(r'^(\d+(?:\.\d+)?)\s+(.+)$');
    final matchQtyOnly = regexQtyOnly.firstMatch(input);
    if (matchQtyOnly != null) {
      return _ParsedIngredient(
        name: matchQtyOnly.group(2)!,
        quantity: double.parse(matchQtyOnly.group(1)!),
        unit: null,
      );
    }

    return _ParsedIngredient(name: input, quantity: null, unit: null);
  }

  Future<void> _deleteIngredient(RecipeIngredient ingredient) async {
    HapticFeedback.mediumImpact();
    await AppDatabase.instance.deleteRecipeIngredient(ingredient.id!);
    _loadData();
  }

  Future<void> _deleteStep(RecipeStep step) async {
    HapticFeedback.mediumImpact();
    await AppDatabase.instance.deleteRecipeStep(step.id!);
    _loadData();
  }

  Future<void> _editRecipeName() async {
    final controller = TextEditingController(text: _recipeName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text('Rename Recipe',
            style: GoogleFonts.spaceMono(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.spaceMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Recipe name...',
            hintStyle: GoogleFonts.spaceMono(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF667EEA)),
            ),
          ),
          onSubmitted: (val) => Navigator.pop(ctx, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.spaceMono(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text('Save',
                style: GoogleFonts.spaceMono(color: const Color(0xFF667EEA))),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      await AppDatabase.instance
          .updateRecipeName(widget.recipe.id!, newName.trim());
      setState(() => _recipeName = newName.trim());
    }
  }

  Future<void> _openLink() async {
    if (_link == null) return;
    final uri = Uri.parse(_link!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _convertToFullRecipe() async {
    await AppDatabase.instance.updateRecipeLink(widget.recipe.id!, null);
    setState(() => _link = null);
  }

  @override
  Widget build(BuildContext context) {
    final isLink = _link != null && _link!.isNotEmpty;

    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _editRecipeName,
                        child: Text(
                          _recipeName,
                          style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content + frosted input bar
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _loading
                          ? const ShimmerPlaceholder(style: ShimmerStyle.listTile)
                          : isLink
                              ? _buildLinkView()
                              : _buildRecipeView(),
                    ),
                    if (!isLink)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: _buildInputBar(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link, size: 64, color: Colors.white.withAlpha(38)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _openLink,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.open_in_new,
                        color: Color(0xFF667EEA), size: 20),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _link!,
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF667EEA),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF667EEA),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _convertToFullRecipe,
              icon: const Icon(Icons.restaurant, size: 18),
              label: Text('Convert to full recipe',
                  style: GoogleFonts.spaceMono(fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeView() {
    if (_ingredients.isEmpty && _steps.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        if (_ingredients.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Ingredients',
              style: GoogleFonts.spaceMono(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (int i = 0; i < _ingredients.length; i++)
            AnimatedListItem(
              index: i,
              child: IngredientTile(
                ingredient: _ingredients[i],
                onDelete: () => _deleteIngredient(_ingredients[i]),
              ),
            ),
        ],
        if (_ingredients.isNotEmpty && _steps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white.withAlpha(26)),
          ),
        if (_steps.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Steps',
              style: GoogleFonts.spaceMono(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (int i = 0; i < _steps.length; i++)
            AnimatedListItem(
              index: i,
              child: StepTile(
                step: _steps[i],
                onDelete: () => _deleteStep(_steps[i]),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21).withAlpha(180),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(13)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle row
          Row(
            children: [
              _buildToggleButton(
                'Ingredient',
                _InputMode.ingredient,
                Icons.egg_outlined,
              ),
              const SizedBox(width: 8),
              _buildToggleButton(
                'Step',
                _InputMode.step,
                Icons.format_list_numbered,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  style: GoogleFonts.spaceMono(
                      color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _inputMode == _InputMode.ingredient
                        ? 'Add ingredient... (e.g. 2kg flour)'
                        : 'Add step...',
                    hintStyle: GoogleFonts.spaceMono(
                        color: Colors.white24, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    _addInput(val);
                    _inputFocusNode.requestFocus();
                  },
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                ),
                child: IconButton(
                  icon:
                      const Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: () {
                    _addInput(_inputController.text);
                    _inputFocusNode.requestFocus();
                  },
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, _InputMode mode, IconData icon) {
    final isActive = _inputMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _inputMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF667EEA).withAlpha(40)
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? const Color(0xFF667EEA)
                : Colors.white.withAlpha(13),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? const Color(0xFF667EEA) : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                color: isActive ? const Color(0xFF667EEA) : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_outlined,
              size: 48, color: Colors.white.withAlpha(38)),
          const SizedBox(height: 12),
          Text(
            'No ingredients or steps yet',
            style: GoogleFonts.spaceMono(
              color: Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use the bar below to add them',
            style: GoogleFonts.spaceMono(
              color: Colors.white24,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsedIngredient {
  final String name;
  final double? quantity;
  final String? unit;

  _ParsedIngredient({required this.name, this.quantity, this.unit});
}
