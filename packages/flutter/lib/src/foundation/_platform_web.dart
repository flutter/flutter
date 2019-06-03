// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Can remove once analyzer summary includes dart:html.
import 'dart:html' as html; // ignore: uri_does_not_exist
import 'platform.dart' as platform;

/// The dart:html implementation of [platform.defaultTargetPlatform].
platform.TargetPlatform get defaultTargetPlatform {
  platform.TargetPlatform result;
  // The existence of this method is tested via the dart2js compile test.
  final String userAgent = html.window.navigator.userAgent;
  if (userAgent.contains('iPhone')
    || userAgent.contains('iPad')
    || userAgent.contains('iPod')) {
    result = platform.TargetPlatform.iOS;
  } else {
    result = platform.TargetPlatform.android;
  }
  if (platform.debugDefaultTargetPlatformOverride != null)
    result = platform.debugDefaultTargetPlatformOverride;
  return result;
}
