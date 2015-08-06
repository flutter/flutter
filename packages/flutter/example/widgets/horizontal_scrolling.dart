// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/box_painter.dart';
import 'package:sky/widgets.dart';

class Circle extends Component {
  Widget build() {
    return new Container(
      width: 50.0,
      margin: new EdgeDims.symmetric(horizontal: 2.0),
      decoration: new BoxDecoration(
        shape: Shape.circle,
        backgroundColor: const Color(0xFF00FF00)
      )
    );
  }
}

class Pad extends Component {
  Widget build() {
    return new SizedBox(width: 10.0);
  }
}

class HorizontalScrollingApp extends App {
  Widget build() {
    List<Widget> circles = [
      new Pad(),
      new Circle(),
      new Circle(),
      new Circle(),
      new Circle(),
      new Circle(),
      new Circle(),
      new Circle(),
      new Circle(),
      new Circle(),
      new Circle(),
      new Circle(),
      new Circle(),
      new Pad(),
    ];

    return new Center(
      child: new Container(
        height: 50.0,
        child: new Flex([
          new ScrollableBlock(circles, scrollDirection: ScrollDirection.horizontal)
        ], justifyContent: FlexJustifyContent.end)
      )
    );
  }
}

void main() {
  runApp(new HorizontalScrollingApp());
}
