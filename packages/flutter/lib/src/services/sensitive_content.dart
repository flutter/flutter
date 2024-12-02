// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// Specifies the sensitivity level that a [SensitiveContent] widget could
/// set for the Flutter app screen.
enum ContentSensitivity {
  /// Content sensitivity auto-detected by the native framework.
  /// 
  /// On Android, a heurisitc based on autofill hints for text input is used to determine
  /// if sensitive content is present. See
  /// https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_AUTO.
  // TODO(camsim99): Implement `autoSensitive` mode that will attempt to match
  // the behavior of `CONTENT_SENSITIVITY_AUTO` on Android that has implemented
  // based on autofill hints.
  autoSensitive,
  
  /// The screen displays sensitive content and the window hosting the screen
  /// will be marked as secure during an active media projection session.
  /// 
  /// For Android, see https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_NOT_SENSITIVE.
  sensitive,

  /// The screen does not display sensitive content.
  /// 
  /// For Android, see https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_NOT_SENSITIVE.
  notSensitive,
}

/// Service for setting content sensitivity of native Flutter views.
class SensitiveContentService {
  /// Creates service to content sensitivity via communication
  /// over the sensitive content [MethodChannel].
  SensitiveContentService() {
    sensitiveContentChannel = SystemChannels.sensitiveContent;
  }

  /// The channel used to communicate with the shell side to set
  /// content sensitivity.
  late MethodChannel sensitiveContentChannel;

   /// Sets content sensitivity level of the Android `View` or `Fragment` with the specified
   /// [flutterViewId] to the level specified by [contentSensitivity] by making a call to the
   /// native embedder.
  void setContentSensitivity(int flutterViewId, ContentSensitivity contentSensitivity) {
    try {
      sensitiveContentChannel.invokeMethod(
        'SensitiveContent.setContentSensitivity',
        <int>[flutterViewId, contentSensitivity.index],
      );
    } catch (e) {
      // Content sensitivity failed to be set.
      throw FlutterError(
        'Content sensitivity failed to be set. Please ensure that the '
        'flutterViewId set corresponds to a valid Android Flutter view '
        'or Fragment.'
      );
    }
  }
}
