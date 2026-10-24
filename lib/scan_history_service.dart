
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ScanHistoryService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();

    _database = await openDatabase(
      join(dbPath, 'agro_care_history.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scan_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            crop TEXT NOT NULL,
            disease TEXT NOT NULL,
            confidence REAL NOT NULL,
            image BLOB,
            advisory TEXT,
            scanned_at TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<int> saveScan({
    required String crop,
    required String disease,
    required double confidence,
    required List<int> imageBytes,
    required Map<String, dynamic>? advisory,
  }) async {
    final db = await database;

    return db.insert('scan_history', {
      'crop': crop,
      'disease': disease,
      'confidence': confidence,
      'image': imageBytes,
      'advisory': advisory == null ? null : jsonEncode(advisory),
      'scanned_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;

    return db.query(
      'scan_history',
      orderBy: 'scanned_at DESC',
    );
  }

  Future<int> deleteScan(int id) async {
    final db = await database;

    return db.delete(
      'scan_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
