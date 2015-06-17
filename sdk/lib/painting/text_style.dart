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

class TextStyle {
  const TextStyle({
    this.color,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.textAlign
  });

  final Color color;
  final String fontFamily;
  final double fontSize; // in pixels
  final FontWeight fontWeight;
  final TextAlign textAlign;

  TextStyle copyWith({
    Color color,
    double fontSize,
    FontWeight fontWeight,
    TextAlign textAlign
  }) {
    return new TextStyle(
      color: color != null ? color : this.color,
      fontFamily: fontFamily != null ? fontFamily : this.fontFamily,
      fontSize: fontSize != null ? fontSize : this.fontSize,
      fontWeight: fontWeight != null ? fontWeight : this.fontWeight,
      textAlign: textAlign != null ? textAlign : this.textAlign
    );
  }

  bool operator ==(other) {
    return other is TextStyle &&
      color == other.color &&
      fontFamily == other.fontFamily && 
      fontSize == other.fontSize &&
      fontWeight == other.fontWeight &&
      textAlign == other.textAlign;
  }

  int get hashCode {
    // Use Quiver: https://github.com/domokit/mojo/issues/236
    int value = 373;
    value = 37 * value + color.hashCode;
    value = 37 * value + fontFamily.hashCode;
    value = 37 * value + fontSize.hashCode;
    value = 37 * value + fontWeight.hashCode;
    value = 37 * value + textAlign.hashCode;
    return value;
  }

  void applyToCSSStyle(CSSStyleDeclaration cssStyle) {
    if (color != null) {
      cssStyle['color'] = 'rgba(${color.red}, ${color.green}, ${color.blue}, ${color.alpha / 255.0})';
    }
    // TODO(hansmuller): escape the fontFamily string.
    if (fontFamily != null) {
      cssStyle['font-family'] = fontFamily;
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
    if (result.isEmpty)
      return '${prefix}<no style specified>';
    return result.join('\n');
  }
}
