// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'colors.dart';
import 'text_theme.dart';

/// A characterization of the of a [TextTheme]'s glyphs that is used to define
/// its localized [TextStyle] geometry for [ThemeData.textTheme].
///
/// The script category defines the overall geometry of a [TextTheme] for
/// the [Typography.geometryThemeFor] method in terms of the
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

/// The color and geometry [TextTheme]s for Material apps.
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
/// The color text themes are [blackMountainView], [whiteMountainView],
/// [blackCupertino], and [whiteCupertino]. The Mountain View theme [TextStyle]s
/// are based on the Roboto fonts as used on Android. The Cupertino themes are
/// based on the [San Francisco
/// font](https://developer.apple.com/ios/human-interface-guidelines/visual-design/typography/)
/// fonts as used by Apple on iOS.
///
/// Two sets of geometry themes are provided: 2014 and 2018. The 2014 themes
/// correspond to the original version of the Material Design spec and are
/// the defaults. The 2018 themes correspond the second iteration of the
/// specification and feature different font sizes, font weights, and
/// letter spacing values.
///
/// By default, [ThemeData.typography] is `Typography.material2014(platform:
/// platform)` which uses [englishLike2014], [dense2014] and [tall2014]. To use
/// the 2018 text theme geometries, specify a value using the [material2018]
/// constructor:
///
/// ```dart
/// typography: Typography.material2018(platform: platform)
/// ```
///
/// See also:
///
///  * [ThemeData.typography], which can be used to configure the
///    text themes used to create [ThemeData.textTheme],
///    [ThemeData.primaryTextTheme], [ThemeData.accentTextTheme].
///  * <https://material.io/design/typography/>
@immutable
class Typography with Diagnosticable {
  /// Creates a typography instance.
  ///
  /// This constructor is identical to [Typography.material2014]. It is
  /// deprecated because the 2014 material design defaults used by that
  /// constructor are obsolete. The current material design specification
  /// recommendations are those reflected by [Typography.material2018].
  @Deprecated(
    'The default Typography constructor defaults to the 2014 material design defaults. '
    'Applications are urged to migrate to Typography.material2018(), or, if the 2014 defaults '
    'are desired, to explicitly request them using Typography.material2014(). '
    'This feature was deprecated after v1.13.8.'
  )
  factory Typography({
    TargetPlatform platform,
    TextTheme black,
    TextTheme white,
    TextTheme englishLike,
    TextTheme dense,
    TextTheme tall,
  }) = Typography.material2014;

  /// Creates a typography instance using material design's 2014 defaults.
  ///
  /// If [platform] is [TargetPlatform.iOS] or [TargetPlatform.macOS], the
  /// default values for [black] and [white] are [blackCupertino] and
  /// [whiteCupertino] respectively. Otherwise they are [blackMountainView] and
  /// [whiteMountainView]. If [platform] is null then both [black] and [white]
  /// must be specified.
  ///
  /// The default values for [englishLike], [dense], and [tall] are
  /// [englishLike2014], [dense2014], and [tall2014].
  factory Typography.material2014({
    TargetPlatform platform = TargetPlatform.android,
    TextTheme black,
    TextTheme white,
    TextTheme englishLike,
    TextTheme dense,
    TextTheme tall,
  }) {
    assert(platform != null || (black != null && white != null));
    return Typography._withPlatform(
      platform,
      black, white,
      englishLike ?? englishLike2014,
      dense ?? dense2014,
      tall ?? tall2014,
    );
  }

  /// Creates a typography instance using material design's 2018 defaults.
  ///
  /// If [platform] is [TargetPlatform.iOS] or [TargetPlatform.macOS], the
  /// default values for [black] and [white] are [blackCupertino] and
  /// [whiteCupertino] respectively. Otherwise they are [blackMountainView] and
  /// [whiteMountainView]. If [platform] is null then both [black] and [white]
  /// must be specified.
  ///
  /// The default values for [englishLike], [dense], and [tall] are
  /// [englishLike2018], [dense2018], and [tall2018].
  factory Typography.material2018({
    TargetPlatform platform = TargetPlatform.android,
    TextTheme black,
    TextTheme white,
    TextTheme englishLike,
    TextTheme dense,
    TextTheme tall,
  }) {
    assert(platform != null || (black != null && white != null));
    return Typography._withPlatform(
      platform,
      black, white,
      englishLike ?? englishLike2018,
      dense ?? dense2018,
      tall ?? tall2018,
    );
  }

  factory Typography._withPlatform(
    TargetPlatform platform,
    TextTheme black,
    TextTheme white,
    TextTheme englishLike,
    TextTheme dense,
    TextTheme tall,
  ) {
    assert(platform != null || (black != null && white != null));
    assert(englishLike != null);
    assert(dense != null);
    assert(tall != null);
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        black ??= blackCupertino;
        white ??= whiteCupertino;
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        black ??= blackMountainView;
        white ??= whiteMountainView;
        break;
      case TargetPlatform.windows:
        black ??= blackRedmond;
        white ??= whiteRedmond;
        break;
      case TargetPlatform.linux:
        black ??= blackHelsinki;
        white ??= whiteHelsinki;
        break;
    }
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
  /// [TextTheme], use the overall [Theme], for example:
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
  /// To look up a localized [TextTheme], use the overall [Theme], for
  /// example: `Theme.of(context).textTheme`.
  final TextTheme englishLike;

  /// Defines text geometry for dense scripts, such as Chinese, Japanese
  /// and Korean.
  ///
  /// This text theme is merged with either [black] or [white], depending
  /// on the overall [ThemeData.brightness], when the current locale's
  /// [MaterialLocalizations.scriptCategory] is [ScriptCategory.dense].
  ///
  /// To look up a localized [TextTheme], use the overall [Theme], for
  /// example: `Theme.of(context).textTheme`.
  final TextTheme dense;

  /// Defines text geometry for tall scripts, such as Farsi, Hindi, and Thai.
  ///
  /// This text theme is merged with either [black] or [white], depending
  /// on the overall [ThemeData.brightness], when the current locale's
  /// [MaterialLocalizations.scriptCategory] is [ScriptCategory.tall].
  ///
  /// To look up a localized [TextTheme], use the overall [Theme], for
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
    return Typography._(
      black ?? this.black,
      white ?? this.white,
      englishLike ?? this.englishLike,
      dense ?? this.dense,
      tall ?? this.tall,
    );
  }

  /// Linearly interpolate between two [Typography] objects.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static Typography lerp(Typography a, Typography b, double t) {
    return Typography._(
      TextTheme.lerp(a.black, b.black, t),
      TextTheme.lerp(a.white, b.white, t),
      TextTheme.lerp(a.englishLike, b.englishLike, t),
      TextTheme.lerp(a.dense, b.dense, t),
      TextTheme.lerp(a.tall, b.tall, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is Typography
        && other.black == black
        && other.white == white
        && other.englishLike == englishLike
        && other.dense == dense
        && other.tall == tall;
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
    final Typography defaultTypography = Typography.material2014();
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
    headline1 : TextStyle(debugLabel: 'blackMountainView headline1', fontFamily: 'Roboto', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline2 : TextStyle(debugLabel: 'blackMountainView headline2', fontFamily: 'Roboto', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline3 : TextStyle(debugLabel: 'blackMountainView headline3', fontFamily: 'Roboto', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline4 : TextStyle(debugLabel: 'blackMountainView headline4', fontFamily: 'Roboto', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline5 : TextStyle(debugLabel: 'blackMountainView headline5', fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    headline6 : TextStyle(debugLabel: 'blackMountainView headline6', fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    bodyText1 : TextStyle(debugLabel: 'blackMountainView bodyText1', fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    bodyText2 : TextStyle(debugLabel: 'blackMountainView bodyText2', fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subtitle1 : TextStyle(debugLabel: 'blackMountainView subtitle1', fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subtitle2 : TextStyle(debugLabel: 'blackMountainView subtitle2', fontFamily: 'Roboto', inherit: true, color: Colors.black,   decoration: TextDecoration.none),
    caption   : TextStyle(debugLabel: 'blackMountainView caption',   fontFamily: 'Roboto', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    button    : TextStyle(debugLabel: 'blackMountainView button',    fontFamily: 'Roboto', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    overline  : TextStyle(debugLabel: 'blackMountainView overline',  fontFamily: 'Roboto', inherit: true, color: Colors.black,   decoration: TextDecoration.none),
  );

  /// A material design text theme with light glyphs based on Roboto.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  static const TextTheme whiteMountainView = TextTheme(
    headline1 : TextStyle(debugLabel: 'whiteMountainView headline1', fontFamily: 'Roboto', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline2 : TextStyle(debugLabel: 'whiteMountainView headline2', fontFamily: 'Roboto', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline3 : TextStyle(debugLabel: 'whiteMountainView headline3', fontFamily: 'Roboto', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline4 : TextStyle(debugLabel: 'whiteMountainView headline4', fontFamily: 'Roboto', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline5 : TextStyle(debugLabel: 'whiteMountainView headline5', fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    headline6 : TextStyle(debugLabel: 'whiteMountainView headline6', fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    bodyText1 : TextStyle(debugLabel: 'whiteMountainView bodyText1', fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    bodyText2 : TextStyle(debugLabel: 'whiteMountainView bodyText2', fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subtitle1 : TextStyle(debugLabel: 'whiteMountainView subtitle1', fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subtitle2 : TextStyle(debugLabel: 'whiteMountainView subtitle2', fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    caption   : TextStyle(debugLabel: 'whiteMountainView caption',   fontFamily: 'Roboto', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    button    : TextStyle(debugLabel: 'whiteMountainView button',    fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    overline  : TextStyle(debugLabel: 'whiteMountainView overline',  fontFamily: 'Roboto', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
  );

  /// A material design text theme with dark glyphs based on Segoe UI.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  static const TextTheme blackRedmond = TextTheme(
    headline1 : TextStyle(debugLabel: 'blackRedmond headline1', fontFamily: 'Segoe UI', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline2 : TextStyle(debugLabel: 'blackRedmond headline2', fontFamily: 'Segoe UI', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline3 : TextStyle(debugLabel: 'blackRedmond headline3', fontFamily: 'Segoe UI', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline4 : TextStyle(debugLabel: 'blackRedmond headline4', fontFamily: 'Segoe UI', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline5 : TextStyle(debugLabel: 'blackRedmond headline5', fontFamily: 'Segoe UI', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    headline6 : TextStyle(debugLabel: 'blackRedmond headline6', fontFamily: 'Segoe UI', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    bodyText1 : TextStyle(debugLabel: 'blackRedmond bodyText1', fontFamily: 'Segoe UI', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    bodyText2 : TextStyle(debugLabel: 'blackRedmond bodyText2', fontFamily: 'Segoe UI', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subtitle1 : TextStyle(debugLabel: 'blackRedmond subtitle1', fontFamily: 'Segoe UI', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subtitle2 : TextStyle(debugLabel: 'blackRedmond subtitle2', fontFamily: 'Segoe UI', inherit: true, color: Colors.black,   decoration: TextDecoration.none),
    caption   : TextStyle(debugLabel: 'blackRedmond caption',   fontFamily: 'Segoe UI', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    button    : TextStyle(debugLabel: 'blackRedmond button',    fontFamily: 'Segoe UI', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    overline  : TextStyle(debugLabel: 'blackRedmond overline',  fontFamily: 'Segoe UI', inherit: true, color: Colors.black,   decoration: TextDecoration.none),
  );

  /// A material design text theme with light glyphs based on Segoe UI.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  static const TextTheme whiteRedmond = TextTheme(
    headline1 : TextStyle(debugLabel: 'whiteRedmond headline1', fontFamily: 'Segoe UI', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline2 : TextStyle(debugLabel: 'whiteRedmond headline2', fontFamily: 'Segoe UI', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline3 : TextStyle(debugLabel: 'whiteRedmond headline3', fontFamily: 'Segoe UI', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline4 : TextStyle(debugLabel: 'whiteRedmond headline4', fontFamily: 'Segoe UI', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline5 : TextStyle(debugLabel: 'whiteRedmond headline5', fontFamily: 'Segoe UI', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    headline6 : TextStyle(debugLabel: 'whiteRedmond headline6', fontFamily: 'Segoe UI', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    bodyText1 : TextStyle(debugLabel: 'whiteRedmond bodyText1', fontFamily: 'Segoe UI', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    bodyText2 : TextStyle(debugLabel: 'whiteRedmond bodyText2', fontFamily: 'Segoe UI', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subtitle1 : TextStyle(debugLabel: 'whiteRedmond subtitle1', fontFamily: 'Segoe UI', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subtitle2 : TextStyle(debugLabel: 'whiteRedmond subtitle2', fontFamily: 'Segoe UI', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    caption   : TextStyle(debugLabel: 'whiteRedmond caption',   fontFamily: 'Segoe UI', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    button    : TextStyle(debugLabel: 'whiteRedmond button',    fontFamily: 'Segoe UI', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    overline  : TextStyle(debugLabel: 'whiteRedmond overline',  fontFamily: 'Segoe UI', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
  );

  static const List<String> _helsinkiFontFallbacks = <String>['Ubuntu', 'Cantarell', 'DejaVu Sans', 'Liberation Sans', 'Arial'];
  /// A material design text theme with dark glyphs based on Roboto, with
  /// fallback fonts that are likely (but not guaranteed) to be installed on
  /// Linux.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  static const TextTheme blackHelsinki = TextTheme(
    headline1 : TextStyle(debugLabel: 'blackHelsinki headline1', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline2 : TextStyle(debugLabel: 'blackHelsinki headline2', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline3 : TextStyle(debugLabel: 'blackHelsinki headline3', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline4 : TextStyle(debugLabel: 'blackHelsinki headline4', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline5 : TextStyle(debugLabel: 'blackHelsinki headline5', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    headline6 : TextStyle(debugLabel: 'blackHelsinki headline6', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    bodyText1 : TextStyle(debugLabel: 'blackHelsinki bodyText1', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    bodyText2 : TextStyle(debugLabel: 'blackHelsinki bodyText2', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subtitle1 : TextStyle(debugLabel: 'blackHelsinki subtitle1', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subtitle2 : TextStyle(debugLabel: 'blackHelsinki subtitle2', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black,   decoration: TextDecoration.none),
    caption   : TextStyle(debugLabel: 'blackHelsinki caption',   fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    button    : TextStyle(debugLabel: 'blackHelsinki button',    fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    overline  : TextStyle(debugLabel: 'blackHelsinki overline',  fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.black,   decoration: TextDecoration.none),
  );

  /// A material design text theme with light glyphs based on Roboto, with fallbacks of DejaVu Sans, Liberation Sans and Arial.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  static const TextTheme whiteHelsinki = TextTheme(
    headline1 : TextStyle(debugLabel: 'whiteHelsinki headline1', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline2 : TextStyle(debugLabel: 'whiteHelsinki headline2', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline3 : TextStyle(debugLabel: 'whiteHelsinki headline3', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline4 : TextStyle(debugLabel: 'whiteHelsinki headline4', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline5 : TextStyle(debugLabel: 'whiteHelsinki headline5', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    headline6 : TextStyle(debugLabel: 'whiteHelsinki headline6', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    bodyText1 : TextStyle(debugLabel: 'whiteHelsinki bodyText1', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    bodyText2 : TextStyle(debugLabel: 'whiteHelsinki bodyText2', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subtitle1 : TextStyle(debugLabel: 'whiteHelsinki subtitle1', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subtitle2 : TextStyle(debugLabel: 'whiteHelsinki subtitle2', fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    caption   : TextStyle(debugLabel: 'whiteHelsinki caption',   fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    button    : TextStyle(debugLabel: 'whiteHelsinki button',    fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    overline  : TextStyle(debugLabel: 'whiteHelsinki overline',  fontFamily: 'Roboto', fontFamilyFallback: _helsinkiFontFallbacks, inherit: true, color: Colors.white,   decoration: TextDecoration.none),
  );

  /// A material design text theme with dark glyphs based on San Francisco.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  static const TextTheme blackCupertino = TextTheme(
    headline1 : TextStyle(debugLabel: 'blackCupertino headline1', fontFamily: '.SF UI Display', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline2 : TextStyle(debugLabel: 'blackCupertino headline2', fontFamily: '.SF UI Display', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline3 : TextStyle(debugLabel: 'blackCupertino headline3', fontFamily: '.SF UI Display', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline4 : TextStyle(debugLabel: 'blackCupertino headline4', fontFamily: '.SF UI Display', inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    headline5 : TextStyle(debugLabel: 'blackCupertino headline5', fontFamily: '.SF UI Display', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    headline6 : TextStyle(debugLabel: 'blackCupertino headline6', fontFamily: '.SF UI Display', inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    bodyText1 : TextStyle(debugLabel: 'blackCupertino bodyText1', fontFamily: '.SF UI Text',    inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    bodyText2 : TextStyle(debugLabel: 'blackCupertino bodyText2', fontFamily: '.SF UI Text',    inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subtitle1 : TextStyle(debugLabel: 'blackCupertino subtitle1', fontFamily: '.SF UI Text',    inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    subtitle2 : TextStyle(debugLabel: 'blackCupertino subtitle2', fontFamily: '.SF UI Text',    inherit: true, color: Colors.black,   decoration: TextDecoration.none),
    caption   : TextStyle(debugLabel: 'blackCupertino caption',   fontFamily: '.SF UI Text',    inherit: true, color: Colors.black54, decoration: TextDecoration.none),
    button    : TextStyle(debugLabel: 'blackCupertino button',    fontFamily: '.SF UI Text',    inherit: true, color: Colors.black87, decoration: TextDecoration.none),
    overline  : TextStyle(debugLabel: 'blackCupertino overline',  fontFamily: '.SF UI Text',    inherit: true, color: Colors.black,   decoration: TextDecoration.none),
  );

  /// A material design text theme with light glyphs based on San Francisco.
  ///
  /// This [TextTheme] provides color but not geometry (font size, weight, etc).
  static const TextTheme whiteCupertino = TextTheme(
    headline1 : TextStyle(debugLabel: 'whiteCupertino headline1', fontFamily: '.SF UI Display', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline2 : TextStyle(debugLabel: 'whiteCupertino headline2', fontFamily: '.SF UI Display', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline3 : TextStyle(debugLabel: 'whiteCupertino headline3', fontFamily: '.SF UI Display', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline4 : TextStyle(debugLabel: 'whiteCupertino headline4', fontFamily: '.SF UI Display', inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    headline5 : TextStyle(debugLabel: 'whiteCupertino headline5', fontFamily: '.SF UI Display', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    headline6 : TextStyle(debugLabel: 'whiteCupertino headline6', fontFamily: '.SF UI Display', inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subtitle1 : TextStyle(debugLabel: 'whiteCupertino subtitle1', fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    bodyText1 : TextStyle(debugLabel: 'whiteCupertino bodyText1', fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    bodyText2 : TextStyle(debugLabel: 'whiteCupertino bodyText2', fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    caption   : TextStyle(debugLabel: 'whiteCupertino caption',   fontFamily: '.SF UI Text',    inherit: true, color: Colors.white70, decoration: TextDecoration.none),
    button    : TextStyle(debugLabel: 'whiteCupertino button',    fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    subtitle2 : TextStyle(debugLabel: 'whiteCupertino subtitle2', fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
    overline  : TextStyle(debugLabel: 'whiteCupertino overline',  fontFamily: '.SF UI Text',    inherit: true, color: Colors.white,   decoration: TextDecoration.none),
  );

  /// Defines text geometry for [ScriptCategory.englishLike] scripts, such as
  /// English, French, Russian, etc.
  static const TextTheme englishLike2014 = TextTheme(
    headline1 : TextStyle(debugLabel: 'englishLike display4 2014', inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.alphabetic),
    headline2 : TextStyle(debugLabel: 'englishLike display3 2014', inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline3 : TextStyle(debugLabel: 'englishLike display2 2014', inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline4 : TextStyle(debugLabel: 'englishLike display1 2014', inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline5 : TextStyle(debugLabel: 'englishLike headline 2014', inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline6 : TextStyle(debugLabel: 'englishLike title 2014',    inherit: false, fontSize:  20.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    bodyText1 : TextStyle(debugLabel: 'englishLike body2 2014',    inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    bodyText2 : TextStyle(debugLabel: 'englishLike body1 2014',    inherit: false, fontSize:  14.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    subtitle1 : TextStyle(debugLabel: 'englishLike subhead 2014',  inherit: false, fontSize:  16.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    subtitle2 : TextStyle(debugLabel: 'englishLike subtitle 2014', inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.1),
    caption   : TextStyle(debugLabel: 'englishLike caption 2014',  inherit: false, fontSize:  12.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    button    : TextStyle(debugLabel: 'englishLike button 2014',   inherit: false, fontSize:  14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    overline  : TextStyle(debugLabel: 'englishLike overline 2014', inherit: false, fontSize:  10.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 1.5),
  );

  /// Defines text geometry for [ScriptCategory.englishLike] scripts, such as
  /// English, French, Russian, etc.
  ///
  /// The font sizes, weights, and letter spacings in this version match the
  /// [latest Material Design specification](https://material.io/go/design-typography#typography-styles).
  static const TextTheme englishLike2018 = TextTheme(
    headline1 : TextStyle(debugLabel: 'englishLike headline1 2018', fontSize: 96.0, fontWeight: FontWeight.w300, textBaseline: TextBaseline.alphabetic, letterSpacing: -1.5),
    headline2 : TextStyle(debugLabel: 'englishLike headline2 2018', fontSize: 60.0, fontWeight: FontWeight.w300, textBaseline: TextBaseline.alphabetic, letterSpacing: -0.5),
    headline3 : TextStyle(debugLabel: 'englishLike headline3 2018', fontSize: 48.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.0),
    headline4 : TextStyle(debugLabel: 'englishLike headline4 2018', fontSize: 34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.25),
    headline5 : TextStyle(debugLabel: 'englishLike headline5 2018', fontSize: 24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.0),
    headline6 : TextStyle(debugLabel: 'englishLike headline6 2018', fontSize: 20.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.15),
    bodyText1 : TextStyle(debugLabel: 'englishLike bodyText1 2018', fontSize: 16.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.5),
    bodyText2 : TextStyle(debugLabel: 'englishLike bodyText2 2018', fontSize: 14.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.25),
    subtitle1 : TextStyle(debugLabel: 'englishLike subtitle1 2018', fontSize: 16.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.15),
    subtitle2 : TextStyle(debugLabel: 'englishLike subtitle2 2018', fontSize: 14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.1),
    button    : TextStyle(debugLabel: 'englishLike button 2018',    fontSize: 14.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic, letterSpacing: 1.25),
    caption   : TextStyle(debugLabel: 'englishLike caption 2018',   fontSize: 12.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 0.4),
    overline  : TextStyle(debugLabel: 'englishLike overline 2018',  fontSize: 10.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic, letterSpacing: 1.5),
  );

  /// Defines text geometry for dense scripts, such as Chinese, Japanese
  /// and Korean.
  static const TextTheme dense2014 = TextTheme(
    headline1 : TextStyle(debugLabel: 'dense display4 2014', inherit: false, fontSize: 112.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic),
    headline2 : TextStyle(debugLabel: 'dense display3 2014', inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    headline3 : TextStyle(debugLabel: 'dense display2 2014', inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    headline4 : TextStyle(debugLabel: 'dense display1 2014', inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    headline5 : TextStyle(debugLabel: 'dense headline 2014', inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    headline6 : TextStyle(debugLabel: 'dense title 2014',    inherit: false, fontSize:  21.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    bodyText1 : TextStyle(debugLabel: 'dense body2 2014',    inherit: false, fontSize:  15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    bodyText2 : TextStyle(debugLabel: 'dense body1 2014',    inherit: false, fontSize:  15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    subtitle1 : TextStyle(debugLabel: 'dense subhead 2014',  inherit: false, fontSize:  17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    subtitle2 : TextStyle(debugLabel: 'dense subtitle 2014', inherit: false, fontSize:  15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    caption   : TextStyle(debugLabel: 'dense caption 2014',  inherit: false, fontSize:  13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    button    : TextStyle(debugLabel: 'dense button 2014',   inherit: false, fontSize:  15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    overline  : TextStyle(debugLabel: 'dense overline 2014', inherit: false, fontSize:  11.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
  );

  /// Defines text geometry for dense scripts, such as Chinese, Japanese
  /// and Korean.
  ///
  /// The font sizes, weights, and letter spacings in this version match the
  /// latest [Material Design specification](https://material.io/go/design-typography#typography-styles).
  static const TextTheme dense2018 = TextTheme(
    headline1 : TextStyle(debugLabel: 'dense headline1 2018', fontSize: 96.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic),
    headline2 : TextStyle(debugLabel: 'dense headline2 2018', fontSize: 60.0, fontWeight: FontWeight.w100, textBaseline: TextBaseline.ideographic),
    headline3 : TextStyle(debugLabel: 'dense headline3 2018', fontSize: 48.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    headline4 : TextStyle(debugLabel: 'dense headline4 2018', fontSize: 34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    headline5 : TextStyle(debugLabel: 'dense headline5 2018', fontSize: 24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    headline6 : TextStyle(debugLabel: 'dense headline6 2018', fontSize: 21.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    bodyText1 : TextStyle(debugLabel: 'dense bodyText1 2018', fontSize: 17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    bodyText2 : TextStyle(debugLabel: 'dense bodyText2 2018', fontSize: 15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    subtitle1 : TextStyle(debugLabel: 'dense subtitle1 2018', fontSize: 17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    subtitle2 : TextStyle(debugLabel: 'dense subtitle2 2018', fontSize: 15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    button    : TextStyle(debugLabel: 'dense button 2018',    fontSize: 15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.ideographic),
    caption   : TextStyle(debugLabel: 'dense caption 2018',   fontSize: 13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
    overline  : TextStyle(debugLabel: 'dense overline 2018',  fontSize: 11.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.ideographic),
  );

  /// Defines text geometry for tall scripts, such as Farsi, Hindi, and Thai.
  static const TextTheme tall2014 = TextTheme(
    headline1 : TextStyle(debugLabel: 'tall display4 2014', inherit: false, fontSize: 112.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline2 : TextStyle(debugLabel: 'tall display3 2014', inherit: false, fontSize:  56.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline3 : TextStyle(debugLabel: 'tall display2 2014', inherit: false, fontSize:  45.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline4 : TextStyle(debugLabel: 'tall display1 2014', inherit: false, fontSize:  34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline5 : TextStyle(debugLabel: 'tall headline 2014', inherit: false, fontSize:  24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline6 : TextStyle(debugLabel: 'tall title 2014',    inherit: false, fontSize:  21.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    bodyText1 : TextStyle(debugLabel: 'tall body2 2014',    inherit: false, fontSize:  15.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    bodyText2 : TextStyle(debugLabel: 'tall body1 2014',    inherit: false, fontSize:  15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    subtitle1 : TextStyle(debugLabel: 'tall subhead 2014',  inherit: false, fontSize:  17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    subtitle2 : TextStyle(debugLabel: 'tall subtitle 2014', inherit: false, fontSize:  15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    caption   : TextStyle(debugLabel: 'tall caption 2014',  inherit: false, fontSize:  13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    button    : TextStyle(debugLabel: 'tall button 2014',   inherit: false, fontSize:  15.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    overline  : TextStyle(debugLabel: 'tall overline 2014', inherit: false, fontSize:  11.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
  );

  /// Defines text geometry for tall scripts, such as Farsi, Hindi, and Thai.
  ///
  /// The font sizes, weights, and letter spacings in this version match the
  /// latest [Material Design specification](https://material.io/go/design-typography#typography-styles).
  static const TextTheme tall2018 = TextTheme(
    headline1 : TextStyle(debugLabel: 'tall headline1 2018', fontSize: 96.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline2 : TextStyle(debugLabel: 'tall headline2 2018', fontSize: 60.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline3 : TextStyle(debugLabel: 'tall headline3 2018', fontSize: 48.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline4 : TextStyle(debugLabel: 'tall headline4 2018', fontSize: 34.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline5 : TextStyle(debugLabel: 'tall headline5 2018', fontSize: 24.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    headline6 : TextStyle(debugLabel: 'tall headline6 2018', fontSize: 21.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    bodyText1 : TextStyle(debugLabel: 'tall bodyText1 2018', fontSize: 17.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    bodyText2 : TextStyle(debugLabel: 'tall bodyText2 2018', fontSize: 15.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    subtitle1 : TextStyle(debugLabel: 'tall subtitle1 2018', fontSize: 17.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    subtitle2 : TextStyle(debugLabel: 'tall subtitle2 2018', fontSize: 15.0, fontWeight: FontWeight.w500, textBaseline: TextBaseline.alphabetic),
    button    : TextStyle(debugLabel: 'tall button 2018',    fontSize: 15.0, fontWeight: FontWeight.w700, textBaseline: TextBaseline.alphabetic),
    caption   : TextStyle(debugLabel: 'tall caption 2018',   fontSize: 13.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
    overline  : TextStyle(debugLabel: 'tall overline 2018',  fontSize: 11.0, fontWeight: FontWeight.w400, textBaseline: TextBaseline.alphabetic),
  );
}
