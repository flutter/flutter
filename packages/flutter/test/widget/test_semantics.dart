// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:sky_services/semantics/semantics.mojom.dart' as engine;

class TestSemanticsClient implements engine.SemanticsClient {
  TestSemanticsClient() {
    Renderer.instance.setSemanticsClient(this);
  }
  final List<engine.SemanticsNode> updates = <engine.SemanticsNode>[];
  updateSemanticsTree(List<engine.SemanticsNode> nodes) {
    assert(!nodes.any((engine.SemanticsNode node) => node == null));
    updates.addAll(nodes);
    updates.add(null);
  }
}
