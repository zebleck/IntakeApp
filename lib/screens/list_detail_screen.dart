import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../db/database.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../widgets/item_tile.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/shimmer_placeholder.dart';
import '../widgets/animated_gradient_background.dart';

class ListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ListDetailScreen({super.key, required this.shoppingList});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  late String _listName;
  List<ShoppingItem> _items = [];
  bool _loading = true;
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _listName = widget.shoppingList.name;
    _loadItems();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items =
        await AppDatabase.instance.getItems(widget.shoppingList.id!);
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _addItem(String input) async {
    if (input.trim().isEmpty) return;
    HapticFeedback.lightImpact();

    final parsed = _parseItemInput(input.trim());
    final item = ShoppingItem(
      listId: widget.shoppingList.id!,
      name: parsed.name,
      quantity: parsed.quantity,
      unit: parsed.unit,
    );

    await AppDatabase.instance.createItem(item);
    _inputController.clear();
    _loadItems();
  }

  _ParsedItem _parseItemInput(String input) {
    // Try to match patterns like "2kg rice", "3 pcs eggs", "500ml milk", "2 apples"
    final regexWithUnit =
        RegExp(r'^(\d+(?:\.\d+)?)\s*(kg|g|ml|l|pcs|oz|lb|cups?|tbsp|tsp)\s+(.+)$', caseSensitive: false);
    final matchWithUnit = regexWithUnit.firstMatch(input);
    if (matchWithUnit != null) {
      return _ParsedItem(
        name: matchWithUnit.group(3)!,
        quantity: double.parse(matchWithUnit.group(1)!),
        unit: matchWithUnit.group(2)!.toLowerCase(),
      );
    }

    // Match "2 apples" (number + space + name, no unit)
    final regexQtyOnly = RegExp(r'^(\d+(?:\.\d+)?)\s+(.+)$');
    final matchQtyOnly = regexQtyOnly.firstMatch(input);
    if (matchQtyOnly != null) {
      return _ParsedItem(
        name: matchQtyOnly.group(2)!,
        quantity: double.parse(matchQtyOnly.group(1)!),
        unit: null,
      );
    }

    return _ParsedItem(name: input, quantity: null, unit: null);
  }

  Future<void> _toggleItem(ShoppingItem item, bool checked) async {
    await AppDatabase.instance.toggleItem(item.id!, checked);
    _loadItems();
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    HapticFeedback.mediumImpact();
    await AppDatabase.instance.deleteItem(item.id!);
    _loadItems();
  }

  Future<void> _editListName() async {
    final controller = TextEditingController(text: _listName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: Text('Rename List',
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
            child: Text('Save',
                style: GoogleFonts.spaceMono(color: const Color(0xFF667EEA))),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      await AppDatabase.instance
          .updateListName(widget.shoppingList.id!, newName.trim());
      setState(() => _listName = newName.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final unchecked = _items.where((i) => !i.isChecked).toList();
    final checked = _items.where((i) => i.isChecked).toList();

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
                        onTap: _editListName,
                        child: Text(
                          _listName,
                          style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_items.isNotEmpty)
                      Text(
                        '${checked.length}/${_items.length}',
                        style: GoogleFonts.spaceMono(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),

              // Items list + frosted input bar
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _loading
                          ? const ShimmerPlaceholder(style: ShimmerStyle.listTile)
                          : _items.isEmpty
                              ? _buildEmptyState()
                              : ListView(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                                  children: [
                                    for (int i = 0; i < unchecked.length; i++)
                                      AnimatedListItem(
                                        index: i,
                                        child: ItemTile(
                                          item: unchecked[i],
                                          onToggle: (val) => _toggleItem(unchecked[i], val),
                                          onDelete: () => _deleteItem(unchecked[i]),
                                        ),
                                      ),
                                    if (checked.isNotEmpty && unchecked.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Divider(
                                                  color:
                                                      Colors.white.withAlpha(26)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12),
                                              child: Text(
                                                'done',
                                                style: GoogleFonts.spaceMono(
                                                  color: Colors.white24,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                  color:
                                                      Colors.white.withAlpha(26)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    for (int i = 0; i < checked.length; i++)
                                      AnimatedListItem(
                                        index: unchecked.length + i,
                                        child: ItemTile(
                                          item: checked[i],
                                          onToggle: (val) => _toggleItem(checked[i], val),
                                          onDelete: () => _deleteItem(checked[i]),
                                        ),
                                      ),
                                  ],
                                ),
                    ),
                    // Frosted glass input bar
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0E21).withAlpha(180),
                              border: Border(
                                top: BorderSide(color: Colors.white.withAlpha(13)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _inputController,
                                    focusNode: _inputFocusNode,
                                    style: GoogleFonts.spaceMono(
                                        color: Colors.white, fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: 'Add item... (e.g. 2kg rice)',
                                      hintStyle: GoogleFonts.spaceMono(
                                          color: Colors.white24, fontSize: 13),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                    onSubmitted: (val) {
                                      _addItem(val);
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
                                      _addItem(_inputController.text);
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
                          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist_outlined,
              size: 48, color: Colors.white.withAlpha(38)),
          const SizedBox(height: 12),
          Text(
            'No items yet',
            style: GoogleFonts.spaceMono(
              color: Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Type below to add items',
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

class _ParsedItem {
  final String name;
  final double? quantity;
  final String? unit;

  _ParsedItem({required this.name, this.quantity, this.unit});
}
