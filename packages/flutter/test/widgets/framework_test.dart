// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class TestState extends State<StatefulWidget> {
  @override
  Widget build(BuildContext context) => null;
}

void main() {
  testWidgets('UniqueKey control test', (WidgetTester tester) async {
    Key key = new UniqueKey();
    expect(key, hasOneLineDescription);
    expect(key, isNot(equals(new UniqueKey())));
  });

  testWidgets('ObjectKey control test', (WidgetTester tester) async {
    Object a = new Object();
    Object b = new Object();
    Key keyA = new ObjectKey(a);
    Key keyA2 = new ObjectKey(a);
    Key keyB = new ObjectKey(b);

    expect(keyA, hasOneLineDescription);
    expect(keyA, equals(keyA2));
    expect(keyA.hashCode, equals(keyA2.hashCode));
    expect(keyA, isNot(equals(keyB)));
  });

  testWidgets('GlobalObjectKey control test', (WidgetTester tester) async {
    Object a = new Object();
    Object b = new Object();
    Key keyA = new GlobalObjectKey(a);
    Key keyA2 = new GlobalObjectKey(a);
    Key keyB = new GlobalObjectKey(b);

    expect(keyA, hasOneLineDescription);
    expect(keyA, equals(keyA2));
    expect(keyA.hashCode, equals(keyA2.hashCode));
    expect(keyA, isNot(equals(keyB)));
  });

  testWidgets('GlobalKey duplication', (WidgetTester tester) async {
    Key key = new GlobalKey(debugLabel: 'problematic');

    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(
          key: const ValueKey<int>(1),
        ),
        new Container(
          key: const ValueKey<int>(2),
        ),
        new Container(
          key: key
        ),
      ],
    ));

    await tester.pumpWidget(new Stack(
      children: <Widget>[
        new Container(
          key: const ValueKey<int>(1),
          child: new SizedBox(key: key),
        ),
        new Container(
          key: const ValueKey<int>(2),
          child: new Placeholder(key: key),
        ),
      ],
    ));

    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey notification exception handling', (WidgetTester tester) async {
    GlobalKey key = new GlobalKey();

    await tester.pumpWidget(new Container(key: key));

    GlobalKey.registerRemoveListener(key, (GlobalKey key) {
      throw new Exception('Misbehaving listener');
    });

    bool didReceiveCallback = false;
    GlobalKey.registerRemoveListener(key, (GlobalKey key) {
      expect(didReceiveCallback, isFalse);
      didReceiveCallback = true;
    });

    await tester.pumpWidget(new Placeholder());

    expect(tester.takeException(), isNotNull);
    expect(didReceiveCallback, isTrue);
  });


  testWidgets('Defunct setState throws exception', (WidgetTester tester) async {
    StateSetter setState;

    await tester.pumpWidget(new StatefulBuilder(
      builder: (BuildContext context, StateSetter setter) {
        setState = setter;
        return new Container();
      },
    ));

    // Control check that setState doesn't throw an exception.
    setState(() { });

    await tester.pumpWidget(new Container());

    expect(() { setState(() { }); }, throwsFlutterError);
  });

  testWidgets('State toString', (WidgetTester tester) async {
    TestState state = new TestState();
    expect(state.toString(), contains('no config'));
  });

  testWidgets('debugPrintGlobalKeyedWidgetLifecycle control test', (WidgetTester tester) async {
    expect(debugPrintGlobalKeyedWidgetLifecycle, isFalse);

    final DebugPrintCallback oldCallback = debugPrint;
    debugPrintGlobalKeyedWidgetLifecycle = true;

    List<String> log = <String>[];
    debugPrint = (String message, { int wrapWidth }) {
      log.add(message);
    };

    GlobalKey key = new GlobalKey();
    await tester.pumpWidget(new Container(key: key));
    expect(log, isEmpty);
    await tester.pumpWidget(new Placeholder());
    debugPrint = oldCallback;
    debugPrintGlobalKeyedWidgetLifecycle = false;

    expect(log.length, equals(2));
    expect(log[0], matches('Deactivated'));
    expect(log[1], matches('Discarding .+ from inactive elements list.'));
  });

  testWidgets('MultiChildRenderObjectElement.children', (WidgetTester tester) async {
    GlobalKey key0, key1, key2;
    await tester.pumpWidget(new Column(
      key: key0 = new GlobalKey(),
      children: <Widget>[
        new Container(),
        new Container(key: key1 = new GlobalKey()),
        new Container(child: new Container()),
        new Container(key: key2 = new GlobalKey()),
        new Container(),
      ],
    ));
    MultiChildRenderObjectElement element = key0.currentContext;
    expect(
      element.children.map((Element element) => element.widget.key), // ignore: INVALID_USE_OF_PROTECTED_MEMBER
      <Key>[null, key1, null, key2, null],
    );
  });
}
