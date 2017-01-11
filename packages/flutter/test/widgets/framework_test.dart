// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

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

    expect(tester.takeException(), isNotNull);
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
}
