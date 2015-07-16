// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

abstract class HitTestTarget {
  void handleEvent(sky.Event event, HitTestEntry entry);
}

class HitTestEntry {
  const HitTestEntry(this.target);
  final HitTestTarget target;
}

class HitTestResult {
  final List<HitTestEntry> path = new List<HitTestEntry>();
  void add(HitTestEntry data) {
    path.add(data);
  }
}
