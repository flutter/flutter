// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('IgnorePointer allows widgets behind', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          GestureDetector(
            onTap: () {log.add('background');},
          ),
          IgnorePointer(
            ignoring: true,
            child: GestureDetector(
              onTap: () {log.add('foreground');},
            ),
          ),
        ],
      ),
    );

    await tester.tap(find.byType(IgnorePointer));
    expect(log, <String>['background']);
    log.clear();

    await tester.pumpWidget(
      Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          GestureDetector(
            onTap: () {log.add('background');},
          ),
          IgnorePointer(
            ignoring: false,
            child: GestureDetector(
              onTap: () {log.add('foreground');},
            ),
          ),
        ],
      ),
    );

    await tester.tap(find.byType(IgnorePointer));
    expect(log, <String>['foreground']);
  });

  testWidgets('IgnorePointer semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      IgnorePointer(
        ignoring: true,
        child: Semantics(
          label: 'test',
          textDirection: TextDirection.ltr,
        ),
      ),
    );
    expect(semantics, hasSemantics(
      TestSemantics.root(), ignoreId: true, ignoreRect: true, ignoreTransform: true));

    await tester.pumpWidget(
      IgnorePointer(
        ignoring: false,
        child: Semantics(
          label: 'test',
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(
            label: 'test',
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
      ignoreId: true, ignoreRect: true, ignoreTransform: true));
    semantics.dispose();
  });

  testWidgets('IgnorePointer allows mouse events', (WidgetTester tester) async {
    final List<String> logs = <String>[];
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(const Offset(200, 200));
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(
      Container(
        alignment: Alignment.topLeft,
        child: Container(
          width: 100,
          height: 100,
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              MouseRegion(onEnter: (_) {logs.add('background');}),
              IgnorePointer(
                ignoring: true,
                child: MouseRegion(onEnter: (_) {logs.add('foreground');}),
              ),
            ],
          ),
        ),
      ),
    );

    await gesture.moveTo(const Offset(50, 50));
    expect(logs, <String>['background']);
    logs.clear();

    await tester.pumpWidget(
      Container(
        alignment: Alignment.topLeft,
        child: Container(
          width: 100,
          height: 100,
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              MouseRegion(onEnter: (_) {logs.add('background');}),
              IgnorePointer(
                ignoring: false,
                child: MouseRegion(onEnter: (_) {logs.add('foreground');}),
              ),
            ],
          ),
        ),
      ),
    );

    expect(logs, <String>['foreground']);
  });
}
