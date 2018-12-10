// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'colors.dart';
import 'text_theme.dart';

/// A characterization of the of a [TextTheme]'s glyphs that is used to define
/// its localized [TextStyle] geometry for [ThemeData.textTheme].
///
/// The script category defines the overall geometry of a [TextTheme] for
/// the static [MaterialTextGeometry.localizedFor] method in terms of the
/// three language categories defined in <https://material.io/go/design-typography>.
///
/// Generally speaking, font sizes for [ScriptCategory.tall] and
/// [ScriptCategory.dense] scripts - for text styles that are smaller than the
/// title style - are one unit larger than they are for
/// [ScriptCategory.englishLike] scripts.
enum ScriptCategory {
  /// The languages of Western, Central, and Eastern Europe and much of
  /// Africa are typically written in the Latin alphabet. Vietnamese is a
  /// notable exception in that, while it uses a localized form of the Latin
  /// writing system, its accented glyphs can be much taller than those
  /// found in Western European languages. The Greek and Cyrillic writing
  /// systems are very similar to Latin.
  englishLike,

  /// Language scripts that require extra line height to accommodate larger
  /// glyphs, including Chinese, Japanese, and Korean.
  dense,

  /// Language scripts that require extra line height to accommodate
  /// larger glyphs, including South and Southeast Asian and
  /// Middle-Eastern languages, like Arabic, Hindi, Telugu, Thai, and
  /// Vietnamese.
  tall,
}

/// The color and geometry [TextThemes] for Material apps.
///
/// The text themes provided by the overall [Theme], like
/// [ThemeData.textTheme], are based on the current locale's
/// [MaterialLocalizations.scriptCategory] and are created
/// by merging a color text theme, [black] or [white]
/// and a geometry text theme, one of [englishLike], [dense],
/// or [tall], depending on the locale.
///
/// To lookup a localized text theme use
/// `Theme.of(context).textTheme` or
/// `Theme.of(context).primaryTextTheme` or
/// `Theme.of(context).accentTextTheme`.
///
/// The color text themes are [blackMountainView],
/// [whiteMountainView], and [blackCupertino] and [whiteCupertino]. The
/// Mountain View theme [TextStyles] are based on the Roboto fonts and the
/// Cupertino themes are based on the San Francisco fonts.
///
/// Two sets of geometry themes are provided: 2014 and 2018. The 2014 themes
/// correspond to the original version of the Material Design spec and are
/// the defaults. The 2018 themes correspond the second iteration of the
/// specification and feature different font sizes, font weights, and
/// letter spacing values.
///
/// By default, [ThemeData.typography] is
/// `Typography(platform: platform)` which uses [englishLike2014],
/// [dense2014] and [tall2014]. To use the 2018 text theme
/// geometries, specify a typography value:
/// ```
/// Typography(
///   platorm: platform,
///   englishLike: Typography.englishLike2018,
///   dense: Typography.dense2018,
///   tall: Typography.tall2018,
/// )
/// ```
///
/// See also:
///
///  * [ThemeData.typography], which can be used to configure the
///    text themes used to create [ThemeData.textTheme],
///    [ThemeData.primaryTextTheme], [ThemeData.accentTextTheme].
///  * <https://material.io/design/typography/>
@immutable
class Typography extends Diagnosticable {
  /// Creates a typography instance.
  ///
  /// If [platform] is specified, the default values for [black] and [white]
  /// are [blackCupertino] and [whiteCupertino] respectively. Otherwise
  /// they are [blackMountainView] and [whiteMoutainView].
  ///
  /// The default values for [englishLike], [dense], and [tall] are
  /// [englishLike2014], [dense2014], and [tall2014].
  factory Typography({
    TargetPlatform platform,
    TextTheme black,
    TextTheme white,
    TextTheme englishLike,
    TextTheme dense,
    TextTheme tall,
  }) {
    switch (platform) {
      case TargetPlatform.iOS:
        black ??= blackCupertino;
        white ??= whiteCupertino;
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        black ??= blackMountainView;
        white ??= whiteMountainView;
    }
    englishLike ??= englishLike2014;
    dense ??= dense2014;
    tall ??= tall2014;
    return Typography._(black, white, englishLike, dense, tall);
  }

  const Typography._(this.black, this.white, this.englishLike, this.dense, this.tall)
    : assert(black != null),
      assert(white != null),
      assert(englishLike != null),
      assert(dense != null),
      assert(tall != null);

  /// A material design text theme with dark glyphs.
  ///
  /// This [TextTheme] should provide color but not geometry (font size,
  /// weight, etc). A text theme's geometry depends on the locale. To look
  /// up a localized [TextTheme], use the overall [Theme], for example:
  /// `Theme.of(context).textTheme`.
  ///
  /// The [englishLike], [dense], and [tall] text theme's provide locale-specific
  /// geometry.
  final TextTheme black;

  /// A material design text theme with light glyphs.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  /// A text theme's geometry depends on the locale. To look up a localized
  /// [TextTheme], use the the overall [Theme], for example:
  /// `Theme.of(context).textTheme`.
  ///
  /// The [englishLike], [dense], and [tall] text theme's provide locale-specific
  /// geometry.
  final TextTheme white;

  /// Defines text geometry for [ScriptCategory.englishLike] scripts, such as
  /// English, French, Russian, etc.
  ///
  /// This text theme is merged with either [black] or [white], depending
  /// on the overall [ThemeData.brightness], when the current locale's
  /// [MaterialLocalizations.scriptCategory] is [ScriptCategory.englishLike].
  ///
  /// To look up a localized [TextTheme], use the the overall [Theme], for
  /// example: `Theme.of(context).textTheme`.
  final TextTheme englishLike;

  /// Defines text geometry for dense scripts, such as Chinese, Japanese
  /// and Korean.
  ///
  /// This text theme is merged with either [black] or [white], depending
  /// on the overall [ThemeData.brightness], when the current locale's
  /// [MaterialLocalizations.scriptCategory] is [ScriptCategory.dense].
  ///
  /// To look up a localized [TextTheme], use the the overall [Theme], for
  /// example: `Theme.of(context).textTheme`.
  final TextTheme dense;

  /// Defines text geometry for tall scripts, such as Farsi, Hindi, and Thai.
  ///
  /// This text theme is merged with either [black] or [white], depending
  /// on the overall [ThemeData.brightness], when the current locale's
  /// [MaterialLocalizations.scriptCategory] is [ScriptCategory.tall].
  ///
  /// To look up a localized [TextTheme], use the the overall [Theme], for
  /// example: `Theme.of(context).textTheme`.
  final TextTheme tall;

  /// Returns one of [englishLike], [dense], or [tall].
  TextTheme geometryThemeFor(ScriptCategory category) {
    assert(category != null);
    switch (category) {
      case ScriptCategory.englishLike:
        return englishLike;
      case ScriptCategory.dense:
        return dense;
      case ScriptCategory.tall:
        return tall;
    }
    return null;
  }

  /// Creates a copy of this [Typography] with the given fields
  /// replaced by the non-null parameter values.
  Typography copyWith({
    TextTheme black,
    TextTheme white,
    TextTheme englishLike,
    TextTheme dense,
    TextTheme tall,
  }) {
    return Typography(
      black: black ?? this.black,
      white: white ?? this.white,
      englishLike: englishLike ?? this.englishLike,
      dense: dense ?? this.dense,
      tall: tall ?? this.tall,
    );
  }

  /// Linearly interpolate between two [Typography] objects.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static Typography lerp(Typography a, Typography b, double t) {
    return Typography(
      black: TextTheme.lerp(a.black, b.black, t),
      white: TextTheme.lerp(a.white, b.white, t),
      englishLike: TextTheme.lerp(a.englishLike, b.englishLike, t),
      dense: TextTheme.lerp(a.dense, b.dense, t),
      tall: TextTheme.lerp(a.tall, b.tall, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final Typography otherTypography = other;
    return otherTypography.black == black
        && otherTypography.white == white
        && otherTypography.englishLike == englishLike
        && otherTypography.dense == dense
        && otherTypography.tall == tall;
  }

  @override
  int get hashCode {
    return hashValues(
      black,
      white,
      englishLike,
      dense,
      tall,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final Typography defaultTypography = Typography();
    properties.add(DiagnosticsProperty<TextTheme>('black', black, defaultValue: defaultTypography.black));
    properties.add(DiagnosticsProperty<TextTheme>('white', white, defaultValue: defaultTypography.white));
    properties.add(DiagnosticsProperty<TextTheme>('englishLike', englishLike, defaultValue: defaultTypography.englishLike));
    properties.add(DiagnosticsProperty<TextTheme>('dense', dense, defaultValue: defaultTypography.dense));
    properties.add(DiagnosticsProperty<TextTheme>('tall', tall, defaultValue: defaultTypography.tall));
  }

  /// A material design text theme with dark glyphs based on Roboto.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  static const TextTheme blackMountainView = TextTheme(
    display4   : TextStyle(debugLabel: 'blackMountainView display4',   fontFamily: 'Roboto', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    display3   : TextStyle(debugLabel: 'blackMountainView display3',   fontFamily: 'Roboto', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    display2   : TextStyle(debugLabel: 'blackMountainView display2',   fontFamily: 'Roboto', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    display1   : TextStyle(debugLabel: 'blackMountainView display1',   fontFamily: 'Roboto', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline   : TextStyle(debugLabel: 'blackMountainView headline',   fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    title      : TextStyle(debugLabel: 'blackMountainView title',      fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subhead    : TextStyle(debugLabel: 'blackMountainView subhead',    fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    body2      : TextStyle(debugLabel: 'blackMountainView body2',      fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    body1      : TextStyle(debugLabel: 'blackMountainView body1',      fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    caption    : TextStyle(debugLabel: 'blackMountainView caption',    fontFamily: 'Roboto', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    button     : TextStyle(debugLabel: 'blackMountainView button',     fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subtitle   : TextStyle(debugLabel: 'blackMountainView subtitle',   fontFamily: 'Roboto', inherit: true, color: Colors.black,   decoration: TextDecoration.none),
    overline   : TextStyle(debugLabel: 'blackMountainView overline',   fontFamily: 'Roboto', inherit: true, color: Colors.black,   decoration: TextDecoration.none),
  );

  /// A material design text theme with light glyphs based on Roboto.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  static const TextTheme whiteMountainView = TextTheme(
    display4   : TextStyle(debugLabel: 'whiteMountainView display4',   fontFamily: 'Roboto', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    display3   : TextStyle(debugLabel: 'whiteMountainView display3',   fontFamily: 'Roboto', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    display2   : TextStyle(debugLabel: 'whiteMountainView display2',   fontFamily: 'Roboto', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    display1   : TextStyle(debugLabel: 'whiteMountainView display1',   fontFamily: 'Roboto', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline   : TextStyle(debugLabel: 'whiteMountainView headline',   fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    title      : TextStyle(debugLabel: 'whiteMountainView title',      fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subhead    : TextStyle(debugLabel: 'whiteMountainView subhead',    fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    body2      : TextStyle(debugLabel: 'whiteMountainView body2',      fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    body1      : TextStyle(debugLabel: 'whiteMountainView body1',      fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    caption    : TextStyle(debugLabel: 'whiteMountainView caption',    fontFamily: 'Roboto', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    button     : TextStyle(debugLabel: 'whiteMountainView button',     fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subtitle   : TextStyle(debugLabel: 'whiteMountainView subtitle',   fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    overline   : TextStyle(debugLabel: 'whiteMountainView overline',   fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
  );

  /// A material design text theme with dark glyphs based on San Francisco.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  static const TextTheme blackCupertino = TextTheme(
    display4   : TextStyle(debugLabel: 'blackCupertino display4',   fontFamily: '.SF UI Display', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    display3   : TextStyle(debugLabel: 'blackCupertino display3',   fontFamily: '.SF UI Display', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    display2   : TextStyle(debugLabel: 'blackCupertino display2',   fontFamily: '.SF UI Display', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    display1   : TextStyle(debugLabel: 'blackCupertino display1',   fontFamily: '.SF UI Display', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline   : TextStyle(debugLabel: 'blackCupertino headline',   fontFamily: '.SF UI Display', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    title      : TextStyle(debugLabel: 'blackCupertino title',      fontFamily: '.SF UI Display', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subhead    : TextStyle(debugLabel: 'blackCupertino subhead',    fontFamily: '.SF UI Text',    inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    body2      : TextStyle(debugLabel: 'blackCupertino body2',      fontFamily: '.SF UI Text',    inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    body1      : TextStyle(debugLabel: 'blackCupertino body1',      fontFamily: '.SF UI Text',    inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    caption    : TextStyle(debugLabel: 'blackCupertino caption',    fontFamily: '.SF UI Text',    inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    button     : TextStyle(debugLabel: 'blackCupertino button',     fontFamily: '.SF UI Text',    inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subtitle   : TextStyle(debugLabel: 'blackCupertino subtitle',   fontFamily: '.SF UI Text',    inherit: true, color: Colors.black,   decoration: TextDecoration.none),
    overline   : TextStyle(debugLabel: 'blackCupertino overline',   fontFamily: '.SF UI Text',    inherit: true, color: Colors.black,   decoration: TextDecoration.none),
  );

  /// A material design text theme with light glyphs based on San Francisco.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  static const TextTheme whiteCupertino = TextTheme(
    display4   : TextStyle(debugLabel: 'whiteCupertino display4',   fontFamily: '.SF UI Display', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    display3   : TextStyle(debugLabel: 'whiteCupertino display3',   fontFamily: '.SF UI Display', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    display2   : TextStyle(debugLabel: 'whiteCupertino display2',   fontFamily: '.SF UI Display', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    display1   : TextStyle(debugLabel: 'whiteCupertino display1',   fontFamily: '.SF UI Display', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline   : TextStyle(debugLabel: 'whiteCupertino headline',   fontFamily: '.SF UI Display', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    title      : TextStyle(debugLabel: 'whiteCupertino title',      fontFamily: '.SF UI Display', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subhead    : TextStyle(debugLabel: 'whiteCupertino subhead',    fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    body2      : TextStyle(debugLabel: 'whiteCupertino body2',      fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    body1      : TextStyle(debugLabel: 'whiteCupertino body1',      fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    caption    : TextStyle(debugLabel: 'whiteCupertino caption',    fontFamily: '.SF UI Text',    inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    button     : TextStyle(debugLabel: 'whiteCupertino button',     fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subtitle   : TextStyle(debugLabel: 'whiteCupertino subtitle',   fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    overline   : TextStyle(debugLabel: 'whiteCupertino overline',   fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
  );

  /// Defines text geometry for [ScriptCategory.englishLike] scripts, such as
  /// English, French, Russian, etc.
  static const TextTheme englishLike2014 = TextTheme(
    display4 : TextStyle(debugLabel: 'englishLike display4 2014', inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.alphabetic),
    display3 : TextStyle(debugLabel: 'englishLike display3 2014', inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display2 : TextStyle(debugLabel: 'englishLike display2 2014', inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display1 : TextStyle(debugLabel: 'englishLike display1 2014', inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline : TextStyle(debugLabel: 'englishLike headline 2014', inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    title    : TextStyle(debugLabel: 'englishLike title 2014',    inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    subhead  : TextStyle(debugLabel: 'englishLike subhead 2014',  inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    body2    : TextStyle(debugLabel: 'englishLike body2 2014',    inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    body1    : TextStyle(debugLabel: 'englishLike body1 2014',    inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    caption  : TextStyle(debugLabel: 'englishLike caption 2014',  inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    button   : TextStyle(debugLabel: 'englishLike button 2014',   inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    subtitle : TextStyle(debugLabel: 'englishLike subtitle 2014', inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.1),
    overline : TextStyle(debugLabel: 'englishLike overline 2014', inherit: false, fontSize:  10.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 1.5),
  );

  /// Defines text geometry for [ScriptCategory.englishLike] scripts, such as
  /// English, French, Russian, etc.
  ///
  /// The font sizes, weights, and letter spacings in this version match the
  /// [latest Material Design specification](https://material.io/go/design-typography#typography-styles).
  static const TextTheme englishLike2018 = TextTheme(
    display4   : TextStyle(debugLabel: 'englishLike display4 2018', fontSize: 96.0, fontWeight: FontWeight.w300, textBaseline: TextBaseline.alphabetic, letterSpacing: -1.5),
    display3   : TextStyle(debugLabel: 'englishLike display3 2018', fontSize: 60.0, fontWeight: FontWeight.w300, textBaseline: TextBaseline.alphabetic, letterSpacing: -0.5),
    display2   : TextStyle(debugLabel: 'englishLike display2 2018', fontSize: 48.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.0),
    display1   : TextStyle(debugLabel: 'englishLike display1 2018', fontSize: 34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.25),
    headline   : TextStyle(debugLabel: 'englishLike headline 2018', fontSize: 24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.0),
    title      : TextStyle(debugLabel: 'englishLike title 2018',    fontSize: 20.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.15),
    subhead    : TextStyle(debugLabel: 'englishLike subhead 2018',  fontSize: 16.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.15),
    body2      : TextStyle(debugLabel: 'englishLike body2 2018',    fontSize: 14.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.25),
    body1      : TextStyle(debugLabel: 'englishLike body1 2018',    fontSize: 16.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.5),
    button     : TextStyle(debugLabel: 'englishLike button 2018',   fontSize: 14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.75),
    caption    : TextStyle(debugLabel: 'englishLike caption 2018',  fontSize: 12.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.4),
    subtitle   : TextStyle(debugLabel: 'englishLike subtitle 2018', fontSize: 14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.1),
    overline   : TextStyle(debugLabel: 'englishLike overline 2018', fontSize: 10.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 1.5),
  );

  /// Defines text geometry for dense scripts, such as Chinese, Japanese
  /// and Korean.
  static const TextTheme dense2014 = TextTheme(
    display4 : TextStyle(debugLabel: 'dense display4 2014', inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic),
    display3 : TextStyle(debugLabel: 'dense display3 2014', inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    display2 : TextStyle(debugLabel: 'dense display2 2014', inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    display1 : TextStyle(debugLabel: 'dense display1 2014', inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    headline : TextStyle(debugLabel: 'dense headline 2014', inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    title    : TextStyle(debugLabel: 'dense title 2014',    inherit: false, fontSize:  21.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    subhead  : TextStyle(debugLabel: 'dense subhead 2014',  inherit: false, fontSize:  17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    body2    : TextStyle(debugLabel: 'dense body2 2014',    inherit: false, fontSize:  15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    body1    : TextStyle(debugLabel: 'dense body1 2014',    inherit: false, fontSize:  15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    caption  : TextStyle(debugLabel: 'dense caption 2014',  inherit: false, fontSize:  13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    button   : TextStyle(debugLabel: 'dense button 2014',   inherit: false, fontSize:  15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    subtitle : TextStyle(debugLabel: 'dense subtitle 2014', inherit: false, fontSize:  15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    overline : TextStyle(debugLabel: 'dense overline 2014', inherit: false, fontSize:  11.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
  );

  /// Defines text geometry for dense scripts, such as Chinese, Japanese
  /// and Korean.
  ///
  /// The font sizes, weights, and letter spacings in this version match the
  /// latest [Material Design specification](https://material.io/go/design-typography#typography-styles).
  static const TextTheme dense2018 = TextTheme(
    display4  : TextStyle(debugLabel: 'dense display4 2018',  fontSize: 96.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic),
    display3  : TextStyle(debugLabel: 'dense display3 2018',  fontSize: 60.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic),
    display2  : TextStyle(debugLabel: 'dense display2 2018',  fontSize: 48.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    display1  : TextStyle(debugLabel: 'dense display1 2018',  fontSize: 34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    headline  : TextStyle(debugLabel: 'dense headline 2018',  fontSize: 24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    title     : TextStyle(debugLabel: 'dense title 2018',     fontSize: 21.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    subhead   : TextStyle(debugLabel: 'dense subhead 2018',   fontSize: 17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    body2     : TextStyle(debugLabel: 'dense body2 2018',     fontSize: 17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    body1     : TextStyle(debugLabel: 'dense body1 2018',     fontSize: 15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    caption   : TextStyle(debugLabel: 'dense caption 2018',   fontSize: 13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    button    : TextStyle(debugLabel: 'dense button 2018',    fontSize: 15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    subtitle  : TextStyle(debugLabel: 'dense subtitle 2018',  fontSize: 15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    overline  : TextStyle(debugLabel: 'dense overline 2018',  fontSize: 11.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
  );

  /// Defines text geometry for tall scripts, such as Farsi, Hindi, and Thai.
  static const TextTheme tall2014 = TextTheme(
    display4 : TextStyle(debugLabel: 'tall display4 2014', inherit: false, fontSize: 112.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display3 : TextStyle(debugLabel: 'tall display3 2014', inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display2 : TextStyle(debugLabel: 'tall display2 2014', inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display1 : TextStyle(debugLabel: 'tall display1 2014', inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline : TextStyle(debugLabel: 'tall headline 2014', inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    title    : TextStyle(debugLabel: 'tall title 2014',    inherit: false, fontSize:  21.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    subhead  : TextStyle(debugLabel: 'tall subhead 2014',  inherit: false, fontSize:  17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    body2    : TextStyle(debugLabel: 'tall body2 2014',    inherit: false, fontSize:  15.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    body1    : TextStyle(debugLabel: 'tall body1 2014',    inherit: false, fontSize:  15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    caption  : TextStyle(debugLabel: 'tall caption 2014',  inherit: false, fontSize:  13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    button   : TextStyle(debugLabel: 'tall button 2014',   inherit: false, fontSize:  15.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    subtitle : TextStyle(debugLabel: 'tall subtitle 2014', inherit: false, fontSize:  15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    overline : TextStyle(debugLabel: 'tall overline 2014', inherit: false, fontSize:  11.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
  );

  /// Defines text geometry for tall scripts, such as Farsi, Hindi, and Thai.
  ///
  /// The font sizes, weights, and letter spacings in this version match the
  /// latest [Material Design specification](https://material.io/go/design-typography#typography-styles).
  static const TextTheme tall2018 = TextTheme(
    display4  : TextStyle(debugLabel: 'tall display4 2018',  fontSize: 96.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display3  : TextStyle(debugLabel: 'tall display3 2018',  fontSize: 60.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display2  : TextStyle(debugLabel: 'tall display2 2018',  fontSize: 48.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    display1  : TextStyle(debugLabel: 'tall display1 2018',  fontSize: 34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline  : TextStyle(debugLabel: 'tall headline 2018',  fontSize: 24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    title     : TextStyle(debugLabel: 'tall title 2018',     fontSize: 21.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    subhead   : TextStyle(debugLabel: 'tall subhead 2018',   fontSize: 17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    body2     : TextStyle(debugLabel: 'tall body2 2018',     fontSize: 17.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    body1     : TextStyle(debugLabel: 'tall body1 2018',     fontSize: 15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    button    : TextStyle(debugLabel: 'tall button 2018',    fontSize: 15.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    caption   : TextStyle(debugLabel: 'tall caption 2018',   fontSize: 13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    subtitle  : TextStyle(debugLabel: 'tall subtitle 2018',  fontSize: 15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    overline  : TextStyle(debugLabel: 'tall overline 2018',  fontSize: 11.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
  );
}
