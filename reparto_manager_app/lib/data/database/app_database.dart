// lib/data/database/app_database.dart
// Capa de Datos e Infraestructura SQLite - Reparto-Manager V2
// Modularización Estricta: < 300 líneas | Funciones < 40 líneas

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'tables_schema.dart';

/// Gestor singleton de conexión a la base de datos local SQLite.
/// Soporta ejecución nativa en Android/iOS, Windows Desktop (FFI) y pruebas unitarias en memoria.
class AppDatabase {
  static const String databaseName = 'reparto_manager_v2.db';
  static AppDatabase? _instance;
  static Database? _database;

  AppDatabase._internal();

  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  /// Instancia activa de la base de datos SQLite.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos en disco o memoria.
  Future<Database> initDatabase({bool inMemory = false, String? customPath}) async {
    _configureFfiIfNeeded();

    final String path;
    if (inMemory) {
      path = inMemoryDatabasePath;
    } else if (customPath != null) {
      path = customPath;
    } else {
      path = await _resolveDatabasePath();
    }

    return await openDatabase(
      path,
      version: TablesSchema.databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  /// Configura FFI para plataformas Desktop (Windows, Linux, macOS) o pruebas de consola.
  void _configureFfiIfNeeded() {
    final bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Resuelve la ruta en disco local según la plataforma.
  Future<String> _resolveDatabasePath() async {
    if (!kIsWeb && Platform.isWindows) {
      final appDataDir = await getApplicationSupportDirectory();
      final dirPath = appDataDir.path;
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return p.join(dirPath, databaseName);
    }
    final dbFolder = await getDatabasesPath();
    return p.join(dbFolder, databaseName);
  }

  /// Habilita claves foráneas y pragmas de alto rendimiento.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  /// Crea todas las 15 tablas e índices compuestos.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final tableSql in TablesSchema.createTablesQueries) {
      batch.execute(tableSql);
    }
    for (final indexSql in TablesSchema.createIndexesQueries) {
      batch.execute(indexSql);
    }
    await batch.commit(noResult: true);
  }

  /// Cierra la conexión activa de la base de datos.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// Resetea la base de datos cerrándola y eliminando su archivo.
  Future<void> resetDatabase() async {
    await close();
    final path = await _resolveDatabasePath();
    await deleteDatabase(path);
  }
}
