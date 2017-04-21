// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show window;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide TypeMatcher;

// This is a regression test for https://github.com/flutter/flutter/issues/5840.

class Bar extends StatefulWidget {
  @override
  BarState createState() => new BarState();
}

class BarState extends State<Bar> {
  final GlobalKey _fooKey = new GlobalKey();

  bool _mode = false;

  void trigger() {
    setState(() {
      _mode = !_mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mode) {
      return new SizedBox(
        child: new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return new StatefulCreationCounter(key: _fooKey);
          },
        ),
      );
    } else {
      return new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return new StatefulCreationCounter(key: _fooKey);
        },
      );
    }
  }
}

class StatefulCreationCounter extends StatefulWidget {
  const StatefulCreationCounter({ Key key }) : super(key: key);

  @override
  StatefulCreationCounterState createState() => new StatefulCreationCounterState();
}

class StatefulCreationCounterState extends State<StatefulCreationCounter> {
  static int creationCount = 0;

  @override
  void initState() {
    super.initState();
    creationCount += 1;
  }

  @override
  Widget build(BuildContext context) => new Container();
}

void main() {
  testWidgets('reparent state with layout builder',
      (WidgetTester tester) async {
    expect(StatefulCreationCounterState.creationCount, 0);
    await tester.pumpWidget(new Bar());
    expect(StatefulCreationCounterState.creationCount, 1);
    final BarState s = tester.state<BarState>(find.byType(Bar));
    s.trigger();
    await tester.pump();
    expect(StatefulCreationCounterState.creationCount, 1);
  });

  testWidgets('Clean then reparent with dependencies',
      (WidgetTester tester) async {

    int layoutBuilderBuildCount = 0;

    StateSetter keyedSetState;
    StateSetter layoutBuilderSetState;
    StateSetter childSetState;

    final GlobalKey key = new GlobalKey();
    final Widget keyedWidget = new StatefulBuilder(
      key: key,
      builder: (BuildContext context, StateSetter setState) {
        keyedSetState = setState;
        MediaQuery.of(context);
        return new Container();
      },
    );

    Widget layoutBuilderChild = keyedWidget;
    Widget deepChild = new Container();

    await tester.pumpWidget(new MediaQuery(
      data: new MediaQueryData.fromWindow(ui.window),
      child: new Column(
        children: <Widget>[
          new StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            layoutBuilderSetState = setState;
            return new LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                layoutBuilderBuildCount += 1;
                return layoutBuilderChild; // initially keyedWidget above, but then a new Container
              },
            );
          }),
          new Container(
            child: new Container(
              child: new Container(
                child: new Container(
                  child: new Container(
                    child: new Container(
                      child: new StatefulBuilder(builder:
                          (BuildContext context, StateSetter setState) {
                        childSetState = setState;
                        return deepChild; // initially a Container, but then the keyedWidget above
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
    expect(layoutBuilderBuildCount, 1);

    keyedSetState(() { /* Change nothing but add the element to the dirty list. */ });

    childSetState(() {
      // The deep child builds in the initial build phase. It takes the child
      // from the LayoutBuilder before the LayoutBuilder has a chance to build.
      deepChild = keyedWidget;
    });

    layoutBuilderSetState(() {
      // The layout builder will build in a separate build scope. This delays
      // the removal of the keyed child until this build scope.
      layoutBuilderChild = new Container();
    });

    // The essential part of this test is that this call to pump doesn't throw.
    await tester.pump();
    expect(layoutBuilderBuildCount, 2);
  });
}
