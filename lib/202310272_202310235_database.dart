import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseInitialization {
  static final DatabaseInitialization instance =
      DatabaseInitialization._internal();

  static Database? _db;

  DatabaseInitialization._internal();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  // abrir o banco, mas não cria tabelas
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('sqflite não funciona na web');
    }

    String path;
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    path = join(documentsDirectory.path, "202310272_202310235.db");

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit(); // inicializa FFI
      databaseFactory = databaseFactoryFfi;

      return await databaseFactory.openDatabase(path);
    }

    // mobile
    return await openDatabase(path);
  }

  // criar o banco 
  Future<void> createDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('sqflite não funciona na web');
    }

    String path;
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    path = join(documentsDirectory.path, "202310272_202310235.db");

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
    } else {
      await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    }
  }

  // criação das tabelas
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tarefas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descricao TEXT,
        prioridade INTEGER,
        criadoEm TEXT,
        nivelAcesso INTEGER NOT NULL
      )
    ''');
  }

  // inserir 
  Future<int> inserirTarefa(Map<String, dynamic> tarefa) async {
    Database dbClient = await db;
    return await dbClient.insert('tarefas', tarefa);
  }

  // listar 
  Future<List<Map<String, dynamic>>> listarTarefas() async {
    Database dbClient = await db;
    return await dbClient.query('tarefas', orderBy: "prioridade DESC, id DESC");
  }

  // editar 
  Future<int> editarTarefa(int id, Map<String, dynamic> tarefa, int usuarioNivel) async {
    if (usuarioNivel != 1) return 0;

    Database dbClient = await db;
    return await dbClient.update(
      'tarefas',
      tarefa,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // excluir 
  Future<int> excluirTarefa(int id, int usuarioNivel) async {
    if (usuarioNivel != 1) return 0;

    Database dbClient = await db;
    return await dbClient.delete(
      'tarefas',
      where: "id = ?",
      whereArgs: [id],
    );
  }
}
