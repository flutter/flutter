// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show TextDecoration;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'text_span.dart';
import 'text_style.dart';

/// An inline, interactive text link.
class InlineLink extends TextSpan {
  /// Create an instance of [InlineLink].
  InlineLink({
    required String text,
    TextStyle? style,
    super.locale,
    super.recognizer,
    super.semanticsLabel,
  }) : super(
    style: style ?? defaultLinkStyle,
    mouseCursor: SystemMouseCursors.click,
    text: text,
  );

  static Color get _linkColor {
    return switch (defaultTargetPlatform) {
      // This value was taken from Safari on an iPhone 14 Pro iOS 16.4
      // simulator.
      TargetPlatform.iOS => const Color(0xff1717f0),
      // This value was taken from Chrome on macOS 13.4.1.
      TargetPlatform.macOS => const Color(0xff0000ee),
      // This value was taken from Chrome on Android 14.
      TargetPlatform.android || TargetPlatform.fuchsia => const Color(0xff0e0eef),
      // This value was taken from the Chrome browser running on GNOME 43.3 on
      // Debian.
      TargetPlatform.linux => const Color(0xff0026e8),
      // This value was taken from the Edge browser running on Windows 10.
      TargetPlatform.windows => const Color(0xff1e2b8b),
    };
  }

  /// The style used for the link by default if none is given.
  @visibleForTesting
  static TextStyle defaultLinkStyle = TextStyle(
    // And decide underline or not per-platform.
    color: _linkColor,
    decoration: TextDecoration.underline,
  );
}
