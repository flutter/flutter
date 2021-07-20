// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'typography.dart';

/// Material design text theme.
///
/// Definitions for the various typographical styles found in Material Design
/// (e.g., button, caption). Rather than creating a [TextTheme] directly,
/// you can obtain an instance as [Typography.black] or [Typography.white].
///
/// To obtain the current text theme, call [Theme.of] with the current
/// [BuildContext] and read the [ThemeData.textTheme] property.
///
/// The names of the TextTheme properties match this table from the
/// [Material Design spec](https://material.io/design/typography/the-type-system.html#type-scale)
/// with two exceptions: the styles called H1-H6 in the spec are
/// headline1-headline6 in the API, and body1,body2 are called
/// bodyText1 and bodyText2.
///
/// ![](https://storage.googleapis.com/spec-host-backup/mio-design%2Fassets%2F1W8kyGVruuG_O8psvyiOaCf1lLFIMzB-N%2Ftypesystem-typescale.png)
///
/// The Material Design typography scheme was significantly changed in the
/// current (2018) version of the specification
/// ([https://material.io/design/typography](https://material.io/design/typography)).
///
/// The 2018 spec has thirteen text styles:
/// ```
/// NAME         SIZE  WEIGHT  SPACING
/// headline1    96.0  light   -1.5
/// headline2    60.0  light   -0.5
/// headline3    48.0  regular  0.0
/// headline4    34.0  regular  0.25
/// headline5    24.0  regular  0.0
/// headline6    20.0  medium   0.15
/// subtitle1    16.0  regular  0.15
/// subtitle2    14.0  medium   0.1
/// body1        16.0  regular  0.5   (bodyText1)
/// body2        14.0  regular  0.25  (bodyText2)
/// button       14.0  medium   1.25
/// caption      12.0  regular  0.4
/// overline     10.0  regular  1.5
/// ```
///
/// ...where "light" is `FontWeight.w300`, "regular" is `FontWeight.w400` and
/// "medium" is `FontWeight.w500`.
///
/// By default, text styles are initialized to match the 2018 Material Design
/// specification as listed above. To provide backwards compatibility, the 2104
/// specification is also available.
///
/// To explicitly configure a [Theme] for the 2018 sizes, weights, and letter
/// spacings, you can initialize its [ThemeData.typography] value using
/// [Typography.material2018]. The [Typography] constructor defaults to this
/// configuration. To configure a [Theme] for the 2014 sizes, weights, and letter
/// spacings, initialize its [ThemeData.typography] value using
/// [Typography.material2014].
///
/// See also:
///
///  * [Typography], the class that generates [TextTheme]s appropriate for a platform.
///  * [Theme], for other aspects of a material design application that can be
///    globally adjusted, such as the color scheme.
///  * <https://material.io/design/typography/>
@immutable
class TextTheme with Diagnosticable {
  /// Creates a text theme that uses the given values.
  ///
  /// Rather than creating a new text theme, consider using [Typography.black]
  /// or [Typography.white], which implement the typography styles in the
  /// material design specification:
  ///
  /// <https://material.io/design/typography/#type-scale>
  ///
  /// If you do decide to create your own text theme, consider using one of
  /// those predefined themes as a starting point for [copyWith] or [apply].
  const TextTheme({
    this.headline1,
    this.headline2,
    this.headline3,
    this.headline4,
    this.headline5,
    this.headline6,
    this.subtitle1,
    this.subtitle2,
    this.bodyText1,
    this.bodyText2,
    this.caption,
    this.button,
    this.overline,
  });

  /// Extremely large text.
  final TextStyle? headline1;

  /// Very, very large text.
  ///
  /// Used for the date in the dialog shown by [showDatePicker].
  final TextStyle? headline2;

  /// Very large text.
  final TextStyle? headline3;

  /// Large text.
  final TextStyle? headline4;

  /// Used for large text in dialogs (e.g., the month and year in the dialog
  /// shown by [showDatePicker]).
  final TextStyle? headline5;

  /// Used for the primary text in app bars and dialogs (e.g., [AppBar.title]
  /// and [AlertDialog.title]).
  final TextStyle? headline6;

  /// Used for the primary text in lists (e.g., [ListTile.title]).
  final TextStyle? subtitle1;

  /// For medium emphasis text that's a little smaller than [subtitle1].
  final TextStyle? subtitle2;

  /// Used for emphasizing text that would otherwise be [bodyText2].
  final TextStyle? bodyText1;

  /// The default text style for [Material].
  final TextStyle? bodyText2;

  /// Used for auxiliary text associated with images.
  final TextStyle? caption;

  /// Used for text on [ElevatedButton], [TextButton] and [OutlinedButton].
  final TextStyle? button;

  /// The smallest style.
  ///
  /// Typically used for captions or to introduce a (larger) headline.
  final TextStyle? overline;

  /// Creates a copy of this text theme but with the given fields replaced with
  /// the new values.
  ///
  /// Consider using [Typography.black] or [Typography.white], which implement
  /// the typography styles in the material design specification, as a starting
  /// point.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// /// A Widget that sets the ambient theme's title text color for its
  /// /// descendants, while leaving other ambient theme attributes alone.
  /// class TitleColorThemeCopy extends StatelessWidget {
  ///   const TitleColorThemeCopy({Key? key, required this.child, required this.titleColor}) : super(key: key);
  ///
  ///   final Color titleColor;
  ///   final Widget child;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final ThemeData theme = Theme.of(context);
  ///     return Theme(
  ///       data: theme.copyWith(
  ///         textTheme: theme.textTheme.copyWith(
  ///           headline6: theme.textTheme.headline6!.copyWith(
  ///             color: titleColor,
  ///           ),
  ///         ),
  ///       ),
  ///       child: child,
  ///     );
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [merge] is used instead of [copyWith] when you want to merge all
  ///    of the fields of a TextTheme instead of individual fields.
  TextTheme copyWith({
    TextStyle? headline1,
    TextStyle? headline2,
    TextStyle? headline3,
    TextStyle? headline4,
    TextStyle? headline5,
    TextStyle? headline6,
    TextStyle? subtitle1,
    TextStyle? subtitle2,
    TextStyle? bodyText1,
    TextStyle? bodyText2,
    TextStyle? caption,
    TextStyle? button,
    TextStyle? overline,
  }) {
    return TextTheme(
      headline1: headline1 ?? this.headline1,
      headline2: headline2 ?? this.headline2,
      headline3: headline3 ?? this.headline3,
      headline4: headline4 ?? this.headline4,
      headline5: headline5 ?? this.headline5,
      headline6: headline6 ?? this.headline6,
      subtitle1: subtitle1 ?? this.subtitle1,
      subtitle2: subtitle2 ?? this.subtitle2,
      bodyText1: bodyText1 ?? this.bodyText1,
      bodyText2: bodyText2 ?? this.bodyText2,
      caption: caption ?? this.caption,
      button: button ?? this.button,
      overline: overline ?? this.overline,
    );
  }

  /// Creates a new [TextTheme] where each text style from this object has been
  /// merged with the matching text style from the `other` object.
  ///
  /// The merging is done by calling [TextStyle.merge] on each respective pair
  /// of text styles from this and the [other] text themes and is subject to
  /// the value of [TextStyle.inherit] flag. For more details, see the
  /// documentation on [TextStyle.merge] and [TextStyle.inherit].
  ///
  /// If this theme, or the `other` theme has members that are null, then the
  /// non-null one (if any) is used. If the `other` theme is itself null, then
  /// this [TextTheme] is returned unchanged. If values in both are set, then
  /// the values are merged using [TextStyle.merge].
  ///
  /// This is particularly useful if one [TextTheme] defines one set of
  /// properties and another defines a different set, e.g. having colors
  /// defined in one text theme and font sizes in another, or when one
  /// [TextTheme] has only some fields defined, and you want to define the rest
  /// by merging it with a default theme.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// /// A Widget that sets the ambient theme's title text color for its
  /// /// descendants, while leaving other ambient theme attributes alone.
  /// class TitleColorTheme extends StatelessWidget {
  ///   const TitleColorTheme({Key? key, required this.child, required this.titleColor}) : super(key: key);
  ///
  ///   final Color titleColor;
  ///   final Widget child;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     ThemeData theme = Theme.of(context);
  ///     // This partialTheme is incomplete: it only has the title style
  ///     // defined. Just replacing theme.textTheme with partialTheme would
  ///     // set the title, but everything else would be null. This isn't very
  ///     // useful, so merge it with the existing theme to keep all of the
  ///     // preexisting definitions for the other styles.
  ///     final TextTheme partialTheme = TextTheme(headline6: TextStyle(color: titleColor));
  ///     theme = theme.copyWith(textTheme: theme.textTheme.merge(partialTheme));
  ///     return Theme(data: theme, child: child);
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [copyWith] is used instead of [merge] when you wish to override
  ///    individual fields in the [TextTheme] instead of merging all of the
  ///    fields of two [TextTheme]s.
  TextTheme merge(TextTheme? other) {
    if (other == null)
      return this;
    return copyWith(
      headline1: headline1?.merge(other.headline1) ?? other.headline1,
      headline2: headline2?.merge(other.headline2) ?? other.headline2,
      headline3: headline3?.merge(other.headline3) ?? other.headline3,
      headline4: headline4?.merge(other.headline4) ?? other.headline4,
      headline5: headline5?.merge(other.headline5) ?? other.headline5,
      headline6: headline6?.merge(other.headline6) ?? other.headline6,
      subtitle1: subtitle1?.merge(other.subtitle1) ?? other.subtitle1,
      subtitle2: subtitle2?.merge(other.subtitle2) ?? other.subtitle2,
      bodyText1: bodyText1?.merge(other.bodyText1) ?? other.bodyText1,
      bodyText2: bodyText2?.merge(other.bodyText2) ?? other.bodyText2,
      caption: caption?.merge(other.caption) ?? other.caption,
      button: button?.merge(other.button) ?? other.button,
      overline: overline?.merge(other.overline) ?? other.overline,
    );
  }

  /// Creates a copy of this text theme but with the given field replaced in
  /// each of the individual text styles.
  ///
  /// The `displayColor` is applied to [headline4], [headline3], [headline2],
  /// [headline1], and [caption]. The `bodyColor` is applied to the remaining
  /// text styles.
  ///
  /// Consider using [Typography.black] or [Typography.white], which implement
  /// the typography styles in the material design specification, as a starting
  /// point.
  TextTheme apply({
    String? fontFamily,
    double fontSizeFactor = 1.0,
    double fontSizeDelta = 0.0,
    Color? displayColor,
    Color? bodyColor,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
  }) {
    return TextTheme(
      headline1: headline1?.apply(
        color: displayColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      headline2: headline2?.apply(
        color: displayColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      headline3: headline3?.apply(
        color: displayColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      headline4: headline4?.apply(
        color: displayColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      headline5: headline5?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      headline6: headline6?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      subtitle1: subtitle1?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      subtitle2: subtitle2?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      bodyText1: bodyText1?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      bodyText2: bodyText2?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      caption: caption?.apply(
        color: displayColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      button: button?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      overline: overline?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
    );
  }

  /// Linearly interpolate between two text themes.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static TextTheme lerp(TextTheme? a, TextTheme? b, double t) {
    assert(t != null);
    return TextTheme(
      headline1: TextStyle.lerp(a?.headline1, b?.headline1, t),
      headline2: TextStyle.lerp(a?.headline2, b?.headline2, t),
      headline3: TextStyle.lerp(a?.headline3, b?.headline3, t),
      headline4: TextStyle.lerp(a?.headline4, b?.headline4, t),
      headline5: TextStyle.lerp(a?.headline5, b?.headline5, t),
      headline6: TextStyle.lerp(a?.headline6, b?.headline6, t),
      subtitle1: TextStyle.lerp(a?.subtitle1, b?.subtitle1, t),
      subtitle2: TextStyle.lerp(a?.subtitle2, b?.subtitle2, t),
      bodyText1: TextStyle.lerp(a?.bodyText1, b?.bodyText1, t),
      bodyText2: TextStyle.lerp(a?.bodyText2, b?.bodyText2, t),
      caption: TextStyle.lerp(a?.caption, b?.caption, t),
      button: TextStyle.lerp(a?.button, b?.button, t),
      overline: TextStyle.lerp(a?.overline, b?.overline, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    return other is TextTheme
      && headline1 == other.headline1
      && headline2 == other.headline2
      && headline3 == other.headline3
      && headline4 == other.headline4
      && headline5 == other.headline5
      && headline6 == other.headline6
      && subtitle1 == other.subtitle1
      && subtitle2 == other.subtitle2
      && bodyText1 == other.bodyText1
      && bodyText2 == other.bodyText2
      && caption == other.caption
      && button == other.button
      && overline == other.overline;
  }

  @override
  int get hashCode {
    // The hashValues() function supports up to 20 arguments.
    return hashValues(
      headline1,
      headline2,
      headline3,
      headline4,
      headline5,
      headline6,
      subtitle1,
      subtitle2,
      bodyText1,
      bodyText2,
      caption,
      button,
      overline,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final TextTheme defaultTheme = Typography.material2018(platform: defaultTargetPlatform).black;
    properties.add(DiagnosticsProperty<TextStyle>('headline1', headline1, defaultValue: defaultTheme.headline1));
    properties.add(DiagnosticsProperty<TextStyle>('headline2', headline2, defaultValue: defaultTheme.headline2));
    properties.add(DiagnosticsProperty<TextStyle>('headline3', headline3, defaultValue: defaultTheme.headline3));
    properties.add(DiagnosticsProperty<TextStyle>('headline4', headline4, defaultValue: defaultTheme.headline4));
    properties.add(DiagnosticsProperty<TextStyle>('headline5', headline5, defaultValue: defaultTheme.headline5));
    properties.add(DiagnosticsProperty<TextStyle>('headline6', headline6, defaultValue: defaultTheme.headline6));
    properties.add(DiagnosticsProperty<TextStyle>('subtitle1', subtitle1, defaultValue: defaultTheme.subtitle1));
    properties.add(DiagnosticsProperty<TextStyle>('subtitle2', subtitle2, defaultValue: defaultTheme.subtitle2));
    properties.add(DiagnosticsProperty<TextStyle>('bodyText1', bodyText1, defaultValue: defaultTheme.bodyText1));
    properties.add(DiagnosticsProperty<TextStyle>('bodyText2', bodyText2, defaultValue: defaultTheme.bodyText2));
    properties.add(DiagnosticsProperty<TextStyle>('caption', caption, defaultValue: defaultTheme.caption));
    properties.add(DiagnosticsProperty<TextStyle>('button', button, defaultValue: defaultTheme.button));
    properties.add(DiagnosticsProperty<TextStyle>('overline', overline, defaultValue: defaultTheme.overline));
  }
}
