// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
library;

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// The level of sensitivity that content in a particular widget tree.
///
/// There are only three levels and can be set via a
/// [SensitiveContent] widget. [ContentSensitivity.sensitive] is the most
/// severe setting and if set with a `SensitiveContent` widget,
/// will cause the tree to remain marked sensitive even if there are other
/// `SensitiveContent` widgets in the tree. [ContentSensitivity.autoSensitive]
/// is the second most severe setting and will cause the tree to remain marked
/// auto-sensitive if there are either (1) no other [SensitiveContent] widgets in the tree or (2) there are only other auto-sensitive or not sensitive
/// `SensitiveContent` widgets in the tree. [ContentSensitive.notSensitive]
/// is the least severe setting and will cause the tree to remain marked not
/// sensitive as long as there are (1) no other [SensitiveContent] widgets in the tree or (2) there are only other not sensitive `SensitiveContent`
/// widgets in the tree. If there are no `SensitiveContent` widget in the tree,
/// the default setting as queried from the embedding will be used. This could be
/// set by a Flutter developer in native Android; otherwise, Android uses [ContentSensitivity.autoSensitive] by default.
///
/// * See [SensitiveContent] for how to set a [ContentSensitivity] level
///   in order for sensitive content to be obscured when the Flutter screen
///   is shared.
enum ContentSensitivity {
  /// Content sensitivity is auto-detected by the native framework.
  ///
  /// When this level is set via a [SensitiveContent] widget, the window
  /// hosting the screen will only be marked as sensitive if other [SensitiveContent]
  /// widgets in the Flutter app with the [sensitive] level are present in the widget tree.
  ///
  /// The sensitive content is unable to be auto-detected by the
  /// native framework.
  // TODO(camsim99): Implement `autoSensitive` mode that matches the behavior
  // of `CONTENT_SENSITIVITY_AUTO` on Android that has implemented based on autofill hints.
  // See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_AUTO.
  autoSensitive(id: 0),

  /// The widget tree contains sensitive content.
  ///
  /// When this level is set via a [SensitiveContent] widget, the windowx
  /// hosting the screen will be marked as sensitive during an active media
  /// projection session.
  ///
  /// See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_SENSITIVE.
  sensitive(id: 1),

  /// The widget tree does not contain sensitive content.
  ///
  /// When this level is set via a [SensitiveContent] widget, the window
  /// hosting the screen will only be marked as sensitive if other [SensitiveContent]
  /// widgets in the Flutter app with the [sensitive] level are present in the widget tree.
  ///
  /// See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_NOT_SENSITIVE.
  notSensitive(id: 2);

  const ContentSensitivity({
    required this.id,
  });

  /// Identifier for each sensitivity level.
  final int id;

  /// Retrieve [ContentSensitivity] level by [id].
  static ContentSensitivity getContentSensitivityById(int id) {
    switch (id) {
      case 0:
        return ContentSensitivity.autoSensitive;
      case 1:
        return ContentSensitivity.sensitive;
      case 2:
        return ContentSensitivity.notSensitive;
      default:
        throw ArgumentError('$id is an invalid ContentSensitvity ID.');
    }
  }
}

/// Service for setting the content sensitivity of the native Android `View`
/// that contains the app's widget tree.
class SensitiveContentService {
  /// Creates service to set content sensitivity of the Android `View` via
  /// communication over the sensitive content [MethodChannel].
  SensitiveContentService() {
    sensitiveContentChannel = SystemChannels.sensitiveContent;
  }

  /// The channel used to communicate with the shell side to set the
  /// content sensitivity of the Android `View`.
  late MethodChannel sensitiveContentChannel;

  /// Sets content sensitivity level of the Android `View` to the level
  /// specified by [contentSensitivity] via a call to the native embedder.
  void setContentSensitivity(ContentSensitivity contentSensitivity) {
    try {
      sensitiveContentChannel.invokeMethod<void>(
        'SensitiveContent.setContentSensitivity',
        contentSensitivity.id,
      );
    } catch (e) {
      // Content sensitivity failed to be set.
      throw FlutterError('Content sensitivity failed to be set: $e');
    }
  }

  /// Gets content sensitivity level of the Android `View` that contains
  /// the app's widget tree.
  Future<int> getContentSensitivity() async {
    try {
      final int? result =
          await sensitiveContentChannel.invokeMethod<int>('SensitiveContent.getContentSensitivity');
      return result!;
    } catch (e) {
      // Content sensitivity failed to be set.
      throw FlutterError('Failed to retrieve content sensitivity: $e');
    }
  }
}
