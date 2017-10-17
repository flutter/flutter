// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Identifiers for the supported Cupertino icons.
///
/// Use with the [Icon] class to show specific icons.
///
/// Icons are identified by their name as listed below.
///
/// To use this class, make sure you add a dependency on `cupertino_icons` in your
/// project's `pubspec.yaml` file. This ensures that the CupertinoIcons font is
/// included in your application. This font is used to display the icons. For example:
///
/// ```yaml
/// name: my_awesome_application
///
/// dependencies:
///   cupertino_icons: ^0.1.0
/// ```
///
/// See also:
///
///  * [Icon]
class CupertinoIcons {
  CupertinoIcons._();

  static const String iconFont = 'CupertinoIcons';
  static const String iconFontPackage = 'cupertino_icons';

  // Manually maintained list

  static const IconData left_chevron = const IconData(0xf3f0, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData right_chevron = const IconData(0xf3f2, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData share = const IconData(0xf4ca, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData book = const IconData(0xf3e7, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData info = const IconData(0xf44c, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData reply = const IconData(0xf4c6, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData conversation_bubble = const IconData(0xf3fb, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData profile_circled = const IconData(0xf419, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData plus_circled = const IconData(0xf48a, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData minus_circled = const IconData(0xf463, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData flag = const IconData(0xf42c, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData search = const IconData(0xf4c6, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData check_mark = const IconData(0xf41e, fontFamily: iconFont, fontPackage: iconFontPackage);

  static const IconData check_mark_circled = const IconData(0xf41f, fontFamily: iconFont, fontPackage: iconFontPackage);
}