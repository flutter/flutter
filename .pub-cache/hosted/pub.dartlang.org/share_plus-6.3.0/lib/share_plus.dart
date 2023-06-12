// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

export 'package:share_plus_platform_interface/share_plus_platform_interface.dart'
    show ShareResult, ShareResultStatus, XFile;

export 'src/share_plus_linux.dart';
export 'src/share_plus_windows.dart'
    if (dart.library.html) 'src/share_plus_web.dart';

/// Plugin for summoning a platform share sheet.
class Share {
  static SharePlatform get _platform => SharePlatform.instance;

  /// Summons the platform's share sheet to share text.
  ///
  /// Wraps the platform's native share dialog. Can share a text and/or a URL.
  /// It uses the `ACTION_SEND` Intent on Android and `UIActivityViewController`
  /// on iOS.
  ///
  /// The optional [subject] parameter can be used to populate a subject if the
  /// user chooses to send an email.
  ///
  /// The optional [sharePositionOrigin] parameter can be used to specify a global
  /// origin rect for the share sheet to popover from on iPads and Macs. It has no effect
  /// on other devices.
  ///
  /// May throw [PlatformException] or [FormatException]
  /// from [MethodChannel].
  static Future<void> share(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) {
    assert(text.isNotEmpty);
    return _platform.share(
      text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Summons the platform's share sheet to share multiple files.
  ///
  /// Wraps the platform's native share dialog. Can share a file.
  /// It uses the `ACTION_SEND` Intent on Android and `UIActivityViewController`
  /// on iOS.
  ///
  /// The optional `mimeTypes` parameter can be used to specify MIME types for
  /// the provided files.
  /// Android supports all natively available MIME types (wildcards like image/*
  /// are also supported) and it's considered best practice to avoid mixing
  /// unrelated file types (eg. image/jpg & application/pdf). If MIME types are
  /// mixed the plugin attempts to find the lowest common denominator. Even
  /// if MIME types are supplied the receiving app decides if those are used
  /// or handled.
  /// On iOS image/jpg, image/jpeg and image/png are handled as images, while
  /// every other MIME type is considered a normal file.
  ///
  /// The optional `sharePositionOrigin` parameter can be used to specify a global
  /// origin rect for the share sheet to popover from on iPads and Macs. It has no effect
  /// on other devices.
  ///
  /// May throw [PlatformException] or [FormatException]
  /// from [MethodChannel].
  @Deprecated("Use shareXFiles instead.")
  static Future<void> shareFiles(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) {
    assert(paths.isNotEmpty);
    assert(paths.every((element) => element.isNotEmpty));
    return _platform.shareFiles(
      paths,
      mimeTypes: mimeTypes,
      subject: subject,
      text: text,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Behaves exactly like [share] while providing feedback on how the user
  /// interacted with the share-sheet. Until the returned future is completed,
  /// any other call to any share method that returns a result _might_ result in
  /// a [PlatformException] (on Android).
  ///
  /// Because IOS, Android and macOS provide different feedback on share-sheet
  /// interaction, a result on IOS will be more specific than on Android or macOS.
  /// While on IOS the selected action can inform its caller that it was completed
  /// or dismissed midway (_actions are free to return whatever they want_),
  /// Android and macOS only record if the user selected an action or outright
  /// dismissed the share-sheet. It is not guaranteed that the user actually shared
  /// something.
  ///
  /// **Currently only implemented on IOS, Android and macOS.**
  ///
  /// Will gracefully fall back to the non result variant if not implemented
  /// for the current environment and return [ShareResult.unavailable].
  static Future<ShareResult> shareWithResult(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    assert(text.isNotEmpty);
    return _platform.shareWithResult(
      text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Behaves exactly like [shareFiles] while providing feedback on how the user
  /// interacted with the share-sheet. Until the returned future is completed,
  /// any other call to any share method that returns a result _might_ result in
  /// a [PlatformException] (on Android).
  ///
  /// Because IOS, Android and macOS provide different feedback on share-sheet
  /// interaction, a result on IOS will be more specific than on Android or macOS.
  /// While on IOS the selected action can inform its caller that it was completed
  /// or dismissed midway (_actions are free to return whatever they want_),
  /// Android and macOS only record if the user selected an action or outright
  /// dismissed the share-sheet. It is not guaranteed that the user actually shared
  /// something.
  ///
  /// **Currently only implemented on IOS, Android and macOS.**
  ///
  /// Will gracefully fall back to the non result variant if not implemented
  /// for the current environment and return [ShareResult.unavailable].
  @Deprecated("Use shareXFiles instead.")
  static Future<ShareResult> shareFilesWithResult(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    assert(paths.isNotEmpty);
    assert(paths.every((element) => element.isNotEmpty));
    return _platform.shareFilesWithResult(
      paths,
      mimeTypes: mimeTypes,
      subject: subject,
      text: text,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Summons the platform's share sheet to share multiple files.
  ///
  /// Wraps the platform's native share dialog. Can share a file.
  /// It uses the `ACTION_SEND` Intent on Android and `UIActivityViewController`
  /// on iOS.
  ///
  /// Android supports all natively available MIME types (wildcards like image/*
  /// are also supported) and it's considered best practice to avoid mixing
  /// unrelated file types (eg. image/jpg & application/pdf). If MIME types are
  /// mixed the plugin attempts to find the lowest common denominator. Even
  /// if MIME types are supplied the receiving app decides if those are used
  /// or handled.
  /// On iOS image/jpg, image/jpeg and image/png are handled as images, while
  /// every other MIME type is considered a normal file.
  ///
  /// The optional `sharePositionOrigin` parameter can be used to specify a global
  /// origin rect for the share sheet to popover from on iPads and Macs. It has no effect
  /// on other devices.
  ///
  /// May throw [PlatformException] or [FormatException]
  /// from [MethodChannel].
  static Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    assert(files.isNotEmpty);
    return _platform.shareXFiles(
      files,
      subject: subject,
      text: text,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}
