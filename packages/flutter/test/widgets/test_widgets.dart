// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

final BoxDecoration kBoxDecorationA = const BoxDecoration(
  backgroundColor: const Color(0xFFFF0000)
);

final BoxDecoration kBoxDecorationB = const BoxDecoration(
  backgroundColor: const Color(0xFF00FF00)
);

final BoxDecoration kBoxDecorationC = const BoxDecoration(
  backgroundColor: const Color(0xFF0000FF)
);

class TestBuildCounter extends StatelessWidget {
  static int buildCount = 0;

  @override
  Widget build(BuildContext context) {
    buildCount += 1;
    return new DecoratedBox(decoration: kBoxDecorationA);
  }
}


class FlipWidget extends StatefulWidget {
  FlipWidget({ Key key, this.left, this.right }) : super(key: key);

  final Widget left;
  final Widget right;

  @override
  FlipWidgetState createState() => new FlipWidgetState();
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
    return _showLeft ? config.left : config.right;
  }
}

void flipStatefulWidget(WidgetTester tester) {
  tester.state<FlipWidgetState>(find.byType(FlipWidget)).flip();
}

class TestScrollable extends StatelessWidget {
  TestScrollable({
    Key key,
    this.axisDirection: AxisDirection.down,
    this.physics,
    this.anchor: 0.0,
    this.center,
    this.slivers: const <Widget>[],
  }) {
    assert(slivers != null);
  }

  final AxisDirection axisDirection;

  final ScrollPhysics physics;

  final double anchor;

  final Key center;

  final List<Widget> slivers;

  Axis get axis => axisDirectionToAxis(axisDirection);

  @override
  Widget build(BuildContext context) {
    return new Scrollable2(
      axisDirection: axisDirection,
      physics: physics,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return new Viewport2(
          axisDirection: axisDirection,
          anchor: anchor,
          offset: offset,
          center: center,
          slivers: slivers,
        );
      }
    );
  }
}
