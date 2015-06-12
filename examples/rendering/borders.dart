// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:sky' as sky;
import 'package:sky/framework/app.dart';
import 'package:sky/framework/rendering/box.dart';
import 'package:sky/framework/rendering/block.dart';
import 'package:sky/framework/rendering/node.dart';

AppView app;

void main() {


  var root = new RenderBlock(children: [
    new RenderPadding(
      padding: new EdgeDims.all(10.0),
      child: new RenderSizedBox(
        desiredSize: new sky.Size.fromHeight(100.0),
        child: new RenderDecoratedBox(
          decoration: new BoxDecoration(
            backgroundColor: new sky.Color(0xFFFFFF00)
          )
        )
      )
    ),
    new RenderPadding(
      padding: new EdgeDims.all(10.0),
      child: new RenderSizedBox(
        desiredSize: new sky.Size.fromHeight(100.0),
        child: new RenderDecoratedBox(
          decoration: new BoxDecoration(
            border: new Border(
              top: new BorderSide(color: new sky.Color(0xFFF00000), width: 5.0),
              right: new BorderSide(color: new sky.Color(0xFFFF9000), width: 10.0),
              bottom: new BorderSide(color: new sky.Color(0xFFFFF000), width: 15.0),
              left: new BorderSide(color: new sky.Color(0xFF00FF00), width: 20.0)
            ),
            backgroundColor: new sky.Color(0xFFDDDDDD)
          )
        )
      )
    ),
    new RenderPadding(
      padding: new EdgeDims.all(10.0),
      child: new RenderSizedBox(
        desiredSize: new sky.Size.fromHeight(100.0),
        child: new RenderDecoratedBox(
          decoration: new BoxDecoration(
            backgroundColor: new sky.Color(0xFFFFFF00)
          )
        )
      )
    ),
    new RenderPadding(
      padding: new EdgeDims.all(10.0),
      child: new RenderSizedBox(
        desiredSize: new sky.Size.fromHeight(100.0),
        child: new RenderDecoratedBox(
          decoration: new BoxDecoration(
            backgroundColor: new sky.Color(0xFFFFFF00)
          )
        )
      )
    ),
    new RenderPadding(
      padding: new EdgeDims.all(10.0),
      child: new RenderSizedBox(
        desiredSize: new sky.Size.fromHeight(100.0),
        child: new RenderDecoratedBox(
          decoration: new BoxDecoration(
            backgroundColor: new sky.Color(0xFFFFFF00)
          )
        )
      )
    ),
  ]);
  app = new AppView(root: root);
}
