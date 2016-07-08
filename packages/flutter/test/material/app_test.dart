// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class StateMarker extends StatefulWidget {
  StateMarker({ Key key, this.child }) : super(key: key);

  final Widget child;

  @override
  StateMarkerState createState() => new StateMarkerState();
}

class StateMarkerState extends State<StateMarker> {
  String marker;

  @override
  Widget build(BuildContext context) {
    if (config.child != null)
      return config.child;
    return new Container();
  }
}

void main() {
  testWidgets('Can nest apps', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new MaterialApp(
          home: new Text('Home sweet home')
        )
      )
    );

    expect(find.text('Home sweet home'), findsOneWidget);
  });

  testWidgets('Focus handling', (WidgetTester tester) async {
    GlobalKey inputKey = new GlobalKey();
    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Center(
          child: new Input(key: inputKey, autofocus: true)
        )
      )
    ));

    expect(Focus.at(inputKey.currentContext), isTrue);
  });

  testWidgets('Can show grid without losing sync', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: new StateMarker()
      )
    );

    StateMarkerState state1 = tester.state(find.byType(StateMarker));
    state1.marker = 'original';

    await tester.pumpWidget(
      new MaterialApp(
        debugShowMaterialGrid: true,
        home: new StateMarker()
      )
    );

    StateMarkerState state2 = tester.state(find.byType(StateMarker));
    expect(state1, equals(state2));
    expect(state2.marker, equals('original'));
  });
}
