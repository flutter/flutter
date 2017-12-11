// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// An event sent by the application to notify interested listeners that
/// something happened to the user interface (e.g. a view scrolled).
///
/// These events are usually interpreted by assistive technologies to give the
/// user additional clues about the current state of the UI.
abstract class SemanticsEvent {
  /// Initializes internal fields.
  ///
  /// [type] is a string that identifies this class of [SemanticsEvent]s.
  const SemanticsEvent(this.type);

  /// The type of this event.
  ///
  /// The type is used by the engine to translate this event into the
  /// appropriate native event (`UIAccessibility*Notification` on iOS and
  /// `AccessibilityEvent` on Android).
  final String type;

  /// Converts this event to a Map that can be encoded with
  /// [StandardMessageCodec].
  ///
  /// [nodeId] is the unique identifier of the semantics node associated with
  /// the event, or null if the event is not associated with a semantics node.
  Map<String, dynamic> toMap({ int nodeId }) {
    final Map<String, dynamic> event = <String, dynamic>{
      'type': type,
      'data': getDataMap(),
    };
    if (nodeId != null)
      event['nodeId'] = nodeId;

    return event;
  }

  /// Returns the event's data object.
  Map<String, dynamic> getDataMap();

  @override
  String toString() {
    final List<String> pairs = <String>[];
    final Map<String, dynamic> dataMap = getDataMap();
    final List<String> sortedKeys = dataMap.keys.toList()..sort();
    for (String key in sortedKeys)
      pairs.add('$key: ${dataMap[key]}');
    return '$runtimeType(${pairs.join(', ')})';
  }
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
  ///
  /// The parameters [axis], [pixels], [minScrollExtent], and [maxScrollExtent] are
  /// required and may not be null.
  ScrollCompletedSemanticsEvent({
    @required this.axis,
    @required this.pixels,
    @required this.maxScrollExtent,
    @required this.minScrollExtent
  }) : assert(axis != null),
       assert(pixels != null),
       assert(maxScrollExtent != null),
       assert(minScrollExtent != null),
       super('scroll');

  /// The axis in which the scroll view was scrolled.
  ///
  /// See also [ScrollPosition.axis].
  final Axis axis;

  /// The current scroll position, in logical pixels.
  ///
  /// See also [ScrollPosition.pixels].
  final double pixels;

  /// The minimum in-range value for [pixels].
  ///
  /// See also [ScrollPosition.minScrollExtent].
  final double minScrollExtent;

  /// The maximum in-range value for [pixels].
  ///
  /// See also [ScrollPosition.maxScrollExtent].
  final double maxScrollExtent;

  @override
  Map<String, dynamic> getDataMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'pixels': pixels.clamp(minScrollExtent, maxScrollExtent),
      'minScrollExtent': minScrollExtent,
      'maxScrollExtent': maxScrollExtent,
    };

    switch (axis) {
      case Axis.horizontal:
        map['axis'] = 'h';
        break;
      case Axis.vertical:
        map['axis'] = 'v';
        break;
    }

    return map;
  }
}

/// An event for a semantic announcement.
///
/// This should be used for announcement that are not seamlessly announced by
/// the system as a result of a UI state change.
///
/// For example a camera application can use this method to make accessibility
/// announcements regarding objects in the viewfinder.
///
/// When possible, prefer using mechanisms like [Semantics] to implicitly
/// trigger announcements over using this event.
class AnnounceSemanticsEvent extends SemanticsEvent {

  /// Constructs an event that triggers an announcement by the platform.
  const AnnounceSemanticsEvent(this.message, this.textDirection) :
    assert(message != null),
    assert(textDirection != null),
    super('announce');

  /// The message to announce.
  ///
  /// This property must not be null.
  final String message;

  /// Text direction for [message].
  ///
  /// This property must not be null.
  final TextDirection textDirection;

  @override
  Map<String, dynamic> getDataMap() {
    return <String, dynamic>{
      'message': message,
      'textDirection': textDirection.index,
    };
  }
}
