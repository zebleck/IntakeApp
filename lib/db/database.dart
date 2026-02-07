import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/recipe_step.dart';
import '../models/food_entry.dart';
import '../models/daily_focus.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('intake.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shopping_lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        list_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        quantity REAL,
        unit TEXT,
        is_checked INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE
      )
    ''');

    await _createRecipeTables(db);
    await _createTrackerTables(db);
  }

  Future<void> _createRecipeTables(Database db) async {
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        link TEXT,
        created_at TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE recipe_ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        quantity REAL,
        unit TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recipe_steps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        step_number INTEGER NOT NULL,
        instruction TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createTrackerTables(Database db) async {
    await db.execute('''
      CREATE TABLE food_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity REAL,
        unit TEXT,
        logged_at TEXT NOT NULL,
        recipe_id INTEGER,
        comment TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_food_entries_date ON food_entries(date)',
    );

    await db.execute('''
      CREATE TABLE daily_focus (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        rating INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createRecipeTables(db);
    }
    if (oldVersion < 3) {
      await _createTrackerTables(db);
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE food_entries ADD COLUMN comment TEXT');
    }
  }

  // --- Shopping Lists ---

  Future<List<ShoppingList>> getLists({bool includeArchived = false}) async {
    final db = await database;
    final where = includeArchived ? null : 'sl.is_archived = 0';

    final result = await db.rawQuery('''
      SELECT sl.*,
        COUNT(si.id) as item_count,
        SUM(CASE WHEN si.is_checked = 1 THEN 1 ELSE 0 END) as checked_count
      FROM shopping_lists sl
      LEFT JOIN shopping_items si ON si.list_id = sl.id
      ${where != null ? 'WHERE $where' : ''}
      GROUP BY sl.id
      ORDER BY sl.created_at DESC
    ''');

    return result.map((map) => ShoppingList.fromMap(map)).toList();
  }

  Future<ShoppingList> createList(String name) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('shopping_lists', {
      'name': name,
      'created_at': now,
      'is_archived': 0,
    });
    return ShoppingList(id: id, name: name, createdAt: now);
  }

  Future<void> updateListName(int id, String name) async {
    final db = await database;
    await db.update(
      'shopping_lists',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> archiveList(int id) async {
    final db = await database;
    await db.update(
      'shopping_lists',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteList(int id) async {
    final db = await database;
    await db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
  }

  // --- Shopping Items ---

  Future<List<ShoppingItem>> getItems(int listId) async {
    final db = await database;
    final result = await db.query(
      'shopping_items',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'is_checked ASC, sort_order ASC, id ASC',
    );
    return result.map((map) => ShoppingItem.fromMap(map)).toList();
  }

  Future<ShoppingItem> createItem(ShoppingItem item) async {
    final db = await database;

    // Get next sort_order
    final maxOrder = await db.rawQuery(
      'SELECT MAX(sort_order) as max_order FROM shopping_items WHERE list_id = ?',
      [item.listId],
    );
    final nextOrder =
        ((maxOrder.first['max_order'] as int?) ?? -1) + 1;

    final id = await db.insert('shopping_items', {
      'list_id': item.listId,
      'name': item.name,
      'quantity': item.quantity,
      'unit': item.unit,
      'is_checked': 0,
      'sort_order': nextOrder,
    });

    return ShoppingItem(
      id: id,
      listId: item.listId,
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      sortOrder: nextOrder,
    );
  }

  Future<void> toggleItem(int id, bool isChecked) async {
    final db = await database;
    await db.update(
      'shopping_items',
      {'is_checked': isChecked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateItem(ShoppingItem item) async {
    final db = await database;
    await db.update(
      'shopping_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // --- Recipes ---

  Future<List<Recipe>> getRecipes({bool includeArchived = false}) async {
    final db = await database;
    final where = includeArchived ? null : 'r.is_archived = 0';

    final result = await db.rawQuery('''
      SELECT r.*,
        COUNT(DISTINCT ri.id) as ingredient_count,
        COUNT(DISTINCT rs.id) as step_count
      FROM recipes r
      LEFT JOIN recipe_ingredients ri ON ri.recipe_id = r.id
      LEFT JOIN recipe_steps rs ON rs.recipe_id = r.id
      ${where != null ? 'WHERE $where' : ''}
      GROUP BY r.id
      ORDER BY r.created_at DESC
    ''');

    return result.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<Recipe> createRecipe(String name, {String? link}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('recipes', {
      'name': name,
      'link': link,
      'created_at': now,
      'is_archived': 0,
    });
    return Recipe(id: id, name: name, link: link, createdAt: now);
  }

  Future<void> updateRecipeName(int id, String name) async {
    final db = await database;
    await db.update(
      'recipes',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateRecipeLink(int id, String? link) async {
    final db = await database;
    await db.update(
      'recipes',
      {'link': link},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteRecipe(int id) async {
    final db = await database;
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Recipe Ingredients ---

  Future<List<RecipeIngredient>> getRecipeIngredients(int recipeId) async {
    final db = await database;
    final result = await db.query(
      'recipe_ingredients',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'sort_order ASC, id ASC',
    );
    return result.map((map) => RecipeIngredient.fromMap(map)).toList();
  }

  Future<RecipeIngredient> createRecipeIngredient(RecipeIngredient ingredient) async {
    final db = await database;

    final maxOrder = await db.rawQuery(
      'SELECT MAX(sort_order) as max_order FROM recipe_ingredients WHERE recipe_id = ?',
      [ingredient.recipeId],
    );
    final nextOrder =
        ((maxOrder.first['max_order'] as int?) ?? -1) + 1;

    final id = await db.insert('recipe_ingredients', {
      'recipe_id': ingredient.recipeId,
      'name': ingredient.name,
      'quantity': ingredient.quantity,
      'unit': ingredient.unit,
      'sort_order': nextOrder,
    });

    return RecipeIngredient(
      id: id,
      recipeId: ingredient.recipeId,
      name: ingredient.name,
      quantity: ingredient.quantity,
      unit: ingredient.unit,
      sortOrder: nextOrder,
    );
  }

  Future<void> deleteRecipeIngredient(int id) async {
    final db = await database;
    await db.delete('recipe_ingredients', where: 'id = ?', whereArgs: [id]);
  }

  // --- Recipe Steps ---

  Future<List<RecipeStep>> getRecipeSteps(int recipeId) async {
    final db = await database;
    final result = await db.query(
      'recipe_steps',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'step_number ASC',
    );
    return result.map((map) => RecipeStep.fromMap(map)).toList();
  }

  Future<RecipeStep> createRecipeStep(RecipeStep step) async {
    final db = await database;

    final maxStep = await db.rawQuery(
      'SELECT MAX(step_number) as max_step FROM recipe_steps WHERE recipe_id = ?',
      [step.recipeId],
    );
    final nextStep =
        ((maxStep.first['max_step'] as int?) ?? 0) + 1;

    final id = await db.insert('recipe_steps', {
      'recipe_id': step.recipeId,
      'step_number': nextStep,
      'instruction': step.instruction,
    });

    return RecipeStep(
      id: id,
      recipeId: step.recipeId,
      stepNumber: nextStep,
      instruction: step.instruction,
    );
  }

  Future<void> deleteRecipeStep(int id) async {
    final db = await database;
    await db.delete('recipe_steps', where: 'id = ?', whereArgs: [id]);
  }

  // --- Food Entries ---

  Future<List<FoodEntry>> getFoodEntries(String date) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT fe.*, r.name as recipe_name
      FROM food_entries fe
      LEFT JOIN recipes r ON r.id = fe.recipe_id
      WHERE fe.date = ?
      ORDER BY fe.logged_at ASC
    ''', [date]);
    return result.map((map) => FoodEntry.fromMap(map)).toList();
  }

  Future<FoodEntry> createFoodEntry(FoodEntry entry) async {
    final db = await database;
    final id = await db.insert('food_entries', entry.toMap());
    return entry.copyWith(id: id);
  }

  Future<void> deleteFoodEntry(int id) async {
    final db = await database;
    await db.delete('food_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateFoodEntryTime(int id, String loggedAt) async {
    final db = await database;
    await db.update(
      'food_entries',
      {'logged_at': loggedAt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateFoodEntryComment(int id, String? comment) async {
    final db = await database;
    await db.update(
      'food_entries',
      {'comment': comment},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateFoodEntryName(int id, String name) async {
    final db = await database;
    await db.update(
      'food_entries',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Daily Focus ---

  Future<DailyFocus?> getDailyFocus(String date) async {
    final db = await database;
    final result = await db.query(
      'daily_focus',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (result.isEmpty) return null;
    return DailyFocus.fromMap(result.first);
  }

  Future<void> setDailyFocus(String date, int rating) async {
    final db = await database;
    await db.insert(
      'daily_focus',
      {'date': date, 'rating': rating},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
