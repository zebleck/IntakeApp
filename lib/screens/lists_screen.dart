import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../db/database.dart';
import '../models/shopping_list.dart';
import '../widgets/list_tile_card.dart';
import 'list_detail_screen.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  List<ShoppingList> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final lists = await AppDatabase.instance.getLists();
    setState(() {
      _lists = lists;
      _loading = false;
    });
  }

  Future<void> _createList() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text('New List',
            style: GoogleFonts.spaceMono(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.spaceMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'List name...',
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
      await AppDatabase.instance.createList(name.trim());
      _loadLists();
    }
  }

  void _openList(ShoppingList list) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListDetailScreen(shoppingList: list),
      ),
    );
    _loadLists();
  }

  Future<void> _deleteList(ShoppingList list) async {
    await AppDatabase.instance.deleteList(list.id!);
    _loadLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E21), Color(0xFF0F1328)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  'intake',
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Text(
                  'Shopping Lists',
                  style: GoogleFonts.spaceMono(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF667EEA),
                        ),
                      )
                    : _lists.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _lists.length,
                            itemBuilder: (ctx, i) => ListTileCard(
                              shoppingList: _lists[i],
                              onTap: () => _openList(_lists[i]),
                              onDelete: () => _deleteList(_lists[i]),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: FloatingActionButton(
          onPressed: _createList,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: Colors.white.withAlpha(38)),
          const SizedBox(height: 16),
          Text(
            'No lists yet',
            style: GoogleFonts.spaceMono(
              color: Colors.white38,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first list',
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
