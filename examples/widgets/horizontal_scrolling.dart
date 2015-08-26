// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets.dart';

class Circle extends Component {
  Circle({ this.margin: EdgeDims.zero });

  final EdgeDims margin;

  Widget build() {
    return new Container(
      width: 50.0,
      margin: margin + new EdgeDims.symmetric(horizontal: 2.0),
      decoration: new BoxDecoration(
        shape: Shape.circle,
        backgroundColor: const Color(0xFF00FF00)
      )
    );
  }
}

class HorizontalScrollingApp extends App {
  Widget build() {
    List<Widget> circles = [
      new Circle(margin: new EdgeDims.only(left: 10.0)),
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
      new Circle(margin: new EdgeDims.only(right: 10.0)),
    ];

    return new Center(
      child: new Container(
        height: 50.0,
        child: new Row([
            new Block(circles, scrollDirection: ScrollDirection.horizontal)
          ],
          justifyContent: FlexJustifyContent.end
        )
      )
    );
  }
}

void main() {
  runApp(new HorizontalScrollingApp());
}
