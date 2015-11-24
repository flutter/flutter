// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(new Opacity(
    opacity: 0.5,
    child: new Container(
      margin: new EdgeDims.all(20.0),
      decoration: new BoxDecoration(
        backgroundColor: new Color(0xFF00FFFF)
      ),
      child: new Column([
        new Container(
          height: 100.0,
          margin: new EdgeDims.all(20.0),
          decoration: new BoxDecoration(
            backgroundColor: new Color(0xFFFF0000)
          )
        ),
        new RepaintBoundary(
          child: new Container(
            height: 100.0,
            margin: new EdgeDims.all(20.0),
            decoration: new BoxDecoration(
              backgroundColor: new Color(0xFF00FF00)
            )
          )
        ),
        new Container(
          height: 100.0,
          margin: new EdgeDims.all(20.0),
          decoration: new BoxDecoration(
            backgroundColor: new Color(0xFF0000FF)
          )
        )
      ])
    )
  ));
  new Timer(new Duration(seconds: 1), () {
    debugDumpApp();
    debugDumpRenderTree();
    debugDumpLayerTree();
  });
}
