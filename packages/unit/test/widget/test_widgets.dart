// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

final BoxDecoration kBoxDecorationA = new BoxDecoration(
  backgroundColor: const Color(0xFFFF0000)
);

final BoxDecoration kBoxDecorationB = new BoxDecoration(
  backgroundColor: const Color(0xFF00FF00)
);

final BoxDecoration kBoxDecorationC = new BoxDecoration(
  backgroundColor: const Color(0xFF0000FF)
);

class TestBuildCounter extends StatelessComponent {
  static int buildCount = 0;

  Widget build(BuildContext context) {
    ++buildCount;
    return new DecoratedBox(decoration: kBoxDecorationA);
  }
}


class FlipComponent extends StatefulComponent {
  FlipComponent({ Key key, this.left, this.right }) : super(key: key);

  final Widget left;
  final Widget right;

  FlipComponentState createState() => new FlipComponentState();
}

class FlipComponentState extends State<FlipComponent> {
  bool _showLeft = true;

  void flip() {
    setState(() {
      _showLeft = !_showLeft;
    });
  }

  Widget build(BuildContext context) {
    return _showLeft ? config.left : config.right;
  }
}

void flipStatefulComponent(WidgetTester tester) {
  StatefulComponentElement stateElement =
      tester.findElement((Element element) => element is StatefulComponentElement);
  expect(stateElement, isNotNull);
  expect(stateElement.state is FlipComponentState, isTrue);
  FlipComponentState state = stateElement.state;
  state.flip();
}
