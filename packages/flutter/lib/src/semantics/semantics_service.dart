// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:async';
import 'dart:ui' show TextDirection;

import 'package:flutter/services.dart' show SystemChannels;

import 'semantics_event.dart' show AnnounceSemanticsEvent, TooltipSemanticsEvent;


/// Allows access to the platform's accessibility services.
///
/// Events sent by this service are handled by the platform-specific
/// accessibility bridge in Flutter's engine.
///
/// When possible, prefer using mechanisms like [Semantics] to implicitly
/// trigger announcements over using this event.
class SemanticsService {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  SemanticsService._();

  /// Sends a semantic announcement.
  ///
  /// This should be used for announcement that are not seamlessly announced by
  /// the system as a result of a UI state change.
  ///
  /// For example a camera application can use this method to make accessibility
  /// announcements regarding objects in the viewfinder.
  static Future<void> announce(String message, TextDirection textDirection) async {
    final AnnounceSemanticsEvent event = AnnounceSemanticsEvent(message, textDirection);
    await SystemChannels.accessibility.send(event.toMap());
  }

  /// Sends a semantic announcement of a tooltip.
  ///
  /// Currently only honored on Android. The contents of [message] will be
  /// read by TalkBack.
  static Future<void> tooltip(String message) async {
    final TooltipSemanticsEvent event = TooltipSemanticsEvent(message);
    await SystemChannels.accessibility.send(event.toMap());
  }
}
