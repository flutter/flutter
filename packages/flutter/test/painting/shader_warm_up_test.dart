// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

class TestCanvas implements Canvas {
  TestCanvas();

  final List<Invocation> invocations = <Invocation>[];

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

void main() {
  test('DefaultShaderWarmUp has expected canvas invocations', () {
    final TestCanvas canvas = TestCanvas();
    const DefaultShaderWarmUp s = DefaultShaderWarmUp();
    s.warmUpOnCanvas(canvas);

    bool hasDrawRectAfterClipRRect = false;
    for (int i = 0; i < canvas.invocations.length - 1; i += 1) {
      if (canvas.invocations[i].memberName == #clipRRect && canvas.invocations[i + 1].memberName == #drawRect) {
        hasDrawRectAfterClipRRect = true;
        break;
      }
    }

    expect(hasDrawRectAfterClipRRect, true);
  });
}
