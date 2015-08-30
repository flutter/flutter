// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;

/// The outcome of running an event handler.
enum EventDisposition {
  /// The event handler ignored this event.
  ignored,

  /// The event handler did not ignore the event but other event handlers should
  /// process the event as well.
  processed,

  /// The event handler did not ignore the event and other event handlers
  /// should not process the event.
  consumed,
}

/// Merges two [EventDisposition] values such that the result indicates the
/// maximum amount of processing indicated by the two inputs.
EventDisposition combineEventDispositions(EventDisposition left, EventDisposition right) {
  if (left == EventDisposition.consumed || right == EventDisposition.consumed)
    return EventDisposition.consumed;
  if (left == EventDisposition.processed || right == EventDisposition.processed)
    return EventDisposition.processed;
  return EventDisposition.ignored;
}

/// An object that can handle events.
abstract class HitTestTarget {
  /// Override this function to receive events.
  EventDisposition handleEvent(sky.Event event, HitTestEntry entry);
}

/// Data collected during a hit test about a specific [HitTestTarget].
///
/// Subclass this object to pass additional information from the hit test phase
/// to the event propagation phase.
class HitTestEntry {
  const HitTestEntry(this.target);

  /// The [HitTestTarget] encountered during the hit test.
  final HitTestTarget target;
}

/// The result of performing a hit test.
class HitTestResult {
  HitTestResult({ List<HitTestEntry> path })
    : path = path != null ? path : new List<HitTestEntry>();

  /// The list of [HitTestEntry] objects recorded during the hit test.
  ///
  /// The first entry in the path is the least specific, typically the one at
  /// the root of tree being hit tested. Event propagation starts with the most
  /// specific (i.e., last) entry and proceeds in reverse order through the
  /// path.
  final List<HitTestEntry> path;

  /// Add a [HitTestEntry] to the path.
  ///
  /// The new entry is added at the end of the path, which means entries should
  /// be added in order from last specific to most specific, typically during a
  /// downward walk in the tree being hit tested.
  void add(HitTestEntry entry) {
    path.add(entry);
  }
}
