// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class Inside extends StatefulWidget {
  @override
  InsideState createState() => new InsideState();
}

class InsideState extends State<Inside> {
  @override
  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: const Text('INSIDE', textDirection: TextDirection.ltr),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    setState(() { });
  }
}

class Middle extends StatefulWidget {
  const Middle({ this.child });

  final Inside child;

  @override
  MiddleState createState() => new MiddleState();
}

class MiddleState extends State<Middle> {
  @override
  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: _handlePointerDown,
      child: widget.child,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    setState(() { });
  }
}

class Outside extends StatefulWidget {
  @override
  OutsideState createState() => new OutsideState();
}

class OutsideState extends State<Outside> {
  @override
  Widget build(BuildContext context) {
    return new Middle(child: new Inside());
  }
}

void main() {
  testWidgets('setState() smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(new Outside());
    final Offset location = tester.getCenter(find.text('INSIDE'));
    final TestGesture gesture = await tester.startGesture(location);
    await tester.pump();
    await gesture.up();
    await tester.pump();
  });
}
