// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../bin/material_cupertino_migration.dart' as migration;

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('material_cupertino_migration_test.');
    Directory('${tempDir.path}/lib').createSync(recursive: true);
    File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: migration_test

dependencies:
  flutter:
    sdk: flutter
''');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('rewrites umbrella Material imports and adds widgets import', () {
    final file = File('${tempDir.path}/lib/main.dart')
      ..writeAsStringSync('''
import 'package:flutter/material.dart';

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: Text('Hello')));
  }
}
''');

    final migration.MigrationResult result = migration.migratePaths(<String>[tempDir.path]);

    expect(result.changedDartFiles, 1);
    expect(result.changedPubspecs, 1);
    expect(file.readAsStringSync(), '''
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart';

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: Text('Hello')));
  }
}
''');
    expect(
      File('${tempDir.path}/pubspec.yaml').readAsStringSync(),
      contains('  material_ui: any\n'),
    );
  });

  test('splits show combinators between widgets and design packages', () {
    final file = File('${tempDir.path}/lib/show_case.dart')
      ..writeAsStringSync('''
import 'package:flutter/cupertino.dart'
    show BuildContext, CupertinoPageScaffold, StatelessWidget, Text, Widget;

class ShowCase extends StatelessWidget {
  const ShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(child: Text('Hello'));
  }
}
''');

    final migration.MigrationResult result = migration.migratePaths(<String>[tempDir.path]);

    expect(result.changedDartFiles, 1);
    expect(result.changedPubspecs, 1);
    expect(file.readAsStringSync(), '''
import 'package:flutter/widgets.dart'
    show BuildContext, StatelessWidget, Text, Widget;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageScaffold;

class ShowCase extends StatelessWidget {
  const ShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(child: Text('Hello'));
  }
}
''');
    expect(
      File('${tempDir.path}/pubspec.yaml').readAsStringSync(),
      contains('  cupertino_ui: any\n'),
    );
  });

  test('includes framework usage from part files', () {
    final owner = File('${tempDir.path}/lib/owner.dart')
      ..writeAsStringSync('''
import 'package:flutter/cupertino.dart';

part 'child.dart';

class Owner extends StatelessWidget {
  const Owner({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(child: Child());
  }
}
''');
    File('${tempDir.path}/lib/child.dart').writeAsStringSync('''
part of 'owner.dart';

class Child extends StatelessWidget {
  const Child({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('part');
  }
}
''');

    final migration.MigrationResult result = migration.migratePaths(<String>[tempDir.path]);

    expect(result.changedDartFiles, 1);
    expect(result.changedPubspecs, 1);
    expect(owner.readAsStringSync(), '''
import 'package:flutter/widgets.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

part 'child.dart';

class Owner extends StatelessWidget {
  const Owner({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(child: Child());
  }
}
''');
  });

  test('adds missing widgets symbols when an existing widgets import is restrictive', () {
    final file = File('${tempDir.path}/lib/restrictive_widgets.dart')
      ..writeAsStringSync('''
import 'package:flutter/widgets.dart' show Text;
import 'package:flutter/material.dart';

class RestrictiveWidgets extends StatelessWidget {
  const RestrictiveWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Text('Hello'));
  }
}
''');

    final migration.MigrationResult result = migration.migratePaths(<String>[tempDir.path]);

    expect(result.changedDartFiles, 1);
    expect(file.readAsStringSync(), '''
import 'package:flutter/widgets.dart' show Text;
import 'package:flutter/widgets.dart'
    show BuildContext, StatelessWidget, Widget;
import 'package:material_ui/material_ui.dart';

class RestrictiveWidgets extends StatelessWidget {
  const RestrictiveWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Text('Hello'));
  }
}
''');
  });

  test('adds a prefixed widgets import when prefixed framework symbols are used', () {
    final file = File('${tempDir.path}/lib/prefixed.dart')
      ..writeAsStringSync('''
import 'package:flutter/material.dart' as m;

class Prefixed extends m.StatelessWidget {
  const Prefixed({super.key});

  @override
  m.Widget build(m.BuildContext context) {
    return const m.MaterialApp(home: m.Text('Hello'));
  }
}
''');

    final migration.MigrationResult result = migration.migratePaths(<String>[tempDir.path]);

    expect(result.changedDartFiles, 1);
    expect(file.readAsStringSync(), '''
import 'package:flutter/widgets.dart' as m;
import 'package:material_ui/material_ui.dart' as m;

class Prefixed extends m.StatelessWidget {
  const Prefixed({super.key});

  @override
  m.Widget build(m.BuildContext context) {
    return const m.MaterialApp(home: m.Text('Hello'));
  }
}
''');
  });

  test('preserves framework symbols from multiple design library show imports', () {
    final file = File('${tempDir.path}/lib/multiple_show.dart')
      ..writeAsStringSync('''
import 'package:flutter/cupertino.dart' show CupertinoButton, Text;
import 'package:flutter/material.dart' show MaterialApp, Widget;

Widget buildButton() {
  return const MaterialApp(home: CupertinoButton(onPressed: null, child: Text('Hello')));
}
''');

    final migration.MigrationResult result = migration.migratePaths(<String>[tempDir.path]);

    expect(result.changedDartFiles, 1);
    expect(file.readAsStringSync(), '''
import 'package:flutter/widgets.dart' show Text;
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoButton;
import 'package:flutter/widgets.dart' show Widget;
import 'package:material_ui/material_ui.dart' show MaterialApp;

Widget buildButton() {
  return const MaterialApp(home: CupertinoButton(onPressed: null, child: Text('Hello')));
}
''');
  });

  test('rewrites directives that combine show and hide combinators', () {
    final file = File('${tempDir.path}/lib/show_hide.dart')
      ..writeAsStringSync('''
import 'package:flutter/material.dart' show MaterialApp, Text, Widget hide Text;

Widget buildApp() {
  return const MaterialApp();
}
''');

    final migration.MigrationResult result = migration.migratePaths(<String>[tempDir.path]);

    expect(result.changedDartFiles, 1);
    expect(file.readAsStringSync(), '''
import 'package:flutter/widgets.dart' show Widget;
import 'package:material_ui/material_ui.dart' show MaterialApp;

Widget buildApp() {
  return const MaterialApp();
}
''');
  });
}
