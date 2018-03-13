// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show window;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SemanticsDebugger smoke test', (WidgetTester tester) async {

    // This is a smoketest to verify that adding a debugger doesn't crash.
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget>[
            new Semantics(),
            new Semantics(
              container: true,
            ),
            new Semantics(
              label: 'label',
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new SemanticsDebugger(
          child: new Stack(
            children: <Widget>[
              new Semantics(),
              new Semantics(
                container: true,
              ),
              new Semantics(
                label: 'label',
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );

    expect(true, isTrue); // expect that we reach here without crashing
  });

  testWidgets('SemanticsDebugger reparents subtree',
      (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey();

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new SemanticsDebugger(
          child: new Stack(
            children: <Widget>[
              new Semantics(label: 'label1', textDirection: TextDirection.ltr),
              new Positioned(
                key: key,
                left: 0.0,
                top: 0.0,
                width: 100.0,
                height: 100.0,
                child: new Semantics(label: 'label2', textDirection: TextDirection.ltr),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new SemanticsDebugger(
          child: new Stack(
            children: <Widget>[
              new Semantics(label: 'label1', textDirection: TextDirection.ltr),
              new Semantics(
                container: true,
                child: new Stack(
                  children: <Widget>[
                    new Positioned(
                      key: key,
                      left: 0.0,
                      top: 0.0,
                      width: 100.0,
                      height: 100.0,
                      child: new Semantics(label: 'label2', textDirection: TextDirection.ltr),
                    ),
                    new Semantics(label: 'label3', textDirection: TextDirection.ltr),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new SemanticsDebugger(
          child: new Stack(
            children: <Widget>[
              new Semantics(label: 'label1', textDirection: TextDirection.ltr),
              new Semantics(
                container: true,
                child: new Stack(
                  children: <Widget>[
                    new Positioned(
                        key: key,
                        left: 0.0,
                        top: 0.0,
                        width: 100.0,
                        height: 100.0,
                        child: new Semantics(label: 'label2', textDirection: TextDirection.ltr)),
                    new Semantics(label: 'label3', textDirection: TextDirection.ltr),
                    new Semantics(label: 'label4', textDirection: TextDirection.ltr),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('SemanticsDebugger interaction test',
      (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new SemanticsDebugger(
          child: new Material(
            child: new ListView(
              children: <Widget>[
                new RaisedButton(
                  onPressed: () {
                    log.add('top');
                  },
                  child: const Text('TOP'),
                ),
                new RaisedButton(
                  onPressed: () {
                    log.add('bottom');
                  },
                  child: const Text('BOTTOM'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('TOP'));
    expect(log, equals(<String>['top']));
    log.clear();

    await tester.tap(find.text('BOTTOM'));
    expect(log, equals(<String>['bottom']));
    log.clear();
  });

  testWidgets('SemanticsDebugger interaction test - negative',
      (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new SemanticsDebugger(
          child: new Material(
            child: new ListView(
              children: <Widget>[
                new RaisedButton(
                  onPressed: () {
                    log.add('top');
                  },
                  child: const Text('TOP', textDirection: TextDirection.ltr),
                ),
                new ExcludeSemantics(
                  child: new RaisedButton(
                    onPressed: () {
                      log.add('bottom');
                    },
                    child: const Text('BOTTOM', textDirection: TextDirection.ltr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('TOP'));
    expect(log, equals(<String>['top']));
    log.clear();

    await tester.tap(find.text('BOTTOM'));
    expect(log, equals(<String>[]));
    log.clear();
  });

  testWidgets('SemanticsDebugger scroll test', (WidgetTester tester) async {
    final Key childKey = new UniqueKey();

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new SemanticsDebugger(
          child: new ListView(
            children: <Widget>[
              new Container(
                key: childKey,
                height: 5000.0,
                color: Colors.green[500],
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));

    await tester.fling(find.byType(ListView), const Offset(0.0, -200.0), 200.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(-480.0));

    await tester.fling(find.byType(ListView), const Offset(200.0, 0.0), 200.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(-480.0));

    await tester.fling(find.byType(ListView), const Offset(-200.0, 0.0), 200.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(-480.0));

    await tester.fling(find.byType(ListView), const Offset(0.0, 200.0), 200.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));
  });

  testWidgets('SemanticsDebugger long press', (WidgetTester tester) async {
    bool didLongPress = false;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new SemanticsDebugger(
          child: new GestureDetector(
            onLongPress: () {
              expect(didLongPress, isFalse);
              didLongPress = true;
            },
            child: const Text('target', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('target'));
    expect(didLongPress, isTrue);
  });

  testWidgets('SemanticsDebugger slider', (WidgetTester tester) async {
    double value = 0.75;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new SemanticsDebugger(
          child: new Directionality(
            textDirection: TextDirection.ltr,
            child: new MediaQuery(
              data: new MediaQueryData.fromWindow(window),
              child: new Material(
                child: new Center(
                  child: new Slider(
                    value: value,
                    onChanged: (double newValue) {
                      value = newValue;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // The fling below must be such that the velocity estimation examines an
    // offset greater than the kTouchSlop. Too slow or too short a distance, and
    // it won't trigger. The actual distance moved doesn't matter since this is
    // interpreted as a gesture by the semantics debugger and sent to the widget
    // as a semantic action that always moves by 10% of the complete track.
    await tester.fling(find.byType(Slider), const Offset(-100.0, 0.0), 2000.0);
    expect(value, equals(0.65));
  });

  testWidgets('SemanticsDebugger checkbox', (WidgetTester tester) async {
    final Key keyTop = new UniqueKey();
    final Key keyBottom = new UniqueKey();

    bool valueTop = false;
    const bool valueBottom = true;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new SemanticsDebugger(
          child: new Material(
            child: new ListView(
              children: <Widget>[
                new Checkbox(
                  key: keyTop,
                  value: valueTop,
                  onChanged: (bool newValue) {
                    valueTop = newValue;
                  },
                ),
                new Checkbox(
                  key: keyBottom,
                  value: valueBottom,
                  onChanged: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(keyTop));

    expect(valueTop, isTrue);
    valueTop = false;
    expect(valueTop, isFalse);

    await tester.tap(find.byKey(keyBottom));

    expect(valueTop, isFalse);
    expect(valueTop, isFalse);
  });
}
