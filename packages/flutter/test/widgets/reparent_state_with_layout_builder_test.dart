// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
          builder: (BuildContext context, BoxConstraints constraints) => new StatefulCreationCounter(key: _fooKey),
        ),
      );
    } else {
      return new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => new StatefulCreationCounter(key: _fooKey),
      );
    }
  }
}

class StatefulCreationCounter extends StatefulWidget {
  StatefulCreationCounter({ Key key }) : super(key: key);

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
  testWidgets('reparent state with layout builder', (WidgetTester tester) async {
    expect(StatefulCreationCounterState.creationCount, 0);
    await tester.pumpWidget(new Bar());
    expect(StatefulCreationCounterState.creationCount, 1);
    BarState s = tester.state/*<BarState>*/(find.byType(Bar));
    s.trigger();
    await tester.pump();
    expect(StatefulCreationCounterState.creationCount, 1);
  });
}
