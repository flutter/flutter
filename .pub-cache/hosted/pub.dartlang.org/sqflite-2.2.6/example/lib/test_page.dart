import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sqflite_example/src/common_import.dart';
import 'package:sqflite_example/src/expect.dart';

import 'model/item.dart';
import 'model/test.dart';
import 'src/item_widget.dart';

export 'package:matcher/matcher.dart';
export 'package:sqflite_example/database/database.dart';

export 'src/expect.dart' show expect, fail;
// ignore_for_file: avoid_print

/// Base test page.
class TestPage extends StatefulWidget {
  /// Base test page.
  TestPage(this.title, {Key? key}) : super(key: key);

  /// The title.
  final String title;

  /// Test list.
  final List<Test> tests = [];

  /// define a test.
  void test(String name, FutureOr Function() fn) {
    tests.add(Test(name, fn));
  }

  /// define a solo test.
  @Deprecated('SOLO_TEST - On purpose to remove before checkin')
  // ignore: non_constant_identifier_names
  void solo_test(String name, FutureOr Function() fn) {
    tests.add(Test(name, fn, solo: true));
  }

  /// skip a test.
  @Deprecated('SKIP_TEST - On purpose to remove before checkin')
  // ignore: non_constant_identifier_names
  void skip_test(String name, FutureOr Function() fn) {
    tests.add(Test(name, fn, skip: true));
  }

  /// Thrown an exception
  void fail([String? message]) {
    throw Exception(message ?? 'should fail');
  }

  @override
  // ignore: library_private_types_in_public_api
  _TestPageState createState() => _TestPageState();
}

/// Verify a condition.
bool? verify(bool? condition, [String? message]) {
  message ??= 'verify failed';
  expect(condition, true, reason: message);
  /*
  if (condition == null) {
    throw new Exception(''$message' null condition');
  }
  if (!condition) {
    throw new Exception(''$message'');
  }
  */
  return condition;
}

/// Group.
abstract class Group {
  /// List of tests.
  List<Test> get tests;

  bool? _hasSolo;
  final _tests = <Test>[];

  /// Add a test.
  void add(Test test) {
    if (!test.skip) {
      if (test.solo) {
        if (_hasSolo != true) {
          _hasSolo = true;
          _tests.clear();
        }
        _tests.add(test);
      } else if (_hasSolo != true) {
        _tests.add(test);
      }
    }
  }

  /// true if it has solo or contains item with solo feature
  bool? get hasSolo => _hasSolo;
}

class _TestPageState extends State<TestPage> with Group {
  int get _itemCount => items.length;

  List<Item> items = [];

  Future _run() async {
    if (!mounted) {
      return null;
    }

    setState(() {
      items.clear();
    });
    _tests.clear();
    for (var test in widget.tests) {
      add(test);
    }
    for (var test in _tests) {
      var item = Item(test.name);

      late int position;
      setState(() {
        position = items.length;
        items.add(item);
      });
      try {
        await test.fn();

        item = Item(test.name)..state = ItemState.success;
      } catch (e, st) {
        print(e);
        print(st);
        item = Item(test.name)..state = ItemState.failure;
      }

      if (!mounted) {
        return null;
      }

      setState(() {
        items[position] = item;
      });
    }
  }

  Future _runTest(int index) async {
    if (!mounted) {
      return null;
    }

    final test = _tests[index];

    var item = items[index];
    setState(() {
      item.state = ItemState.running;
    });
    try {
      print('TEST Running ${test.name}');
      await test.fn();
      print('TEST Done ${test.name}');

      item = Item(test.name)..state = ItemState.success;
    } catch (e, st) {
      print('TEST Error $e running ${test.name}');
      try {
        print(st);
      } catch (_) {}
      item = Item(test.name)..state = ItemState.failure;
    }

    if (!mounted) {
      return null;
    }

    setState(() {
      items[index] = item;
    });
  }

  @override
  void initState() {
    super.initState();
    /*
    setState(() {
      _itemCount = 3;
    });
    */
    _run();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title), actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Run again',
            onPressed: _run,
          ),
        ]),
        body:
            ListView.builder(itemBuilder: _itemBuilder, itemCount: _itemCount));
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final item = getItem(index);
    return ItemWidget(item, (Item item) {
      //Navigator.of(context).pushNamed(item.route);
      _runTest(index);
    });
  }

  Item getItem(int index) {
    return items[index];
  }

  @override
  List<Test> get tests => widget.tests;
}
