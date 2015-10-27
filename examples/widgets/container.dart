// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class ContainerApp extends StatelessComponent {
  Widget build(BuildContext context) {
    return new Column(<Widget>[
        new Container(
          padding: new EdgeDims.all(10.0),
          margin: new EdgeDims.all(10.0),
          decoration: new BoxDecoration(backgroundColor: const Color(0xFFCCCCCC)),
          child: new NetworkImage(
            src: "https://raw.githubusercontent.com/dart-lang/logos/master/logos_and_wordmarks/dart-logo.png",
            width: 300.0,
            height: 300.0
          )
        ),
        new Container(
          decoration: new BoxDecoration(backgroundColor: const Color(0xFFFFFF00)),
          padding: new EdgeDims.symmetric(horizontal: 50.0, vertical: 75.0),
          child: new Row(<Widget>[
            new RaisedButton(
              child: new Text('PRESS ME'),
              onPressed: () => print("Hello World")
            ),
            new RaisedButton(
              child: new Text('DISABLED')
            )
          ])
        ),
        new Flexible(
          child: new Container(
            decoration: new BoxDecoration(backgroundColor: const Color(0xFF00FFFF))
          )
        ),
      ],
      justifyContent: FlexJustifyContent.spaceBetween
    );
  }
}

void main() {
  runApp(new ContainerApp());
}
