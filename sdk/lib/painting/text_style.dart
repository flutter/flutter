// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

enum FontWeight {
  w100,
  w200,
  w300,
  w400,
  w500,
  w600,
  w700,
  w800,
  w900
}

const thin = FontWeight.w100;
const extraLight = FontWeight.w200;
const light = FontWeight.w300;
const normal = FontWeight.w400;
const medium = FontWeight.w500;
const semiBold = FontWeight.w600;
const bold = FontWeight.w700;
const extraBold = FontWeight.w800;
const black = FontWeight.w900;

enum TextAlign {
  left,
  right,
  center
}

enum TextDecoration {
  none,
  underline,
  overline,
  lineThrough
}

const underline = const <TextDecoration>[TextDecoration.underline];
const overline = const <TextDecoration>[TextDecoration.overline];
const lineThrough = const <TextDecoration>[TextDecoration.lineThrough];

enum TextDecorationStyle {
  solid,
  double,
  dotted,
  dashed,
  wavy
}

class TextStyle {
  const TextStyle({
    this.color,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.decoration,
    this.decorationColor,
    this.decorationStyle
  });

  final Color color;
  final String fontFamily;
  final double fontSize; // in pixels
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final List<TextDecoration> decoration; // TODO(ianh): Switch this to a Set<> once Dart supports constant Sets
  final Color decorationColor;
  final TextDecorationStyle decorationStyle;

  TextStyle copyWith({
    Color color,
    double fontSize,
    FontWeight fontWeight,
    TextAlign textAlign,
    TextDecoration decoration,
    Color decorationColor,
    TextDecorationStyle decorationStyle
  }) {
    return new TextStyle(
      color: color != null ? color : this.color,
      fontFamily: fontFamily != null ? fontFamily : this.fontFamily,
      fontSize: fontSize != null ? fontSize : this.fontSize,
      fontWeight: fontWeight != null ? fontWeight : this.fontWeight,
      textAlign: textAlign != null ? textAlign : this.textAlign,
      decoration: decoration != null ? decoration : this.decoration,
      decorationColor: decorationColor != null ? decorationColor : this.decorationColor,
      decorationStyle: decorationStyle != null ? decorationStyle : this.decorationStyle
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

  void applyToCSSStyle(CSSStyleDeclaration cssStyle) {
    if (color != null) {
      cssStyle['color'] = _colorToCSSString(color);
    }
    if (fontFamily != null) {
      cssStyle['font-family'] = _fontFamilyToCSSString(fontFamily);
    }
    if (fontSize != null) {
      cssStyle['font-size'] = "${fontSize}px";
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
    if (textAlign != null) {
      cssStyle['text-align'] = const {
        TextAlign.left: 'left',
        TextAlign.right: 'right',
        TextAlign.center: 'center',
      }[textAlign];
    }
    if (decoration != null) {
      cssStyle['text-decoration'] = _decorationToCSSString(decoration);
      if (decorationColor != null)
        cssStyle['text-decoration-color'] = _colorToCSSString(decorationColor);
      if (decorationStyle != null)
        cssStyle['text-decoration-style'] = _decorationStyleToCSSString(decorationStyle);
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
      textAlign == other.textAlign && 
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
    value = 37 * value + textAlign.hashCode;
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
    if (textAlign != null)
      result.add('${prefix}textAlign: $textAlign');
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
