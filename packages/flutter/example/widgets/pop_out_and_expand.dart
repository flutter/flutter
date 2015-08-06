// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/painting/box_painter.dart';
import 'package:sky/widgets.dart';

class Circle extends Component {
  Circle({ this.child });

  Widget child;

  Widget build() {
    return new Container(
      height: 100.0,
      margin: new EdgeDims.symmetric(horizontal: 20.0, vertical: 4.0),
      decoration: new BoxDecoration(
        backgroundColor: const Color(0xFF0000FF)
      ),
      child: new Center(
        child: child
      )
    );
  }
}

class CircleData {
  final GlobalKey key;
  final String content;

  CircleData({ this.key, this.content });
}

class ExampleApp extends App {
  ExampleApp() {
    for (int i = 0; i < 20; ++i) {
      _data.add(new CircleData(
        key: new GlobalKey(),
        content: '$i'
      ));
    }
  }

  final List<CircleData> _data = new List<CircleData>();

  GlobalKey _keyToMimic;

  Widget _buildCircle(CircleData circleData) {
    return new Mimicable(
      key: circleData.key,
      child: new Listener(
        child: new Circle(
          child: new Text(circleData.content)
        ),
        onGestureTap: (_) {
          setState(() {
            _keyToMimic = circleData.key;
          });
        }
      )
    );
  }

  Widget build() {
    List<Widget> circles = new List<Widget>();
    for (int i = 0; i < 20; ++i) {
      circles.add(_buildCircle(_data[i]));
    }

    List<Widget> layers = new List<Widget>();
    layers.add(new ScrollableBlock(circles));

    if (_keyToMimic != null) {
      layers.add(
        new Positioned(
          top: 50.0,
          left: 50.0,
          child: new Mimic(
            original: _keyToMimic)
        )
      );
    }

    return new Stack(layers);
  }
}

void main() {
  runApp(new ExampleApp());
}
