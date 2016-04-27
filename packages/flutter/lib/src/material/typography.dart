// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/painting.dart';

import 'colors.dart';

// TODO(eseidel): Font weights are supposed to be language relative.
// TODO(jackson): Baseline should be language relative.
// These values are for English-like text.
// TODO(ianh): There's no font-family specified here.

/// Material design text theme.
///
/// Definitions for the various typographical styles found in material design
/// (e.g., headline, caption). Rather than creating a [TextTheme] directly,
/// you can obtain an instance as [Typography.black] or [Typography.white].
///
/// To obtain the current text theme, call [Theme.of] with the current
/// [BuildContext] and read the [ThemeData.textTheme] property.
///
/// See also:
///
///  * [Typography]
///  * [Theme]
///  * [ThemeData]
///  * <http://www.google.com/design/spec/style/typography.html>
class TextTheme {

  const TextTheme._(this.display4, this.display3, this.display2, this.display1, this.headline, this.title, this.subhead, this.body2, this.body1, this.caption, this.button);

  const TextTheme._black()
    : display4 = const TextStyle(inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic);

  const TextTheme._white()
    : display4 = const TextStyle(inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic);

  /// Extremely large text.
  ///
  /// The font size is 112 pixels.
  final TextStyle display4;

  /// Very, very large text.
  ///
  /// Used for the date in [DatePicker].
  final TextStyle display3;

  /// Very large text.
  final TextStyle display2;

  /// Large text.
  final TextStyle display1;

  /// Used for large text in dialogs (e.g., the month and year in [DatePicker]).
  final TextStyle headline;

  /// Used for the primary text in app bars and dialogs (e.g., [AppBar.title] and [Dialog.title]).
  final TextStyle title;

  /// Used for the primary text in lists (e.g., [ListItem.title]).
  final TextStyle subhead;

  /// Used for emphasizing text that would otherwise be [body1].
  final TextStyle body2;

  /// Used for the default text style for [Material].
  final TextStyle body1;

  /// Used for auxillary text associted with images.
  final TextStyle caption;

  /// Used for text on [RaisedButton] and [FlatButton].
  final TextStyle button;

  /// Linearly interpolate between two text themes.
  static TextTheme lerp(TextTheme begin, TextTheme end, double t) {
    return new TextTheme._(
      TextStyle.lerp(begin.display4, end.display4, t),
      TextStyle.lerp(begin.display3, end.display3, t),
      TextStyle.lerp(begin.display2, end.display2, t),
      TextStyle.lerp(begin.display1, end.display1, t),
      TextStyle.lerp(begin.headline, end.headline, t),
      TextStyle.lerp(begin.title, end.title, t),
      TextStyle.lerp(begin.subhead, end.subhead, t),
      TextStyle.lerp(begin.body2, end.body2, t),
      TextStyle.lerp(begin.body1, end.body1, t),
      TextStyle.lerp(begin.caption, end.caption, t),
      TextStyle.lerp(begin.button, end.button, t)
    );
  }
}

/// The two material design text themes.
///
/// [Typography.black] and [Typography.white] define the two text themes used in
/// material design. The black text theme, which uses darkly colored glyphs, is
/// used on lightly colored backgrounds in light themes. The white text theme,
/// which uses lightly colored glyphs, is used on darkly colored backgrounds in
/// in light themes and in dark themes.
///
/// To obtain the current text theme, call [Theme.of] with the current
/// [BuildContext] and read the [ThemeData.textTheme] property.
///
/// See also:
///
///  * [Theme]
///  * [ThemeData]
///  * <http://www.google.com/design/spec/style/typography.html>
class Typography {
  Typography._();

  /// A material design text theme with darkly colored glyphs.
  static const TextTheme black = const TextTheme._black();

  /// A material design text theme with lightly colored glyphs.
  static const TextTheme white = const TextTheme._white();
}
