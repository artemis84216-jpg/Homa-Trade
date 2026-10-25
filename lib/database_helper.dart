import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('homa_trade.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE terms (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT, category TEXT, image_path TEXT, created_at TEXT)');
    await db.execute('CREATE TABLE strategies (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, category TEXT, description TEXT, entry_conditions TEXT, exit_conditions TEXT, stop_loss TEXT, take_profit TEXT, tools TEXT, image_path TEXT, created_at TEXT)');
    await db.execute('CREATE TABLE compound_plans (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, initial_capital REAL, daily_target_percent REAL, total_days INTEGER, predicted_date TEXT, achieved_date TEXT, notes TEXT, created_at TEXT)');
    await db.execute('CREATE TABLE compound_days (id INTEGER PRIMARY KEY AUTOINCREMENT, plan_id INTEGER, day_number INTEGER, target_amount REAL, achieved INTEGER DEFAULT 0, actual_amount REAL, date TEXT, notes TEXT)');
    await db.execute('CREATE TABLE backtests (id INTEGER PRIMARY KEY AUTOINCREMENT, strategy_name TEXT, symbol TEXT, timeframe TEXT, start_date TEXT, end_date TEXT, result TEXT, risk_reward REAL, emotion TEXT, notes TEXT, image_path TEXT, created_at TEXT)');
    await db.execute('CREATE TABLE broker_accounts (id INTEGER PRIMARY KEY AUTOINCREMENT, broker_name TEXT NOT NULL, account_type TEXT, username TEXT, password TEXT, login_url TEXT, balance REAL, notes TEXT, created_at TEXT)');
    await db.execute('CREATE TABLE watchlist (id INTEGER PRIMARY KEY AUTOINCREMENT, symbol TEXT NOT NULL, reason TEXT, target_price REAL, stop_price REAL, notes TEXT, is_active INTEGER DEFAULT 1, created_at TEXT)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE compound_plans ADD COLUMN predicted_date TEXT');
      await db.execute('ALTER TABLE compound_plans ADD COLUMN achieved_date TEXT');
    }
  }

  // ===== متدهای Terms =====
  Future<int> insertTerm(Map<String, dynamic> t) async { final db = await instance.database; return await db.insert('terms', t); }
  Future<List<Map<String, dynamic>>> getAllTerms() async { final db = await instance.database; return await db.query('terms', orderBy: 'id DESC'); }
  Future<int> updateTerm(int id, Map<String, dynamic> t) async { final db = await instance.database; return await db.update('terms', t, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteTerm(int id) async { final db = await instance.database; return await db.delete('terms', where: 'id = ?', whereArgs: [id]); }

  // ===== متدهای Strategies =====
  Future<int> insertStrategy(Map<String, dynamic> s) async { final db = await instance.database; return await db.insert('strategies', s); }
  Future<List<Map<String, dynamic>>> getAllStrategies() async { final db = await instance.database; return await db.query('strategies', orderBy: 'id DESC'); }
  Future<int> updateStrategy(int id, Map<String, dynamic> s) async { final db = await instance.database; return await db.update('strategies', s, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteStrategy(int id) async { final db = await instance.database; return await db.delete('strategies', where: 'id = ?', whereArgs: [id]); }

  // ===== متدهای Compound =====
  Future<int> insertCompoundPlan(Map<String, dynamic> p) async { final db = await instance.database; return await db.insert('compound_plans', p); }
  Future<List<Map<String, dynamic>>> getAllCompoundPlans() async { final db = await instance.database; return await db.query('compound_plans', orderBy: 'id DESC'); }
  Future<int> updateCompoundPlan(int id, Map<String, dynamic> p) async { final db = await instance.database; return await db.update('compound_plans', p, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteCompoundPlan(int id) async { final db = await instance.database; return await db.delete('compound_plans', where: 'id = ?', whereArgs: [id]); }
  Future<int> insertCompoundDay(Map<String, dynamic> d) async { final db = await instance.database; return await db.insert('compound_days', d); }
  Future<List<Map<String, dynamic>>> getCompoundDaysByPlan(int planId) async { final db = await instance.database; return await db.query('compound_days', where: 'plan_id = ?', whereArgs: [planId], orderBy: 'day_number ASC'); }
  Future<int> updateCompoundDay(int id, Map<String, dynamic> d) async { final db = await instance.database; return await db.update('compound_days', d, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteCompoundDay(int id) async { final db = await instance.database; return await db.delete('compound_days', where: 'id = ?', whereArgs: [id]); }

  // ===== متدهای Backtests =====
  Future<int> insertBacktest(Map<String, dynamic> b) async { final db = await instance.database; return await db.insert('backtests', b); }
  Future<List<Map<String, dynamic>>> getAllBacktests() async { final db = await instance.database; return await db.query('backtests', orderBy: 'id DESC'); }
  Future<int> updateBacktest(int id, Map<String, dynamic> b) async { final db = await instance.database; return await db.update('backtests', b, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteBacktest(int id) async { final db = await instance.database; return await db.delete('backtests', where: 'id = ?', whereArgs: [id]); }

  // ===== متدهای Brokers =====
  Future<int> insertBrokerAccount(Map<String, dynamic> a) async { final db = await instance.database; return await db.insert('broker_accounts', a); }
  Future<List<Map<String, dynamic>>> getAllBrokerAccounts() async { final db = await instance.database; return await db.query('broker_accounts', orderBy: 'id DESC'); }
  Future<int> updateBrokerAccount(int id, Map<String, dynamic> a) async { final db = await instance.database; return await db.update('broker_accounts', a, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteBrokerAccount(int id) async { final db = await instance.database; return await db.delete('broker_accounts', where: 'id = ?', whereArgs: [id]); }

  // ===== متدهای Watchlist =====
  Future<int> insertWatchlist(Map<String, dynamic> w) async { final db = await instance.database; return await db.insert('watchlist', w); }
  Future<List<Map<String, dynamic>>> getAllWatchlist() async { final db = await instance.database; return await db.query('watchlist', where: 'is_active = 1', orderBy: 'id DESC'); }
  Future<int> updateWatchlist(int id, Map<String, dynamic> w) async { final db = await instance.database; return await db.update('watchlist', w, where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteWatchlist(int id) async { final db = await instance.database; return await db.delete('watchlist', where: 'id = ?', whereArgs: [id]); }

  // ===== Reset =====
  Future<void> resetDatabase() async {
    final db = await instance.database;
    await db.delete('terms'); await db.delete('strategies'); await db.delete('compound_plans');
    await db.delete('compound_days'); await db.delete('backtests'); await db.delete('broker_accounts');
    await db.delete('watchlist');
  }
}