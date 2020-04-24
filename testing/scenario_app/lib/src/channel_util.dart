// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ui';

import 'package:meta/meta.dart';

/// Util method to replicate the behavior of a `MethodChannel` in the Flutter
/// framework.
void sendJsonMethodCall({
  @required Window window,
  @required String channel,
  @required String method,
  dynamic arguments,
  PlatformMessageResponseCallback callback,
}) {
  window.sendPlatformMessage(
    channel,
    // This recreates a combination of OptionalMethodChannel, JSONMethodCodec,
    // and _DefaultBinaryMessenger in the framework.
    utf8.encoder.convert(
      const JsonCodec().encode(<String, dynamic>{
        'method': method,
        'args': arguments,
      })
    ).buffer.asByteData(),
    callback,
  );
}
