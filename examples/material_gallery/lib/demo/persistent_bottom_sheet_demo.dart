// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class PersistentBottomSheetDemo extends StatefulWidget {
  static const String routeName = '/persistent-bottom-sheet';

  @override
  _PersistentBottomSheetDemoState createState() => new _PersistentBottomSheetDemoState();
}

class _PersistentBottomSheetDemoState extends State<PersistentBottomSheetDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final TextStyle textStyle = new TextStyle(
    color: Colors.indigo[400],
    fontSize: 24.0,
    textAlign: TextAlign.center
  );

  VoidCallback _showBottomSheetCallback;

  @override
  void initState() {
    super.initState();
    _showBottomSheetCallback = showBottomSheet;
  }


  void showBottomSheet() {
    setState(() { // disable the button
      _showBottomSheetCallback = null;
    });
    _scaffoldKey.currentState.showBottomSheet/*<Null>*/((BuildContext context) {
      return new Container(
        decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: Colors.black26))
        ),
        child: new Padding(
          padding: const EdgeInsets.all(32.0),
          child: new Text('This is a Material persistent bottom sheet. Drag downwards to dismiss it.', style: textStyle)
        )
      );
    })
    .closed.then((_) {
      setState(() { // re-enable the button
        _showBottomSheetCallback = showBottomSheet;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(title: new Text('Persistent bottom sheet')),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(icon: Icons.add),
        backgroundColor: Colors.redAccent[200]
      ),
      body: new Center(
        child: new RaisedButton(
          onPressed: _showBottomSheetCallback,
          child: new Text('SHOW BOTTOM SHEET')
        )
      )
    );
  }
}
