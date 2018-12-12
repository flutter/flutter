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

  /// A book silhouette spread open. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [book_solid], which is similar, but filled in.
  static const IconData book = IconData(0xf3e7, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A book silhouette spread open. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [book], which is similar, but not filled in.
  static const IconData book_solid = IconData(0xf3e8, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A book silhouette spread open containing a bookmark in the upper right. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [bookmark_solid], which is similar, but filled in.
  static const IconData bookmark = IconData(0xf3e9, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A book silhouette spread open containing a bookmark in the upper right. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [bookmark], which is similar, but not filled in.
  static const IconData bookmark_solid = IconData(0xf3ea, fontFamily: iconFont, fontPackage: iconFontPackage);

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

  /// A symbol representing a single musical note.
  static const IconData music_note = IconData(0xf46b, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A triangle facing to the right. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [play_arrow_solid], which is similar, but filled in.
  static const IconData play_arrow = IconData(0xf487, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A triangle facing to the right. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [play_arrow], which is similar, but not filled in.
  static const IconData play_arrow_solid = IconData(0xf488, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Two verticale rectangles. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [pause_solid], which is similar, but filled in.
  static const IconData pause = IconData(0xf477, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Two verticale rectangles. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [pause], which is similar, but not filled in.
  static const IconData pause_solid = IconData(0xf478, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// The infinity symbol.
  ///
  /// See also:
  ///
  ///  * [loop_thick], which is similar, but thicker.
  static const IconData loop = IconData(0xf449, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// The infinity symbol.
  ///
  /// See also:
  ///
  ///  * [loop], which is similar, but thinner.
  static const IconData loop_thick = IconData(0xf44a, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A speaker with a single small sound wave.
  ///
  /// See also:
  ///
  ///  * [volume_mute], which is similar, but has no sound waves.
  ///  * [volume_off], which is similar, but with an additional larger sound wave and a diagonal line crossing the whole icon.
  ///  * [volume_up], which has an additional larger sound wave next to the small one.
  static const IconData volume_down = IconData(0xf3b7, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A speaker symbol.
  ///
  /// See also:
  ///
  ///  * [volume_down], which is similar, but adds a small sound wave.
  ///  * [volume_off], which is similar, but adds a small and a large sound wave and a diagonal line crossing the whole icon.
  ///  * [volume_up], which is similar, but has a small and a large sound wave.
  static const IconData volume_mute = IconData(0xf3b8, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A speaker with a small and a large sound wave and a diagonal line crossing the whole icon.
  ///
  /// See also:
  ///
  ///  * [volume_down], which is similar, but not crossed out and only has the small wave.
  ///  * [volume_mute], which is similar, but not crossed out.
  ///  * [volume_up], which is the version of this icon that is not crossed out.
  static const IconData volume_off = IconData(0xf3b9, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A speaker with a small and a large sound wave.
  ///
  /// See also:
  ///
  ///  * [volume_down], which is similar, but only has the small sound wave.
  ///  * [volume_mute], which is similar, but has no sound waves.
  ///  * [volume_off], which is the crossed out version of this icon.
  static const IconData volume_up = IconData(0xf3ba, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// All four corners of a square facing inwards.
  ///
  /// See also:
  ///
  ///  * [fullscreen_exit], which is similar, but has the corners facing outwards.
  static const IconData fullscreen = IconData(0xf386, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// All four corners of a square facing outwards.
  ///
  /// See also:
  ///
  ///  * [fullscreen], which is similar, but has the corners facing inwards.
  static const IconData fullscreen_exit = IconData(0xf37d, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A filled in microphone with a diagonal line crossing it.
  ///
  /// See also:
  ///
  ///  * [mic], which is similar, but not filled in and without a diagonal line.
  ///  * [mic_solid], which is similar, but without a diagonal line.
  static const IconData mic_off = IconData(0xf45f, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A microphone.
  ///
  /// See also:
  ///
  ///  * [mic_solid], which is similar, but filled in.
  ///  * [mic_off], which is similar, but filled in and with a diagonal line crossing the icon.
  static const IconData mic = IconData(0xf460, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A filled in microphone.
  ///
  /// See also:
  ///
  ///  * [mic], which is similar, but not filled in.
  ///  * [mic_off], which is similar, but with a diagonal line crossing the icon.
  static const IconData mic_solid = IconData(0xf461, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A circle with a dotted clock face inside with hands showing 10:30.
  ///
  /// See also:
  ///
  ///  * [clock_solid], which is similar, but filled in.
  ///  * [time], which is similar, but without dots on the clock face.
  ///  * [time_solid], which is similar, but filled in and without dots on the clock face.
  static const IconData clock = IconData(0xf4be, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A filled in circle with a dotted clock face inside with hands showing 10:30.
  ///
  /// See also:
  ///
  ///  * [clock], which is similar, but not filled in.
  ///  * [time], which is similar, but not filled in and without dots on the clock face.
  ///  * [time_solid], which is similar, but without dots on the clock face.
  static const IconData clock_solid = IconData(0xf4bf, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A circle with with a 90 degree angle shape in the center, resembeling a clock with hands showing 09:00.
  ///
  /// See also:
  ///
  ///  * [time_solid], which is similar, but filled in.
  ///  * [clock], which is similar, but with dots on the clockface.
  ///  * [clock_solid], which is similar, but filled in and with dots on the clockface.
  static const IconData time = IconData(0xf402, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A filled in circle with with a 90 degree angle shape in the center, resembeling a clock with hands showing 09:00.
  ///
  /// See also:
  ///
  ///  * [time], which is similar, but not filled in.
  ///  * [clock], which is similar, but not filled in and with dots on the clockface.
  ///  * [clock_solid], which is similar, but with dots on the clockface.
  static const IconData time_solid = IconData(0xf403, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// An unlocked padlock.
  ///
  /// See also:
  ///
  ///  * [padlock_solid], which is similar, but filled in.
  static const IconData padlock = IconData(0xf4c8, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// An unlocked padlock.
  ///
  /// See also:
  ///
  ///  * [padlock], which is similar, but not filled in.
  static const IconData padlock_solid = IconData(0xf4c9, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// An open eye.
  ///
  /// See also:
  ///
  ///  * [eye_solid], which is similar, but filled in.
  static const IconData eye = IconData(0xf424, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// An open eye.
  ///
  /// See also:
  ///
  ///  * [eye], which is similar, but not filled in.
  static const IconData eye_solid = IconData(0xf425, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A single person. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [person_solid], which is similar, but filled in.
  ///  * [person_add], which has an additional plus sign next to the person.
  ///  * [group], which consists of three people.
  static const IconData person = IconData(0xf47d, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A single person. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [person], which is similar, but not filled in.
  ///  * [person_add_solid], which has an additional plus sign next to the person.
  ///  * [group_solid], which consists of three people.
  static const IconData person_solid = IconData(0xf47e, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A single person with a plus sign next to it. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [person_add_solid], which is similar, but filled in.
  ///  * [person], which is just the person.
  ///  * [group], which consists of three people.
  static const IconData person_add = IconData(0xf47f, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A single person with a plus sign next to it. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [person_add], which is similar, but not filled in.
  ///  * [person_solid], which is just the person.
  ///  * [group_solid], which consists of three people.
  static const IconData person_add_solid = IconData(0xf480, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A group of three people. This icon is not filled in.
  ///
  /// See also:
  ///
  ///  * [group_solid], which is similar, but filled in.
  ///  * [person], which is just a single person.
  static const IconData group = IconData(0xf47b, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A group of three people. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [group], which is similar, but not filled in.
  ///  * [person_solid], which is just a single person.
  static const IconData group_solid = IconData(0xf47c, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Outline of a closed mail envelope.
  static const IconData mail = IconData(0xf422, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A closed mail envelope. This icon is filled in.
  static const IconData mail_solid = IconData(0xf423, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Outline of a location pin.
  static const IconData location = IconData(0xf455, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A location pin. This icon is filled in.
  static const IconData location_solid = IconData(0xf456, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Outline of a sticker tag.
  ///
  /// See also:
  ///
  ///  * [tags], similar but with 2 overlapping tags.
  static const IconData tag = IconData(0xf48c, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// A sticker tag. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [tags_solid], similar but with 2 overlapping tags.
  static const IconData tag_solid = IconData(0xf48d, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// Outlines of 2 overlapping sticker tags.
  ///
  /// See also:
  ///
  ///  * [tag], similar but with only one tag.
  static const IconData tags = IconData(0xf48e, fontFamily: iconFont, fontPackage: iconFontPackage);

  /// 2 overlapping sticker tags. This icon is filled in.
  ///
  /// See also:
  ///
  ///  * [tag_solid], similar but with only one tag.
  static const IconData tags_solid = IconData(0xf48f, fontFamily: iconFont, fontPackage: iconFontPackage);
}
