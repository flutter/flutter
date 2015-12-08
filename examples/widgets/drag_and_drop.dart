// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

class ExampleDragTarget extends StatefulComponent {
  ExampleDragTargetState createState() => new ExampleDragTargetState();
}

class ExampleDragTargetState extends State<ExampleDragTarget> {
  Color _color = Colors.grey[500];

  void _handleAccept(Color data) {
    setState(() {
      _color = data;
    });
  }

  Widget build(BuildContext context) {
    return new DragTarget<Color>(
      onAccept: _handleAccept,
      builder: (BuildContext context, List<Color> data, _) {
        return new Container(
          height: 100.0,
          margin: new EdgeDims.all(10.0),
          decoration: new BoxDecoration(
            border: new Border.all(
              width: 3.0,
              color: data.isEmpty ? Colors.white : Colors.blue[500]
            ),
            backgroundColor: data.isEmpty ? _color : Colors.grey[200]
          )
        );
      }
    );
  }
}

class Dot extends StatelessComponent {
  Dot({ Key key, this.color, this.size, this.child }) : super(key: key);
  final Color color;
  final double size;
  final Widget child;
  Widget build(BuildContext context) {
    return new Container(
      width: size,
      height: size,
      decoration: new BoxDecoration(
        backgroundColor: color,
        shape: BoxShape.circle
      ),
      child: child
    );
  }
}

class ExampleDragSource extends StatelessComponent {
  ExampleDragSource({
    Key key,
    this.color,
    this.heavy: false,
    this.under: true,
    this.child
  }) : super(key: key);

  final Color color;
  final bool heavy;
  final bool under;
  final Widget child;

  static const double kDotSize = 50.0;
  static const double kHeavyMultiplier = 1.5;
  static const double kFingerSize = 50.0;

  Widget build(BuildContext context) {
    double size = kDotSize;
    if (heavy)
      size *= kHeavyMultiplier;

    Widget contents = new DefaultTextStyle(
      style: Theme.of(context).text.body1.copyWith(textAlign: TextAlign.center),
      child: new Dot(
        color: color,
        size: size,
        child: new Center(child: child)
      )
    );

    Widget feedback = new Opacity(
      opacity: 0.75,
      child: contents
    );

    Offset feedbackOffset;
    DragAnchor anchor;
    if (!under) {
      feedback = new Transform(
        transform: new Matrix4.identity()
                     ..translate(-size / 2.0, -(size / 2.0 + kFingerSize)),
        child: feedback
      );
      feedbackOffset = const Offset(0.0, -kFingerSize);
      anchor = DragAnchor.pointer;
    } else {
      feedbackOffset = Offset.zero;
      anchor = DragAnchor.child;
    }

    if (heavy) {
      return new LongPressDraggable<Color>(
        data: color,
        child: contents,
        feedback: feedback,
        feedbackOffset: feedbackOffset,
        dragAnchor: anchor
      );
    } else {
      return new Draggable<Color>(
        data: color,
        child: contents,
        feedback: feedback,
        feedbackOffset: feedbackOffset,
        dragAnchor: anchor
      );
    }
  }
}

class DragAndDropApp extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text('Drag and Drop Flutter Demo')
      ),
      body: new Column(<Widget>[
        new Flexible(child: new Row(<Widget>[
            new ExampleDragSource(
              color: const Color(0xFFFFF000),
              under: true,
              heavy: false,
              child: new Text('under')
            ),
            new ExampleDragSource(
              color: const Color(0xFF0FFF00),
              under: false,
              heavy: true,
              child: new Text('long-press above')
            ),
            new ExampleDragSource(
              color: const Color(0xFF00FFF0),
              under: false,
              heavy: false,
              child: new Text('above')
            ),
          ],
          alignItems: FlexAlignItems.center,
          justifyContent: FlexJustifyContent.spaceAround
        )),
        new Flexible(child: new Row(<Widget>[
          new Flexible(child: new ExampleDragTarget()),
          new Flexible(child: new ExampleDragTarget()),
          new Flexible(child: new ExampleDragTarget()),
          new Flexible(child: new ExampleDragTarget()),
        ])),
      ])
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'Drag and Drop Flutter Demo',
    routes: <String, RouteBuilder>{
     '/': (RouteArguments args) => new DragAndDropApp()
    }
  ));
}
