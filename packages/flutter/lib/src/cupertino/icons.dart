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
///  * <https://github.com/flutter/cupertino_icons/blob/master/map.png>, a map of the icons in this icons font.
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

  /// iOS style share icon with an arrow pointing up from a box. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [share_solid], which is similar, but filled in.
  ///  * [share_up], for another (pre-iOS 7) version of this icon.
  static const IconData share = IconData(0xf4ca, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// iOS style share icon with an arrow pointing up from a box. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [share], which is similar, but not filled in.
  ///  * [share_up], for another (pre-iOS 7) version of this icon.
  static const IconData share_solid = IconData(0xf4cb, fontFamily: iconFont, fontPackage: iconFontPackage);

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
  ///
  /// See also:
  ///
  ///  * [check_mark_circled], which consists of this check mark and a circle surrounding it.
  static const IconData check_mark = IconData(0xf3fd, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A checkmark in a circle. The circle is not filled in.
  ///
  /// See also:
  ///
  ///  * [check_mark_circled_solid], which is similar, but filled in.
  ///  * [check_mark], which is the check mark without a circle.
  static const IconData check_mark_circled = IconData(0xf3fe, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A checkmark in a circle. The circle is filled in.
  ///
  /// See also:
  ///
  ///  * [check_mark_circled], which is similar, but not filled in.
  static const IconData check_mark_circled_solid = IconData(0xf3ff, fontFamily: iconFont, fontPackage: iconFontPackage);

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

  /// A solid up arrow.
  static const IconData up_arrow = IconData(0xf366, fontFamily: iconFont, fontPackage: iconFontPackage);

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

  /// A camera for still photographs. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [photo_camera], which is similar, but not filled in.
  ///  * [video_camera_solid], for the moving picture equivalent.
  static const IconData photo_camera = IconData(0xf3f5, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A camera for still photographs. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [photo_camera_solid], which is similar, but filled in.
  ///  * [video_camera], for the moving picture equivalent.
  static const IconData photo_camera_solid = IconData(0xf3f6, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A camera for moving pictures. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [video_camera_solid], which is similar, but filled in.
  ///  * [photo_camera], for the still photograph equivalent.
  static const IconData video_camera = IconData(0xf4cc, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A camera for moving pictures. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [video_camera], which is similar, but not filled in.
  ///  * [photo_camera_solid], for the still photograph equivalent.
  static const IconData video_camera_solid = IconData(0xf4cd, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A camera containing two circular arrows pointing at each other, which indicate switching. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [switch_camera_solid], which is similar, but filled in.
  static const IconData switch_camera = IconData(0xf49e, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A camera containing two circular arrows pointing at each other, which indicate switching. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [switch_camera], which is similar, but not filled in.
  static const IconData switch_camera_solid = IconData(0xf49f, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A collection of folders, which store collections of files, i.e. an album. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [collections_solid], which is similar, but filled in.
  static const IconData collections = IconData(0xf3c9, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A collection of folders, which store collections of files, i.e. an album. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [collections], which is similar, but not filled in.
  static const IconData collections_solid = IconData(0xf3ca, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A single folder, which stores multiple files. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [folder_solid], which is similar, but filled in.
  ///  * [folder_open], which is the pre-iOS 7 version of this icon.
  static const IconData folder = IconData(0xf434, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A single folder, which stores multiple files. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [folder], which is similar, but not filled in.
  ///  * [folder_open], which is the pre-iOS 7 version of this icon and not filled in.
  static const IconData folder_solid = IconData(0xf435, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A single folder that indicates being opened. A folder like this typically stores multiple files.
  ///
  /// See also:
  ///
  ///  * [folder], which is the equivalent of this icon for iOS versions later than or equal to iOS 7.
  static const IconData folder_open = IconData(0xf38a, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A trash bin for removing items. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [delete_solid], which is similar, but filled in.
  static const IconData delete = IconData(0xf4c4, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A trash bin for removing items. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [delete], which is similar, but not filled in.
  static const IconData delete_solid = IconData(0xf4c5, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A trash bin with minimal detail for removing items.
  ///
  /// See also:
  ///
  ///  * [delete], which is the iOS 7 equivalent of this icon with richer detail.
  static const IconData delete_simple = IconData(0xf37f, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A simple pen.
  ///
  /// See also:
  ///
  ///  * [pencil], which is similar, but has less detail and looks like a pencil.
  static const IconData pen = IconData(0xf2bf, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A simple pencil.
  ///
  /// See also:
  ///
  ///  * [pen], which is similar, but has more detail and looks like a pen.
  static const IconData pencil = IconData(0xf37e, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A box for writing and a pen on top (that indicates the writing). This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [create_solid], which is similar, but filled in.
  ///  * [pencil], which is just a pencil.
  ///  * [pen], which is just a pen.
  static const IconData create = IconData(0xf417, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A box for writing and a pen on top (that indicates the writing). This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [create], which is similar, but not filled in.
  ///  * [pencil], which is just a pencil.
  ///  * [pen], which is just a pen.
  static const IconData create_solid = IconData(0xf417, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// An arrow on a circular path with its end pointing at its start.
  ///
  /// See also:
  ///
  ///  * [refresh_circled], which is this icon put in a circle.
  ///  * [refresh_thin], which is an arrow of the same concept, but thinner and with a smaller gap in between its end and start.
  ///  * [refresh_thick], which is similar, but rotated 45 degrees clockwise and thicker.
  ///  * [refresh_bold], which is similar, but rotated 90 degrees clockwise and much thicker.
  static const IconData refresh = IconData(0xf49a, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// An arrow on a circular path with its end pointing at its start surrounded by a circle. This is icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [refresh_circled_solid], which is similar, but filled in.
  ///  * [refresh], which is the arrow of this icon without a circle.
  static const IconData refresh_circled = IconData(0xf49b, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// An arrow on a circular path with its end pointing at its start surrounded by a circle. This is icon is filled in.
  ///
  /// See also:
  ///
  ///  * [refresh_circled], which is similar, but not filled in.
  ///  * [refresh], which is the arrow of this icon filled in without a circle.
  static const IconData refresh_circled_solid = IconData(0xf49c, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// An arrow on a circular path with its end pointing at its start.
  ///
  /// See also:
  ///
  ///  * [refresh], which is an arrow of the same concept, but thicker and with a larger gap in between its end and start.
  static const IconData refresh_thin = IconData(0xf49d, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// An arrow on a circular path with its end pointing at its start.
  ///
  /// See also:
  ///
  ///  * [refresh], which is similar, but rotated 45 degrees anti-clockwise and thinner.
  ///  * [refresh_bold], which is similar, but rotated 45 degrees clockwise and thicker.
  static const IconData refresh_thick = IconData(0xf3a8, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// An arrow on a circular path with its end pointing at its start.
  ///
  /// See also:
  ///
  ///  * [refresh_thick], which is similar, but rotated 45 degrees anti-clockwise and thinner.
  ///  * [refresh], which is similar, but rotated 90 degrees anti-clockwise and much thinner.
  static const IconData refresh_bold = IconData(0xf21c, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A cross of two diagonal lines from edge to edge crossing in an angle of 90 degrees, which is used for dismissal.
  ///
  /// See also:
  ///
  ///  * [clear_circled], which uses this cross as a blank space in a filled out circled.
  ///  * [clear], which uses a thinner cross and is the iOS 7 equivalent of this icon.
  static const IconData clear_thick = IconData(0xf2d7, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A cross of two diagonal lines from edge to edge crossing in an angle of 90 degrees, which is used for dismissal, used as a blank space in a circle.
  ///
  /// See also:
  ///
  ///  * [clear], which is equivalent to the cross of this icon without a circle.
  ///  * [clear_circled_solid], which is similar, but uses a thinner cross.
  static const IconData clear_thick_circled = IconData(0xf36e, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A cross of two diagonal lines from edge to edge crossing in an angle of 90 degrees, which is used for dismissal.
  ///
  /// See also:
  ///
  ///  * [clear_circled], which consists of this cross and a circle surrounding it.
  ///  * [clear], which uses a thicker cross and is the pre-iOS 7 equivalent of this icon.
  static const IconData clear = IconData(0xf404, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A cross of two diagonal lines from edge to edge crossing in an angle of 90 degrees, which is used for dismissal, surrounded by circle. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [clear_circled_solid], which is similar, but filled in.
  ///  * [clear], which is the standalone cross of this icon.
  static const IconData clear_circled = IconData(0xf405, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A cross of two diagonal lines from edge to edge crossing in an angle of 90 degrees, which is used for dismissal, used as a blank space in a circle. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [clear_circled], which is similar, but not filled in.
  static const IconData clear_circled_solid = IconData(0xf406, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Two straight lines, one horizontal and one vertical, meeting in the middle, which is the equivalent of a plus sign.
  ///
  /// See also:
  ///
  ///  * [plus_circled], which is the pre-iOS 7 version of this icon with a thicker cross.
  ///  * [add_circled], which consists of the plus and a circle around it.
  static const IconData add = IconData(0xf489, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Two straight lines, one horizontal and one vertical, meeting in the middle, which is the equivalent of a plus sign, surrounded by a circle. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [plus_circled], which is the pre-iOS 7 version of this icon with a thicker cross and a filled in circle.
  ///  * [add_circled_solid], which is similar, but filled in.
  static const IconData add_circled = IconData(0xf48a, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Two straight lines, one horizontal and one vertical, meeting in the middle, which is the equivalent of a plus sign, surrounded by a circle. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [plus_circled], which is the pre-iOS 7 version of this icon with a thicker cross.
  ///  * [add_circled], which is similar, but not filled in.
  static const IconData add_circled_solid = IconData(0xf48b, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A gear with eigth cogs. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [gear_solid], which is similar, but filled in.
  ///  * [gear_big], which is the pre-iOS 7 version of this icon and appears bigger because of fewer and bigger cogs.
  ///  * [settings], which is another cogwheel with a different design.
  static const IconData gear = IconData(0xf43c, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A gear with eigth cogs. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [gear], which is similar, but not filled in.
  ///  * [settings_solid], which is another cogwheel with a different design.
  static const IconData gear_solid = IconData(0xf43d, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A gear with six cogs.
  ///
  /// See also:
  ///
  ///  * [gear], which is the iOS 7 version of this icon and appears smaller because of more and larger cogs.
  ///  * [settings_solid], which is another cogwheel with a different design.
  static const IconData gear_big = IconData(0xf2f7, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A cogwheel with many cogs and decoration in the middle. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [settings_solid], which is similar, but filled in.
  ///  * [gear], which is another cogwheel with a different design.
  static const IconData settings = IconData(0xf411, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A cogwheel with many cogs and decoration in the middle. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [settings], which is similar, but not filled in.
  ///  * [gear_solid], which is another cogwheel with a different design.
  static const IconData settings_solid = IconData(0xf412, fontFamily: iconFont, fontPackage: iconFontPackage);
}
