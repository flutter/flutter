// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

const String _text1 =
  "Snackbars provide lightweight feedback about an operation by "
  "showing a brief message at the bottom of the screen. Snackbars "
  "can contain an action.";

const String _text2 =
  "Snackbars should contain a single line of text directly related "
  "to the operation performed. They cannot contain icons.";

const String _text3 =
  "By default snackbars automatically disappear after a few seconds ";

class SnackBarDemo extends StatelessComponent {
  SnackBarDemo({ Key key }) : super(key: key);

  Widget buildBody(BuildContext context) {
    return new Padding(
      padding: const EdgeDims.all(24.0),
      child: new Column(
        children: <Widget>[
          new Text(_text1),
          new Text(_text2),
          new RaisedButton(
            child: new Text('Show a SnackBar'),
            onPressed: () {
              Scaffold.of(context).showSnackBar(new SnackBar(
                content: new Text('This is a SnackBar'),
                actions: <SnackBarAction>[
                  new SnackBarAction(
                    label: 'Action',
                    onPressed: () {
                      Scaffold.of(context).showSnackBar(new SnackBar(
                        content: new Text("You pressed the SnackBar's Action")
                      ));
                    }
                  )
                ]
              ));
            }
          ),
          new Text(_text3),
        ]
        .map((Widget child) {
          return new Container(
            margin: const EdgeDims.symmetric(vertical: 12.0),
            child: child
          );
        })
        .toList()
      )
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text('SnackBar')
      ),
      body: new Builder(
        // Create an inner BuildContext so that the snackBar onPressed methods
        // can refer to the Scaffold with Scaffold.of().
        builder: buildBody
      )
    );
  }
}
