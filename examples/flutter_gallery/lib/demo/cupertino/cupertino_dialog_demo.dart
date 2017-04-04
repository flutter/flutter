// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const Color _kBlue = const Color(0xFF007AFF);

class CupertinoDialogDemo extends StatefulWidget {
  static const String routeName = '/cupertino/dialog';

  @override
  _CupertinoDialogDemoState createState() => new _CupertinoDialogDemoState();
}

class _CupertinoDialogDemoState extends State<CupertinoDialogDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void showDemoDialog<T>({ BuildContext context, Widget child }) {
    showDialog<T>(
      context: context,
      child: child,
      barrierDismissible: false,
    )
    .then<Null>((T value) { // The value passed to Navigator.pop() or null.
      if (value != null) {
        _scaffoldKey.currentState.showSnackBar(new SnackBar(
          content: new Text('You selected: $value')
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text('Cupertino Dialogs'),
      ),
      body: new ListView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 72.0),
        children: <Widget> [
          new CupertinoButton(
            child: new Text('Alert'),
            color: _kBlue,
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: new CupertinoAlertDialog(
                  content: new Text('Discard draft?'),
                  actions: <Widget>[
                    new CupertinoDialogAction(
                      child: new Text('Discard'),
                      isDestructive: true,
                      onPressed: () { Navigator.pop(context, 'OK'); }
                    ),
                    new CupertinoDialogAction(
                      child: new Text('Cancel', style: const TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () { Navigator.pop(context, 'Cancel'); }
                    ),
                  ]
                ),
              );
            },
          ),
          new Padding(padding: const EdgeInsets.all(8.0)),
          new CupertinoButton(
            child: new Text('Alert with Title'),
            color: _kBlue,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 36.0),
            onPressed: () {
              showDemoDialog<String>(
                context: context,
                child: new CupertinoAlertDialog(
                  title: new Text('Allow "Maps" to access your location while you use the app?'),
                  content: new Text(
                    'Your current location will be displayed on the map and used for directions, '
                    'nearby search results, and estimated travel times.'
                  ),
                  actions: <Widget>[
                    new CupertinoDialogAction(
                      child: new Text('Don\'t Allow'),
                      onPressed: () { Navigator.pop(context, 'Disallow'); }
                    ),
                    new CupertinoDialogAction(
                      child: new Text('Allow'),
                      onPressed: () { Navigator.pop(context, 'Allow'); }
                    ),
                  ]
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
