import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../db/database.dart';
import '../models/recipe.dart';
import '../services/gemini_service.dart';
import '../widgets/recipe_tile_card.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/animated_gradient_background.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Recipe> _recipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final recipes = await AppDatabase.instance.getRecipes();
    setState(() {
      _recipes = recipes;
      _loading = false;
    });
  }

  Future<void> _showCreateOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.restaurant, color: Color(0xFF667EEA)),
                title: Text('New Recipe',
                    style: GoogleFonts.spaceMono(color: Colors.white)),
                subtitle: Text('With ingredients & steps',
                    style: GoogleFonts.spaceMono(
                        color: Colors.white38, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _createRecipe();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: Color(0xFF764BA2)),
                title: Text('Save Link',
                    style: GoogleFonts.spaceMono(color: Colors.white)),
                subtitle: Text('Bookmark a recipe URL',
                    style: GoogleFonts.spaceMono(
                        color: Colors.white38, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _createLinkRecipe();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createRecipe() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text('New Recipe',
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
            child: Text('Create',
                style: GoogleFonts.spaceMono(color: const Color(0xFF667EEA))),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      final recipe = await AppDatabase.instance.createRecipe(name.trim());
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: recipe),
          ),
        );
        _loadRecipes();
      }
    }
  }

  Future<void> _createLinkRecipe() async {
    final nameController = TextEditingController();
    final linkController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        bool isExtracting = false;
        String? errorText;

        Future<void> extractUrlFromCamera(StateSetter setLocalState) async {
          setLocalState(() {
            isExtracting = true;
            errorText = null;
          });
          try {
            final image = await ImagePicker()
                .pickImage(source: ImageSource.camera);
            if (image == null) {
              setLocalState(() => isExtracting = false);
              return;
            }
            final bytes = await image.readAsBytes();
            final url = await GeminiService.extractUrlFromImage(bytes);
            if (url != null) {
              linkController.text = url;
              setLocalState(() => isExtracting = false);
            } else {
              setLocalState(() {
                isExtracting = false;
                errorText = 'No URL found in image';
              });
            }
          } catch (e) {
            setLocalState(() {
              isExtracting = false;
              errorText = e.toString();
            });
          }
        }

        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            title: Text('Save Link',
                style: GoogleFonts.spaceMono(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: GoogleFonts.spaceMono(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Name...',
                    hintStyle: GoogleFonts.spaceMono(color: Colors.white38),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF667EEA)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: linkController,
                        style: GoogleFonts.spaceMono(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'URL...',
                          hintStyle:
                              GoogleFonts.spaceMono(color: Colors.white38),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF667EEA)),
                          ),
                        ),
                        onSubmitted: (val) => Navigator.pop(ctx, {
                          'name': nameController.text,
                          'link': val,
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isExtracting)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF764BA2),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        color: const Color(0xFF764BA2),
                        onPressed: () => extractUrlFromCamera(setLocalState),
                      ),
                  ],
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorText!,
                      style: GoogleFonts.spaceMono(
                        color: Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.spaceMono(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, {
                  'name': nameController.text,
                  'link': linkController.text,
                }),
                child: Text('Save',
                    style: GoogleFonts.spaceMono(
                        color: const Color(0xFF667EEA))),
              ),
            ],
          ),
        );
      },
    );

    if (result != null &&
        result['name']!.trim().isNotEmpty &&
        result['link']!.trim().isNotEmpty) {
      await AppDatabase.instance.createRecipe(
        result['name']!.trim(),
        link: result['link']!.trim(),
      );
      _loadRecipes();
    }
  }

  void _openRecipe(Recipe recipe) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: recipe),
      ),
    );
    _loadRecipes();
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    await AppDatabase.instance.deleteRecipe(recipe.id!);
    _loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ).createShader(bounds),
                  child: Text(
                    'intake',
                    style: GoogleFonts.spaceMono(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Text(
                  'Recipes',
                  style: GoogleFonts.spaceMono(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const ShimmerPlaceholder(style: ShimmerStyle.card)
                    : _recipes.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                            itemCount: _recipes.length,
                            itemBuilder: (ctx, i) => AnimatedListItem(
                              index: i,
                              child: RecipeTileCard(
                                recipe: _recipes[i],
                                onTap: () => _openRecipe(_recipes[i]),
                                onDelete: () => _deleteRecipe(_recipes[i]),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
          child: FloatingActionButton(
            onPressed: _showCreateOptions,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined,
              size: 64, color: Colors.white.withAlpha(38)),
          const SizedBox(height: 16),
          Text(
            'No recipes yet',
            style: GoogleFonts.spaceMono(
              color: Colors.white38,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first recipe',
            style: GoogleFonts.spaceMono(
              color: Colors.white24,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
