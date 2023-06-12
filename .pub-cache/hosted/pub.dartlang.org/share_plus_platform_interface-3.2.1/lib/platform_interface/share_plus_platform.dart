// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../method_channel/method_channel_share.dart';

/// The interface that implementations of `share_plus` must implement.
class SharePlatform extends PlatformInterface {
  /// Constructs a SharePlatform.
  SharePlatform() : super(token: _token);

  static final Object _token = Object();

  static SharePlatform _instance = MethodChannelShare();

  /// The default instance of [SharePlatform] to use.
  ///
  /// Defaults to [MethodChannelShare].
  static SharePlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [SharePlatform] when they register themselves.
  static set instance(SharePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Share text.
  Future<void> share(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) {
    return _instance.share(
      text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share files.
  @Deprecated("Use shareXFiles instead.")
  Future<void> shareFiles(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) {
    return _instance.shareFiles(
      paths,
      mimeTypes: mimeTypes,
      subject: subject,
      text: text,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Share text with Result.
  Future<ShareResult> shareWithResult(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    await _instance.share(
      text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );

    return _resultUnavailable;
  }

  /// Share files with Result.
  @Deprecated("Use shareXFiles instead.")
  Future<ShareResult> shareFilesWithResult(
    List<String> paths, {
    List<String>? mimeTypes,
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    await _instance.shareFiles(
      paths,
      mimeTypes: mimeTypes,
      subject: subject,
      text: text,
      sharePositionOrigin: sharePositionOrigin,
    );

    return _resultUnavailable;
  }

  /// Share [XFile] objects with Result.
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
  }) async {
    return _instance.shareXFiles(
      files,
      subject: subject,
      text: text,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}

/// The result of a share to determine what action the
/// user has taken.
///
/// [status] provides an easy way to determine how the
/// share-sheet was handled by the user, while [raw] provides
/// possible access to the action selected.
class ShareResult {
  /// The raw return value from the share.
  ///
  /// Note that an empty string means the share-sheet was
  /// dismissed without any action and the special value
  /// `dev.fluttercommunity.plus/share/unavailable` points
  /// to the current environment not supporting share results.
  final String raw;

  /// The action the user has taken
  final ShareResultStatus status;

  const ShareResult(this.raw, this.status);
}

/// How the user handled the share-sheet
enum ShareResultStatus {
  /// The user has selected an action
  success,

  /// The user dismissed the share-sheet
  dismissed,

  /// The status can not be determined
  unavailable,
}

/// Returned if the platform is not supported
const _resultUnavailable = ShareResult(
  'dev.fluttercommunity.plus/share/unavailable',
  ShareResultStatus.unavailable,
);
