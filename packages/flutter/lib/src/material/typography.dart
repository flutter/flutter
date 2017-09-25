// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'colors.dart';

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

  TextTheme merge(TextTheme other) {
    if (other == null)
      return this;
    return copyWith(
      display4: display4.merge(other.display4),
      display3: display3.merge(other.display3),
      display2: display2.merge(other.display2),
      display1: display1.merge(other.display1),
      headline: headline.merge(other.headline),
      title: title.merge(other.title),
      subhead: subhead.merge(other.subhead),
      body2: body2.merge(other.body2),
      body1: body1.merge(other.body1),
      caption: caption.merge(other.caption),
      button: button.merge(other.button),
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
          _MaterialTextColorThemes.blackMountainView,
          _MaterialTextColorThemes.whiteMountainView,
        );
      case TargetPlatform.iOS:
        return const Typography._(
          _MaterialTextColorThemes.blackCupertino,
          _MaterialTextColorThemes.whiteCupertino,
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

/// Provides default text theme colors compliant with the Material Design
/// specification.
///
/// The geometric font properties are missing in these color themes. App are
/// expected to use [Theme.of] to get [TextTheme] objects fully populated with
/// font properties.
///
/// See also: https://material.io/guidelines/style/typography.html
// TODO(yjbanov): implement font fallback (see "Font stack" at https://material.io/guidelines/style/typography.html)
class _MaterialTextColorThemes {
  static const TextTheme blackMountainView = const TextTheme(
    display4: const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.black54),
    display3: const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.black54),
    display2: const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.black54),
    display1: const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.black54),
    headline: const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.black87),
    title   : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.black87),
    subhead : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.black87),
    body2   : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.black87),
    body1   : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.black87),
    caption : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.black54),
    button  : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.black87),
  );

  static const TextTheme whiteMountainView = const TextTheme(
    display4: const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.white70),
    display3: const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.white70),
    display2: const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.white70),
    display1: const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.white70),
    headline: const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.white),
    title   : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.white),
    subhead : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.white),
    body2   : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.white),
    body1   : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.white),
    caption : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.white70),
    button  : const TextStyle(fontFamily: 'Roboto',         inherit: false, color: Colors.white),
  );

  static const TextTheme blackCupertino = const TextTheme(
    display4: const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.black54),
    display3: const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.black54),
    display2: const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.black54),
    display1: const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.black54),
    headline: const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.black87),
    title   : const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.black87),
    subhead : const TextStyle(fontFamily: '.SF UI Text',    inherit: false, color: Colors.black87),
    body2   : const TextStyle(fontFamily: '.SF UI Text',    inherit: false, color: Colors.black87),
    body1   : const TextStyle(fontFamily: '.SF UI Text',    inherit: false, color: Colors.black87),
    caption : const TextStyle(fontFamily: '.SF UI Text',    inherit: false, color: Colors.black54),
    button  : const TextStyle(fontFamily: '.SF UI Text',    inherit: false, color: Colors.black87),
  );

  static const TextTheme whiteCupertino = const TextTheme(
    display4: const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.white70),
    display3: const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.white70),
    display2: const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.white70),
    display1: const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.white70),
    headline: const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.white),
    title   : const TextStyle(fontFamily: '.SF UI Display', inherit: false, color: Colors.white),
    subhead : const TextStyle(fontFamily: '.SF UI Text',    inherit: false, color: Colors.white),
    body2   : const TextStyle(fontFamily: '.SF UI Text',    inherit: false, color: Colors.white),
    body1   : const TextStyle(fontFamily: '.SF UI Text',    inherit: false, color: Colors.white),
    caption : const TextStyle(fontFamily: '.SF UI Text',    inherit: false, color: Colors.white70),
    button  : const TextStyle(fontFamily: '.SF UI Text',    inherit: false, color: Colors.white),
  );
}

/// Defines text geometries for the three language categories defined in
/// https://material.io/guidelines/style/typography.html.
class MaterialTextGeometry {
  /// The name of the English-like script category.
  static const String englishLikeCategory = 'English-like';

  /// The name of the dense script category.
  static const String denseCategory = 'dense';

  /// The name of the tall script category.
  static const String tallCategory = 'tall';

  /// The mapping from script category names to text themes.
  static const Map<String, TextTheme> _categoryToTextTheme = const <String, TextTheme>{
    englishLikeCategory: englishLike,
    denseCategory: dense,
    tallCategory: tall,
  };

  /// Looks up text geometry corresponding to the given [scriptCategoryName].
  ///
  /// Most apps would not call this method directly, but rather call [Theme.of]
  /// and use the [TextTheme] fields of the returned [ThemeData] object.
  ///
  /// [scriptCategoryName] must be one of [englishLikeCategory], [denseCategory]
  /// and [tallCategory].
  ///
  /// See also:
  ///
  ///  * [DefaultMaterialLocalizations.localTextGeometry], which uses this
  ///    method to look-up text geometry for the current locale.
  static TextTheme forScriptCategory(String scriptCategoryName) => _categoryToTextTheme[scriptCategoryName];

  /// Defines text geometry for English-like scripts, such as English, French, Russian, etc.
  static const TextTheme englishLike = const TextTheme(
    display4: const TextStyle(fontSize: 112.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.alphabetic),
    display3: const TextStyle(fontSize:  56.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display2: const TextStyle(fontSize:  45.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display1: const TextStyle(fontSize:  34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline: const TextStyle(fontSize:  24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    title   : const TextStyle(fontSize:  20.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    subhead : const TextStyle(fontSize:  16.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    body2   : const TextStyle(fontSize:  14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    body1   : const TextStyle(fontSize:  14.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    caption : const TextStyle(fontSize:  12.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    button  : const TextStyle(fontSize:  14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
  );

  /// Defines text geometry for dense scripts, such as Chinese, Japanese, Korean, etc.
  static const TextTheme dense = const TextTheme(
    display4: const TextStyle(fontSize: 112.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic),
    display3: const TextStyle(fontSize:  56.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    display2: const TextStyle(fontSize:  45.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    display1: const TextStyle(fontSize:  34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    headline: const TextStyle(fontSize:  24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    title   : const TextStyle(fontSize:  21.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    subhead : const TextStyle(fontSize:  17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    body2   : const TextStyle(fontSize:  15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    body1   : const TextStyle(fontSize:  15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    caption : const TextStyle(fontSize:  13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    button  : const TextStyle(fontSize:  15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
  );

  /// Defines text geometry for tall scripts, such as Farsi, Hindi, Thai, etc.
  static const TextTheme tall = const TextTheme(
    display4: const TextStyle(fontSize: 112.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display3: const TextStyle(fontSize:  56.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display2: const TextStyle(fontSize:  45.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display1: const TextStyle(fontSize:  34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline: const TextStyle(fontSize:  24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    title   : const TextStyle(fontSize:  21.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    subhead : const TextStyle(fontSize:  17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    body2   : const TextStyle(fontSize:  15.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    body1   : const TextStyle(fontSize:  15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    caption : const TextStyle(fontSize:  13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    button  : const TextStyle(fontSize:  15.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
  );
}
