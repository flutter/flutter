// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class Inside extends StatefulComponent {
  InsideState createState() => new InsideState();
}

class InsideState extends State<Inside> {
  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: new Text('INSIDE')
    );
  }

  void _handlePointerDown(_) {
    setState(() { });
  }
}

class Middle extends StatefulComponent {
  Middle({ this.child });

  final Inside child;

  MiddleState createState() => new MiddleState();
}

class MiddleState extends State<Middle> {
  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: config.child
    );
  }

  void _handlePointerDown(_) {
    setState(() { });
  }
}

class Outside extends StatefulComponent {
  OutsideState createState() => new OutsideState();
}

class OutsideState extends State<Outside> {
  Widget build(BuildContext context) {
    return new Middle(child: new Inside());
  }
}

void main() {
  test('setState() smoke test', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Outside());
      TestPointer pointer = new TestPointer(1);
      Point location = tester.getCenter(tester.findText('INSIDE'));
      tester.dispatchEvent(pointer.down(location), location);
      tester.pump();
      tester.dispatchEvent(pointer.up(), location);
      tester.pump();
    });
  });
}
