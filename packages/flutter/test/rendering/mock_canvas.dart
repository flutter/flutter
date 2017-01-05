// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

class MockCanvas implements Canvas {
  final List<Invocation> invocations = <Invocation>[];

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

class MockPaintingContext implements PaintingContext {
  MockPaintingContext(this.canvas);

  @override
  final Canvas canvas;

  @override
  void noSuchMethod(Invocation invocation) {
  }
}
