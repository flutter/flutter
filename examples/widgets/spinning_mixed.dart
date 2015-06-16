// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/app/scheduler.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/raised_button.dart';
import 'package:sky/widgets/ui_node.dart';
import 'package:vector_math/vector_math.dart';

import '../lib/solid_color_box.dart';
import '../../tests/resources/display_list.dart';

// Solid colour, RenderObject version
void addFlexChildSolidColor(RenderFlex parent, sky.Color backgroundColor, { int flex: 0 }) {
  RenderSolidColorBox child = new RenderSolidColorBox(backgroundColor);
  parent.add(child);
  child.parentData.flex = flex;
}

// Solid colour, Widget version
class Rectangle extends Component {
  Rectangle(this.color, { String key }) : super(key: key);
  final Color color;
  UINode build() {
    return new Flexible(
      child: new Container(
        decoration: new BoxDecoration(backgroundColor: color)
      )
    );
  }
}

UINode builder() {
  return new Flex([
      new Rectangle(const Color(0xFF00FFFF), key: 'a'),
      new Container(
        padding: new EdgeDims.all(10.0),
        margin: new EdgeDims.all(10.0),
        decoration: new BoxDecoration(backgroundColor: const Color(0xFFCCCCCC)),
        child: new RaisedButton(
          child: new Flex([
            new Image(src: "https://www.dartlang.org/logos/dart-logo.png"),
            new Text('PRESS ME'),
          ]),
          onPressed: () => print("Hello World")
        )
      ),
      new Rectangle(const Color(0xFFFFFF00), key: 'b'),
    ],
    direction: FlexDirection.vertical,
    justifyContent: FlexJustifyContent.spaceBetween
  );
}

double timeBase;
RenderTransform transformBox;

final TestRenderView tester = new TestRenderView();

void rotate(double timeStamp) {
  if (timeBase == null)
    timeBase = timeStamp;
  double delta = (timeStamp - timeBase) / 1000; // radians

  transformBox.setIdentity();
  transformBox.translate(transformBox.size.width / 2.0, transformBox.size.height / 2.0);
  transformBox.rotateZ(delta);
  transformBox.translate(-transformBox.size.width / 2.0, -transformBox.size.height / 2.0);
}

void main() {
  // Because we're going to use UINodes, we want to initialise its
  // AppView, not use the default one. We don't really need to do
  // this, because RenderObjectToUINodeAdapter does it for us, but
  // it's good practice in case we happen to not have a
  // RenderObjectToUINodeAdapter in our tree at startup, or in case we
  // want a renderViewOverride.
  UINodeAppView.initUINodeAppView();

  RenderFlex flexRoot = new RenderFlex(direction: FlexDirection.vertical);

  RenderProxyBox proxy = new RenderProxyBox();
  new RenderObjectToUINodeAdapter(proxy, builder); // adds itself to proxy

  addFlexChildSolidColor(flexRoot, const sky.Color(0xFFFF00FF), flex: 1);
  flexRoot.add(proxy);
  addFlexChildSolidColor(flexRoot, const sky.Color(0xFF0000FF), flex: 1);

  transformBox = new RenderTransform(child: flexRoot, transform: new Matrix4.identity());
  RenderPadding root = new RenderPadding(padding: new EdgeDims.all(20.0), child: transformBox);

  UINodeAppView.appView.root = root;
  addPersistentFrameCallback(rotate);
}
