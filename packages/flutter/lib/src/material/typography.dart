// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'colors.dart';

// TODO(eseidel): Font weights are supposed to be language relative.
// TODO(jackson): Baseline should be language relative.
// TODO(ianh): These values are for English-like text.

/// Material design text theme.
///
/// Definitions for the various typographical styles found in material design
/// (e.g., headline, caption). Rather than creating a [TextTheme] directly,
/// you can obtain an instance as [Typography.black] or [Typography.white].
///
/// To obtain the current text theme, call [Theme.of] with the current
/// [BuildContext] and read the [ThemeData.textTheme] property.
///
/// The following image [from the material design
/// specification](https://material.io/guidelines/style/typography.html#typography-styles)
/// shows the recommended styles for each of the properties of a [TextTheme].
/// This image uses the `Roboto` font, which is the font used on Android. On
/// iOS, the [San Francisco
/// font](https://developer.apple.com/ios/human-interface-guidelines/visual-design/typography/)
/// is automatically used instead.
///
/// ![To see the image, visit the typography site referenced below.](https://storage.googleapis.com/material-design/publish/material_v_11/assets/0Bzhp5Z4wHba3alhXZ2pPWGk3Zjg/style_typography_styles_scale.png)
///
/// See also:
///
///  * [Typography], the class that generates [TextTheme]s appropriate for a platform.
///  * [Theme], for other aspects of a material design application that can be
///    globally adjusted, such as the color scheme.
///  * <http://material.google.com/style/typography.html>
@immutable
class TextTheme {
  /// Create a text theme that uses the given values.
  ///
  /// Rather than creating a new text theme, consider using [Typography.black]
  /// or [Typography.white], which implement the typography styles in the
  /// material design specification:
  ///
  /// <https://material.google.com/style/typography.html#typography-styles>
  ///
  /// If you do decide to create your own text theme, consider using one of
  /// those predefined themes as a starting point for [copyWith] or [apply].
  const TextTheme({
    this.display4,
    this.display3,
    this.display2,
    this.display1,
    this.headline,
    this.title,
    this.subhead,
    this.body2,
    this.body1,
    this.caption,
    this.button,
  });

  const TextTheme._blackMountainView()
    : display4 = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic);

  const TextTheme._whiteMountainView()
    : display4 = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(fontFamily: 'Roboto',         inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic);

  const TextTheme._blackCupertino()
    : display4 = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(fontFamily: '.SF UI Text',    inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(fontFamily: '.SF UI Text',    inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(fontFamily: '.SF UI Text',    inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, color: Colors.black87, textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(fontFamily: '.SF UI Text',    inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, color: Colors.black54, textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(fontFamily: '.SF UI Text',    inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.black87, textBaseline: TextBaseline.alphabetic);

  const TextTheme._whiteCupertino()
    : display4 = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display3 = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display2 = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      display1 = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      headline = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      title    = const TextStyle(fontFamily: '.SF UI Display', inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      subhead  = const TextStyle(fontFamily: '.SF UI Text',    inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      body2    = const TextStyle(fontFamily: '.SF UI Text',    inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      body1    = const TextStyle(fontFamily: '.SF UI Text',    inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, color: Colors.white,   textBaseline: TextBaseline.alphabetic),
      caption  = const TextStyle(fontFamily: '.SF UI Text',    inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, color: Colors.white70, textBaseline: TextBaseline.alphabetic),
      button   = const TextStyle(fontFamily: '.SF UI Text',    inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, color: Colors.white,   textBaseline: TextBaseline.alphabetic);

  /// Extremely large text.
  ///
  /// The font size is 112 pixels.
  final TextStyle display4;

  /// Very, very large text.
  ///
  /// Used for the date in the dialog shown by [showDatePicker].
  final TextStyle display3;

  /// Very large text.
  final TextStyle display2;

  /// Large text.
  final TextStyle display1;

  /// Used for large text in dialogs (e.g., the month and year in the dialog
  /// shown by [showDatePicker]).
  final TextStyle headline;

  /// Used for the primary text in app bars and dialogs (e.g., [AppBar.title]
  /// and [AlertDialog.title]).
  final TextStyle title;

  /// Used for the primary text in lists (e.g., [ListTile.title]).
  final TextStyle subhead;

  /// Used for emphasizing text that would otherwise be [body1].
  final TextStyle body2;

  /// Used for the default text style for [Material].
  final TextStyle body1;

  /// Used for auxillary text associated with images.
  final TextStyle caption;

  /// Used for text on [RaisedButton] and [FlatButton].
  final TextStyle button;

  /// Creates a copy of this text theme but with the given fields replaced with
  /// the new values.
  ///
  /// Consider using [Typography.black] or [Typography.white], which implement
  /// the typography styles in the material design specification, as a starting
  /// point.
  TextTheme copyWith({
    TextStyle display4,
    TextStyle display3,
    TextStyle display2,
    TextStyle display1,
    TextStyle headline,
    TextStyle title,
    TextStyle subhead,
    TextStyle body2,
    TextStyle body1,
    TextStyle caption,
    TextStyle button
  }) {
    return new TextTheme(
      display4: display4 ?? this.display4,
      display3: display3 ?? this.display3,
      display2: display2 ?? this.display2,
      display1: display1 ?? this.display1,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      subhead: subhead ?? this.subhead,
      body2: body2 ?? this.body2,
      body1: body1 ?? this.body1,
      caption: caption ?? this.caption,
      button: button ?? this.button,
    );
  }

  /// Creates a copy of this text theme but with the given field replaced in
  /// each of the individual text styles.
  ///
  /// The `displayColor` is applied to [display4], [display3], [display2],
  /// [display1], and [caption]. The `bodyColor` is applied to the remaining
  /// text styles.
  ///
  /// Consider using [Typography.black] or [Typography.white], which implement
  /// the typography styles in the material design specification, as a starting
  /// point.
  TextTheme apply({
    String fontFamily,
    double fontSizeFactor: 1.0,
    double fontSizeDelta: 0.0,
    Color displayColor,
    Color bodyColor
  }) {
    return new TextTheme(
      display4: display4.apply(
        color: displayColor,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      display3: display3.apply(
        color: displayColor,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      display2: display2.apply(
        color: displayColor,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      display1: display1.apply(
        color: displayColor,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      headline: headline.apply(
        color: bodyColor,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      title: title.apply(
        color: bodyColor,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      subhead: subhead.apply(
        color: bodyColor,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      body2: body2.apply(
        color: bodyColor,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      body1: body1.apply(
        color: bodyColor,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      caption: caption.apply(
        color: displayColor,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      button: button.apply(
        color: bodyColor,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
    );
  }

  /// Linearly interpolate between two text themes.
  static TextTheme lerp(TextTheme begin, TextTheme end, double t) {
    return new TextTheme(
      display4: TextStyle.lerp(begin.display4, end.display4, t),
      display3: TextStyle.lerp(begin.display3, end.display3, t),
      display2: TextStyle.lerp(begin.display2, end.display2, t),
      display1: TextStyle.lerp(begin.display1, end.display1, t),
      headline: TextStyle.lerp(begin.headline, end.headline, t),
      title: TextStyle.lerp(begin.title, end.title, t),
      subhead: TextStyle.lerp(begin.subhead, end.subhead, t),
      body2: TextStyle.lerp(begin.body2, end.body2, t),
      body1: TextStyle.lerp(begin.body1, end.body1, t),
      caption: TextStyle.lerp(begin.caption, end.caption, t),
      button: TextStyle.lerp(begin.button, end.button, t),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final TextTheme typedOther = other;
    return display4 == typedOther.display4 &&
           display3 == typedOther.display3 &&
           display2 == typedOther.display2 &&
           display1 == typedOther.display1 &&
           headline == typedOther.headline &&
           title == typedOther.title &&
           subhead == typedOther.subhead &&
           body2 == typedOther.body2 &&
           body1 == typedOther.body1 &&
           caption == typedOther.caption &&
           button == typedOther.button;
  }

  @override
  int get hashCode {
    return hashValues(
      display4,
      display3,
      display2,
      display1,
      headline,
      title,
      subhead,
      body2,
      body1,
      caption,
      button,
    );
  }
}

/// The two material design text themes.
///
/// Material design defines two text themes: [black] and [white]. The black
/// text theme, which uses dark glyphs, is used on light backgrounds in light
/// themes. The white text theme, which uses light glyphs, is used in dark
/// themes and on dark backgrounds in light themes.
///
/// To obtain the current text theme, call [Theme.of] with the current
/// [BuildContext] and read the [ThemeData.textTheme] property.
///
/// See also:
///
///  * [TextTheme], which shows what the text styles in a theme look like.
///  * [Theme], for other aspects of a material design application that can be
///    globally adjusted, such as the color scheme.
///  * <http://material.google.com/style/typography.html>
class Typography {
  /// Creates the default typography for the specified platform.
  factory Typography({ @required TargetPlatform platform }) {
    assert(platform != null);
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return const Typography._(
            const TextTheme._blackMountainView(),
            const TextTheme._whiteMountainView(),
        );
      case TargetPlatform.iOS:
        return const Typography._(
            const TextTheme._blackCupertino(),
            const TextTheme._whiteCupertino(),
        );
    }
    return null;
  }

  const Typography._(this.black, this.white);

  /// A material design text theme with dark glyphs.
  final TextTheme black;

  /// A material design text theme with light glyphs.
  final TextTheme white;
}
