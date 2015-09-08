// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

/// The thickness of the glyphs used to draw the text
enum FontWeight {
  /// Thin, the least thick
  w100,

  /// Extra-light
  w200,

  /// Light
  w300,

  /// Normal / regular / plain
  w400,

  /// Medium
  w500,

  /// Semi-bold
  w600,

  /// Bold
  w700,

  /// Extra-bold
  w800,

  /// Black, the most thick
  w900
}

/// A normal font weight
const normal = FontWeight.w400;

/// A bold font weight
const bold = FontWeight.w700;

/// Whether to slant the glyphs in the font
enum FontStyle {
  /// Use the upright glyphs
  normal,

  /// Use glyphs designed for slanting
  italic,

  /// Use the upright glyphs but slant them during painting
  oblique  // TODO(abarth): Remove. We don't really support this value.
}

/// Whether to align text horizontally
enum TextAlign {
  /// Align the text on the left edge of the container
  left,

  /// Align the text on the right edge of the container
  right,

  /// Align the text in the center of the container
  center
}

/// A horizontal line used for aligning text
enum TextBaseline {
  // The horizontal line used to align the bottom of glyphs for alphabetic characters
  alphabetic,

  // The horizontal line used to align ideographic characters
  ideographic
}

/// A linear decoration to draw near the text
enum TextDecoration {
  /// Do not draw a decoration
  none,

  /// Draw a line underneath each line of text
  underline,

  /// Draw a line above each line of text
  overline,

  /// Draw a line through each line of text
  lineThrough
}

/// Draw a line underneath each line of text
const underline = const <TextDecoration>[TextDecoration.underline];

/// Draw a line above each line of text
const overline = const <TextDecoration>[TextDecoration.overline];

/// Draw a line through each line of text
const lineThrough = const <TextDecoration>[TextDecoration.lineThrough];

/// The style in which to draw a text decoration
enum TextDecorationStyle {
  /// Draw a solid line
  solid,

  /// Draw two lines
  double,

  /// Draw a dotted line
  dotted,

  /// Draw a dashed line
  dashed,

  /// Draw a sinusoidal line
  wavy
}

/// An immutable style in which paint text
class TextStyle {
  const TextStyle({
    this.color,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.textAlign,
    this.textBaseline,
    this.height,
    this.decoration,
    this.decorationColor,
    this.decorationStyle
  });

  /// The color to use when painting the text
  final Color color;

  /// The name of the font to use when painting the text
  final String fontFamily;

  /// The size of gyphs (in logical pixels) to use when painting the text
  final double fontSize;

  /// The font weight to use when painting the text
  final FontWeight fontWeight;

  /// The font style to use when painting the text
  final FontStyle fontStyle;

  /// How the text should be aligned (applies only to the outermost
  /// StyledTextSpan, which establishes the container for the text)
  final TextAlign textAlign;

  /// The baseline to use for aligning the text
  final TextBaseline textBaseline;

  /// The distance between the text baselines, as a multiple of the font size
  final double height;

  /// A list of decorations to paint near the text
  final List<TextDecoration> decoration; // TODO(ianh): Switch this to a Set<> once Dart supports constant Sets

  /// The color in which to paint the text decorations
  final Color decorationColor;

  /// The style in which to paint the text decorations
  final TextDecorationStyle decorationStyle;

  /// Returns a new text style that matches this text style but with the given
  /// values replaced
  TextStyle copyWith({
    Color color,
    String fontFamily,
    double fontSize,
    FontWeight fontWeight,
    FontStyle fontStyle,
    TextAlign textAlign,
    TextBaseline textBaseline,
    double height,
    List<TextDecoration> decoration,
    Color decorationColor,
    TextDecorationStyle decorationStyle
  }) {
    return new TextStyle(
      color: color != null ? color : this.color,
      fontFamily: fontFamily != null ? fontFamily : this.fontFamily,
      fontSize: fontSize != null ? fontSize : this.fontSize,
      fontWeight: fontWeight != null ? fontWeight : this.fontWeight,
      fontStyle: fontStyle != null ? fontStyle : this.fontStyle,
      textAlign: textAlign != null ? textAlign : this.textAlign,
      textBaseline: textBaseline != null ? textBaseline : this.textBaseline,
      height: height != null ? height : this.height,
      decoration: decoration != null ? decoration : this.decoration,
      decorationColor: decorationColor != null ? decorationColor : this.decorationColor,
      decorationStyle: decorationStyle != null ? decorationStyle : this.decorationStyle
    );
  }

  /// Returns a new text style that matches this text style but with some values
  /// replaced by the non-null parameters of the given text style
  TextStyle merge(TextStyle other) {
    return copyWith(
      color: other.color,
      fontFamily: other.fontFamily,
      fontSize: other.fontSize,
      fontWeight: other.fontWeight,
      fontStyle: other.fontStyle,
      textAlign: other.textAlign,
      textBaseline: other.textBaseline,
      height: other.height,
      decoration: other.decoration,
      decorationColor: other.decorationColor,
      decorationStyle: other.decorationStyle
    );
  }

  static String _colorToCSSString(Color color) {
    return 'rgba(${color.red}, ${color.green}, ${color.blue}, ${color.alpha / 255.0})';
  }

  static String _fontFamilyToCSSString(String fontFamily) {
    // TODO(hansmuller): escape the fontFamily string.
    return fontFamily;
  }

  static String _decorationToCSSString(List<TextDecoration> decoration) {
    assert(decoration != null);
    const toCSS = const <TextDecoration, String>{
      TextDecoration.none: 'none',
      TextDecoration.underline: 'underline',
      TextDecoration.overline: 'overline',
      TextDecoration.lineThrough: 'lineThrough'
    };
    return decoration.map((d) => toCSS[d]).join(' ');
  }

  static String _decorationStyleToCSSString(TextDecorationStyle decorationStyle) {
    assert(decorationStyle != null);
    const toCSS = const <TextDecorationStyle, String>{
      TextDecorationStyle.solid: 'solid',
      TextDecorationStyle.double: 'double',
      TextDecorationStyle.dotted: 'dotted',
      TextDecorationStyle.dashed: 'dashed',
      TextDecorationStyle.wavy: 'wavy'
    };
    return toCSS[decorationStyle];
  }

  /// Program this text style into the engine
  ///
  /// Note: This function will likely be removed when we refactor the interface
  /// between the framework and the engine
  void applyToCSSStyle(CSSStyleDeclaration cssStyle) {
    if (color != null) {
      cssStyle['color'] = _colorToCSSString(color);
    }
    if (fontFamily != null) {
      cssStyle['font-family'] = _fontFamilyToCSSString(fontFamily);
    }
    if (fontSize != null) {
      cssStyle['font-size'] = '${fontSize}px';
    }
    if (fontWeight != null) {
      cssStyle['font-weight'] = const {
        FontWeight.w100: '100',
        FontWeight.w200: '200',
        FontWeight.w300: '300',
        FontWeight.w400: '400',
        FontWeight.w500: '500',
        FontWeight.w600: '600',
        FontWeight.w700: '700',
        FontWeight.w800: '800',
        FontWeight.w900: '900'
      }[fontWeight];
    }
    if (fontStyle != null) {
      cssStyle['font-style'] = const {
        FontStyle.normal: 'normal',
        FontStyle.italic: 'italic',
        FontStyle.oblique: 'oblique',
      }[fontStyle];
    }
    if (decoration != null) {
      cssStyle['text-decoration'] = _decorationToCSSString(decoration);
      if (decorationColor != null)
        cssStyle['text-decoration-color'] = _colorToCSSString(decorationColor);
      if (decorationStyle != null)
        cssStyle['text-decoration-style'] = _decorationStyleToCSSString(decorationStyle);
    }
  }

  /// Program the container aspects of this text style into the engine
  ///
  /// Note: This function will likely be removed when we refactor the interface
  /// between the framework and the engine
  void applyToContainerCSSStyle(CSSStyleDeclaration cssStyle) {
    if (textAlign != null) {
      cssStyle['text-align'] = const {
        TextAlign.left: 'left',
        TextAlign.right: 'right',
        TextAlign.center: 'center',
      }[textAlign];
    }
    if (height != null) {
      cssStyle['line-height'] = '${height}';
    }
  }

  bool operator ==(other) {
    if (identical(this, other))
      return true;
    return other is TextStyle &&
      color == other.color &&
      fontFamily == other.fontFamily &&
      fontSize == other.fontSize &&
      fontWeight == other.fontWeight &&
      fontStyle == other.fontStyle &&
      textAlign == other.textAlign &&
      textBaseline == other.textBaseline &&
      decoration == other.decoration &&
      decorationColor == other.decorationColor &&
      decorationStyle == other.decorationStyle;
  }

  int get hashCode {
    // Use Quiver: https://github.com/domokit/mojo/issues/236
    int value = 373;
    value = 37 * value + color.hashCode;
    value = 37 * value + fontFamily.hashCode;
    value = 37 * value + fontSize.hashCode;
    value = 37 * value + fontWeight.hashCode;
    value = 37 * value + fontStyle.hashCode;
    value = 37 * value + textAlign.hashCode;
    value = 37 * value + textBaseline.hashCode;
    value = 37 * value + decoration.hashCode;
    value = 37 * value + decorationColor.hashCode;
    value = 37 * value + decorationStyle.hashCode;
    return value;
  }

  String toString([String prefix = '']) {
    List<String> result = [];
    if (color != null)
      result.add('${prefix}color: $color');
    // TODO(hansmuller): escape the fontFamily string.
    if (fontFamily != null)
      result.add('${prefix}fontFamily: "${fontFamily}"');
    if (fontSize != null)
      result.add('${prefix}fontSize: $fontSize');
    if (fontWeight != null)
      result.add('${prefix}fontWeight: $fontWeight');
    if (fontStyle != null)
      result.add('${prefix}fontStyle: $fontStyle');
    if (textAlign != null)
      result.add('${prefix}textAlign: $textAlign');
    if (textBaseline != null)
      result.add('${prefix}textBaseline: $textBaseline');
    if (decoration != null)
      result.add('${prefix}decoration: $decoration');
    if (decorationColor != null)
      result.add('${prefix}decorationColor: $decorationColor');
    if (decorationStyle != null)
      result.add('${prefix}decorationStyle: $decorationStyle');
    if (result.isEmpty)
      return '${prefix}<no style specified>';
    return result.join('\n');
  }
}
