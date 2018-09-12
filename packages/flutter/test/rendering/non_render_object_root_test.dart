// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import '../flutter_test_alternative.dart';

import 'rendering_tester.dart';

class RealRoot extends AbstractNode {
  RealRoot(this.child) {
    if (child != null)
      adoptChild(child);
  }

  final RenderObject child;

  @override
  void redepthChildren() {
    if (child != null)
      redepthChild(child);
  }

  @override
  void attach(Object owner) {
    super.attach(owner);
    child?.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    child?.detach();
  }

  @override
  PipelineOwner get owner => super.owner;

  void layout() {
    child?.layout(BoxConstraints.tight(const Size(500.0, 500.0)));
  }
}

void main() {
  test('non-RenderObject roots', () {
    RenderPositionedBox child;
    final RealRoot root = RealRoot(
      child = RenderPositionedBox(
        alignment: Alignment.center,
        child: RenderSizedBox(const Size(100.0, 100.0))
      )
    );
    root.attach(PipelineOwner());

    child.scheduleInitialLayout();
    root.layout();

    child.markNeedsLayout();
    root.layout();
  });
}
