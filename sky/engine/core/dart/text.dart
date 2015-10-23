// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// Whether to slant the glyphs in the font
enum FontStyle {
  /// Use the upright glyphs
  normal,

  /// Use glyphs designed for slanting
  italic,
}

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

// This encoding must match the C++ version of ParagraphBuilder::pushStyle.
//
// The encoded array buffer has 7 elements.
//
//  - Element 0: A bit field where the ith bit indicates wheter the ith element
//    has a non-null value. Bits 7 and 8 indicate whether |fontFamily| and
//    |fontSize| are non-null, respectively. Bit 0 is unused.
//
//  - Element 1: The |color| in ARGB with 8 bits per channel.
//
//  - Element 2: A bit field indicating which text decorations are present in
//    the |textDecoration| list. The ith bit is set if there's a TextDecoration
//    with enum index i in the list.
//
//  - Element 3: The |decorationColor| in ARGB with 8 bits per channel.
//
//  - Element 4: The enum index of the |decorationStyle|.
//
//  - Element 5: The enum index of the |fontWeight|.
//
//  - Element 6: The enum index of the |fontStyle|.
//
Int32List _encodeTextStyle(Color color,
                           List<TextDecoration> decoration,
                           Color decorationColor,
                           TextDecorationStyle decorationStyle,
                           FontWeight fontWeight,
                           FontStyle fontStyle,
                           String fontFamily,
                           double fontSize) {
  Int32List result = new Int32List(7);
  if (color != null) {
    result[0] |= 1 << 1;
    result[1] = color.value;
  }
  if (decoration != null) {
    result[0] |= 1 << 2;
    for (TextDecoration value in decoration) {
      int shift = value.index - 1;
      if (shift != 0)
        result[2] |= 1 << shift;
    }
  }
  if (decorationColor != null) {
    result[0] |= 1 << 3;
    result[3] = decorationColor.value;
  }
  if (decorationStyle != null) {
    result[0] |= 1 << 4;
    result[4] = decorationStyle.index;
  }
  if (fontWeight != null) {
    result[0] |= 1 << 5;
    result[5] = fontWeight.index;
  }
  if (fontStyle != null) {
    result[0] |= 1 << 6;
    result[6] = fontStyle.index;
  }
  if (fontFamily != null) {
    result[0] |= 1 << 7;
    // Passed separately to native.
  }
  if (fontSize != null) {
    result[0] |= 1 << 8;
    // Passed separately to native.
  }
  return result;
}

class TextStyle {
  TextStyle({
    Color color,
    List<TextDecoration> decoration,
    Color decorationColor,
    TextDecorationStyle decorationStyle,
    FontWeight fontWeight,
    FontStyle fontStyle,
    String fontFamily,
    double fontSize
  }) : _encoded = _encodeTextStyle(color,
                                   decoration,
                                   decorationColor,
                                   decorationStyle,
                                   fontWeight,
                                   fontStyle,
                                   fontFamily,
                                   fontSize),
       _fontFamily = fontFamily ?? '',
       _fontSize = fontSize;

  final Int32List _encoded;
  final String _fontFamily;
  final double _fontSize;
}

// This encoding must match the C++ version ParagraphBuilder::build.
//
// The encoded array buffer has 3 elements.
//
//  - Element 0: A bit field where the ith bit indicates wheter the ith element
//    has a non-null value. Bit 3 indicates whether |lineHeight| is non-null.
//    Bit 0 is unused.
//
//  - Element 1: The enum index of the |textAlign|.
//
//  - Element 2: The enum index of the |textBaseline|.
//
Int32List _encodeParagraphStyle(TextAlign textAlign,
                                TextBaseline textBaseline,
                                double lineHeight) {
  Int32List result = new Int32List(3);
  if (textAlign != null) {
    result[0] |= 1 << 1;
    result[1] = textAlign.index;
  }
  if (textBaseline != null) {
    result[0] |= 1 << 2;
    result[2] = textBaseline.index;
  }
  if (lineHeight != null) {
    result[0] |= 1 << 3;
    // Passed separately to native.
  }
  return result;
}

class ParagraphStyle {
  ParagraphStyle({
    TextAlign textAlign,
    TextBaseline textBaseline,
    double lineHeight
  }) : _encoded = _encodeParagraphStyle(textAlign, textBaseline, lineHeight),
       _lineHeight = lineHeight;

  final Int32List _encoded;
  final double _lineHeight;
}

class ParagraphBuilder extends _ParagraphBuilder {
  void pushStyle(TextStyle style) {
    _pushStyle(style._encoded, style._fontFamily, style._fontSize);
  }

  void pop() => _pop();
  void addText(String text) => _addText(text);

  Paragraph build(ParagraphStyle style) {
    Paragraph result = _build(style._encoded, style._lineHeight);
    return result;
  }
}
