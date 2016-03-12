// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ModalBottomSheetDemo extends StatelessComponent {
  final TextStyle textStyle = new TextStyle(
    color: Colors.indigo[400],
    fontSize: 24.0,
    textAlign: TextAlign.center
  );

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(center: new Text("Modal Bottom Sheet")),
      body: new Center(
        child: new Container(
          width: 200.0,
          height: 200.0,
          child: new RaisedButton(
            child: new Text('Show the modal bottom sheet', style: textStyle),
            onPressed: () {
              showModalBottomSheet(context: context, builder: (_) {
                return new Container(
                  child: new Padding(
                    padding: const EdgeDims.all(32.0),
                    child: new Text("This is the modal bottom sheet. Click anywhere to dismiss.", style: textStyle)
                  )
                );
              });
            }
          )
        )
      )
    );
  }
}
