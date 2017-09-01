// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// An event that can be send by the application to notify interested listeners
/// that something happened to the user interface (e.g. a view scrolled).
///
/// These events are usually interpreted by assistive technologies to give the
/// user additional clues about the current state of the UI.
abstract class SemanticsEvent {

  /// Initializes internal fields.
  ///
  /// `type` is a string that identifies this class of [SemanticsEvent]s.
  SemanticsEvent(this.type);

  /// The type of this event.
  final String type;

  /// Converts this event to a JSON-encodable Map.
  Map<String, dynamic> toJson();
}

/// Notifies that a scroll action has been completed.
class ScrollSemanticsEvent extends SemanticsEvent {

  /// Creates a [ScrollSemanticsEvent].
  // TODO(goderbauer): add more metadata to this event (e.g. how far are we scrolled?).
  ScrollSemanticsEvent() : super('scroll');

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};
}
