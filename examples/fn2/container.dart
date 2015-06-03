// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'package:sky/framework/fn2.dart';
import 'package:sky/framework/rendering/box.dart';

class ContainerApp extends App {
  UINode build() {
    return new EventListenerNode(
      new BlockContainer(children: [
        new Container(
          padding: new EdgeDims.all(10.0),
          margin: new EdgeDims.all(10.0),
          desiredSize: new sky.Size(double.INFINITY, 100.0),
          decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFF00FF00)),
          child: new BlockContainer(
              children: [
                  new Container(
                      decoration: new BoxDecoration(backgroundColor: const sky.Color(0xFFFFFF00)),
                      desiredSize: new sky.Size(double.INFINITY, 20.0)
                  )
              ])),
      ]),
      onPointerDown: _handlePointerDown);
  }

  void _handlePointerDown(sky.PointerEvent event) {
    print("_handlePointerDown");
  }
}

void main() {
  new ContainerApp();
}
