// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs
// ignore_for_file: avoid_unused_constructor_parameters

import 'dart:html' as html; // ignore: uri_does_not_exist
import 'platform.dart';

TargetPlatform get defaultTargetPlatform {
  TargetPlatform result;
  // The existence of this method is tested via the dart2js compile test.
  final String userAgent = html.window.navigator.userAgent;
  if (userAgent.contains('iPhone')
    || userAgent.contains('iPad')
    || userAgent.contains('iPod')) {
    result = TargetPlatform.iOS;
  } else {
    result = TargetPlatform.android;
  }
  if (debugDefaultTargetPlatformOverride != null)
    result = debugDefaultTargetPlatformOverride;
  return result;
}
