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
  /// [type] is a string that identifies this class of [SemanticsEvent]s.
  SemanticsEvent(this.type);

  /// The type of this event.
  ///
  /// The type is used by the engine to translate this event into the
  /// appropriate native event (`UIAccessibility*Notification` on iOS and
  /// `AccessibilityEvent` on Android).
  final String type;

  /// Converts this event to a Map that can be encoded with
  /// [StandardMessageCodec].
  Map<String, dynamic> toMap();
}

/// Notifies that a scroll action has been completed.
///
/// This event translates into a `AccessibilityEvent.TYPE_VIEW_SCROLLED` on
/// Android and a `UIAccessibilityPageScrolledNotification` on iOS. It is
/// processed by the accessibility systems of the operating system to provide
/// additional feedback to the user about the state of a scrollable view (e.g.
/// on Android, a ping sound is played to indicate that a scroll action was
/// successful).
class ScrollCompletedSemanticsEvent extends SemanticsEvent {
  /// Creates a [ScrollCompletedSemanticsEvent].
  ///
  /// This event should be sent after a scroll action is completed. It is
  /// interpreted by assistive technologies to provide additional feedback about
  /// the just completed scroll action to the user.
  // TODO(goderbauer): add more metadata to this event (e.g. how far are we scrolled?).
  ScrollCompletedSemanticsEvent() : super('scroll');

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{};
}
