// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/material.dart';
import 'package:sky/src/fn3.dart';

final double kTop = 10.0 + sky.view.paddingTop;
final double kLeft = 10.0;

class DragData {
  DragData(this.text);

  final String text;
}

class ExampleDragTarget extends StatefulComponent {
  ExampleDragTargetState createState() => new ExampleDragTargetState();
}

class ExampleDragTargetState extends State<ExampleDragTarget> {
  String _text = 'ready';

  void _handleAccept(DragData data) {
    setState(() {
      _text = data.text;
    });
  }

  Widget build(BuildContext context) {
    return new DragTarget<DragData>(
      onAccept: _handleAccept,
      builder: (BuildContext context, List<DragData> data, _) {
        return new Container(
          width: 100.0,
          height: 100.0,
          margin: new EdgeDims.all(10.0),
          decoration: new BoxDecoration(
            border: new Border.all(
              width: 3.0,
              color: data.isEmpty ? Colors.white : Colors.blue[500]
            ),
            backgroundColor: data.isEmpty ? Colors.grey[500] : Colors.green[500]
          ),
          child: new Center(
            child: new Text(_text)
          )
        );
      }
    );
  }
}

class Dot extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Container(
      width: 50.0,
      height: 50.0,
      decoration: new BoxDecoration(
        backgroundColor: Colors.deepOrange[500]
      )
    );
  }
}

class DragAndDropApp extends StatefulComponent {
  DragAndDropAppState createState() => new DragAndDropAppState(this);
}

class DragAndDropAppState extends State<DragAndDropApp> {
  DragController _dragController;
  Offset _displacement = Offset.zero;

  void _startDrag(sky.PointerEvent event) {
    setState(() {
      _dragController = new DragController(new DragData("Orange"));
      _dragController.update(new Point(event.x, event.y));
      _displacement = Offset.zero;
    });
  }

  void _updateDrag(sky.PointerEvent event) {
    setState(() {
      _dragController.update(new Point(event.x, event.y));
      _displacement += new Offset(event.dx, event.dy);
    });
  }

  void _cancelDrag(sky.PointerEvent event) {
    setState(() {
      _dragController.cancel();
      _dragController = null;
    });
  }

  void _drop(sky.PointerEvent event) {
    setState(() {
      _dragController.update(new Point(event.x, event.y));
      _dragController.drop();
      _dragController = null;
      _displacement = Offset.zero;
    });
  }

  Widget build(BuildContext context) {
    List<Widget> layers = <Widget>[
      new Row([
        new ExampleDragTarget(),
        new ExampleDragTarget(),
        new ExampleDragTarget(),
        new ExampleDragTarget(),
      ]),
      new Positioned(
        top: kTop,
        left: kLeft,
        // TODO(abarth): We should be using a GestureDetector
        child: new Listener(
          onPointerDown: _startDrag,
          onPointerMove: _updateDrag,
          onPointerCancel: _cancelDrag,
          onPointerUp: _drop,
          child: new Dot()
        )
      ),
    ];

    if (_dragController != null) {
      layers.add(
        new Positioned(
          top: kTop + _displacement.dy,
          left: kLeft + _displacement.dx,
          child: new IgnorePointer(
            child: new Opacity(
              opacity: 0.5,
              child: new Dot()
            )
          )
        )
      );
    }

    return new Container(
      decoration: new BoxDecoration(backgroundColor: Colors.pink[500]),
      child: new Stack(layers)
    );
  }
}

void main() {
  runApp(new DragAndDropApp());
}
