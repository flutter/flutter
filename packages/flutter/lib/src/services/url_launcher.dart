// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'platform_messages.dart';

/// Allows applications to delegate responsbility of handling certain URLs to
/// the underlying platform.
class UrlLauncher {
  UrlLauncher._();

  /// Parse the specified URL string and delegate handling of the same to the
  /// underlying platform.
  static Future<Null> launch(String urlString) async {
    await PlatformMessages.invokeMethod(
      'flutter/platform',
      'UrlLauncher.launch',
      <String>[ urlString ],
    );
  }
}
