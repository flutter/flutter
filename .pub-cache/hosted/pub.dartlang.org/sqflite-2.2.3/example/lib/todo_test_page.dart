import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'test_page.dart';

/// `todo` table name
const String tableTodo = 'todo';

/// id column name
const String columnId = '_id';

/// title column name
const String columnTitle = 'title';

/// done column name
const String columnDone = 'done';

/// Todo model.
class Todo {
  /// Todo model.
  Todo();

  /// Read from a record.
  Todo.fromMap(Map map) {
    id = map[columnId] as int?;
    title = map[columnTitle] as String?;
    done = map[columnDone] == 1;
  }

  /// id.
  int? id;

  /// title.
  String? title;

  /// done.
  bool? done;

  /// Convert to a record.
  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      columnTitle: title,
      columnDone: done == true ? 1 : 0
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }
}

/// Todo provider.
class TodoProvider {
  /// The database when opened.
  late Database db;

  /// Open the database.
  Future open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
create table $tableTodo ( 
  $columnId integer primary key autoincrement, 
  $columnTitle text not null,
  $columnDone integer not null)
''');
    });
  }

  /// Insert a todo.
  Future<Todo> insert(Todo todo) async {
    todo.id = await db.insert(tableTodo, todo.toMap());
    return todo;
  }

  /// Get a todo.
  Future<Todo?> getTodo(int id) async {
    final List<Map> maps = await db.query(tableTodo,
        columns: [columnId, columnDone, columnTitle],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Todo.fromMap(maps.first);
    }
    return null;
  }

  /// Delete a todo.
  Future<int> delete(int id) async {
    return await db.delete(tableTodo, where: '$columnId = ?', whereArgs: [id]);
  }

  /// Update a todo.
  Future<int> update(Todo todo) async {
    return await db.update(tableTodo, todo.toMap(),
        where: '$columnId = ?', whereArgs: [todo.id!]);
  }

  /// Close database.
  Future close() async => db.close();
}

/// Todo test page.
class TodoTestPage extends TestPage {
  /// Todo test page.
  TodoTestPage({Key? key}) : super('Todo example', key: key) {
    test('open', () async {
      // await Sqflite.devSetDebugModeOn(true);
      final path = await initDeleteDb('simple_todo_open.db');
      final todoProvider = TodoProvider();
      await todoProvider.open(path);

      await todoProvider.close();
      //await Sqflite.setDebugModeOn(false);
    });

    test('insert/query/update/delete', () async {
      // await Sqflite.devSetDebugModeOn();
      final path = await initDeleteDb('simple_todo.db');
      final todoProvider = TodoProvider();
      await todoProvider.open(path);

      var todo = Todo()..title = 'test';
      await todoProvider.insert(todo);
      expect(todo.id, 1);

      expect(await todoProvider.getTodo(0), null);
      todo = (await todoProvider.getTodo(1))!;
      expect(todo.id, 1);
      expect(todo.title, 'test');
      expect(todo.done, false);

      todo.done = true;
      expect(await todoProvider.update(todo), 1);
      todo = (await todoProvider.getTodo(1))!;
      expect(todo.id, 1);
      expect(todo.title, 'test');
      expect(todo.done, true);

      expect(await todoProvider.delete(0), 0);
      expect(await todoProvider.delete(1), 1);
      expect(await todoProvider.getTodo(1), null);

      await todoProvider.close();
      //await Sqflite.setDebugModeOn(false);
    });
  }
}
