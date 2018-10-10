// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

class TestGestureRecognizer extends GestureRecognizer {
  TestGestureRecognizer({ Object debugOwner }) : super(debugOwner: debugOwner);

  @override
  String get debugDescription => 'debugDescription content';

  @override
  void addPointer(PointerDownEvent event) { }

  @override
  void acceptGesture(int pointer) { }

  @override
  void rejectGesture(int pointer) { }
}

void main() {
  test('GestureRecognizer smoketest', () {
    final TestGestureRecognizer recognizer = TestGestureRecognizer(debugOwner: 0);
    expect(recognizer, hasAGoodToStringDeep);
  });
}
