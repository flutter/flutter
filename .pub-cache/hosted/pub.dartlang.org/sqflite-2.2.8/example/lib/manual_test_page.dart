import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
// ignore: implementation_imports
import 'package:sqflite/src/factory_mixin.dart' as impl;
import 'package:sqflite/utils/utils.dart';
import 'package:sqflite_example/src/item_widget.dart';
import 'package:sqflite_example/utils.dart';

// ignore_for_file: avoid_print

import 'model/item.dart';
import 'src/common_import.dart';

/// Manual test page.
class ManualTestPage extends StatefulWidget {
  /// Test page.
  const ManualTestPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ManualTestPageState createState() => _ManualTestPageState();
}

class _ManualTestPageState extends State<ManualTestPage> {
  Database? database;
  static const String dbName = 'manual_test.db';

  Future<void> showToast(String message) async {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text(message), duration: const Duration(milliseconds: 300)));
  }

  Future<Database> _openDatabase() async {
    return database ??= await databaseFactory.openDatabase(dbName);
  }

  Future _closeDatabase() async {
    await database?.close();
    database = null;
  }

  Future _deleteDatabase() async {
    await databaseFactory.deleteDatabase(dbName);
  }

  Future _incrementVersion() async {
    final version = await database!.getVersion();
    print('version $version');
    await database!.setVersion(version + 1);
  }

  late List<SqfMenuItem> items;
  late List<ItemWidget> itemWidgets;

  Future<bool> pop() async {
    return true;
  }

  Future<void> _addAndQuery({int? msDelay, bool? noSynchronized}) async {
    // await databaseFactory.debugSetLogLevel(sqfliteLogLevelVerbose);
    var db = await _openDatabase();

    // ignore: invalid_use_of_visible_for_testing_member
    db.internalsDoNotUseSynchronized = noSynchronized ?? false;
    await db.transaction((txn) async {
      await txn.execute(
          'CREATE TABLE IF NOT EXISTS Task(id INTEGER PRIMARY KEY, name TEXT)');
      await txn.execute('INSERT INTO Task(name) VALUES (?)',
          ['task ${DateTime.now().toIso8601String()}']);
      var count =
          firstIntValue(await txn.query('Task', columns: [sqlCountColumn]));
      unawaited(showToast('$count task(s)'));
      if (msDelay != null) {
        await Future<void>.delayed(Duration(milliseconds: msDelay));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    items = <SqfMenuItem>[
      SqfMenuItem('SQLite version', () async {
        final db = await openDatabase(inMemoryDatabasePath);

        final results = await db.rawQuery('select sqlite_version()');
        print('select sqlite_version(): $results');
        var version = results.first.values.first;
        print('sqlite version: $version');
        await db.close();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('select sqlite_version(): $version'),
          ));
        }
      }, summary: 'select sqlite_version()'),
      SqfMenuItem('Factory information', () async {
        var info = databaseFactory.toString();
        print('sqlite database factory: $info');
        unawaited(showToast(info));
      }, summary: 'toString()'),
      SqfMenuItem('openDatabase', () async {
        await _openDatabase();
      }, summary: 'Open the database'),
      SqfMenuItem('transaction add and query and pause', () async {
        await _addAndQuery(msDelay: 5000);
      }, summary: 'open/create table/add/query/pause'),
      SqfMenuItem('transaction add and query and pause no synchronized',
          () async {
        await _addAndQuery(msDelay: 5000, noSynchronized: true);
      }, summary: 'open/create table/add/query/pause'),
      SqfMenuItem('BEGIN EXCLUSIVE', () async {
        final db = await _openDatabase();
        await db.execute('BEGIN EXCLUSIVE');
      },
          summary:
              'Execute than exit or hot-restart the application. Open the database if needed'),
      SqfMenuItem('close', () async {
        await _closeDatabase();
      },
          summary:
              'Execute after starting then exit the app using the back button on Android and restart from the launcher.'),
      SqfMenuItem('delete', () async {
        await _deleteDatabase();
      },
          summary:
              'Try open (then optionally) delete, exit or hot-restart then delete then open'),
      SqfMenuItem('log level: none', () async {
        // ignore: deprecated_member_use
        await Sqflite.devSetOptions(
            // ignore: deprecated_member_use
            SqfliteOptions(logLevel: sqfliteLogLevelNone));
      }, summary: 'No logs'),
      SqfMenuItem('log level: sql', () async {
        // ignore: deprecated_member_use
        await Sqflite.devSetOptions(
            // ignore: deprecated_member_use
            SqfliteOptions(logLevel: sqfliteLogLevelSql));
      }, summary: 'Log sql command and basic database operation'),
      SqfMenuItem('log level: verbose', () async {
        // ignore: deprecated_member_use
        await Sqflite.devSetOptions(
            // ignore: deprecated_member_use
            SqfliteOptions(logLevel: sqfliteLogLevelVerbose));
      }, summary: 'Verbose logs, for debugging'),
      SqfMenuItem('Get info', () async {
        final factory = databaseFactory as impl.SqfliteDatabaseFactoryMixin;
        final info = await factory.getDebugInfo();
        print(info.toString());
      }, summary: 'Implementation info (dev only)'),
      SqfMenuItem('Increment version', () async {
        print(await _incrementVersion());
      }, summary: 'Implementation info (dev only)'),
      SqfMenuItem('Multiple db', () async {
        await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) {
          return const MultipleDbTestPage();
        }));
      }, summary: 'Open multiple databases'),
      ...[800000, 1500000, 15000000, 150000000]
          .map((size) => SqfMenuItem('Big blob $size', () async {
                await testBigBlog(size);
              }))
    ];
  }

  Future<void> testBigBlog(int size) async {
    // await Sqflite.devSetDebugModeOn(true);
    var db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (Database db, int version) async {
      await db
          .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value BLOB)');
    });
    try {
      var blob =
          Uint8List.fromList(List.generate(size, (index) => index % 256));
      var id = await db.insert('Test', {'value': blob});

      /// Get the value field from a given id
      Future<Uint8List> getValue(int id) async {
        return ((await db.query('Test', where: 'id = $id')).first)['value']
            as Uint8List;
      }

      var ok = (await getValue(id)).length == blob.length;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$size: $ok')));
      }
    } finally {
      await db.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    itemWidgets = items
        .map((item) => ItemWidget(
              item,
              (item) async {
                final stopwatch = Stopwatch()..start();
                final future = (item as SqfMenuItem).run();
                setState(() {});
                await future;
                // always add a small delay
                final elapsed = stopwatch.elapsedMilliseconds;
                if (elapsed < 300) {
                  await sleep(300 - elapsed);
                }
                setState(() {});
              },
              summary: item.summary,
            ))
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual tests'),
      ),
      body: WillPopScope(
        onWillPop: pop,
        child: ListView(
          children: itemWidgets,
        ),
      ),
    );
  }
}

/// Multiple db test page.
class MultipleDbTestPage extends StatelessWidget {
  /// Test page.
  const MultipleDbTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget dbTile(String name) {
      return ListTile(
        title: Text(name),
        onTap: () {
          Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) {
            return SimpleDbTestPage(
              dbName: name,
            );
          }));
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple databases'),
      ),
      body: ListView(
        children: <Widget>[
          dbTile('data1.db'),
          dbTile('data2.db'),
          dbTile('data3.db')
        ],
      ),
    );
  }
}

/// Simple db test page.
class SimpleDbTestPage extends StatefulWidget {
  /// Simple db test page.
  const SimpleDbTestPage({Key? key, required this.dbName}) : super(key: key);

  /// db name.
  final String dbName;

  @override
  // ignore: library_private_types_in_public_api
  _SimpleDbTestPageState createState() => _SimpleDbTestPageState();
}

class _SimpleDbTestPageState extends State<SimpleDbTestPage> {
  Database? database;

  Future<Database> _openDatabase() async {
    // await Sqflite.devSetOptions(SqfliteOptions(logLevel: sqfliteLogLevelVerbose));
    return database ??= await databaseFactory.openDatabase(widget.dbName,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute('CREATE TABLE Test (value TEXT)');
            }));
  }

  Future _closeDatabase() async {
    await database?.close();
    database = null;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Simple db ${widget.dbName}'),
        ),
        body: Builder(
          builder: (context) {
            Widget menuItem(String title, void Function() onTap,
                {String? summary}) {
              return ListTile(
                title: Text(title),
                subtitle: summary == null ? null : Text(summary),
                onTap: onTap,
              );
            }

            Future countRecord() async {
              final db = await _openDatabase();
              final result =
                  firstIntValue(await db.query('test', columns: ['COUNT(*)']));
              // Temp for nnbd successfull lint
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$result records'),
                  duration: const Duration(milliseconds: 700),
                ));
              }
            }

            final items = <Widget>[
              menuItem('open Database', () async {
                await _openDatabase();
              }, summary: 'Open the database'),
              menuItem('Add record', () async {
                final db = await _openDatabase();
                await db.insert('test', {'value': 'some_value'});
                await countRecord();
              }, summary: 'Add one record. Open the database if needed'),
              menuItem('Count record', () async {
                await countRecord();
              }, summary: 'Count records. Open the database if needed'),
              menuItem(
                'Close Database',
                () async {
                  await _closeDatabase();
                },
              ),
              menuItem(
                'Delete database',
                () async {
                  await databaseFactory.deleteDatabase(widget.dbName);
                },
              ),
            ];
            return ListView(
              children: items,
            );
          },
        ));
  }
}
