// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/material.dart';
import 'package:sky/painting.dart';
import 'package:sky/rendering.dart';
import 'package:sky/widgets.dart';

class DragData {
  DragData(this.text);

  final String text;
}

class ExampleDragTarget extends StatefulComponent {
  ExampleDragTargetState createState() => new ExampleDragTargetState();
}

class ExampleDragTargetState extends State<ExampleDragTarget> {
  String _text = 'Drag Target';

  void _handleAccept(DragData data) {
    setState(() {
      _text = 'dropped: ${data.text}';
    });
  }

  Widget build(BuildContext context) {
    return new DragTarget<DragData>(
      onAccept: _handleAccept,
      builder: (BuildContext context, List<DragData> data, _) {
        return new Container(
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
  Dot({ Key key, this.color }): super(key: key);
  final Color color;
  Widget build(BuildContext context) {
    return new Container(
      width: 50.0,
      height: 50.0,
      decoration: new BoxDecoration(
        backgroundColor: color
      )
    );
  }
}

class ExampleDragSource extends StatelessComponent {
  ExampleDragSource({ Key key, this.navigator, this.name, this.color }): super(key: key);
  final NavigatorState navigator;
  final String name;
  final Color color;
  Widget build(BuildContext context) {
    return new Draggable(
      navigator: navigator,
      data: new DragData(name),
      child: new Dot(color: color),
      feedback: new Dot(color: color)
    );
  }
}

class DragAndDropApp extends StatefulComponent {
  DragAndDropApp({ this.navigator });
  final NavigatorState navigator;
  DragAndDropAppState createState() => new DragAndDropAppState();
}

class DragAndDropAppState extends State<DragAndDropApp> {
  Widget build(BuildContext context) {
    return new Scaffold(
      toolbar: new ToolBar(
        center: new Text('Drag and Drop Flutter Demo')
      ),
      body: new Material(
        child: new DefaultTextStyle(
          style: Theme.of(context).text.body1.copyWith(textAlign: TextAlign.center),
          child: new Column([
            new Flexible(child: new Row([
                new ExampleDragSource(navigator: config.navigator, name: 'Orange', color: const Color(0xFFFF9000)),
                new ExampleDragSource(navigator: config.navigator, name: 'Teal', color: const Color(0xFF00FFFF)),
                new ExampleDragSource(navigator: config.navigator, name: 'Yellow', color: const Color(0xFFFFF000)),
              ],
              alignItems: FlexAlignItems.center,
              justifyContent: FlexJustifyContent.spaceAround
            )),
            new Flexible(child: new Row([
              new Flexible(child: new ExampleDragTarget()),
              new Flexible(child: new ExampleDragTarget()),
              new Flexible(child: new ExampleDragTarget()),
              new Flexible(child: new ExampleDragTarget()),
            ])),
          ])
        )
      )
    );
  }
}

void main() {
  runApp(new App(
    title: 'Drag and Drop Flutter Demo',
    routes: {
     '/': (NavigatorState navigator, Route route) => new DragAndDropApp(navigator: navigator)
    }
  ));
}
