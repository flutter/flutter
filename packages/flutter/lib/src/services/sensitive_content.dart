// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
library;

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// The possible values for a widget tree's content sensitivity.
///
/// {@template flutter.services.ContentSensitivity}
/// There are three [ContentSensitivity] levels, and these can be set via the
/// `SensitiveContent` widget.
///
/// [ContentSensitivity.sensitive] is the highest prioritized setting, and if it is set,
/// it will cause the tree to remain marked sensitive even if there are other
/// `SensitiveContent` widgets in the tree.
///
/// [ContentSensitivity.autoSensitive] is the second most prioritized setting, and it will
/// cause the tree to remain marked auto-sensitive if there are no sensitive `SensitiveContent`
/// widgets elsewhere in the tree.
///
/// [ContentSensitivity.notSensitive] is the least prioritized setting, and it will cause the tree to
/// remain marked auto-sensitive if there are no sensitive `SensitiveContent` widgets elsewhere in
/// the tree. If there are no `SensitiveContent` widgets in the tree, the default setting as
/// queried from the embedding will be used. This could be set by a Flutter developer in native
/// Android; otherwise, Android uses [ContentSensitivity.autoSensitive] by default; see
/// https://developer.android.com/reference/android/view/View#getContentSensitivity().
/// {@endtemplate}
///
/// * See `SensitiveContent` for how to set a [ContentSensitivity] level
///   in order for sensitive content to be obscured when the Flutter screen
///   is shared.
enum ContentSensitivity {
  /// Content sensitivity is auto-detected by the native platform.
  ///
  /// When this level is set via a `SensitiveContent` widget, the window
  /// hosting the screen will only be marked as sensitive if other `SensitiveContent`
  /// widgets in the Flutter app with the [sensitive] level are present in the widget tree.
  ///
  /// See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_AUTO for how
  /// this mode behaves on native Android.
  ///
  /// For Android `View`s, this mode attempts to auto detect passwords, 2factor tokens, and other
  /// sensitive content. As of API 35, Android cannot determine if Flutter `View`s contain sensitive
  /// content automatically, and thus will never obscure the screen.
  // TODO(camsim99): Implement `autoSensitive` mode that matches the behavior
  // of `CONTENT_SENSITIVITY_AUTO` on Android that has implemented based on autofill hints; see
  // https://github.com/flutter/flutter/issues/160879.
  autoSensitive,

  /// The widget tree contains sensitive content.
  ///
  /// When this level is set via a `SensitiveContent` widget, the window
  /// hosting the screen will be marked as sensitive during an active media
  /// projection session.
  ///
  /// See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_SENSITIVE.
  sensitive,

  /// The widget tree does not contain sensitive content.
  ///
  /// When this level is set via a `SensitiveContent` widget, the window
  /// hosting the screen will only be marked as sensitive if other `SensitiveContent`
  /// widgets in the Flutter app with the [sensitive] level are present in the widget tree.
  ///
  /// See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_NOT_SENSITIVE.
  notSensitive,

  /// The sensitivity content level is unknown to Flutter.
  ///
  /// This mode may represent the current content sensitivity of the window if, for example, Android
  /// adds a new mode that is not recognized by the `SensitiveContent` widget.
  ///
  /// This mode cannot be used to set the sensitivity level of a `SensitiveContent` widget.
  _unknown,
}

/// Service for setting the content sensitivity of the native app window (Android `View`)
/// that contains the app's widget tree.
///
/// This service is only currently supported on Android API 35+.
class SensitiveContentService {
  /// Creates service to set content sensitivity of an app window (Android `View`) via
  /// communication over the sensitive content [MethodChannel].
  SensitiveContentService() {
    sensitiveContentChannel = SystemChannels.sensitiveContent;
  }

  /// The channel used to communicate with the shell side to get and set the
  /// content sensitivity of an app window (Android `View`).
  late MethodChannel sensitiveContentChannel;

  /// Sets content sensitivity level of the app window (Android `View`) that contains the app's widget
  /// tree to the level specified by [contentSensitivity] via a call to the native embedder.
  Future<void> setContentSensitivity(ContentSensitivity contentSensitivity) async {
    await sensitiveContentChannel.invokeMethod<void>(
      'SensitiveContent.setContentSensitivity',
      contentSensitivity.index,
    );
  }

  /// Gets content sensitivity level of the app window (Android `View`) that contains
  /// the app's widget tree.
  Future<ContentSensitivity> getContentSensitivity() async {
    final int? result = await sensitiveContentChannel.invokeMethod<int>(
      'SensitiveContent.getContentSensitivity',
    );

    final ContentSensitivity contentSensitivity = ContentSensitivity.values[result!];
    if (contentSensitivity == ContentSensitivity._unknown) {
      throw UnsupportedError(
        'Android Flutter View has a content sensitivity mode '
        'that is not recognized by Flutter. If you see this error, it '
        'is possible that the View uses a new mode that Flutter needs to '
        'support; please file an issue.',
      );
    }

    return contentSensitivity;
  }

  /// Returns whether or not setting content sensitivity levels is supported
  /// by the device.
  ///
  /// This method must be called before attempting to call [getContentSensitivity]
  /// or [setContentSensitivity].
  ///
  /// This feature is only supported on Android 35+ currently. Its return value will
  /// not change and thus, is safe to cache.
  Future<bool> isSupported() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    return (await sensitiveContentChannel.invokeMethod<bool>('SensitiveContent.isSupported'))!;
  }
}
