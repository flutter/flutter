// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'test_widgets.dart';

class ProbeWidget extends StatefulWidget {
  @override
  ProbeWidgetState createState() => new ProbeWidgetState();
}

class ProbeWidgetState extends State<ProbeWidget> {
  static int buildCount = 0;

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  void didUpdateConfig(ProbeWidget oldConfig) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    setState(() {});
    buildCount++;
    return new Container();
  }
}

class BadWidget extends StatelessWidget {
  BadWidget(this.parentState);

  final State parentState;

  @override
  Widget build(BuildContext context) {
    parentState.setState(() {});
    return new Container();
  }
}

class BadWidgetParent extends StatefulWidget {
  @override
  BadWidgetParentState createState() => new BadWidgetParentState();
}

class BadWidgetParentState extends State<BadWidgetParent> {
  @override
  Widget build(BuildContext context) {
    return new BadWidget(this);
  }
}

class BadDisposeWidget extends StatefulWidget {
  @override
  BadDisposeWidgetState createState() => new BadDisposeWidgetState();
}

class BadDisposeWidgetState extends State<BadDisposeWidget> {
  @override
  Widget build(BuildContext context) {
    return new Container();
  }

  @override
  void dispose() {
    setState(() { /* This is invalid behavior. */ });
    super.dispose();
  }
}

void main() {
  testWidgets('Legal times for setState', (WidgetTester tester) {
    GlobalKey flipKey = new GlobalKey();
    expect(ProbeWidgetState.buildCount, equals(0));
    tester.pumpWidget(new ProbeWidget());
    expect(ProbeWidgetState.buildCount, equals(1));
    tester.pumpWidget(new ProbeWidget());
    expect(ProbeWidgetState.buildCount, equals(2));
    tester.pumpWidget(new FlipWidget(
      key: flipKey,
      left: new Container(),
      right: new ProbeWidget()
    ));
    expect(ProbeWidgetState.buildCount, equals(2));
    FlipWidgetState flipState1 = flipKey.currentState;
    flipState1.flip();
    tester.pump();
    expect(ProbeWidgetState.buildCount, equals(3));
    FlipWidgetState flipState2 = flipKey.currentState;
    flipState2.flip();
    tester.pump();
    expect(ProbeWidgetState.buildCount, equals(3));
    tester.pumpWidget(new Container());
    expect(ProbeWidgetState.buildCount, equals(3));
  });

  testWidgets('Setting parent state during build is forbidden', (WidgetTester tester) {
    tester.pumpWidget(new BadWidgetParent());
    expect(tester.takeException(), isNotNull);
    tester.pumpWidget(new Container());
  });

  testWidgets('Setting state during dispose is forbidden', (WidgetTester tester) {
    tester.pumpWidget(new BadDisposeWidget());
    expect(tester.takeException(), isNull);
    tester.pumpWidget(new Container());
    expect(tester.takeException(), isNotNull);
  });
}
