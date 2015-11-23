// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class TestWidget extends StatefulComponent {
  TestWidget({ this.child, this.persistentState, this.syncedState });

  final Widget child;
  final int persistentState;
  final int syncedState;

  TestWidgetState createState() => new TestWidgetState();
}

class TestWidgetState extends State<TestWidget> {
  int persistentState;
  int syncedState;
  int updates = 0;

  void initState() {
    super.initState();
    persistentState = config.persistentState;
    syncedState = config.syncedState;
  }

  void didUpdateConfig(TestWidget oldConfig) {
    syncedState = config.syncedState;
    // we explicitly do NOT sync the persistentState from the new instance
    // because we're using that to track whether we got recreated
    updates += 1;
  }

  Widget build(BuildContext context) => config.child;
}

void main() {

  test('no change', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(
        new Container(
          child: new Container(
            child: new TestWidget(
              persistentState: 1,
              child: new Container()
            )
          )
        )
      );

      TestWidgetState state = tester.findStateOfType(TestWidgetState);

      expect(state.persistentState, equals(1));
      expect(state.updates, equals(0));

      tester.pumpWidget(
        new Container(
          child: new Container(
            child: new TestWidget(
              persistentState: 2,
              child: new Container()
            )
          )
        )
      );

      expect(state.persistentState, equals(1));
      expect(state.updates, equals(1));

      tester.pumpWidget(new Container());
    });
  });

  test('remove one', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(
        new Container(
          child: new Container(
            child: new TestWidget(
              persistentState: 10,
              child: new Container()
            )
          )
        )
      );

      TestWidgetState state = tester.findStateOfType(TestWidgetState);

      expect(state.persistentState, equals(10));
      expect(state.updates, equals(0));

      tester.pumpWidget(
        new Container(
          child: new TestWidget(
            persistentState: 11,
            child: new Container()
          )
        )
      );

      state = tester.findStateOfType(TestWidgetState);

      expect(state.persistentState, equals(11));
      expect(state.updates, equals(0));

      tester.pumpWidget(new Container());
    });
  });

  test('swap instances around', () {
    testWidgets((WidgetTester tester) {
      Widget a = new TestWidget(persistentState: 0x61, syncedState: 0x41, child: new Text('apple'));
      Widget b = new TestWidget(persistentState: 0x62, syncedState: 0x42, child: new Text('banana'));
      tester.pumpWidget(new Column(<Widget>[]));

      GlobalKey keyA = new GlobalKey();
      GlobalKey keyB = new GlobalKey();

      tester.pumpWidget(
        new Column(<Widget>[
          new Container(
            key: keyA,
            child: a
          ),
          new Container(
            key: keyB,
            child: b
          )
        ])
      );

      TestWidgetState first, second;

      first = tester.findStateByConfig(a);
      second = tester.findStateByConfig(b);

      expect(first.config, equals(a));
      expect(first.persistentState, equals(0x61));
      expect(first.syncedState, equals(0x41));
      expect(second.config, equals(b));
      expect(second.persistentState, equals(0x62));
      expect(second.syncedState, equals(0x42));

      tester.pumpWidget(
        new Column(<Widget>[
          new Container(
            key: keyA,
            child: a
          ),
          new Container(
            key: keyB,
            child: b
          )
        ])
      );

      first = tester.findStateByConfig(a);
      second = tester.findStateByConfig(b);

      // same as before
      expect(first.config, equals(a));
      expect(first.persistentState, equals(0x61));
      expect(first.syncedState, equals(0x41));
      expect(second.config, equals(b));
      expect(second.persistentState, equals(0x62));
      expect(second.syncedState, equals(0x42));

      // now we swap the nodes over
      // since they are both "old" nodes, they shouldn't sync with each other even though they look alike

      tester.pumpWidget(
        new Column(<Widget>[
          new Container(
            key: keyA,
            child: b
          ),
          new Container(
            key: keyB,
            child: a
          )
        ])
      );

      first = tester.findStateByConfig(b);
      second = tester.findStateByConfig(a);

      expect(first.config, equals(b));
      expect(first.persistentState, equals(0x61));
      expect(first.syncedState, equals(0x42));
      expect(second.config, equals(a));
      expect(second.persistentState, equals(0x62));
      expect(second.syncedState, equals(0x41));
    });
  });
}
