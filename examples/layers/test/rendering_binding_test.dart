// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/src/binding.dart';

void main() {
  test('ViewRenderingFlutterBinding initializes when platform semantics is enabled', () {
    final binding = _SemanticsEnabledViewRenderingFlutterBinding(root: RenderPositionedBox());

    expect(RendererBinding.instance, same(binding));
    expect(binding.rootPipelineOwner.semanticsOwner, isNotNull);
  });
}

class _SemanticsEnabledViewRenderingFlutterBinding extends ViewRenderingFlutterBinding {
  _SemanticsEnabledViewRenderingFlutterBinding({super.root});

  @override
  bool get semanticsEnabled => true;
}
