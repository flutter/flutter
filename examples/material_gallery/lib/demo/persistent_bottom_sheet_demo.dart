// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class PersistentBottomSheetDemo extends StatelessWidget {

  final TextStyle textStyle = new TextStyle(
    color: Colors.indigo[400],
    fontSize: 24.0,
    textAlign: TextAlign.center
  );

  void showBottomSheet(BuildContext context) {
    Scaffold.of(context).showBottomSheet((_) {
      return new Container(
        decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: Colors.black26))
        ),
        child: new Padding(
          padding: const EdgeInsets.all(32.0),
          child: new Text("This is a Material persistent bottom sheet. Drag downwards to dismiss it.", style: textStyle)
        )
      );
    });
  }

  @override
  Widget build(BuildContext notUsed) { // Can't find the Scaffold from this context.
    return new Scaffold(
      appBar: new AppBar(title: new Text("Persistent Bottom Sheet")),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(icon: Icons.add),
        backgroundColor: Colors.redAccent[200]
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new Center(
            child: new Container(
              width: 200.0,
              height: 200.0,
              child: new RaisedButton(
                onPressed: () { showBottomSheet(context); },
                child: new Text('Show the persistent bottom sheet', style: textStyle)
              )
            )
          );
        }
      )
    );
  }
}
