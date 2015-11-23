// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'test_widgets.dart';

class ProbeWidget extends StatefulComponent {
  ProbeWidgetState createState() => new ProbeWidgetState();
}

class ProbeWidgetState extends State<ProbeWidget> {
  static int buildCount = 0;

  void initState() {
    super.initState();
    setState(() {});
  }

  void didUpdateConfig(ProbeWidget oldConfig) {
    setState(() {});
  }

  Widget build(BuildContext context) {
    setState(() {});
    buildCount++;
    return new Container();
  }
}

class BadWidget extends StatelessComponent {
  BadWidget(this.parentState);

  final State parentState;

  Widget build(BuildContext context) {
    parentState.setState(() {});
    return new Container();
  }
}

class BadWidgetParent extends StatefulComponent {
  BadWidgetParentState createState() => new BadWidgetParentState();
}

class BadWidgetParentState extends State<BadWidgetParent> {
  Widget build(BuildContext context) {
    return new BadWidget(this);
  }
}

class BadDisposeWidget extends StatefulComponent {
  BadDisposeWidgetState createState() => new BadDisposeWidgetState();
}

class BadDisposeWidgetState extends State<BadDisposeWidget> {
  Widget build(BuildContext context) {
    return new Container();
  }

  void dispose() {
    setState(() {});
    super.dispose();
  }
}

void main() {
  dynamic cachedException;

  // ** WARNING **
  // THIS TEST OVERRIDES THE NORMAL EXCEPTION HANDLING
  // AND DOES NOT REPORT EXCEPTIONS FROM THE FRAMEWORK

  setUp(() {
    assert(cachedException == null);
    debugWidgetsExceptionHandler = (String context, dynamic exception, StackTrace stack) {
      cachedException = exception;
    };
    debugSchedulerExceptionHandler = (dynamic exception, StackTrace stack) { throw exception; };
  });

  tearDown(() {
    assert(cachedException == null);
    cachedException = null;
    debugWidgetsExceptionHandler = null;
    debugSchedulerExceptionHandler = null;
  });

  test('Legal times for setState', () {
    testWidgets((WidgetTester tester) {
      GlobalKey flipKey = new GlobalKey();
      expect(ProbeWidgetState.buildCount, equals(0));
      tester.pumpWidget(new ProbeWidget());
      expect(ProbeWidgetState.buildCount, equals(1));
      tester.pumpWidget(new ProbeWidget());
      expect(ProbeWidgetState.buildCount, equals(2));
      tester.pumpWidget(new FlipComponent(
        key: flipKey,
        left: new Container(),
        right: new ProbeWidget()
      ));
      expect(ProbeWidgetState.buildCount, equals(2));
      (flipKey.currentState as FlipComponentState).flip();
      tester.pump();
      expect(ProbeWidgetState.buildCount, equals(3));
      (flipKey.currentState as FlipComponentState).flip();
      tester.pump();
      expect(ProbeWidgetState.buildCount, equals(3));
      tester.pumpWidget(new Container());
      expect(ProbeWidgetState.buildCount, equals(3));
    });
  });

  test('Setting parent state during build is forbidden', () {
    testWidgets((WidgetTester tester) {
      expect(cachedException, isNull);
      tester.pumpWidget(new BadWidgetParent());
      expect(cachedException, isNotNull);
      cachedException = null;
      tester.pumpWidget(new Container());
      expect(cachedException, isNull);
    });
  });

  test('Setting state during dispose is forbidden', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new BadDisposeWidget());
      expect(() {
        tester.pumpWidget(new Container());
      }, throws);
    });
  });
}
