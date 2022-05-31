// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

enum FontStyle {
  normal,
  italic,
}

enum PlaceholderAlignment {
  baseline,
  aboveBaseline,
  belowBaseline,
  top,
  bottom,
  middle,
}

class FontWeight {
  const FontWeight._(this.index);
  final int index;
  static const FontWeight w100 = FontWeight._(0);
  static const FontWeight w200 = FontWeight._(1);
  static const FontWeight w300 = FontWeight._(2);
  static const FontWeight w400 = FontWeight._(3);
  static const FontWeight w500 = FontWeight._(4);
  static const FontWeight w600 = FontWeight._(5);
  static const FontWeight w700 = FontWeight._(6);
  static const FontWeight w800 = FontWeight._(7);
  static const FontWeight w900 = FontWeight._(8);
  static const FontWeight normal = w400;
  static const FontWeight bold = w700;
  static const List<FontWeight> values = <FontWeight>[
    w100,
    w200,
    w300,
    w400,
    w500,
    w600,
    w700,
    w800,
    w900
  ];
  static FontWeight? lerp(FontWeight? a, FontWeight? b, double t) {
    assert(t != null); // ignore: unnecessary_null_comparison
    if (a == null && b == null) {
      return null;
    }
    return values[engine.clampInt(
      lerpDouble(a?.index ?? normal.index, b?.index ?? normal.index, t)!
          .round(),
      0,
      8,
    )];
  }

  @override
  String toString() {
    return const <int, String>{
      0: 'FontWeight.w100',
      1: 'FontWeight.w200',
      2: 'FontWeight.w300',
      3: 'FontWeight.w400',
      4: 'FontWeight.w500',
      5: 'FontWeight.w600',
      6: 'FontWeight.w700',
      7: 'FontWeight.w800',
      8: 'FontWeight.w900',
    }[index]!;
  }
}

class FontFeature {
  const FontFeature(this.feature, [this.value = 1])
      : assert(feature != null), // ignore: unnecessary_null_comparison
        assert(feature.length == 4,
            'Feature tag must be exactly four characters long.'),
        assert(value != null), // ignore: unnecessary_null_comparison
        assert(value >= 0, 'Feature value must be zero or a positive integer.');
  const FontFeature.enable(String feature) : this(feature, 1);
  const FontFeature.disable(String feature) : this(feature, 0);
  const FontFeature.alternative(this.value) : feature = 'aalt';
  const FontFeature.alternativeFractions()
      : feature = 'afrc',
        value = 1;
  const FontFeature.contextualAlternates()
      : feature = 'calt',
        value = 1;
  const FontFeature.caseSensitiveForms()
      : feature = 'case',
        value = 1;
  factory FontFeature.characterVariant(int value) {
    assert(value >= 1);
    assert(value <= 20);
    return FontFeature('cv${value.toString().padLeft(2, "0")}');
  }
  const FontFeature.denominator()
      : feature = 'dnom',
        value = 1;
  const FontFeature.fractions()
      : feature = 'frac',
        value = 1;
  const FontFeature.historicalForms()
      : feature = 'hist',
        value = 1;
  const FontFeature.historicalLigatures()
      : feature = 'hlig',
        value = 1;
  const FontFeature.liningFigures()
      : feature = 'lnum',
        value = 1;
  const FontFeature.localeAware({bool enable = true})
      : feature = 'locl',
        value = enable ? 1 : 0;
  const FontFeature.notationalForms([this.value = 1])
      : feature = 'nalt',
        assert(value >= 0);
  const FontFeature.numerators()
      : feature = 'numr',
        value = 1;
  const FontFeature.oldstyleFigures()
      : feature = 'onum',
        value = 1;
  const FontFeature.ordinalForms()
      : feature = 'ordn',
        value = 1;
  const FontFeature.proportionalFigures()
      : feature = 'pnum',
        value = 1;
  const FontFeature.randomize()
      : feature = 'rand',
        value = 1;
  const FontFeature.stylisticAlternates()
      : feature = 'salt',
        value = 1;
  const FontFeature.scientificInferiors()
      : feature = 'sinf',
        value = 1;
  factory FontFeature.stylisticSet(int value) {
    assert(value >= 1);
    assert(value <= 20);
    return FontFeature('ss${value.toString().padLeft(2, "0")}');
  }
  const FontFeature.subscripts()
      : feature = 'subs',
        value = 1;
  const FontFeature.superscripts()
      : feature = 'sups',
        value = 1;
  const FontFeature.swash([this.value = 1])
      : feature = 'swsh',
        assert(value >= 0);
  const FontFeature.tabularFigures()
      : feature = 'tnum',
        value = 1;
  const FontFeature.slashedZero()
      : feature = 'zero',
        value = 1;

  final String feature;
  final int value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is FontFeature &&
        other.feature == feature &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(feature, value);

  @override
  String toString() => "FontFeature('$feature', $value)";
}

class FontVariation {
  const FontVariation(
    this.axis,
    this.value,
  ) : assert(axis != null),
      assert(axis.length == 4, 'Axis tag must be exactly four characters long.'),
      assert(value != null);

  final String axis;
  final double value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is FontVariation
        && other.axis == axis
        && other.value == value;
  }

  @override
  int get hashCode => Object.hash(axis, value);

  @override
  String toString() => "FontVariation('$axis', $value)";
}

// The order of this enum must match the order of the values in RenderStyleConstants.h's ETextAlign.
enum TextAlign {
  left,
  right,
  center,
  justify,
  start,
  end,
}

enum TextBaseline {
  alphabetic,
  ideographic,
}

class TextDecoration {
  const TextDecoration._(this._mask);
  factory TextDecoration.combine(List<TextDecoration> decorations) {
    int mask = 0;
    for (final TextDecoration decoration in decorations) {
      mask |= decoration._mask;
    }
    return TextDecoration._(mask);
  }

  final int _mask;
  bool contains(TextDecoration other) {
    return (_mask | other._mask) == _mask;
  }

  static const TextDecoration none = TextDecoration._(0x0);
  static const TextDecoration underline = TextDecoration._(0x1);
  static const TextDecoration overline = TextDecoration._(0x2);
  static const TextDecoration lineThrough = TextDecoration._(0x4);

  @override
  bool operator ==(Object other) {
    return other is TextDecoration && other._mask == _mask;
  }

  @override
  int get hashCode => _mask.hashCode;

  @override
  String toString() {
    if (_mask == 0) {
      return 'TextDecoration.none';
    }
    final List<String> values = <String>[];
    if (_mask & underline._mask != 0) {
      values.add('underline');
    }
    if (_mask & overline._mask != 0) {
      values.add('overline');
    }
    if (_mask & lineThrough._mask != 0) {
      values.add('lineThrough');
    }
    if (values.length == 1) {
      return 'TextDecoration.${values[0]}';
    }
    return 'TextDecoration.combine([${values.join(", ")}])';
  }
}

enum TextDecorationStyle { solid, double, dotted, dashed, wavy }

enum TextLeadingDistribution {
  proportional,
  even,
}

class TextHeightBehavior {
  const TextHeightBehavior({
    this.applyHeightToFirstAscent = true,
    this.applyHeightToLastDescent = true,
    this.leadingDistribution = TextLeadingDistribution.proportional,
  });
  final bool applyHeightToFirstAscent;
  final bool applyHeightToLastDescent;
  final TextLeadingDistribution leadingDistribution;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TextHeightBehavior &&
        other.applyHeightToFirstAscent == applyHeightToFirstAscent &&
        other.applyHeightToLastDescent == applyHeightToLastDescent &&
        other.leadingDistribution == leadingDistribution;
  }

  @override
  int get hashCode {
    return Object.hash(
      applyHeightToFirstAscent,
      applyHeightToLastDescent,
    );
  }

  @override
  String toString() {
    return 'TextHeightBehavior('
        'applyHeightToFirstAscent: $applyHeightToFirstAscent, '
        'applyHeightToLastDescent: $applyHeightToLastDescent, '
        'leadingDistribution: $leadingDistribution'
        ')';
  }
}

abstract class TextStyle {
  factory TextStyle({
    Color? color,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextBaseline? textBaseline,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    Paint? background,
    Paint? foreground,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    List<FontVariation>? fontVariations,
  }) {
    if (engine.useCanvasKit) {
      return engine.CkTextStyle(
        color: color,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        textBaseline: textBaseline,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        height: height,
        leadingDistribution: leadingDistribution,
        locale: locale,
        background: background as engine.CkPaint?,
        foreground: foreground as engine.CkPaint?,
        shadows: shadows,
        fontFeatures: fontFeatures,
      );
    } else {
      return engine.EngineTextStyle(
        color: color,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        textBaseline: textBaseline,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        height: height,
        locale: locale,
        background: background,
        foreground: foreground,
        shadows: shadows,
        fontFeatures: fontFeatures,
        fontVariations: fontVariations,
      );
    }
  }
}

abstract class ParagraphStyle {
  //   See: https://github.com/flutter/flutter/issues/9819
  factory ParagraphStyle({
    TextAlign? textAlign,
    TextDirection? textDirection,
    int? maxLines,
    String? fontFamily,
    double? fontSize,
    double? height,
    TextHeightBehavior? textHeightBehavior,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    StrutStyle? strutStyle,
    String? ellipsis,
    Locale? locale,
  }) {
    if (engine.useCanvasKit) {
      return engine.CkParagraphStyle(
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: height,
        textHeightBehavior: textHeightBehavior,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        strutStyle: strutStyle,
        ellipsis: ellipsis,
        locale: locale,
      );
    } else {
      return engine.EngineParagraphStyle(
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: height,
        textHeightBehavior: textHeightBehavior,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        strutStyle: strutStyle,
        ellipsis: ellipsis,
        locale: locale,
      );
    }
  }
}

abstract class StrutStyle {
  /// Creates a new StrutStyle object.
  ///
  /// * `fontFamily`: The name of the font to use when painting the text (e.g.,
  ///   Roboto).
  ///
  /// * `fontFamilyFallback`: An ordered list of font family names that will be searched for when
  ///    the font in `fontFamily` cannot be found.
  ///
  /// * `fontSize`: The size of glyphs (in logical pixels) to use when painting
  ///   the text.
  ///
  /// * `lineHeight`: The minimum height of the line boxes, as a multiple of the
  ///   font size. The lines of the paragraph will be at least
  ///   `(lineHeight + leading) * fontSize` tall when fontSize
  ///   is not null. When fontSize is null, there is no minimum line height. Tall
  ///   glyphs due to baseline alignment or large [TextStyle.fontSize] may cause
  ///   the actual line height after layout to be taller than specified here.
  ///   [fontSize] must be provided for this property to take effect.
  ///
  /// * `leading`: The minimum amount of leading between lines as a multiple of
  ///   the font size. [fontSize] must be provided for this property to take effect.
  ///
  /// * `fontWeight`: The typeface thickness to use when painting the text
  ///   (e.g., bold).
  ///
  /// * `fontStyle`: The typeface variant to use when drawing the letters (e.g.,
  ///   italics).
  ///
  /// * `forceStrutHeight`: When true, the paragraph will force all lines to be exactly
  ///   `(lineHeight + leading) * fontSize` tall from baseline to baseline.
  ///   [TextStyle] is no longer able to influence the line height, and any tall
  ///   glyphs may overlap with lines above. If a [fontFamily] is specified, the
  ///   total ascent of the first line will be the min of the `Ascent + half-leading`
  ///   of the [fontFamily] and `(lineHeight + leading) * fontSize`. Otherwise, it
  ///   will be determined by the Ascent + half-leading of the first text.
  factory StrutStyle({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    double? leading,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    bool? forceStrutHeight,
  }) {
    if (engine.useCanvasKit) {
      return engine.CkStrutStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: fontSize,
        height: height,
        leadingDistribution: leadingDistribution,
        leading: leading,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        forceStrutHeight: forceStrutHeight,
      );
    } else {
      return engine.EngineStrutStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: fontSize,
        height: height,
        leadingDistribution: leadingDistribution,
        leading: leading,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        forceStrutHeight: forceStrutHeight,
      );
    }
  }
}

// The order of this enum must match the order of the values in TextDirection.h's TextDirection.
enum TextDirection {
  rtl,
  ltr,
}

class TextBox {
  const TextBox.fromLTRBD(
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.direction,
  );
  final double left;
  final double top;
  final double right;
  final double bottom;
  final TextDirection direction;
  Rect toRect() => Rect.fromLTRB(left, top, right, bottom);
  double get start {
    return (direction == TextDirection.ltr) ? left : right;
  }

  double get end {
    return (direction == TextDirection.ltr) ? right : left;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TextBox &&
        other.left == left &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom &&
        other.direction == direction;
  }

  @override
  int get hashCode => Object.hash(left, top, right, bottom, direction);

  @override
  String toString() {
    return 'TextBox.fromLTRBD(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, ${right.toStringAsFixed(1)}, ${bottom.toStringAsFixed(1)}, $direction)';
  }
}

enum TextAffinity {
  upstream,
  downstream,
}

class TextPosition {
  const TextPosition({
    required this.offset,
    this.affinity = TextAffinity.downstream,
  })  : assert(offset != null), // ignore: unnecessary_null_comparison
        assert(affinity != null); // ignore: unnecessary_null_comparison
  final int offset;
  final TextAffinity affinity;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TextPosition &&
        other.offset == offset &&
        other.affinity == affinity;
  }

  @override
  int get hashCode => Object.hash(offset, affinity);

  @override
  String toString() {
    return '$runtimeType(offset: $offset, affinity: $affinity)';
  }
}

class TextRange {
  const TextRange({
    required this.start,
    required this.end,
  })  : assert(start >= -1),
        assert(end >= -1);
  const TextRange.collapsed(int offset)
      : assert(offset >= -1),
        start = offset,
        end = offset;
  static const TextRange empty = TextRange(start: -1, end: -1);
  final int start;
  final int end;
  bool get isValid => start >= 0 && end >= 0;
  bool get isCollapsed => start == end;
  bool get isNormalized => end >= start;
  String textBefore(String text) {
    assert(isNormalized);
    return text.substring(0, start);
  }

  String textAfter(String text) {
    assert(isNormalized);
    return text.substring(end);
  }

  String textInside(String text) {
    assert(isNormalized);
    return text.substring(start, end);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TextRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(
        start.hashCode,
        end.hashCode,
      );

  @override
  String toString() => 'TextRange(start: $start, end: $end)';
}

class ParagraphConstraints {
  const ParagraphConstraints({
    required this.width,
  }) : assert(width != null); // ignore: unnecessary_null_comparison
  final double width;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ParagraphConstraints && other.width == width;
  }

  @override
  int get hashCode => width.hashCode;

  @override
  String toString() => '$runtimeType(width: $width)';
}

enum BoxHeightStyle {
  tight,
  max,
  includeLineSpacingMiddle,
  includeLineSpacingTop,
  includeLineSpacingBottom,
  strut,
}

enum BoxWidthStyle {
  // Provide tight bounding boxes that fit widths to the runs of each line
  // independently.
  tight,
  max,
}

abstract class LineMetrics {
  factory LineMetrics({
    required bool hardBreak,
    required double ascent,
    required double descent,
    required double unscaledAscent,
    required double height,
    required double width,
    required double left,
    required double baseline,
    required int lineNumber,
  }) = engine.EngineLineMetrics;
  bool get hardBreak;
  double get ascent;
  double get descent;
  double get unscaledAscent;
  double get height;
  double get width;
  double get left;
  double get baseline;
  int get lineNumber;
}

abstract class Paragraph {
  double get width;
  double get height;
  double get longestLine;
  double get minIntrinsicWidth;
  double get maxIntrinsicWidth;
  double get alphabeticBaseline;
  double get ideographicBaseline;
  bool get didExceedMaxLines;
  void layout(ParagraphConstraints constraints);
  List<TextBox> getBoxesForRange(int start, int end,
      {BoxHeightStyle boxHeightStyle = BoxHeightStyle.tight,
      BoxWidthStyle boxWidthStyle = BoxWidthStyle.tight});
  TextPosition getPositionForOffset(Offset offset);
  TextRange getWordBoundary(TextPosition position);
  TextRange getLineBoundary(TextPosition position);
  List<TextBox> getBoxesForPlaceholders();
  List<LineMetrics> computeLineMetrics();
}

abstract class ParagraphBuilder {
  factory ParagraphBuilder(ParagraphStyle style) {
    if (engine.useCanvasKit) {
      return engine.CkParagraphBuilder(style);
    }
    return engine.CanvasParagraphBuilder(style as engine.EngineParagraphStyle);
  }
  void pushStyle(TextStyle style);
  void pop();
  void addText(String text);
  Paragraph build();
  int get placeholderCount;
  List<double> get placeholderScales;
  void addPlaceholder(
    double width,
    double height,
    PlaceholderAlignment alignment, {
    double scale = 1.0,
    double? baselineOffset,
    TextBaseline? baseline,
  });
}

Future<void> loadFontFromList(Uint8List list, {String? fontFamily}) {
  if (engine.useCanvasKit) {
    return engine.skiaFontCollection
        .loadFontFromList(list, fontFamily: fontFamily)
        .then((_) => engine.sendFontChangeMessage());
  } else {
    return engine.fontCollection
        .loadFontFromList(list, fontFamily: fontFamily!)
        .then((_) => engine.sendFontChangeMessage());
  }
}
