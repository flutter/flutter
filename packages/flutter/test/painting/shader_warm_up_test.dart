// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

class TestCanvas implements Canvas {
  TestCanvas([this.invocations]);

  final List<Invocation> invocations;

  @override
  void noSuchMethod(Invocation invocation) {
    invocations?.add(invocation);
  }
}

void main() {
  test('DefaultShaderWarmUp has expected canvas invocations', () {
    final List<Invocation> invocations = <Invocation>[];
    final TestCanvas canvas = TestCanvas(invocations);
    const DefaultShaderWarmUp s = DefaultShaderWarmUp();
    s.warmUpOnCanvas(canvas);

    bool hasDrawRectAfterClipRRect = false;
    for (int i = 0; i < invocations.length - 1; i += 1) {
      if (invocations[i].memberName == #clipRRect && invocations[i + 1].memberName == #drawRect) {
        hasDrawRectAfterClipRRect = true;
        break;
      }
    }

    expect(hasDrawRectAfterClipRRect, true);
  });
}
