// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show ParagraphStyle, TextStyle, lerpDouble;

import 'basic_types.dart';

/// An immutable style in which paint text.
class TextStyle {
  /// Creates a text style.
  const TextStyle({
    this.inherit: true,
    this.color,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.wordSpacing,
    this.textBaseline,
    this.height,
    this.decoration,
    this.decorationColor,
    this.decorationStyle
  });

  /// Whether null values are replaced with their value in an ancestor text style (e.g., in a [TextSpan] tree).
  final bool inherit;

  /// The color to use when painting the text.
  final Color color;

  /// The name of the font to use when painting the text (e.g., Roboto).
  final String fontFamily;

  /// The size of gyphs (in logical pixels) to use when painting the text.
  final double fontSize;

  /// The typeface thickness to use when painting the text (e.g., bold).
  final FontWeight fontWeight;

  /// The typeface variant to use when drawing the letters (e.g., italics).
  final FontStyle fontStyle;

  /// The amount of space (in logical pixels) to add between each letter.
  final double letterSpacing;

  /// The amount of space (in logical pixels) to add at each sequence of white-space (i.e. between each word).
  final double wordSpacing;

  /// The baseline to use for aligning the text.
  final TextBaseline textBaseline;

  /// The height of this text span, as a multiple of the font size.
  ///
  /// If applied to the root [TextSpan], this value sets the line height, which
  /// is the minimum distance between subsequent text baselines, as multiple of
  /// the font size.
  final double height;

  /// The decorations to paint near the text (e.g., an underline).
  final TextDecoration decoration;

  /// The color in which to paint the text decorations.
  final Color decorationColor;

  /// The style in which to paint the text decorations (e.g., dashed).
  final TextDecorationStyle decorationStyle;

  /// Creates a copy of this text style but with the given fields replaced with the new values.
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
    TextDecoration decoration,
    Color decorationColor,
    TextDecorationStyle decorationStyle
  }) {
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
      decoration: decoration ?? this.decoration,
      decorationColor: decorationColor ?? this.decorationColor,
      decorationStyle: decorationStyle ?? this.decorationStyle
    );
  }

  /// Returns a new text style that matches this text style but with some values
  /// replaced by the non-null parameters of the given text style. If the given
  /// text style is null, simply returns this text style.
  TextStyle merge(TextStyle other) {
    if (other == null)
      return this;
    assert(other.inherit);
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
      decoration: other.decoration,
      decorationColor: other.decorationColor,
      decorationStyle: other.decorationStyle
    );
  }

  /// Interpolate between two text styles.
  ///
  /// This will not work well if the styles don't set the same fields.
  static TextStyle lerp(TextStyle begin, TextStyle end, double t) {
    assert(begin.inherit == end.inherit);
    return new TextStyle(
      inherit: end.inherit,
      color: Color.lerp(begin.color, end.color, t),
      fontFamily: t < 0.5 ? begin.fontFamily : end.fontFamily,
      fontSize: ui.lerpDouble(begin.fontSize ?? end.fontSize, end.fontSize ?? begin.fontSize, t),
      // TODO(ianh): Replace next line with "fontWeight: FontWeight.lerp(begin.fontWeight, end.fontWeight, t)," once engine is revved
      fontWeight: FontWeight.values[ui.lerpDouble(begin?.fontWeight?.index ?? FontWeight.normal.index, end?.fontWeight?.index ?? FontWeight.normal.index, t.clamp(0.0, 1.0)).round()],
      fontStyle: t < 0.5 ? begin.fontStyle : end.fontStyle,
      letterSpacing: ui.lerpDouble(begin.letterSpacing ?? end.letterSpacing, end.letterSpacing ?? begin.letterSpacing, t),
      wordSpacing: ui.lerpDouble(begin.wordSpacing ?? end.wordSpacing, end.wordSpacing ?? begin.wordSpacing, t),
      textBaseline: t < 0.5 ? begin.textBaseline : end.textBaseline,
      height: ui.lerpDouble(begin.height ?? end.height, end.height ?? begin.height, t),
      decoration: t < 0.5 ? begin.decoration : end.decoration,
      decorationColor: Color.lerp(begin.decorationColor, end.decorationColor, t),
      decorationStyle: t < 0.5 ? begin.decorationStyle : end.decorationStyle
    );
  }

  /// The style information for text runs, encoded for use by `dart:ui`.
  ui.TextStyle get textStyle {
    return new ui.TextStyle(
      color: color,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontFamily: fontFamily,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height
    );
  }

  /// The style information for paragraphs, encoded for use by `dart:ui`.
  ui.ParagraphStyle getParagraphStyle({ TextAlign textAlign }) {
    return new ui.ParagraphStyle(
      textAlign: textAlign,
      textBaseline: textBaseline,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontFamily: fontFamily,
      fontSize: fontSize,
      lineHeight: height
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! TextStyle)
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
      decoration,
      decorationColor,
      decorationStyle
    );
  }

  @override
  String toString([String prefix = '']) {
    List<String> result = <String>[];
    result.add('${prefix}inherit: $inherit');
    if (color != null)
      result.add('${prefix}color: $color');
    if (fontFamily != null)
      result.add('${prefix}family: "$fontFamily"');
    if (fontSize != null)
      result.add('${prefix}size: $fontSize');
    if (fontWeight != null) {
      switch (fontWeight) {
        case FontWeight.w100:
          result.add('${prefix}weight: 100');
          break;
        case FontWeight.w200:
          result.add('${prefix}weight: 200');
          break;
        case FontWeight.w300:
          result.add('${prefix}weight: 300');
          break;
        case FontWeight.w400:
          result.add('${prefix}weight: 400');
          break;
        case FontWeight.w500:
          result.add('${prefix}weight: 500');
          break;
        case FontWeight.w600:
          result.add('${prefix}weight: 600');
          break;
        case FontWeight.w700:
          result.add('${prefix}weight: 700');
          break;
        case FontWeight.w800:
          result.add('${prefix}weight: 800');
          break;
        case FontWeight.w900:
          result.add('${prefix}weight: 900');
          break;
      }
    }
    if (fontStyle != null) {
      switch (fontStyle) {
        case FontStyle.normal:
          result.add('${prefix}style: normal');
          break;
        case FontStyle.italic:
          result.add('${prefix}style: italic');
          break;
      }
    }
    if (letterSpacing != null)
      result.add('${prefix}letterSpacing: ${letterSpacing}x');
    if (wordSpacing != null)
      result.add('${prefix}wordSpacing: ${wordSpacing}x');
    if (textBaseline != null) {
      switch (textBaseline) {
        case TextBaseline.alphabetic:
          result.add('${prefix}baseline: alphabetic');
          break;
        case TextBaseline.ideographic:
          result.add('${prefix}baseline: ideographic');
          break;
      }
    }
    if (height != null)
      result.add('${prefix}height: ${height}x');
    if (decoration != null || decorationColor != null || decorationStyle != null) {
      String decorationDescription = '${prefix}decoration: ';
      bool haveDecorationDescription = false;
      if (decorationStyle != null) {
        switch (decorationStyle) {
          case TextDecorationStyle.solid:
            decorationDescription += 'solid';
            break;
          case TextDecorationStyle.double:
            decorationDescription += 'double';
            break;
          case TextDecorationStyle.dotted:
            decorationDescription += 'dotted';
            break;
          case TextDecorationStyle.dashed:
            decorationDescription += 'dashed';
            break;
          case TextDecorationStyle.wavy:
            decorationDescription += 'wavy';
            break;
        }
        haveDecorationDescription = true;
      }
      if (decorationColor != null) {
        if (haveDecorationDescription)
          decorationDescription += ' ';
        decorationDescription += '$decorationColor';
        haveDecorationDescription = true;
      }
      if (decoration != null) {
        if (haveDecorationDescription)
          decorationDescription += ' ';
        decorationDescription += '$decoration';
        haveDecorationDescription = true;
      }
      assert(haveDecorationDescription);
      result.add(decorationDescription);
    }
    if (result.isEmpty)
      return '$prefix<no style specified>';
    return result.join('\n');
  }
}
