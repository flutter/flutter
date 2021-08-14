// Copyright 2014 The Flutter Authors. All rights reserved.
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
  Map<String, dynamic> toMap({ int? nodeId }) {
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
    for (final String key in sortedKeys)
      pairs.add('$key: ${dataMap[key]}');
    return '${objectRuntimeType(this, 'SemanticsEvent')}(${pairs.join(', ')})';
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
  const AnnounceSemanticsEvent(this.message, this.textDirection)
    : assert(message != null),
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

/// An event for a semantic announcement of a tooltip.
///
/// This is only used by Android to announce tooltip values.
class TooltipSemanticsEvent extends SemanticsEvent {
  /// Constructs an event that triggers a tooltip announcement by the platform.
  const TooltipSemanticsEvent(this.message) : super('tooltip');

  /// The text content of the tooltip.
  final String message;

  @override
  Map<String, dynamic> getDataMap() {
    return <String, dynamic>{
      'message': message,
    };
  }
}

/// An event which triggers long press semantic feedback.
///
/// Currently only honored on Android. Triggers a long-press specific sound
/// when TalkBack is enabled.
class LongPressSemanticsEvent extends SemanticsEvent {
  /// Constructs an event that triggers a long-press semantic feedback by the platform.
  const LongPressSemanticsEvent() : super('longPress');

  @override
  Map<String, dynamic> getDataMap() => const <String, dynamic>{};
}

/// An event which triggers tap semantic feedback.
///
/// Currently only honored on Android. Triggers a tap specific sound when
/// TalkBack is enabled.
class TapSemanticEvent extends SemanticsEvent {
  /// Constructs an event that triggers a long-press semantic feedback by the platform.
  const TapSemanticEvent() : super('tap');

  @override
  Map<String, dynamic> getDataMap() => const <String, dynamic>{};
}

/// An event which triggers a polite announcement of a live region.
///
/// This requires that the semantics node has already been marked as a live
/// region. On Android, TalkBack will make a verbal announcement, as long as
/// the label of the semantics node has changed since the last live region
/// update. iOS does not currently support this event.
///
/// Deprecated. This message was never implemented, and references to it should
/// be removed.
///
/// See also:
///
///  * [SemanticsFlag.isLiveRegion], for a description of live regions.
///
@Deprecated(
  'This event has never been implemented and will be removed in a future version of Flutter. References to it should be removed. '
  'This feature was deprecated after v1.26.0-18.0.pre.',
)
class UpdateLiveRegionEvent extends SemanticsEvent {
  /// Creates a new [UpdateLiveRegionEvent].
  @Deprecated(
    'This event has never been implemented and will be removed in a future version of Flutter. References to it should be removed. '
    'This feature was deprecated after v1.26.0-18.0.pre.',
  )
  const UpdateLiveRegionEvent() : super('updateLiveRegion');

  @override
  Map<String, dynamic> getDataMap() => const <String, dynamic>{};
}
