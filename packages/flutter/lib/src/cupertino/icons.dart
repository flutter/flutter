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
  static const IconData left_chevron = IconData(0xf3d2, fontFamily: iconFont, fontPackage: iconFontPackage, matchTextDirection: true);

  /// A thin right chevron.
  static const IconData right_chevron = IconData(0xf3d3, fontFamily: iconFont, fontPackage: iconFontPackage, matchTextDirection: true);

  /// iOS style share icon with an arrow pointing up from a box.
  ///
  /// For another (pre-iOS 7) version of this icon, see [share_up].
  static const IconData share = IconData(0xf4ca, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A book silhouette spread open.
  static const IconData book = IconData(0xf3e7, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A letter 'i' in a circle.
  static const IconData info = IconData(0xf44c, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A curved up and left pointing arrow.
  ///
  /// For another version of this icon, see [reply_thick_solid].
  static const IconData reply = IconData(0xf4c6, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A chat bubble.
  static const IconData conversation_bubble = IconData(0xf3fb, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A person's silhouette in a circle.
  static const IconData profile_circled = IconData(0xf419, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A '+' sign in a circle.
  static const IconData plus_circled = IconData(0xf48a, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A '-' sign in a circle.
  static const IconData minus_circled = IconData(0xf463, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A right facing flag and pole outline.
  static const IconData flag = IconData(0xf42c, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A magnifier loop outline.
  static const IconData search = IconData(0xf4a5, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A checkmark.
  static const IconData check_mark = IconData(0xf3fd, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A checkmark in a circle.
  static const IconData check_mark_circled = IconData(0xf3fe, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A thicker left chevron used in iOS for the navigation bar back button.
  static const IconData back = IconData(0xf3cf, fontFamily: iconFont, fontPackage: iconFontPackage, matchTextDirection: true);

  /// A thicker right chevron that's the reverse of [back].
  static const IconData forward = IconData(0xf3d1, fontFamily: iconFont, fontPackage: iconFontPackage, matchTextDirection: true);

  /// Outline of a simple front-facing house.
  static const IconData home = IconData(0xf447, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A right-facing shopping cart outline.
  static const IconData shopping_cart = IconData(0xf3f7, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Three solid dots.
  static const IconData ellipsis = IconData(0xf46a, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A phone handset outline.
  static const IconData phone = IconData(0xf4b8, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A phone handset.
  static const IconData phone_solid = IconData(0xf4b9, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A solid down arrow.
  static const IconData down_arrow = IconData(0xf35d, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A charging battery.
  static const IconData battery_charging = IconData(0xf111, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// An empty battery.
  static const IconData battery_empty = IconData(0xf112, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A full battery.
  static const IconData battery_full = IconData(0xf113, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A 75% charged battery.
  static const IconData battery_75_percent = IconData(0xf114, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A 25% charged battery.
  static const IconData battery_25_percent = IconData(0xf115, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// The bluetooth logo.
  static const IconData bluetooth = IconData(0xf116, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A restart arrow, pointing downwards.
  static const IconData restart = IconData(0xf21c, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Two curved up and left pointing arrows.
  static const IconData reply_all = IconData(0xf21d, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A curved up and left pointing arrow.
  ///
  /// For another version of this icon, see [reply].
  static const IconData reply_thick_solid = IconData(0xf21e, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// iOS style share icon with an arrow pointing upwards to the right from a box.
  ///
  /// For another version of this icon (introduced in iOS 7), see [share].
  static const IconData share_up = IconData(0xf220, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Two right-facing intertwined arrows.
  static const IconData shuffle_thick = IconData(0xf221, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Symbolizes a photo camera
  static const IconData photo_camera = IconData(0xf3f5, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Solid [photo_camera]
  static const IconData photo_camera_solid = IconData(0xf3f6, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Symbolizes a video camera
  static const IconData video_camera = IconData(0xf4cc, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Solid [video_camera]
  static const IconData video_camera_solid = IconData(0xf4cd, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Camera filled with two circular arrows, which indicate switching
  static const IconData switch_camera = IconData(0xf49e, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Solid [switch_camera]
  static const IconData switch_camera_solid = IconData(0xf49f, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Envelopes stacked facing forwards
  static const IconData collections = IconData(0xf3c9, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Solid [collections]
  static const IconData collections_solid = IconData(0xf3ca, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Single envelope, i.e. a folder
  static const IconData folder = IconData(0xf434, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Solid [folder]
  static const IconData folder_solid = IconData(0xf435, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Old version of [folder]
  static const IconData folder_open = IconData(0xf38a, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Trash can
  static const IconData delete = IconData(0xf4c4, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Solid [delete]
  static const IconData delete_solid = IconData(0xf4c5, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Old version of [delete]
  static const IconData delete_old = IconData(0xf37f, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A pen (pencil [create_simple])
  static const IconData create = IconData(0xf2bf, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A pencil (pen [create]), simple because the pencil has less detail, i.e. a more minimal design
  static const IconData create_simple = IconData(0xf37e, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Arrow on a circular path, its end pointing towards its start
  static const IconData refresh = IconData(0xf49a, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// [refresh] in a circle
  static const IconData refresh_circled = IconData(0xf49b, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Solid [refresh_circle]
  static const IconData refresh_circled_solid = IconData(0xf49c, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A thinner version of [refresh], where start and end are also closer together
  static const IconData refresh_thin = IconData(0xf49d, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Cross (two diagonal lines from edge to edge crossing in an angle of 90 degrees)
  static const IconData clear = IconData(0xf2d7, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Thinner (iOS 7) version of [clear]
  static const IconData clear_thin = IconData(0xf404, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// [clear_thin] in a circle
  static const IconData clear_circled = IconData(0xf405, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Solid [clear_circled]
  static const IconData clear_circled_solid = IconData(0xf406, fontFamily: iconFont, fontPackage: iconFontPackage);
}
