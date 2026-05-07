import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/debt_model1.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database!= null) return _database!;
    _database = await _initDB('debt_book.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        paidAmount REAL NOT NULL, 
        dateBorrowed TEXT NOT NULL,
        dueDate TEXT,
        description TEXT
      )
    ''');
  }

  Future<int> insertDebt(DebtModel debt) async {
    final db = await instance.database;
    return await db.insert('debts', debt.toMap());
  }

  Future<List<DebtModel>> getDebtsByType(String type) async {
    final db = await instance.database;
    final result = await db.query(
      'debts',
      where: 'type =?',
      whereArgs: [type],
      orderBy: 'id DESC',
    );
    return result.map((map) => DebtModel.fromMap(map)).toList();
  }

  Future<double> getTotalAmount(String type) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount - paidAmount) as total FROM debts WHERE type =?',
      [type],
    );
    return (result.first['total'] as num?)?.toDouble()?? 0.0;
  }

  Future<int> deleteDebt(int id) async {
    final db = await instance.database;
    return await db.delete(
      'debts',
      where: 'id =?',
      whereArgs: [id],
    );
  }
  Future<int> updatePaidAmount(int id, double payAmount) async {
    // final db = await database;
    // return await db.rawUpdate(
    // 'UPDATE debts SET paidAmount = paidAmount + ? WHERE id = ?',
    // [payAmount, id],
    // );
    final db = await instance.database;
   final maps = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return 0; // No debt found with the given id
    final debt = DebtModel.fromMap(maps.first);
    final newPaidAmount = debt.paidAmount + payAmount;
    return await db.update(
      'debts',
      {'paidAmount': newPaidAmount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<int> addMoreDebt(int id, double moreAmount) async {
    final db = await instance.database;
    return await db.rawUpdate(
    'UPDATE debts SET amount = amount + ? WHERE id = ?',
    [moreAmount, id],
    );
  }
  Future<int> updateDebt(DebtModel debt) async {
    final db = await database;
    return await db.update(
    'debts',
    debt.toMap(),
    where: 'id = ?',
    whereArgs: [debt.id],
    );
  }
}