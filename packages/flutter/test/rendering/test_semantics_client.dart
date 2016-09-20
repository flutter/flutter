// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_services/semantics.dart' as mojom;

class TestSemanticsClient {
  TestSemanticsClient(PipelineOwner pipelineOwner) {
    _semanticsOwner = pipelineOwner.addSemanticsListener(_updateSemanticsTree);
  }

  SemanticsOwner _semanticsOwner;

  void dispose() {
    _semanticsOwner.removeListener(_updateSemanticsTree);
    _semanticsOwner = null;
  }

  final List<mojom.SemanticsNode> updates = <mojom.SemanticsNode>[];

  void _updateSemanticsTree(List<mojom.SemanticsNode> nodes) {
    updates.addAll(nodes);
  }
}
