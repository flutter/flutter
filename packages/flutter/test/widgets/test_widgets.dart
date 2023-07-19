// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const BoxDecoration kBoxDecorationA = BoxDecoration(
  color: Color(0xFFFF0000),
);

const BoxDecoration kBoxDecorationB = BoxDecoration(
  color: Color(0xFF00FF00),
);

const BoxDecoration kBoxDecorationC = BoxDecoration(
  color: Color(0xFF0000FF),
);

class TestBuildCounter extends StatelessWidget {
  const TestBuildCounter({ super.key });

  static int buildCount = 0;

  @override
  Widget build(BuildContext context) {
    buildCount += 1;
    return const DecoratedBox(decoration: kBoxDecorationA);
  }
}


class FlipWidget extends StatefulWidget {
  const FlipWidget({ super.key, required this.left, required this.right });

  final Widget left;
  final Widget right;

  @override
  FlipWidgetState createState() => FlipWidgetState();
}

class FlipWidgetState extends State<FlipWidget> {
  bool _showLeft = true;

  void flip() {
    setState(() {
      _showLeft = !_showLeft;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showLeft ? widget.left : widget.right;
  }
}

void flipStatefulWidget(WidgetTester tester, { bool skipOffstage = true }) {
  tester.state<FlipWidgetState>(find.byType(FlipWidget, skipOffstage: skipOffstage)).flip();
}

// Test sliver which always attempts to paint itself whether it is visible or not.
// Use for checking if slivers which take sliver children paints optimally.
class RenderMockSliverToBoxAdapter extends RenderSliverToBoxAdapter {
  RenderMockSliverToBoxAdapter({
    super.child,
    required this.incrementCounter,
  });
  final void Function() incrementCounter;

  @override
  void paint(PaintingContext context, Offset offset) {
    incrementCounter();
  }
}

class MockSliverToBoxAdapter extends SingleChildRenderObjectWidget {
  /// Creates a sliver that contains a single box widget.
  const MockSliverToBoxAdapter({
    super.key,
    super.child,
    required this.incrementCounter,
  });

  final void Function() incrementCounter;

  @override
  RenderMockSliverToBoxAdapter createRenderObject(BuildContext context) =>
    RenderMockSliverToBoxAdapter(incrementCounter: incrementCounter);
}
