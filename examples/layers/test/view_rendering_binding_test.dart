// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/src/binding.dart';

class _SemanticsEnabledBinding extends ViewRenderingFlutterBinding {
  _SemanticsEnabledBinding({super.root});

  @override
  late final TestPlatformDispatcher platformDispatcher = TestPlatformDispatcher(
    platformDispatcher: super.platformDispatcher,
  )..semanticsEnabledTestValue = true;
}

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/160157.
  test('ViewRenderingFlutterBinding works when semantics is enabled at startup', () {
    final binding = _SemanticsEnabledBinding(
      root: RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.tightFor(width: 10, height: 10),
      ),
    );

    final PipelineOwner owner = binding.rootPipelineOwner;
    expect(owner.semanticsOwner, isNotNull);

    owner.flushLayout();
    owner.flushSemantics();
    expect(owner.semanticsOwner!.rootSemanticsNode, isNotNull);
  });
}
