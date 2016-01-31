// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:sky_services/semantics/semantics.mojom.dart' as mojom;

class TestSemanticsListener implements mojom.SemanticsListener {
  TestSemanticsListener() {
    Renderer.instance.setSemanticsClient(this);
  }
  final List<mojom.SemanticsNode> updates = <mojom.SemanticsNode>[];
  updateSemanticsTree(List<mojom.SemanticsNode> nodes) {
    assert(!nodes.any((mojom.SemanticsNode node) => node == null));
    updates.addAll(nodes);
    updates.add(null);
  }
}
