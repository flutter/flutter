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
  ///
  /// Arguments:
  ///
  /// * [urlString]: The URL string to be parsed by the underlying platform and
  ///   before it attempts to launch the same.
  static Future<Null> launch(String urlString) async {
    await PlatformMessages.sendJSON('flutter/platform', <String, dynamic>{
      'method': 'UrlLauncher.launch',
      'args': <String>[ urlString ],
    });
  }
}
