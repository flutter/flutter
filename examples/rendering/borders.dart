// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

void main() {
  RenderFlex root = new RenderFlex(
    children: <RenderBox>[
      new RenderPadding(
        padding: new EdgeDims.all(10.0),
        child: new RenderConstrainedBox(
          additionalConstraints: new BoxConstraints.tightFor(height: 100.0),
          child: new RenderDecoratedBox(
            decoration: new BoxDecoration(
              backgroundColor: new ui.Color(0xFFFFFF00)
            )
          )
        )
      ),
      new RenderPadding(
        padding: new EdgeDims.all(10.0),
        child: new RenderConstrainedBox(
          additionalConstraints: new BoxConstraints.tightFor(height: 100.0),
          child: new RenderDecoratedBox(
            decoration: new BoxDecoration(
              border: new Border(
                top: new BorderSide(color: new ui.Color(0xFFF00000), width: 5.0),
                right: new BorderSide(color: new ui.Color(0xFFFF9000), width: 10.0),
                bottom: new BorderSide(color: new ui.Color(0xFFFFF000), width: 15.0),
                left: new BorderSide(color: new ui.Color(0xFF00FF00), width: 20.0)
              ),
              backgroundColor: new ui.Color(0xFFDDDDDD)
            )
          )
        )
      ),
      new RenderPadding(
        padding: new EdgeDims.all(10.0),
        child: new RenderConstrainedBox(
          additionalConstraints: new BoxConstraints.tightFor(height: 100.0),
          child: new RenderDecoratedBox(
            decoration: new BoxDecoration(
              backgroundColor: new ui.Color(0xFFFFFF00)
            )
          )
        )
      ),
      new RenderPadding(
        padding: new EdgeDims.all(10.0),
        child: new RenderConstrainedBox(
          additionalConstraints: new BoxConstraints.tightFor(height: 100.0),
          child: new RenderDecoratedBox(
            decoration: new BoxDecoration(
              backgroundColor: new ui.Color(0xFFFFFF00)
            )
          )
        )
      ),
      new RenderPadding(
        padding: new EdgeDims.all(10.0),
        child: new RenderConstrainedBox(
          additionalConstraints: new BoxConstraints.tightFor(height: 100.0),
          child: new RenderDecoratedBox(
            decoration: new BoxDecoration(
              backgroundColor: new ui.Color(0xFFFFFF00)
            )
          )
        )
      ),
    ],
    direction: FlexDirection.vertical
  );
  new RenderingFlutterBinding(root: root);
}
