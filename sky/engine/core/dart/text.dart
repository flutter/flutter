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
class FontWeight {
  const FontWeight._(this.index);

  final int index;

  /// Thin, the least thick
  static const w100 = const FontWeight._(0);

  /// Extra-light
  static const w200 = const FontWeight._(1);

  /// Light
  static const w300 = const FontWeight._(2);

  /// Normal / regular / plain
  static const w400 = const FontWeight._(3);

  /// Medium
  static const w500 = const FontWeight._(4);

  /// Semi-bold
  static const w600 = const FontWeight._(5);

  /// Bold
  static const w700 = const FontWeight._(6);

  /// Extra-bold
  static const w800 = const FontWeight._(7);

  /// Black, the most thick
  static const w900 = const FontWeight._(8);

  static const normal = w400;
  static const bold = w700;

  static const List<FontWeight> values = const [
    w100, w200, w300, w400, w500, w600, w700, w800, w900
  ];

  String toString() {
    return const {
      0: FontWeight.w100,
      1: FontWeight.w200,
      2: FontWeight.w300,
      3: FontWeight.w400,
      4: FontWeight.w500,
      5: FontWeight.w600,
      6: FontWeight.w700,
      7: FontWeight.w800,
      8: FontWeight.w900,
    }[index];
  }
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
class TextDecoration {
  const TextDecoration._(this._mask);

  /// Constructs a decoration that paints the union of all the given decorations.
  factory TextDecoration.combine(List<TextDecoration> decorations) {
    int mask = 0;
    for (TextDecoration decoration in decorations)
      mask |= decoration._mask;
    return new TextDecoration._(mask);
  }

  final int _mask;

  /// Whether this decoration will paint at least as much decoration as the given decoration.
  bool contains(TextDecoration other) {
    return (_mask | other._mask) == _mask;
  }

  /// Do not draw a decoration
  static const TextDecoration none = const TextDecoration._(0x0);

  /// Draw a line underneath each line of text
  static const TextDecoration underline = const TextDecoration._(0x1);

  /// Draw a line above each line of text
  static const TextDecoration overline = const TextDecoration._(0x2);

  /// Draw a line through each line of text
  static const TextDecoration lineThrough = const TextDecoration._(0x4);

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! TextDecoration)
      return false;
    final TextDecoration typedOther = other;
    return _mask == typedOther._mask;
  }

  int get hashCode => _mask.hashCode;

  String toString() {
    if (_mask == 0)
      return 'TextDecoration.none';
    List<String> values = <String>[];
    if (_mask & underline._mask != 0)
      values.add('underline');
    if (_mask & overline._mask != 0)
      values.add('overline');
    if (_mask & lineThrough._mask != 0)
      values.add('lineThrough');
    if (values.length == 1)
      return 'TextDecoration.${values[0]}';
    return 'TextDecoration.combine([${values.join(", ")}])';
  }
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
//    has a non-null value. Bits 7 to 11 indicate whether |fontFamily|,
//    |fontSize|, |letterSpacing|, |wordSpacing|, and |lineHeight| are non-null,
//    respectively. Bit 0 is unused.
//
//  - Element 1: The |color| in ARGB with 8 bits per channel.
//
//  - Element 2: A bit field indicating which text decorations are present in
//    the |textDecoration| list. The ith bit is set if there's a TextDecoration
//    with enum index i in the list.
//
//  - Element 3: The |decorationColor| in ARGB with 8 bits per channel.
//
//  - Element 4: The bit field of the |decorationStyle|.
//
//  - Element 5: The index of the |fontWeight|.
//
//  - Element 6: The enum index of the |fontStyle|.
//
Int32List _encodeTextStyle(Color color,
                           TextDecoration decoration,
                           Color decorationColor,
                           TextDecorationStyle decorationStyle,
                           FontWeight fontWeight,
                           FontStyle fontStyle,
                           String fontFamily,
                           double fontSize,
                           double letterSpacing,
                           double wordSpacing,
                           double lineHeight) {
  Int32List result = new Int32List(7);
  if (color != null) {
    result[0] |= 1 << 1;
    result[1] = color.value;
  }
  if (decoration != null) {
    result[0] |= 1 << 2;
    result[2] = decoration._mask;
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
  if (letterSpacing != null) {
    result[0] |= 1 << 9;
    // Passed separately to native.
  }
  if (wordSpacing != null) {
    result[0] |= 1 << 10;
    // Passed separately to native.
  }
  if (lineHeight != null) {
    result[0] |= 1 << 11;
    // Passed separately to native.
  }
  return result;
}

class TextStyle {
  TextStyle({
    Color color,
    TextDecoration decoration,
    Color decorationColor,
    TextDecorationStyle decorationStyle,
    FontWeight fontWeight,
    FontStyle fontStyle,
    String fontFamily,
    double fontSize,
    double letterSpacing,
    double wordSpacing,
    double lineHeight
  }) : _encoded = _encodeTextStyle(color,
                                   decoration,
                                   decorationColor,
                                   decorationStyle,
                                   fontWeight,
                                   fontStyle,
                                   fontFamily,
                                   fontSize,
                                   letterSpacing,
                                   wordSpacing,
                                   lineHeight),
       _fontFamily = fontFamily ?? '',
       _fontSize = fontSize,
       _letterSpacing = letterSpacing,
       _wordSpacing = wordSpacing,
       _lineHeight = lineHeight;

  final Int32List _encoded;
  final String _fontFamily;
  final double _fontSize;
  final double _letterSpacing;
  final double _wordSpacing;
  final double _lineHeight;

  String toString() {
    return 'TextStyle(${_encoded[0]}|'
             'color: ${          _encoded[0] & 0x001 == 0x001 ? new Color(_encoded[1])                  : "unspecified"}, '
             'decoration: ${     _encoded[0] & 0x002 == 0x002 ? new TextDecoration._(_encoded[2])       : "unspecified"}, '
             'decorationColor: ${_encoded[0] & 0x004 == 0x004 ? new Color(_encoded[3])                  : "unspecified"}, '
             'decorationStyle: ${_encoded[0] & 0x008 == 0x008 ? TextDecorationStyle.values[_encoded[4]] : "unspecified"}, '
             'fontWeight: ${     _encoded[0] & 0x010 == 0x010 ? FontWeight.values[_encoded[5]]          : "unspecified"}, '
             'fontStyle: ${      _encoded[0] & 0x020 == 0x020 ? FontStyle.values[_encoded[6]]           : "unspecified"}, '
             'fontFamily: ${     _encoded[0] & 0x040 == 0x040 ? _fontFamily                             : "unspecified"}, '
             'fontSize: ${       _encoded[0] & 0x080 == 0x080 ? _fontSize                               : "unspecified"}, '
             'letterSpacing: ${  _encoded[0] & 0x100 == 0x100 ? "${_letterSpacing}x"                    : "unspecified"}, '
             'wordSpacing: ${    _encoded[0] & 0x200 == 0x200 ? "${_wordSpacing}x"                      : "unspecified"}, '
             'lineHeight: ${     _encoded[0] & 0x400 == 0x400 ? "${_lineHeight}x"                       : "unspecified"}'
           ')';
  }
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

  String toString() {
    return 'ParagraphStyle('
             'textAlign: ${   _encoded[0] & 0x1 == 0x1 ? TextAlign.values[_encoded[1]]    : "unspecified"}, '
             'textBaseline: ${_encoded[0] & 0x2 == 0x2 ? TextBaseline.values[_encoded[2]] : "unspecified"}, '
             'lineHeight: ${  _encoded[0] & 0x3 == 0x3 ? "${_lineHeight}x"                : "unspecified"}'
           ')';
  }
}

abstract class Paragraph extends NativeFieldWrapperClass2 {
  double get minWidth native "Paragraph_minWidth";
  void set minWidth(double value) native "Paragraph_setMinWidth";
  double get maxWidth native "Paragraph_maxWidth";
  void set maxWidth(double value) native "Paragraph_setMaxWidth";
  double get minHeight native "Paragraph_minHeight";
  void set minHeight(double value) native "Paragraph_setMinHeight";
  double get maxHeight native "Paragraph_maxHeight";
  void set maxHeight(double value) native "Paragraph_setMaxHeight";
  double get width native "Paragraph_width";
  double get height native "Paragraph_height";
  double get minIntrinsicWidth native "Paragraph_minIntrinsicWidth";
  double get maxIntrinsicWidth native "Paragraph_maxIntrinsicWidth";
  double get alphabeticBaseline native "Paragraph_alphabeticBaseline";
  double get ideographicBaseline native "Paragraph_ideographicBaseline";

  void layout() native "Paragraph_layout";
  void paint(Canvas canvas, Offset offset) native "Paragraph_paint";
}

class ParagraphBuilder extends NativeFieldWrapperClass2 {
  void _constructor() native "ParagraphBuilder_constructor";
  ParagraphBuilder() { _constructor(); }

  void _pushStyle(Int32List encoded, String fontFamily, double fontSize, double letterSpacing, double wordSpacing, double lineHeight) native "ParagraphBuilder_pushStyle";
  void pushStyle(TextStyle style) => _pushStyle(style._encoded, style._fontFamily, style._fontSize, style._letterSpacing, style._wordSpacing, style._lineHeight);

  void pop() native "ParagraphBuilder_pop";

  void addText(String text) native "ParagraphBuilder_addText";

  Paragraph _build(Int32List encoded, double lineHeight) native "ParagraphBuilder_build";
  Paragraph build(ParagraphStyle style) => _build(style._encoded, style._lineHeight);
}

