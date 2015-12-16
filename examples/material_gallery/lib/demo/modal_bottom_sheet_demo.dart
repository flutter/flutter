// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'widget_demo.dart';

class ModalBottomSheetDemo extends StatelessComponent {
  final TextStyle textStyle = new TextStyle(
    color: Colors.indigo[400],
    fontSize: 24.0,
    textAlign: TextAlign.center
  );

  void _showModalBottomSheet(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) {
      return new Container(
        child: new Padding(
          padding: const EdgeDims.all(32.0),
          child: new Text("This is the modal bottom sheet. Click anywhere to dismiss.", style: textStyle)
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
          onPressed: () { _showModalBottomSheet(context); },
          child: new Text('Show the modal bottom sheet', style: textStyle)
        )
      )
    );
  }
}

final WidgetDemo kModalBottomSheetDemo = new WidgetDemo(
  title: 'Modal Bottom Sheet',
  routeName: '/modalBottomSheet',
  builder: (_) => new ModalBottomSheetDemo()
);
