// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
library;

import 'dart:ui' show FlutterView, PlatformDispatcher, TextDirection;

import 'package:flutter/services.dart' show SystemChannels;

import 'semantics_event.dart' show AnnounceSemanticsEvent, Assertiveness, TooltipSemanticsEvent;

export 'dart:ui' show TextDirection;

/// Allows access to the platform's accessibility services.
///
/// Events sent by this service are handled by the platform-specific
/// accessibility bridge in Flutter's engine.
///
/// When possible, prefer using mechanisms like [Semantics] to implicitly
/// trigger announcements over using this event.
abstract final class SemanticsService {
  /// Sends a semantic announcement.
  ///
  /// This method is deprecated. Prefer using [sendAnnouncement] instead.
  ///
  /// {@template flutter.semantics.service.announce}
  /// This should be used for announcement that are not seamlessly announced by
  /// the system as a result of a UI state change.
  ///
  /// For example a camera application can use this method to make accessibility
  /// announcements regarding objects in the viewfinder.
  ///
  /// The assertiveness level of the announcement is determined by [assertiveness].
  /// Currently, this is only supported by the web engine and has no effect on
  /// other platforms. The default mode is [Assertiveness.polite].
  ///
  /// Not all platforms support announcements. Check to see if it is supported using
  /// [MediaQuery.supportsAnnounceOf] before calling this method.
  ///
  /// ### Android
  /// Android has [deprecated announcement events][1] due to its disruptive
  /// behavior with TalkBack forcing it to clear its speech queue and speak the
  /// provided text. Instead, use mechanisms like [Semantics] to implicitly
  /// trigger announcements.
  ///
  /// [1]: https://developer.android.com/reference/android/view/View#announceForAccessibility(java.lang.CharSequence)
  /// {@endtemplate}
  ///
  @Deprecated(
    'Use sendAnnouncement instead. '
    'This API is incompatible with multiple windows. '
    'This feature was deprecated after v3.35.0-0.1.pre.',
  )
  static Future<void> announce(
    String message,
    TextDirection textDirection, {
    Assertiveness assertiveness = Assertiveness.polite,
  }) async {
    final FlutterView? view = PlatformDispatcher.instance.implicitView;
    assert(
      view != null,
      'SemanticsService.announce is incompatible with multiple windows. '
      'Use SemanticsService.sendAnnouncement instead.',
    );
    final event = AnnounceSemanticsEvent(
      message,
      textDirection,
      view!.viewId,
      assertiveness: assertiveness,
    );
    await SystemChannels.accessibility.send(event.toMap());
  }

  /// Sends a semantic announcement for a particular view.
  ///
  /// One can use [View.of] to get the current [FlutterView].
  ///
  /// {@macro flutter.semantics.service.announce}
  static Future<void> sendAnnouncement(
    FlutterView view,
    String message,
    TextDirection textDirection, {
    Assertiveness assertiveness = Assertiveness.polite,
  }) async {
    final event = AnnounceSemanticsEvent(
      message,
      textDirection,
      view.viewId,
      assertiveness: assertiveness,
    );
    await SystemChannels.accessibility.send(event.toMap());
  }

  /// Sends a semantic announcement of a tooltip.
  ///
  /// Currently only honored on Android. The contents of [message] will be
  /// read by TalkBack.
  static Future<void> tooltip(String message) async {
    final event = TooltipSemanticsEvent(message);
    await SystemChannels.accessibility.send(event.toMap());
  }
}
