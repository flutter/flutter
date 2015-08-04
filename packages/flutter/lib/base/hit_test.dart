// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

enum EventDisposition {
  ignored,
  processed,
  consumed,
}

EventDisposition combineEventDispositions(EventDisposition left, EventDisposition right) {
  if (left == EventDisposition.consumed || right == EventDisposition.consumed)
    return EventDisposition.consumed;
  if (left == EventDisposition.processed || right == EventDisposition.processed)
    return EventDisposition.processed;
  return EventDisposition.ignored;
}

abstract class HitTestTarget {
  EventDisposition handleEvent(sky.Event event, HitTestEntry entry);
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
