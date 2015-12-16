// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'widget_demo.dart';

class PersistentBottomSheetDemo extends StatelessComponent {

  final TextStyle textStyle = new TextStyle(
    color: Colors.indigo[400],
    fontSize: 24.0,
    textAlign: TextAlign.center
  );

  void _showBottomSheet(BuildContext context) {
    Scaffold.of(context).showBottomSheet((_) {
      return new Container(
        decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: Colors.black26, width: 1.0))
        ),
        child: new Padding(
          padding: const EdgeDims.all(32.0),
          child: new Text("This is a Material persistent bottom sheet. Drag downwards to dismiss it.", style: textStyle)
        )
      );
    });
  }

  Widget build(BuildContext context) {
    return new Center(
      child: new Container(
        width: 200.0,
        height: 200.0,
        child: new RaisedButton(
          onPressed: () { _showBottomSheet(context); },
          child: new Text('Show the persistent bottom sheet', style: textStyle)
        )
      )
    );
  }
}

final WidgetDemo kPersistentBottomSheetDemo = new WidgetDemo(
  title: 'Persistent Bottom Sheet',
  routeName: '/persistentBottomSheet',
  builder: (_) => new PersistentBottomSheetDemo(),
  floatingActionButtonBuilder: (_) {
    return new FloatingActionButton(
      child: new Icon(icon: 'content/add'),
      backgroundColor: Colors.redAccent[200]
    );
  }
);
