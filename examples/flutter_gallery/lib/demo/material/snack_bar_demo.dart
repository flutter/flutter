// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const String _text1 =
  'Snackbars provide lightweight feedback about an operation by '
  'showing a brief message at the bottom of the screen. Snackbars '
  'can contain an action.';

const String _text2 =
  'Snackbars should contain a single line of text directly related '
  'to the operation performed. They cannot contain icons.';

const String _text3 =
  'By default snackbars automatically disappear after a few seconds ';

class SnackBarDemo extends StatefulWidget {
  const SnackBarDemo({ Key key }) : super(key: key);

  static const String routeName = '/material/snack-bar';

  @override
  _SnackBarDemoState createState() => new _SnackBarDemoState();
}

class _SnackBarDemoState extends State<SnackBarDemo> {
  int _snackBarIndex = 1;

  Widget buildBody(BuildContext context) {
    return new SafeArea(
      top: false,
      bottom: false,
      child: new ListView(
        padding: const EdgeInsets.all(24.0),
        children: <Widget>[
          const Text(_text1),
          const Text(_text2),
          new Center(
            child: new RaisedButton(
              child: const Text('SHOW A SNACKBAR'),
              onPressed: () {
                final int thisSnackBarIndex = _snackBarIndex++;
                Scaffold.of(context).showSnackBar(new SnackBar(
                  content: new Text('This is snackbar #$thisSnackBarIndex.'),
                  action: new SnackBarAction(
                    label: 'ACTION',
                    onPressed: () {
                      Scaffold.of(context).showSnackBar(new SnackBar(
                        content: new Text('You pressed snackbar $thisSnackBarIndex\'s action.')
                      ));
                    }
                  ),
                ));
              }
            ),
          ),
          const Text(_text3),
        ]
        .map((Widget child) {
          return new Container(
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            child: child
          );
        })
        .toList()
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Snackbar')
      ),
      body: new Builder(
        // Create an inner BuildContext so that the snackBar onPressed methods
        // can refer to the Scaffold with Scaffold.of().
        builder: buildBody
      )
    );
  }
}
