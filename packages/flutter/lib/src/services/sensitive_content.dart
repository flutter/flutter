// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
library;

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// The level of sensitivity that content in a particular Flutter view
/// contains.
///
/// There are only three levels and can be set on a Flutter view via a
/// [SensitiveContent] widget. [ContentSensitivity.sensitive] is the most
/// severe setting and if set on a view with a `SensitiveContent` widget,
/// will cause the view to remain marked sensitive even if there are other
/// `SensitiveContent` widget in the tree. [ContentSensitivity.autoSensitive]
/// is the second most severe setting and will cause the view to remain marked
/// auto-sensitive if there are only other auto-sensitive or not sensitive
/// `SensitiveContent` widgets in the tree. [ContentSensitive.notSensitive]
/// is the least severe setting and will cause the view to remain marked not
/// sensitive as long ase there are only other not sensitive `SensitiveContent`
/// widgets in the tree. If there are no `SensitiveContent` widget in the tree,
/// the default setting will be used. This could be set by a Flutter developer in
/// the engine; otherwise, Android uses [ContentSensitivity.autoSensitive] by default.
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

  /// The view displays sensitive content.
  ///
  /// When this level is set via a [SensitiveContent] widget, the windowx
  /// hosting the screen will be marked as sensitive during an active media
  /// projection session.
  ///
  /// See https://developer.android.com/reference/android/view/View#CONTENT_SENSITIVITY_SENSITIVE.
  sensitive(id: 1),

  /// The view does not display sensitive content.
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

/// Service for setting the content sensitivity of native Flutter views.
class SensitiveContentService {
  /// Creates service to set content sensitivity of Flutter views via
  /// communication over the sensitive content [MethodChannel].
  SensitiveContentService() {
    sensitiveContentChannel = SystemChannels.sensitiveContent;
  }

  /// The channel used to communicate with the shell side to set the
  /// content sensitivity of Flutter views.
  late MethodChannel sensitiveContentChannel;

  /// Sets content sensitivity level of the native backing to a Flutter view
  /// with the specified [flutterViewId] to the level specified by
  /// [contentSensitivity] via a call to the native embedder.
  void setContentSensitivity(int flutterViewId, ContentSensitivity contentSensitivity) {
    try {
      sensitiveContentChannel.invokeMethod<void>(
        'SensitiveContent.setContentSensitivity',
        <String, dynamic>{
          'flutterViewId': flutterViewId,
          'contentSensitivityLevel': contentSensitivity.id
        },
      );
    } catch (e) {
      // Content sensitivity failed to be set.
      throw FlutterError('Content sensitivity failed to be set. Please ensure that the '
          'flutterViewId $flutterViewId corresponds to a valid Android Flutter View '
          'or Fragment.');
    }
  }

  /// Gets content sensitivity level of the native backing to a Flutter view
  /// with the specified [flutterViewId] via a call to the native embedder.
  Future<int> getContentSensitivity(int flutterViewId) async {
    try {
      final int? result = await sensitiveContentChannel.invokeMethod<int>(
        'SensitiveContent.getContentSensitivity',
        <String, dynamic>{'flutterViewId': flutterViewId},
      );
      return result!;
    } catch (e) {
      // Content sensitivity failed to be set.
      throw FlutterError(
          'Failed to retrieve content sensitivity. Please ensure that the flutterViewId '
          '$flutterViewId corresponds to a valid Android Flutter View for Fragment. ');
    }
  }
}
