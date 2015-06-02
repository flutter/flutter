// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'package:sky/framework/fn2.dart';

class ContainerApp extends App {
  UINode build() {
    return new EventListenerNode(
      new Rectangle(0xFF00FFFF),
      onPointerDown: _handlePointerDown);
  }

  void _handlePointerDown(sky.PointerEvent event) {
    print("_handlePointerDown");
  }
}

void main() {
  new ContainerApp();
}
