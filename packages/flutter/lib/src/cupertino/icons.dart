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
///  * [Icon], used to show these icons.
///  * <https://github.com/flutter/cupertino_icons/blob/master/map.png>, a map of the
///    icons in this icons font.
class CupertinoIcons {
  CupertinoIcons._();

  /// The icon font used for Cupertino icons.
  static const String iconFont = 'CupertinoIcons';

  /// The dependent package providing the Cupertino icons font.
  static const String iconFontPackage = 'cupertino_icons';

  // Manually maintained list.

  /// A thin left chevron.
  static const IconData left_chevron = const IconData(0xf3d2, fontFamily: iconFont, fontPackage: iconFontPackage, matchTextDirection: true);

  /// A thin right chevron.
  static const IconData right_chevron = const IconData(0xf3d3, fontFamily: iconFont, fontPackage: iconFontPackage, matchTextDirection: true);

  /// iOS style share icon with an arrow pointing up from a box.
  static const IconData share = const IconData(0xf4ca, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A book silhouette spread open.
  static const IconData book = const IconData(0xf3e7, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A letter 'i' in a circle.
  static const IconData info = const IconData(0xf44c, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A curved up and left pointing arrow.
  static const IconData reply = const IconData(0xf4c6, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A chat bubble.
  static const IconData conversation_bubble = const IconData(0xf3fb, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A person's silhouette in a circle.
  static const IconData profile_circled = const IconData(0xf419, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A '+' sign in a circle.
  static const IconData plus_circled = const IconData(0xf48a, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A '-' sign in a circle.
  static const IconData minus_circled = const IconData(0xf463, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A right facing flag and pole outline.
  static const IconData flag = const IconData(0xf42c, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A magnifier loop outline.
  static const IconData search = const IconData(0xf4a5, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A checkmark.
  static const IconData check_mark = const IconData(0xf3fd, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A checkmark in a circle.
  static const IconData check_mark_circled = const IconData(0xf3fe, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A thicker left chevron used in iOS for the navigation bar back button.
  static const IconData back = const IconData(0xf3cf, fontFamily: iconFont, fontPackage: iconFontPackage, matchTextDirection: true);

  /// Outline of a simple front-facing house.
  static const IconData home = const IconData(0xf447, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A right-facing shopping cart outline.
  static const IconData shopping_cart = const IconData(0xf3f7, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Three solid dots.
  static const IconData ellipsis = const IconData(0xf46a, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A phone handset outline.
  static const IconData phone = const IconData(0xf4b8, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A phone handset.
  static const IconData phone_solid = const IconData(0xf4b9, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A solid down arrow.
  static const IconData down_arrow = const IconData(0xf35d, fontFamily: iconFont, fontPackage: iconFontPackage);
}
