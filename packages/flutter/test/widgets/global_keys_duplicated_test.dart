// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

// There's also some duplicate GlobalKey tests in the framework_test.dart file.

void main() {
  testWidgets('GlobalKey children of one node', (WidgetTester tester) async {
    // This is actually a test of the regular duplicate key logic, which
    // happens before the duplicate GlobalKey logic.
    await tester.pumpWidget(Stack(children: <Widget>[
      Container(key: const GlobalObjectKey(0)),
      Container(key: const GlobalObjectKey(0)),
    ]));
    final dynamic error = tester.takeException();
    expect(error, isFlutterError);
    expect(error.toString(), startsWith('Duplicate keys found.\n'));
    expect(error.toString(), contains('Stack'));
    expect(error.toString(), contains('[GlobalObjectKey ${describeIdentity(0)}]'));
  });

  testWidgets('GlobalKey children of two nodes', (WidgetTester tester) async {
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(child: Container(key: const GlobalObjectKey(0))),
        Container(child: Container(key: const GlobalObjectKey(0))),
      ],
    ));
    final dynamic error = tester.takeException();
    expect(error, isFlutterError);
    expect(error.toString(), startsWith('Multiple widgets used the same GlobalKey.\n'));
    expect(error.toString(), contains('different widgets that both had the following description'));
    expect(error.toString(), contains('Container'));
    expect(error.toString(), contains('[GlobalObjectKey ${describeIdentity(0)}]'));
    expect(error.toString(), endsWith('\nA GlobalKey can only be specified on one widget at a time in the widget tree.'));
  });

  testWidgets('GlobalKey children of two different nodes', (WidgetTester tester) async {
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(child: Container(key: const GlobalObjectKey(0))),
        Container(key: const Key('x'), child: Container(key: const GlobalObjectKey(0))),
      ],
    ));
    final dynamic error = tester.takeException();
    expect(error, isFlutterError);
    expect(error.toString(), startsWith('Multiple widgets used the same GlobalKey.\n'));
    expect(error.toString(), isNot(contains('different widgets that both had the following description')));
    expect(error.toString(), contains('Container'));
    expect(error.toString(), contains("Container-[<'x'>]"));
    expect(error.toString(), contains('[GlobalObjectKey ${describeIdentity(0)}]'));
    expect(error.toString(), endsWith('\nA GlobalKey can only be specified on one widget at a time in the widget tree.'));
  });

  testWidgets('GlobalKey children of two nodes', (WidgetTester tester) async {
    StateSetter nestedSetState;
    bool flag = false;
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(child: Container(key: const GlobalObjectKey(0))),
        Container(child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            nestedSetState = setState;
            if (flag)
              return Container(key: const GlobalObjectKey(0));
            return Container();
          },
        )),
      ],
    ));
    nestedSetState(() { flag = true; });
    await tester.pump();
    final dynamic error = tester.takeException();
    expect(error.toString(), startsWith('Duplicate GlobalKey detected in widget tree.\n'));
    expect(error.toString(), contains('The following GlobalKey was specified multiple times'));
    // The following line is verifying the grammar is correct in this common case.
    // We should probably also verify the three other combinations that can be generated...
    expect(error.toString().split('\n').join(' '), contains('This was determined by noticing that after the widget with the above global key was moved out of its previous parent, that previous parent never updated during this frame, meaning that it either did not update at all or updated before the widget was moved, in either case implying that it still thinks that it should have a child with that global key.'));
    expect(error.toString(), contains('[GlobalObjectKey ${describeIdentity(0)}]'));
    expect(error.toString(), contains('Container'));
    expect(error.toString(), endsWith('\nA GlobalKey can only be specified on one widget at a time in the widget tree.'));
    expect(error, isFlutterError);
  });
}
