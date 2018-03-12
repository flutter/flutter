// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../rendering/src/solid_color_box.dart';

// Solid colour, RenderObject version
void addFlexChildSolidColor(RenderFlex parent, Color backgroundColor, { int flex: 0 }) {
  final RenderSolidColorBox child = new RenderSolidColorBox(backgroundColor);
  parent.add(child);
  final FlexParentData childParentData = child.parentData;
  childParentData.flex = flex;
}

// Solid colour, Widget version
class Rectangle extends StatelessWidget {
  const Rectangle(this.color, { Key key }) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return new Expanded(
      child: new Container(
        color: color,
      )
    );
  }
}

double value;
RenderObjectToWidgetElement<RenderBox> element;
BuildOwner owner = new BuildOwner();
void attachWidgetTreeToRenderTree(RenderProxyBox container) {
  element = new RenderObjectToWidgetAdapter<RenderBox>(
    container: container,
    child: new Directionality(
      textDirection: TextDirection.ltr,
      child: new Container(
        height: 300.0,
        child: new Column(
          children: <Widget>[
            const Rectangle(const Color(0xFF00FFFF)),
            new Material(
              child: new Container(
                padding: const EdgeInsets.all(10.0),
                margin: const EdgeInsets.all(10.0),
                child: new Row(
                  children: <Widget>[
                    new RaisedButton(
                      child: new Row(
                        children: <Widget>[
                          new Image.network('https://flutter.io/images/favicon.png'),
                          const Text('PRESS ME'),
                        ],
                      ),
                      onPressed: () {
                        value = value == null ? 0.1 : (value + 0.1) % 1.0;
                        attachWidgetTreeToRenderTree(container);
                      },
                    ),
                    new CircularProgressIndicator(value: value),
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                ),
              ),
            ),
            const Rectangle(const Color(0xFFFFFF00)),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        ),
      ),
    ),
  ).attachToRenderTree(owner, element);
}

Duration timeBase;
RenderTransform transformBox;

void rotate(Duration timeStamp) {
  timeBase ??= timeStamp;
  final double delta = (timeStamp - timeBase).inMicroseconds.toDouble() / Duration.microsecondsPerSecond; // radians

  transformBox.setIdentity();
  transformBox.rotateZ(delta);

  owner.buildScope(element);
}

void main() {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  final RenderProxyBox proxy = new RenderProxyBox();
  attachWidgetTreeToRenderTree(proxy);

  final RenderFlex flexRoot = new RenderFlex(direction: Axis.vertical);
  addFlexChildSolidColor(flexRoot, const Color(0xFFFF00FF), flex: 1);
  flexRoot.add(proxy);
  addFlexChildSolidColor(flexRoot, const Color(0xFF0000FF), flex: 1);

  transformBox = new RenderTransform(child: flexRoot, transform: new Matrix4.identity(), alignment: Alignment.center);
  final RenderPadding root = new RenderPadding(padding: const EdgeInsets.all(80.0), child: transformBox);

  binding.renderView.child = root;
  binding.addPersistentFrameCallback(rotate);
}
