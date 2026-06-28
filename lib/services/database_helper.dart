import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../models/debt_model1.dart';
import '../models/debt_history_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const String _databaseFileName = 'debt_book.db';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database!= null) return _database!;
    _database = await _initDB('debt_book.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<String> get databaseFilePath async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _databaseFileName);
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
        description TEXT,
        photoPath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE debt_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debtId INTEGER NOT NULL,
        action TEXT NOT NULL,
        amount REAL,
        balanceAfter REAL,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE debts ADD COLUMN photoPath TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debt_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          debtId INTEGER NOT NULL,
          action TEXT NOT NULL,
          amount REAL,
          balanceAfter REAL,
          note TEXT,
          createdAt TEXT NOT NULL
        )
      ''');

      final debts = await db.query('debts');
      for (final row in debts) {
        final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
        final paidAmount = (row['paidAmount'] as num?)?.toDouble() ?? 0.0;
        await db.insert('debt_history', {
          'debtId': row['id'],
          'action': 'Created',
          'amount': amount,
          'balanceAfter': amount - paidAmount,
          'note': row['description'],
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<int> insertDebt(DebtModel debt) async {
    final db = await instance.database;
    final debtId = await db.insert('debts', debt.toMap());
    await _insertHistory(
      db,
      debtId: debtId,
      action: 'Created',
      amount: debt.amount,
      balanceAfter: debt.amount - debt.paidAmount,
      note: debt.description,
    );
    return debtId;
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
  Future<int> updatePaidAmount(
    int id,
    double payAmount, {
    String? note,
  }) async {
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
    final result = await db.update(
      'debts',
      {'paidAmount': newPaidAmount},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _insertHistory(
      db,
      debtId: id,
      action: 'Payment',
      amount: payAmount,
      balanceAfter: debt.amount - newPaidAmount,
      note: note,
    );
    return result;
  }
  Future<int> addMoreDebt(int id, double moreAmount) async {
    final db = await instance.database;
    final maps = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return 0;

    final debt = DebtModel.fromMap(maps.first);
    final result = await db.rawUpdate(
    'UPDATE debts SET amount = amount + ? WHERE id = ?',
    [moreAmount, id],
    );
    await _insertHistory(
      db,
      debtId: id,
      action: 'Added More',
      amount: moreAmount,
      balanceAfter: (debt.amount + moreAmount) - debt.paidAmount,
      note: 'Debt amount increased',
    );
    return result;
  }
  Future<int> updateDebt(DebtModel debt) async {
    final db = await database;
    final result = await db.update(
    'debts',
    debt.toMap(),
    where: 'id = ?',
    whereArgs: [debt.id],
    );
    if (debt.id != null) {
      await _insertHistory(
        db,
        debtId: debt.id!,
        action: 'Updated',
        amount: debt.amount,
        balanceAfter: debt.amount - debt.paidAmount,
        note: 'Debt details updated',
      );
    }
    return result;
  }

  Future<List<DebtHistoryEntry>> getDebtHistory(int debtId) async {
    final db = await instance.database;
    final result = await db.query(
      'debt_history',
      where: 'debtId = ?',
      whereArgs: [debtId],
      orderBy: 'datetime(createdAt) DESC, id DESC',
    );
    return result.map(DebtHistoryEntry.fromMap).toList();
  }

  Future<void> _insertHistory(
    Database db, {
    required int debtId,
    required String action,
    double? amount,
    double? balanceAfter,
    String? note,
  }) async {
    await db.insert('debt_history', {
      'debtId': debtId,
      'action': action,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'note': note,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db == null) return;
    await db.close();
    _database = null;
  }

  Future<String> backupDatabaseToFile(String destinationPath) async {
    final sourcePath = await databaseFilePath;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Database file not found');
    }

    final destinationFile = File(destinationPath);
    await destinationFile.create(recursive: true);
    await sourceFile.copy(destinationFile.path);
    return destinationFile.path;
  }

  Future<String> restoreDatabaseFromFile(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Backup file not found');
    }

    await closeDatabase();

    final destinationPath = await databaseFilePath;
    final destinationFile = File(destinationPath);
    if (await destinationFile.exists()) {
      await destinationFile.delete();
    }

    await sourceFile.copy(destinationPath);
    return destinationPath;
  }
}