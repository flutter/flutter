// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'events.dart';

/// An object that can hit-test pointers.
abstract class HitTestable {
  void hitTest(HitTestResult result, Point position);
}

/// An object that can handle events.
abstract class HitTestTarget {
  /// Override this function to receive events.
  void handleEvent(PointerEvent event, HitTestEntry entry);
}

/// Data collected during a hit test about a specific [HitTestTarget].
///
/// Subclass this object to pass additional information from the hit test phase
/// to the event propagation phase.
class HitTestEntry {
  const HitTestEntry(this.target);

  /// The [HitTestTarget] encountered during the hit test.
  final HitTestTarget target;

  String toString() => '$target';
}

/// The result of performing a hit test.
class HitTestResult {
  HitTestResult({ List<HitTestEntry> path })
    : path = path ?? <HitTestEntry>[];

  /// The list of [HitTestEntry] objects recorded during the hit test.
  ///
  /// The first entry in the path is the most specific, typically the one at
  /// the leaf of tree being hit tested. Event propagation starts with the most
  /// specific (i.e., first) entry and proceeds in order through the path.
  final List<HitTestEntry> path;

  /// Add a [HitTestEntry] to the path.
  ///
  /// The new entry is added at the end of the path, which means entries should
  /// be added in order from most specific to least specific, typically during an
  /// upward walk of the tree being hit tested.
  void add(HitTestEntry entry) {
    path.add(entry);
  }

  String toString() => 'HitTestResult(${path.isEmpty ? "<empty path>" : path.join(", ")})';
}
