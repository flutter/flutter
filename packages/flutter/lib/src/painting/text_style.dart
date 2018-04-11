// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show ParagraphStyle, TextStyle, lerpDouble, Locale;

import 'package:flutter/foundation.dart';

import 'basic_types.dart';

const String _kDefaultDebugLabel = 'unknown';

/// An immutable style in which paint text.
///
/// ## Sample code
///
/// ### Bold
///
/// Here, a single line of text in a [Text] widget is given a specific style
/// override. The style is mixed with the ambient [DefaultTextStyle] by the
/// [Text] widget.
///
/// ```dart
/// new Text(
///   'No, we need bold strokes. We need this plan.',
///   style: new TextStyle(fontWeight: FontWeight.bold),
/// )
/// ```
///
/// ### Italics
///
/// As in the previous example, the [Text] widget is given a specific style
/// override which is implicitly mixed with the ambient [DefaultTextStyle].
///
/// ```dart
/// new Text(
///   'Welcome to the present, we\'re running a real nation.',
///   style: new TextStyle(fontStyle: FontStyle.italic),
/// )
/// ```
///
/// ### Opacity
///
/// Each line here is progressively more opaque. The base color is
/// [material.Colors.black], and [Color.withOpacity] is used to create a
/// derivative color with the desired opacity. The root [TextSpan] for this
/// [RichText] widget is explicitly given the ambient [DefaultTextStyle], since
/// [RichText] does not do that automatically. The inner [TextStyle] objects are
/// implicitly mixed with the parent [TextSpan]'s [TextSpan.style].
///
/// ```dart
/// new RichText(
///   text: new TextSpan(
///     style: DefaultTextStyle.of(context).style,
///     children: <TextSpan>[
///       new TextSpan(
///         text: 'You don\'t have the votes.\n',
///         style: new TextStyle(color: Colors.black.withOpacity(0.6)),
///       ),
///       new TextSpan(
///         text: 'You don\'t have the votes!\n',
///         style: new TextStyle(color: Colors.black.withOpacity(0.8)),
///       ),
///       new TextSpan(
///         text: 'You\'re gonna need congressional approval and you don\'t have the votes!\n',
///         style: new TextStyle(color: Colors.black.withOpacity(1.0)),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ### Size
///
/// In this example, the ambient [DefaultTextStyle] is explicitly manipulated to
/// obtain a [TextStyle] that doubles the default font size.
///
/// ```dart
/// new Text(
///   'These are wise words, enterprising men quote \'em.',
///   style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0),
/// )
/// ```
///
/// ### Line height
///
/// The [height] property can be used to change the line height. Here, the line
/// height is set to 100 logical pixels, so that the text is very spaced out.
///
/// ```dart
/// new Text(
///   'Don\'t act surprised, you guys, cuz I wrote \'em!',
///   style: new TextStyle(height: 100.0),
/// )
/// ```
///
/// ### Wavy red underline with black text
///
/// Styles can be combined. In this example, the misspelt word is drawn in black
/// text and underlined with a wavy red line to indicate a spelling error. (The
/// remainder is styled according to the Flutter default text styles, not the
/// ambient [DefaultTextStyle], since no explicit style is given and [RichText]
/// does not automatically use the ambient [DefaultTextStyle].)
///
/// ```dart
/// new RichText(
///   text: new TextSpan(
///     text: 'Don\'t tax the South ',
///     children: <TextSpan>[
///       new TextSpan(
///         text: 'cuz',
///         style: new TextStyle(
///           color: Colors.black,
///           decoration: TextDecoration.underline,
///           decorationColor: Colors.red,
///           decorationStyle: TextDecorationStyle.wavy,
///         ),
///       ),
///       new TextSpan(
///         text: ' we got it made in the shade',
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ### Custom Fonts
///
/// Custom fonts can be declared in the `pubspec.yaml` file as shown below:
///
///```yaml
/// flutter:
///   fonts:
///     - family: Raleway
///       fonts:
///         - asset: fonts/Raleway-Regular.ttf
///         - asset: fonts/Raleway-Medium.ttf
///           weight: 500
///         - asset: assets/fonts/Raleway-SemiBold.ttf
///           weight: 600
///      - family: Schyler
///        fonts:
///          - asset: fonts/Schyler-Regular.ttf
///          - asset: fonts/Schyler-Italic.ttf
///            style: italic
///```
///
/// The `family` property determines the name of the font, which you can use in
/// the [fontFamily] argument. The `asset` property is a path to the font file,
/// relative to the `pubspec.yaml` file. The `weight` property specifies the
/// weight of the glyph outlines in the file as an integer multiple of 100
/// between 100 and 900. This corresponds to the [FontWeight] class and can be
/// used in the [fontWeight] argument. The `style` property specifies whether the
/// outlines in the file are `italic` or `normal`. These values correspond to
/// the [FontStyle] class and can be used in the [fontStyle] argument.
///
/// To select a custom font, create [TextStyle] using the [fontFamily]
/// argument as shown in the example below:
///
/// ```dart
/// const TextStyle(fontFamily: 'Raleway')
/// ```
///
/// To use a font family defined in a package, the [package] argument must be
/// provided. For instance, suppose the font declaration above is in the
/// `pubspec.yaml` of a package named `my_package` which the app depends on.
/// Then creating the TextStyle is done as follows:
///
/// ```dart
/// const TextStyle(fontFamily: 'Raleway', package: 'my_package')
/// ```
///
/// If the package internally uses the font it defines, it should still specify
/// the `package` argument when creating the text style as in the example above.
///
/// A package can also provide font files without declaring a font in its
/// `pubspec.yaml`. These files should then be in the `lib/` folder of the
/// package. The font files will not automatically be bundled in the app, instead
/// the app can use these selectively when declaring a font. Suppose a package
/// named `my_package` has:
///
/// ```
/// lib/fonts/Raleway-Medium.ttf
/// ```
///
/// Then the app can declare a font like in the example below:
///
///```yaml
/// flutter:
///   fonts:
///     - family: Raleway
///       fonts:
///         - asset: assets/fonts/Raleway-Regular.ttf
///         - asset: packages/my_package/fonts/Raleway-Medium.ttf
///           weight: 500
///```
///
/// The `lib/` is implied, so it should not be included in the asset path.
///
/// In this case, since the app locally defines the font, the TextStyle is
/// created without the `package` argument:
///
///```dart
/// const TextStyle(fontFamily: 'Raleway')
/// ```
///
/// See also:
///
///  * [Text], the widget for showing text in a single style.
///  * [DefaultTextStyle], the widget that specifies the default text styles for
///    [Text] widgets, configured using a [TextStyle].
///  * [RichText], the widget for showing a paragraph of mix-style text.
///  * [TextSpan], the class that wraps a [TextStyle] for the purposes of
///    passing it to a [RichText].
@immutable
class TextStyle extends Diagnosticable {
  /// Creates a text style.
  ///
  /// The `package` argument must be non-null if the font family is defined in a
  /// package. It is combined with the `fontFamily` argument to set the
  /// [fontFamily] property.
  const TextStyle({
    this.inherit: true,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.wordSpacing,
    this.textBaseline,
    this.height,
    this.locale,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.debugLabel,
    String fontFamily,
    String package,
  }) : fontFamily = package == null ? fontFamily : 'packages/$package/$fontFamily',
       assert(inherit != null);


  /// Whether null values are replaced with their value in an ancestor text
  /// style (e.g., in a [TextSpan] tree).
  ///
  /// If this is false, properties that don't have explicit values will revert
  /// to the defaults: white in color, a font size of 10 pixels, in a sans-serif
  /// font face.
  final bool inherit;

  /// The color to use when painting the text.
  final Color color;

  /// The name of the font to use when painting the text (e.g., Roboto). If the
  /// font is defined in a package, this will be prefixed with
  /// 'packages/package_name/' (e.g. 'packages/cool_fonts/Roboto'). The
  /// prefixing is done by the constructor when the `package` argument is
  /// provided.
  final String fontFamily;

  /// The size of glyphs (in logical pixels) to use when painting the text.
  ///
  /// During painting, the [fontSize] is multiplied by the current
  /// `textScaleFactor` to let users make it easier to read text by increasing
  /// its size.
  ///
  /// [getParagraphStyle] will default to 14 logical pixels if the font size
  /// isn't specified here.
  final double fontSize;

  // The default font size if none is specified.
  static const double _defaultFontSize = 14.0;

  /// The typeface thickness to use when painting the text (e.g., bold).
  final FontWeight fontWeight;

  /// The typeface variant to use when drawing the letters (e.g., italics).
  final FontStyle fontStyle;

  /// The amount of space (in logical pixels) to add between each letter.
  /// A negative value can be used to bring the letters closer.
  final double letterSpacing;

  /// The amount of space (in logical pixels) to add at each sequence of
  /// white-space (i.e. between each word). A negative value can be used to
  /// bring the words closer.
  final double wordSpacing;

  /// The common baseline that should be aligned between this text span and its
  /// parent text span, or, for the root text spans, with the line box.
  final TextBaseline textBaseline;

  /// The height of this text span, as a multiple of the font size.
  ///
  /// If applied to the root [TextSpan], this value sets the line height, which
  /// is the minimum distance between subsequent text baselines, as multiple of
  /// the font size.
  final double height;

  /// The locale used to select region-specific glyphs.
  final ui.Locale locale;

  /// The decorations to paint near the text (e.g., an underline).
  final TextDecoration decoration;

  /// The color in which to paint the text decorations.
  final Color decorationColor;

  /// The style in which to paint the text decorations (e.g., dashed).
  final TextDecorationStyle decorationStyle;

  /// A human-readable description of this text style.
  ///
  /// This property is maintained only in debug builds.
  ///
  /// When merging ([merge]), copying ([copyWith]), modifying using [apply], or
  /// interpolating ([lerp]), the label of the resulting style is marked with
  /// the debug labels of the original styles. This helps figuring out where a
  /// particular text style came from.
  ///
  /// This property is not considered when comparing text styles using `==` or
  /// [compareTo], and it does not affect [hashCode].
  final String debugLabel;

  /// Creates a copy of this text style but with the given fields replaced with
  /// the new values.
  TextStyle copyWith({
    Color color,
    String fontFamily,
    double fontSize,
    FontWeight fontWeight,
    FontStyle fontStyle,
    double letterSpacing,
    double wordSpacing,
    TextBaseline textBaseline,
    double height,
    ui.Locale locale,
    TextDecoration decoration,
    Color decorationColor,
    TextDecorationStyle decorationStyle,
    String debugLabel,
  }) {
    String newDebugLabel;
    assert(() {
      if (this.debugLabel != null)
        newDebugLabel = debugLabel ?? '(${this.debugLabel}).copyWith';
      return true;
    }());
    return new TextStyle(
      inherit: inherit,
      color: color ?? this.color,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      textBaseline: textBaseline ?? this.textBaseline,
      height: height ?? this.height,
      locale: locale ?? this.locale,
      decoration: decoration ?? this.decoration,
      decorationColor: decorationColor ?? this.decorationColor,
      decorationStyle: decorationStyle ?? this.decorationStyle,
      debugLabel: newDebugLabel,
    );
  }

  /// Creates a copy of this text style replacing or altering the specified
  /// properties.
  ///
  /// The non-numeric properties [color], [fontFamily], [decoration],
  /// [decorationColor] and [decorationStyle] are replaced with the new values.
  ///
  /// The numeric properties are multiplied by the given factors and then
  /// incremented by the given deltas.
  ///
  /// For example, `style.apply(fontSizeFactor: 2.0, fontSizeDelta: 1.0)` would
  /// return a [TextStyle] whose [fontSize] is `style.fontSize * 2.0 + 1.0`.
  ///
  /// For the [fontWeight], the delta is applied to the [FontWeight] enum index
  /// values, so that for instance `style.apply(fontWeightDelta: -2)` when
  /// applied to a `style` whose [fontWeight] is [FontWeight.w500] will return a
  /// [TextStyle] with a [FontWeight.w300].
  ///
  /// The numeric arguments must not be null.
  ///
  /// If the underlying values are null, then the corresponding factors and/or
  /// deltas must not be specified.
  TextStyle apply({
    Color color,
    TextDecoration decoration,
    Color decorationColor,
    TextDecorationStyle decorationStyle,
    String fontFamily,
    double fontSizeFactor: 1.0,
    double fontSizeDelta: 0.0,
    int fontWeightDelta: 0,
    double letterSpacingFactor: 1.0,
    double letterSpacingDelta: 0.0,
    double wordSpacingFactor: 1.0,
    double wordSpacingDelta: 0.0,
    double heightFactor: 1.0,
    double heightDelta: 0.0,
  }) {
    assert(fontSizeFactor != null);
    assert(fontSizeDelta != null);
    assert(fontSize != null || (fontSizeFactor == 1.0 && fontSizeDelta == 0.0));
    assert(fontWeightDelta != null);
    assert(fontWeight != null || fontWeightDelta == 0.0);
    assert(letterSpacingFactor != null);
    assert(letterSpacingDelta != null);
    assert(letterSpacing != null || (letterSpacingFactor == 1.0 && letterSpacingDelta == 0.0));
    assert(wordSpacingFactor != null);
    assert(wordSpacingDelta != null);
    assert(wordSpacing != null || (wordSpacingFactor == 1.0 && wordSpacingDelta == 0.0));
    assert(heightFactor != null);
    assert(heightDelta != null);
    assert(heightFactor != null || (heightFactor == 1.0 && heightDelta == 0.0));

    String modifiedDebugLabel;
    assert(() {
      if (debugLabel != null)
        modifiedDebugLabel = '($debugLabel).apply';
      return true;
    }());

    return new TextStyle(
      inherit: inherit,
      color: color ?? this.color,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize == null ? null : fontSize * fontSizeFactor + fontSizeDelta,
      fontWeight: fontWeight == null ? null : FontWeight.values[(fontWeight.index + fontWeightDelta).clamp(0, FontWeight.values.length - 1)],
      fontStyle: fontStyle,
      letterSpacing: letterSpacing == null ? null : letterSpacing * letterSpacingFactor + letterSpacingDelta,
      wordSpacing: wordSpacing == null ? null : wordSpacing * wordSpacingFactor + wordSpacingDelta,
      textBaseline: textBaseline,
      height: height == null ? null : height * heightFactor + heightDelta,
      locale: locale,
      decoration: decoration ?? this.decoration,
      decorationColor: decorationColor ?? this.decorationColor,
      decorationStyle: decorationStyle ?? this.decorationStyle,
      debugLabel: modifiedDebugLabel,
    );
  }

  /// Returns a new text style that is a combination of this style and the given
  /// [other] style.
  ///
  /// If the given [other] text style has its [TextStyle.inherit] set to true,
  /// its null properties are replaced with the non-null properties of this text
  /// style. The [other] style _inherits_ the properties of this style. Another
  /// way to think of it is that the "missing" properties of the [other] style
  /// are _filled_ by the properties of this style.
  ///
  /// If the given [other] text style has its [TextStyle.inherit] set to false,
  /// returns the given [other] style unchanged. The [other] style does not
  /// inherit properties of this style.
  ///
  /// If the given text style is null, returns this text style.
  TextStyle merge(TextStyle other) {
    if (other == null)
      return this;
    if (!other.inherit)
      return other;

    String mergedDebugLabel;
    assert(() {
      if (other.debugLabel != null || debugLabel != null)
        mergedDebugLabel = '(${debugLabel ?? _kDefaultDebugLabel}).merge(${other.debugLabel ?? _kDefaultDebugLabel})';
      return true;
    }());

    return copyWith(
      color: other.color,
      fontFamily: other.fontFamily,
      fontSize: other.fontSize,
      fontWeight: other.fontWeight,
      fontStyle: other.fontStyle,
      letterSpacing: other.letterSpacing,
      wordSpacing: other.wordSpacing,
      textBaseline: other.textBaseline,
      height: other.height,
      locale: other.locale,
      decoration: other.decoration,
      decorationColor: other.decorationColor,
      decorationStyle: other.decorationStyle,
      debugLabel: mergedDebugLabel,
    );
  }

  /// Interpolate between two text styles.
  ///
  /// This will not work well if the styles don't set the same fields.
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an [AnimationController].
  static TextStyle lerp(TextStyle a, TextStyle b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    assert(a.inherit == b.inherit);

    String lerpDebugLabel;
    assert(() {
      lerpDebugLabel = 'lerp(${a.debugLabel ?? _kDefaultDebugLabel} ⎯${t.toStringAsFixed(1)}→ ${b.debugLabel ?? _kDefaultDebugLabel})';
      return true;
    }());

    return new TextStyle(
      inherit: b.inherit,
      color: Color.lerp(a.color, b.color, t),
      fontFamily: t < 0.5 ? a.fontFamily : b.fontFamily,
      fontSize: ui.lerpDouble(a.fontSize ?? b.fontSize, b.fontSize ?? a.fontSize, t),
      fontWeight: FontWeight.lerp(a.fontWeight, b.fontWeight, t),
      fontStyle: t < 0.5 ? a.fontStyle : b.fontStyle,
      letterSpacing: ui.lerpDouble(a.letterSpacing ?? b.letterSpacing, b.letterSpacing ?? a.letterSpacing, t),
      wordSpacing: ui.lerpDouble(a.wordSpacing ?? b.wordSpacing, b.wordSpacing ?? a.wordSpacing, t),
      textBaseline: t < 0.5 ? a.textBaseline : b.textBaseline,
      height: ui.lerpDouble(a.height ?? b.height, b.height ?? a.height, t),
      locale: t < 0.5 ? a.locale : b.locale,
      decoration: t < 0.5 ? a.decoration : b.decoration,
      decorationColor: Color.lerp(a.decorationColor, b.decorationColor, t),
      decorationStyle: t < 0.5 ? a.decorationStyle : b.decorationStyle,
      debugLabel: lerpDebugLabel,
    );
  }

  /// The style information for text runs, encoded for use by `dart:ui`.
  ui.TextStyle getTextStyle({ double textScaleFactor: 1.0 }) {
    return new ui.TextStyle(
      color: color,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      textBaseline: textBaseline,
      fontFamily: fontFamily,
      fontSize: fontSize == null ? null : fontSize * textScaleFactor,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      locale: locale,
    );
  }

  /// The style information for paragraphs, encoded for use by `dart:ui`.
  ///
  /// The `textScaleFactor` argument must not be null. If omitted, it defaults
  /// to 1.0. The other arguments may be null. The `maxLines` argument, if
  /// specified and non-null, must be greater than zero.
  ///
  /// If the font size on this style isn't set, it will default to 14 logical
  /// pixels.
  ui.ParagraphStyle getParagraphStyle({
      TextAlign textAlign,
      TextDirection textDirection,
      double textScaleFactor: 1.0,
      String ellipsis,
      int maxLines,
      ui.Locale locale,
  }) {
    assert(textScaleFactor != null);
    assert(maxLines == null || maxLines > 0);
    return new ui.ParagraphStyle(
      textAlign: textAlign,
      textDirection: textDirection,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontFamily: fontFamily,
      fontSize: (fontSize ?? _defaultFontSize) * textScaleFactor,
      lineHeight: height,
      maxLines: maxLines,
      ellipsis: ellipsis,
      locale: locale,
    );
  }

  /// Describe the difference between this style and another, in terms of how
  /// much damage it will make to the rendering.
  ///
  /// See also:
  ///
  ///  * [TextSpan.compareTo], which does the same thing for entire [TextSpan]s.
  RenderComparison compareTo(TextStyle other) {
    if (identical(this, other))
      return RenderComparison.identical;
    if (inherit != other.inherit ||
        fontFamily != other.fontFamily ||
        fontSize != other.fontSize ||
        fontWeight != other.fontWeight ||
        fontStyle != other.fontStyle ||
        letterSpacing != other.letterSpacing ||
        wordSpacing != other.wordSpacing ||
        textBaseline != other.textBaseline ||
        height != other.height ||
        locale != other.locale)
      return RenderComparison.layout;
    if (color != other.color ||
        decoration != other.decoration ||
        decorationColor != other.decorationColor ||
        decorationStyle != other.decorationStyle)
      return RenderComparison.paint;
    return RenderComparison.identical;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final TextStyle typedOther = other;
    return inherit == typedOther.inherit &&
           color == typedOther.color &&
           fontFamily == typedOther.fontFamily &&
           fontSize == typedOther.fontSize &&
           fontWeight == typedOther.fontWeight &&
           fontStyle == typedOther.fontStyle &&
           letterSpacing == typedOther.letterSpacing &&
           wordSpacing == typedOther.wordSpacing &&
           textBaseline == typedOther.textBaseline &&
           height == typedOther.height &&
           locale == typedOther.locale &&
           decoration == typedOther.decoration &&
           decorationColor == typedOther.decorationColor &&
           decorationStyle == typedOther.decorationStyle;
  }

  @override
  int get hashCode {
    return hashValues(
      inherit,
      color,
      fontFamily,
      fontSize,
      fontWeight,
      fontStyle,
      letterSpacing,
      wordSpacing,
      textBaseline,
      height,
      locale,
      decoration,
      decorationColor,
      decorationStyle
    );
  }

  @override
  String toStringShort() => '$runtimeType';

  /// Adds all properties prefixing property names with the optional `prefix`.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties, { String prefix: '' }) {
    super.debugFillProperties(properties);
    if (debugLabel != null)
      properties.add(new MessageProperty('${prefix}debugLabel', debugLabel));
    final List<DiagnosticsNode> styles = <DiagnosticsNode>[];
    styles.add(new DiagnosticsProperty<Color>('${prefix}color', color, defaultValue: null));
    styles.add(new StringProperty('${prefix}family', fontFamily, defaultValue: null, quoted: false));
    styles.add(new DoubleProperty('${prefix}size', fontSize, defaultValue: null));
    String weightDescription;
    if (fontWeight != null) {
      switch (fontWeight) {
        case FontWeight.w100:
          weightDescription = '100';
          break;
        case FontWeight.w200:
          weightDescription = '200';
          break;
        case FontWeight.w300:
          weightDescription = '300';
          break;
        case FontWeight.w400:
          weightDescription = '400';
          break;
        case FontWeight.w500:
          weightDescription = '500';
          break;
        case FontWeight.w600:
          weightDescription = '600';
          break;
        case FontWeight.w700:
          weightDescription = '700';
          break;
        case FontWeight.w800:
          weightDescription = '800';
          break;
        case FontWeight.w900:
          weightDescription = '900';
          break;
      }
    }
    // TODO(jacobr): switch this to use enumProperty which will either cause the
    // weight description to change to w600 from 600 or require existing
    // enumProperty to handle this special case.
    styles.add(new DiagnosticsProperty<FontWeight>(
      '${prefix}weight',
      fontWeight,
      description: weightDescription,
      defaultValue: null,
    ));
    styles.add(new EnumProperty<FontStyle>('${prefix}style', fontStyle, defaultValue: null));
    styles.add(new DoubleProperty('${prefix}letterSpacing', letterSpacing, defaultValue: null));
    styles.add(new DoubleProperty('${prefix}wordSpacing', wordSpacing, defaultValue: null));
    styles.add(new EnumProperty<TextBaseline>('${prefix}baseline', textBaseline, defaultValue: null));
    styles.add(new DoubleProperty('${prefix}height', height, unit: 'x', defaultValue: null));
    styles.add(new StringProperty('${prefix}locale', locale?.toString(), defaultValue: null, quoted: false));
    if (decoration != null || decorationColor != null || decorationStyle != null) {
      final List<String> decorationDescription = <String>[];
      if (decorationStyle != null)
        decorationDescription.add(describeEnum(decorationStyle));

      // Hide decorationColor from the default text view as it is shown in the
      // terse decoration summary as well.
      styles.add(new DiagnosticsProperty<Color>('${prefix}decorationColor', decorationColor, defaultValue: null, level: DiagnosticLevel.fine));

      if (decorationColor != null)
        decorationDescription.add('$decorationColor');

      // Intentionally collide with the property 'decoration' added below.
      // Tools that show hidden properties could choose the first property
      // matching the name to disambiguate.
      styles.add(new DiagnosticsProperty<TextDecoration>('${prefix}decoration', decoration, defaultValue: null, level: DiagnosticLevel.hidden));
      if (decoration != null)
        decorationDescription.add('$decoration');
      assert(decorationDescription.isNotEmpty);
      styles.add(new MessageProperty('${prefix}decoration', decorationDescription.join(' ')));
    }

    final bool styleSpecified = styles.any((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info));
    properties.add(new DiagnosticsProperty<bool>('${prefix}inherit', inherit, level: (!styleSpecified && inherit) ? DiagnosticLevel.fine : DiagnosticLevel.info));
    styles.forEach(properties.add);

    if (!styleSpecified)
      properties.add(new FlagProperty('inherit', value: inherit, ifTrue: '$prefix<all styles inherited>', ifFalse: '$prefix<no style specified>'));
  }
}
