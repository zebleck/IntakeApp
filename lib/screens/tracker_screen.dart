import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../db/database.dart';
import '../models/food_entry.dart';
import '../models/daily_focus.dart';
import '../widgets/food_entry_tile.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  DateTime _selectedDate = DateTime.now();
  List<FoodEntry> _entries = [];
  DailyFocus? _focus;
  bool _loading = true;
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();

  // Optional recipe link
  int? _linkedRecipeId;
  String? _linkedRecipeName;

  // Optional custom time (null = use current time)
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Future<void> _loadData() async {
    final dateStr = _dateKey(_selectedDate);
    final entries = await AppDatabase.instance.getFoodEntries(dateStr);
    final focus = await AppDatabase.instance.getDailyFocus(dateStr);
    setState(() {
      _entries = entries;
      _focus = focus;
      _loading = false;
    });
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _loading = true;
    });
    _loadData();
  }

  void _goToNextDay() {
    if (_isToday) return;
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _loading = true;
    });
    _loadData();
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _loading = true;
    });
    _loadData();
  }

  Future<void> _setFocus(int rating) async {
    final dateStr = _dateKey(_selectedDate);
    await AppDatabase.instance.setDailyFocus(dateStr, rating);
    _loadData();
  }

  Future<void> _addFood(String input) async {
    if (input.trim().isEmpty) return;

    final parsed = _parseItemInput(input.trim());
    DateTime loggedAt;
    if (_selectedTime != null) {
      loggedAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    } else {
      loggedAt = DateTime.now();
    }
    final entry = FoodEntry(
      date: _dateKey(_selectedDate),
      name: parsed.name,
      quantity: parsed.quantity,
      unit: parsed.unit,
      loggedAt: loggedAt.toIso8601String(),
      recipeId: _linkedRecipeId,
    );

    await AppDatabase.instance.createFoodEntry(entry);
    _inputController.clear();
    setState(() {
      _linkedRecipeId = null;
      _linkedRecipeName = null;
      _selectedTime = null;
    });
    _loadData();
  }

  _ParsedItem _parseItemInput(String input) {
    final regexWithUnit = RegExp(
        r'^(\d+(?:\.\d+)?)\s*(kg|g|ml|l|pcs|oz|lb|cups?|tbsp|tsp)\s+(.+)$',
        caseSensitive: false);
    final matchWithUnit = regexWithUnit.firstMatch(input);
    if (matchWithUnit != null) {
      return _ParsedItem(
        name: matchWithUnit.group(3)!,
        quantity: double.parse(matchWithUnit.group(1)!),
        unit: matchWithUnit.group(2)!.toLowerCase(),
      );
    }

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

  Future<void> _pickTime() async {
    final initial = _selectedTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
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
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _editEntryTime(FoodEntry entry, TimeOfDay time) async {
    final dt = DateTime.parse(entry.loggedAt);
    final updated = DateTime(dt.year, dt.month, dt.day, time.hour, time.minute);
    await AppDatabase.instance.updateFoodEntryTime(
      entry.id!,
      updated.toIso8601String(),
    );
    _loadData();
  }

  Future<void> _editEntryComment(FoodEntry entry, String? comment) async {
    await AppDatabase.instance.updateFoodEntryComment(entry.id!, comment);
    _loadData();
  }

  Future<void> _deleteEntry(FoodEntry entry) async {
    await AppDatabase.instance.deleteFoodEntry(entry.id!);
    _loadData();
  }

  Future<void> _pickRecipe() async {
    final recipes = await AppDatabase.instance.getRecipes();
    if (!mounted) return;

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Link recipe',
                    style: GoogleFonts.spaceMono(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (recipes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No recipes yet',
                    style: GoogleFonts.spaceMono(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: recipes.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.menu_book,
                          color: Color(0xFF667EEA), size: 20),
                      title: Text(
                        recipes[i].name,
                        style: GoogleFonts.spaceMono(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _linkedRecipeId = recipes[i].id;
                          _linkedRecipeName = recipes[i].name;
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
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
              // Header
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
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  'Tracker',
                  style: GoogleFonts.spaceMono(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),

              // Date nav bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white54),
                      onPressed: _goToPreviousDay,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _formatDate(_selectedDate),
                          style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (!_isToday)
                      GestureDetector(
                        onTap: _goToToday,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Today',
                            style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.chevron_right,
                          color: _isToday ? Colors.white12 : Colors.white54),
                      onPressed: _isToday ? null : _goToNextDay,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF667EEA),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        children: [
                          // Focus section
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'Focus',
                              style: GoogleFonts.spaceMono(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _buildFocusRow(),
                          const SizedBox(height: 16),

                          // Food log divider
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                      color: Colors.white.withAlpha(26)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    'food log',
                                    style: GoogleFonts.spaceMono(
                                      color: Colors.white24,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                      color: Colors.white.withAlpha(26)),
                                ),
                              ],
                            ),
                          ),

                          // Food entries
                          if (_entries.isEmpty)
                            _buildEmptyState()
                          else
                            ..._entries.map((e) => FoodEntryTile(
                                  entry: e,
                                  onDelete: () => _deleteEntry(e),
                                  onTimeEdit: (time) =>
                                      _editEntryTime(e, time),
                                  onCommentEdit: (comment) =>
                                      _editEntryComment(e, comment),
                                )),
                        ],
                      ),
              ),

              // Input bar
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFocusRow() {
    final currentRating = _focus?.rating;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(10, (i) {
          final rating = i + 1;
          final isSelected = currentRating == rating;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => _setFocus(rating),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withAlpha(13),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: Center(
                  child: Text(
                    '$rating',
                    style: GoogleFonts.spaceMono(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(13)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chips row (time + recipe)
          if (_selectedTime != null || _linkedRecipeName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (_selectedTime != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedTime = null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule,
                                  color: Color(0xFF667EEA), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                _selectedTime!.format(context),
                                style: GoogleFonts.spaceMono(
                                  color: const Color(0xFF667EEA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.close,
                                  color: Color(0xFF667EEA), size: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_linkedRecipeName != null)
                    GestureDetector(
                      onTap: () => setState(() {
                        _linkedRecipeId = null;
                        _linkedRecipeName = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _linkedRecipeName!,
                              style: GoogleFonts.spaceMono(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.close,
                                color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
                    hintText: 'Add food... (e.g. 2kg chicken)',
                    hintStyle: GoogleFonts.spaceMono(
                        color: Colors.white24, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    _addFood(val);
                    _inputFocusNode.requestFocus();
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.schedule,
                  color: _selectedTime != null
                      ? const Color(0xFF667EEA)
                      : Colors.white38,
                  size: 20,
                ),
                onPressed: _pickTime,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: Icon(
                  Icons.link,
                  color: _linkedRecipeId != null
                      ? const Color(0xFF667EEA)
                      : Colors.white38,
                  size: 20,
                ),
                onPressed: _pickRecipe,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: EdgeInsets.zero,
              ),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: () {
                    _addFood(_inputController.text);
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_outlined,
                size: 48, color: Colors.white.withAlpha(38)),
            const SizedBox(height: 12),
            Text(
              'No food logged',
              style: GoogleFonts.spaceMono(
                color: Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use the bar below to add entries',
              style: GoogleFonts.spaceMono(
                color: Colors.white24,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
