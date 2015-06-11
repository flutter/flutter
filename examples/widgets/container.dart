// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/flex.dart';
import 'package:sky/framework/widgets/ui_node.dart';
import 'package:sky/framework/widgets/wrappers.dart';

class Rectangle extends Component {

  Rectangle(this.color, { Object key }) : super(key: key);

  final Color color;

  UINode build() {
    return new FlexExpandingChild(
      new Container(
        decoration: new BoxDecoration(backgroundColor: color)
      )
    );
  }

}

class ContainerApp extends App {
  UINode build() {
    return new Flex([
        new Rectangle(const Color(0xFF00FFFF), key: 'a'),
        new Container(
          padding: new EdgeDims.all(10.0),
          margin: new EdgeDims.all(10.0),
          decoration: new BoxDecoration(backgroundColor: const Color(0xFFCCCCCC)),
          child: new Image(src: "https://www.dartlang.org/logos/dart-logo.png",
            size: new Size(300.0, 300.0),
            key: 1
          )
        ),
        new Rectangle(const Color(0xFFFFFF00), key: 'b'),
      ],
      direction: FlexDirection.vertical,
      justifyContent: FlexJustifyContent.spaceBetween
    );
  }
}

void main() {
  new ContainerApp();
}
