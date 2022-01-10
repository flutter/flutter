// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:math' as math;

import 'package:ui/ui.dart' as ui;

import '../browser_detection.dart';
import '../embedder.dart';
import '../util.dart';
import 'layout_service.dart';
import 'ruler.dart';

class EngineLineMetrics implements ui.LineMetrics {
  EngineLineMetrics({
    required this.hardBreak,
    required this.ascent,
    required this.descent,
    required this.unscaledAscent,
    required this.height,
    required this.width,
    required this.left,
    required this.baseline,
    required this.lineNumber,
  })  : displayText = null,
        ellipsis = null,
        startIndex = -1,
        endIndex = -1,
        endIndexWithoutNewlines = -1,
        widthWithTrailingSpaces = width,
        boxes = <RangeBox>[],
        spaceBoxCount = 0;

  EngineLineMetrics.rich(
    this.lineNumber, {
    required this.ellipsis,
    required this.startIndex,
    required this.endIndex,
    required this.endIndexWithoutNewlines,
    required this.hardBreak,
    required this.width,
    required this.widthWithTrailingSpaces,
    required this.left,
    required this.height,
    required this.baseline,
    required this.ascent,
    required this.descent,
    required this.boxes,
    required this.spaceBoxCount,
  })  : displayText = null,
        unscaledAscent = double.infinity;

  /// The text to be rendered on the screen representing this line.
  final String? displayText;

  /// The string to be displayed as an overflow indicator.
  ///
  /// When the value is non-null, it means this line is overflowing and the
  /// [ellipsis] needs to be displayed at the end of it.
  final String? ellipsis;

  /// The index (inclusive) in the text where this line begins.
  final int startIndex;

  /// The index (exclusive) in the text where this line ends.
  ///
  /// When the line contains an overflow, then [endIndex] goes until the end of
  /// the text and doesn't stop at the overflow cutoff.
  final int endIndex;

  /// The index (exclusive) in the text where this line ends, ignoring newline
  /// characters.
  final int endIndexWithoutNewlines;

  /// The list of boxes representing the entire line, possibly across multiple
  /// spans.
  final List<RangeBox> boxes;

  /// The number of boxes that are space-only.
  final int spaceBoxCount;

  @override
  final bool hardBreak;

  @override
  final double ascent;

  @override
  final double descent;

  @override
  final double unscaledAscent;

  @override
  final double height;

  @override
  final double width;

  /// The full width of the line including all trailing space but not new lines.
  ///
  /// The difference between [width] and [widthWithTrailingSpaces] is that
  /// [widthWithTrailingSpaces] includes trailing spaces in the width
  /// calculation while [width] doesn't.
  ///
  /// For alignment purposes for example, the [width] property is the right one
  /// to use because trailing spaces shouldn't affect the centering of text.
  /// But for placing cursors in text fields, we do care about trailing
  /// spaces so [widthWithTrailingSpaces] is more suitable.
  final double widthWithTrailingSpaces;

  @override
  final double left;

  @override
  final double baseline;

  @override
  final int lineNumber;

  bool overlapsWith(int startIndex, int endIndex) {
    return startIndex < this.endIndex && this.startIndex < endIndex;
  }

  @override
  int get hashCode => ui.hashValues(
        displayText,
        startIndex,
        endIndex,
        hardBreak,
        ascent,
        descent,
        unscaledAscent,
        height,
        width,
        left,
        baseline,
        lineNumber,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineLineMetrics &&
        other.displayText == displayText &&
        other.startIndex == startIndex &&
        other.endIndex == endIndex &&
        other.hardBreak == hardBreak &&
        other.ascent == ascent &&
        other.descent == descent &&
        other.unscaledAscent == unscaledAscent &&
        other.height == height &&
        other.width == width &&
        other.left == left &&
        other.baseline == baseline &&
        other.lineNumber == lineNumber;
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'LineMetrics(hardBreak: $hardBreak, '
          'ascent: $ascent, '
          'descent: $descent, '
          'unscaledAscent: $unscaledAscent, '
          'height: $height, '
          'width: $width, '
          'left: $left, '
          'baseline: $baseline, '
          'lineNumber: $lineNumber)';
    } else {
      return super.toString();
    }
  }
}

/// The web implementation of [ui.ParagraphStyle].
class EngineParagraphStyle implements ui.ParagraphStyle {
  /// Creates a new instance of [EngineParagraphStyle].
  EngineParagraphStyle({
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.fontFamily,
    this.fontSize,
    this.height,
    ui.TextHeightBehavior? textHeightBehavior,
    this.fontWeight,
    this.fontStyle,
    ui.StrutStyle? strutStyle,
    this.ellipsis,
    this.locale,
  })  : _textHeightBehavior = textHeightBehavior,
        // TODO(mdebbar): add support for strut style., b/128317744
        _strutStyle = strutStyle as EngineStrutStyle?;

  final ui.TextAlign? textAlign;
  final ui.TextDirection? textDirection;
  final ui.FontWeight? fontWeight;
  final ui.FontStyle? fontStyle;
  final int? maxLines;
  final String? fontFamily;
  final double? fontSize;
  final double? height;
  final ui.TextHeightBehavior? _textHeightBehavior;
  final EngineStrutStyle? _strutStyle;
  final String? ellipsis;
  final ui.Locale? locale;

  // The effective style attributes should be consistent with paragraph_style.h.
  ui.TextAlign get effectiveTextAlign => textAlign ?? ui.TextAlign.start;
  ui.TextDirection get effectiveTextDirection => textDirection ?? ui.TextDirection.ltr;

  double? get lineHeight {
    // TODO(mdebbar): Implement proper support for strut styles.
    // https://github.com/flutter/flutter/issues/32243
    final EngineStrutStyle? strutStyle = _strutStyle;
    final double? strutHeight = strutStyle?._height;
    if (strutStyle == null || strutHeight == null || strutHeight == 0) {
      // When there's no strut height, always use paragraph style height.
      return height;
    }
    if (strutStyle._forceStrutHeight == true) {
      // When strut height is forced, ignore paragraph style height.
      return strutHeight;
    }
    // In this case, strut height acts as a minimum height for all parts of the
    // paragraph. So we take the max of strut height and paragraph style height.
    return math.max(strutHeight, height ?? 0.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineParagraphStyle &&
        other.textAlign == textAlign &&
        other.textDirection == textDirection &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.maxLines == maxLines &&
        other.fontFamily == fontFamily &&
        other.fontSize == fontSize &&
        other.height == height &&
        other._textHeightBehavior == _textHeightBehavior &&
        other.ellipsis == ellipsis &&
        other.locale == locale;
  }

  @override
  int get hashCode {
    return ui.hashValues(
        textAlign,
        textDirection,
        fontWeight,
        fontStyle,
        maxLines,
        fontFamily,
        fontSize,
        height,
        _textHeightBehavior,
        ellipsis,
        locale);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      final double? fontSize = this.fontSize;
      final double? height = this.height;
      return 'ParagraphStyle('
          'textAlign: ${textAlign ?? "unspecified"}, '
          'textDirection: ${textDirection ?? "unspecified"}, '
          'fontWeight: ${fontWeight ?? "unspecified"}, '
          'fontStyle: ${fontStyle ?? "unspecified"}, '
          'maxLines: ${maxLines ?? "unspecified"}, '
          'textHeightBehavior: ${_textHeightBehavior ?? "unspecified"}, '
          'fontFamily: ${fontFamily ?? "unspecified"}, '
          'fontSize: ${fontSize != null ? fontSize.toStringAsFixed(1) : "unspecified"}, '
          'height: ${height != null ? "${height.toStringAsFixed(1)}x" : "unspecified"}, '
          'ellipsis: ${ellipsis != null ? "\"$ellipsis\"" : "unspecified"}, '
          'locale: ${locale ?? "unspecified"}'
          ')';
    } else {
      return super.toString();
    }
  }
}

/// The web implementation of [ui.TextStyle].
class EngineTextStyle implements ui.TextStyle {
  /// Constructs an [EngineTextStyle] with all properties being required.
  ///
  /// This is good for call sites that need to be updated whenever a new
  /// property is added to [EngineTextStyle]. Non-updated call sites will fail
  /// the build otherwise.
  factory EngineTextStyle({
    required ui.Color? color,
    required ui.TextDecoration? decoration,
    required ui.Color? decorationColor,
    required ui.TextDecorationStyle? decorationStyle,
    required double? decorationThickness,
    required ui.FontWeight? fontWeight,
    required ui.FontStyle? fontStyle,
    required ui.TextBaseline? textBaseline,
    required String? fontFamily,
    required List<String>? fontFamilyFallback,
    required double? fontSize,
    required double? letterSpacing,
    required double? wordSpacing,
    required double? height,
    required ui.Locale? locale,
    required ui.Paint? background,
    required ui.Paint? foreground,
    required List<ui.Shadow>? shadows,
    required List<ui.FontFeature>? fontFeatures,
  }) = EngineTextStyle.only;

  /// Constructs an [EngineTextStyle] with only the given properties.
  ///
  /// This constructor should be used sparingly in tests, for example. Or when
  /// we know for sure that not all properties are needed.
  EngineTextStyle.only({
    this.color,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.fontWeight,
    this.fontStyle,
    this.textBaseline,
    String? fontFamily,
    this.fontFamilyFallback,
    this.fontSize,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.locale,
    this.background,
    this.foreground,
    this.shadows,
    this.fontFeatures,
  })  : assert(
            color == null || foreground == null,
            'Cannot provide both a color and a foreground\n'
            'The color argument is just a shorthand for "foreground: new Paint()..color = color".'),
        isFontFamilyProvided = fontFamily != null,
        fontFamily = fontFamily ?? '';

  /// Constructs an [EngineTextStyle] by reading properties from an
  /// [EngineParagraphStyle].
  factory EngineTextStyle.fromParagraphStyle(
    EngineParagraphStyle paragraphStyle,
  ) {
    return EngineTextStyle.only(
      fontWeight: paragraphStyle.fontWeight,
      fontStyle: paragraphStyle.fontStyle,
      fontFamily: paragraphStyle.fontFamily,
      fontSize: paragraphStyle.fontSize,
      height: paragraphStyle.height,
      locale: paragraphStyle.locale,
    );
  }

  final ui.Color? color;
  final ui.TextDecoration? decoration;
  final ui.Color? decorationColor;
  final ui.TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final ui.FontWeight? fontWeight;
  final ui.FontStyle? fontStyle;
  final ui.TextBaseline? textBaseline;
  final bool isFontFamilyProvided;
  final String fontFamily;
  final List<String>? fontFamilyFallback;
  final List<ui.FontFeature>? fontFeatures;
  final double? fontSize;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final ui.Locale? locale;
  final ui.Paint? background;
  final ui.Paint? foreground;
  final List<ui.Shadow>? shadows;

  String get effectiveFontFamily {
    if (assertionsEnabled) {
      // In the flutter tester environment, we use a predictable-size font
      // "Ahem". This makes widget tests predictable and less flaky.
      if (ui.debugEmulateFlutterTesterEnvironment) {
        return 'Ahem';
      }
    }
    if (fontFamily.isEmpty) {
      return FlutterViewEmbedder.defaultFontFamily;
    }
    return fontFamily;
  }

  String? _cssFontString;

  /// Font string to be used in CSS.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/CSS/font>.
  String get cssFontString {
    return _cssFontString ??= buildCssFontString(
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      fontSize: fontSize,
      fontFamily: effectiveFontFamily,
    );
  }

  late final TextHeightStyle heightStyle = _createHeightStyle();

  TextHeightStyle _createHeightStyle() {
    return TextHeightStyle(
      fontFamily: effectiveFontFamily,
      fontSize: fontSize ?? FlutterViewEmbedder.defaultFontSize,
      height: height,
      // TODO(mdebbar): Pass the actual value when font features become supported
      //                https://github.com/flutter/flutter/issues/64595
      fontFeatures: null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineTextStyle &&
        other.color == color &&
        other.decoration == decoration &&
        other.decorationColor == decorationColor &&
        other.decorationStyle == decorationStyle &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.textBaseline == textBaseline &&
        other.fontFamily == fontFamily &&
        other.fontSize == fontSize &&
        other.letterSpacing == letterSpacing &&
        other.wordSpacing == wordSpacing &&
        other.height == height &&
        other.locale == locale &&
        other.background == background &&
        other.foreground == foreground &&
        listEquals<ui.Shadow>(other.shadows, shadows) &&
        listEquals<String>(other.fontFamilyFallback, fontFamilyFallback);
  }

  @override
  int get hashCode => ui.hashValues(
        color,
        decoration,
        decorationColor,
        decorationStyle,
        decorationThickness,
        fontWeight,
        fontStyle,
        textBaseline,
        fontFamily,
        fontFamilyFallback,
        fontSize,
        letterSpacing,
        wordSpacing,
        height,
        locale,
        background,
        foreground,
        shadows,
      );

  @override
  String toString() {
    if (assertionsEnabled) {
      final List<String>? fontFamilyFallback = this.fontFamilyFallback;
      final double? fontSize = this.fontSize;
      final double? height = this.height;
      return 'TextStyle('
          'color: ${color ?? "unspecified"}, '
          'decoration: ${decoration ?? "unspecified"}, '
          'decorationColor: ${decorationColor ?? "unspecified"}, '
          'decorationStyle: ${decorationStyle ?? "unspecified"}, '
          'decorationThickness: ${decorationThickness ?? "unspecified"}, '
          'fontWeight: ${fontWeight ?? "unspecified"}, '
          'fontStyle: ${fontStyle ?? "unspecified"}, '
          'textBaseline: ${textBaseline ?? "unspecified"}, '
          'fontFamily: ${isFontFamilyProvided && fontFamily != '' ? fontFamily : "unspecified"}, '
          'fontFamilyFallback: ${isFontFamilyProvided && fontFamilyFallback != null && fontFamilyFallback.isNotEmpty ? fontFamilyFallback : "unspecified"}, '
          'fontSize: ${fontSize != null ? fontSize.toStringAsFixed(1) : "unspecified"}, '
          'letterSpacing: ${letterSpacing != null ? "${letterSpacing}x" : "unspecified"}, '
          'wordSpacing: ${wordSpacing != null ? "${wordSpacing}x" : "unspecified"}, '
          'height: ${height != null ? "${height.toStringAsFixed(1)}x" : "unspecified"}, '
          'locale: ${locale ?? "unspecified"}, '
          'background: ${background ?? "unspecified"}, '
          'foreground: ${foreground ?? "unspecified"}, '
          'shadows: ${shadows ?? "unspecified"}, '
          'fontFeatures: ${fontFeatures ?? "unspecified"}'
          ')';
    } else {
      return super.toString();
    }
  }
}

/// The web implementation of [ui.StrutStyle].
class EngineStrutStyle implements ui.StrutStyle {
  EngineStrutStyle({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    double? leading,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    bool? forceStrutHeight,
  })  : _fontFamily = fontFamily,
        _fontFamilyFallback = fontFamilyFallback,
        _fontSize = fontSize,
        _height = height,
        _leadingDistribution = leadingDistribution,
        _leading = leading,
        _fontWeight = fontWeight,
        _fontStyle = fontStyle,
        _forceStrutHeight = forceStrutHeight;

  final String? _fontFamily;
  final List<String>? _fontFamilyFallback;
  final double? _fontSize;
  final double? _height;
  final double? _leading;
  final ui.FontWeight? _fontWeight;
  final ui.FontStyle? _fontStyle;
  final bool? _forceStrutHeight;
  final ui.TextLeadingDistribution? _leadingDistribution;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineStrutStyle &&
        other._fontFamily == _fontFamily &&
        other._fontSize == _fontSize &&
        other._height == _height &&
        other._leading == _leading &&
        other._leadingDistribution == _leadingDistribution &&
        other._fontWeight == _fontWeight &&
        other._fontStyle == _fontStyle &&
        other._forceStrutHeight == _forceStrutHeight &&
        listEquals<String>(other._fontFamilyFallback, _fontFamilyFallback);
  }

  @override
  int get hashCode => ui.hashValues(
        _fontFamily,
        _fontFamilyFallback,
        _fontSize,
        _height,
        _leading,
        _leadingDistribution,
        _fontWeight,
        _fontStyle,
        _forceStrutHeight,
      );
}

/// Holds information for a placeholder in a paragraph.
///
/// [width], [height] and [baselineOffset] are expected to be already scaled.
class ParagraphPlaceholder {
  ParagraphPlaceholder(
    this.width,
    this.height,
    this.alignment, {
    required this.baselineOffset,
    required this.baseline,
  });

  /// The scaled width of the placeholder.
  final double width;

  /// The scaled height of the placeholder.
  final double height;

  /// Specifies how the placeholder rectangle will be vertically aligned with
  /// the surrounding text.
  final ui.PlaceholderAlignment alignment;

  /// When the [alignment] value is [ui.PlaceholderAlignment.baseline], the
  /// [baselineOffset] indicates the distance from the baseline to the top of
  /// the placeholder rectangle.
  final double baselineOffset;

  /// Dictates whether to use alphabetic or ideographic baseline.
  final ui.TextBaseline baseline;
}

/// Converts [fontWeight] to its CSS equivalent value.
String? fontWeightToCss(ui.FontWeight? fontWeight) {
  if (fontWeight == null) {
    return null;
  }
  return fontWeightIndexToCss(fontWeightIndex: fontWeight.index);
}

String fontWeightIndexToCss({int fontWeightIndex = 3}) {
  switch (fontWeightIndex) {
    case 0:
      return '100';
    case 1:
      return '200';
    case 2:
      return '300';
    case 3:
      return 'normal';
    case 4:
      return '500';
    case 5:
      return '600';
    case 6:
      return 'bold';
    case 7:
      return '800';
    case 8:
      return '900';
  }

  assert(() {
    throw AssertionError(
      'Failed to convert font weight $fontWeightIndex to CSS.',
    );
  }());

  return '';
}

/// Applies a text [style] to an [element], translating the properties to their
/// corresponding CSS equivalents.
///
/// If [isSpan] is true, the text element is a span within richtext and
/// should not assign effectiveFontFamily if fontFamily was not specified.
void applyTextStyleToElement({
  required html.HtmlElement element,
  required EngineTextStyle style,
  bool isSpan = false,
}) {
  assert(element != null); // ignore: unnecessary_null_comparison
  assert(style != null); // ignore: unnecessary_null_comparison
  bool updateDecoration = false;
  final html.CssStyleDeclaration cssStyle = element.style;

  final ui.Color? color = style.foreground?.color ?? style.color;
  if (style.foreground?.style == ui.PaintingStyle.stroke) {
    // When comparing the outputs of the Bitmap Canvas and the DOM
    // implementation, we have found, that we need to set the background color
    // of the text to transparent to achieve the same effect as in the Bitmap
    // Canvas and the Skia Engine where only the text stroke is painted.
    // If we don't set it here to transparent, the text will inherit the color
    // of it's parent element.
    cssStyle.color = 'transparent';
    // Use hairline (device pixel when strokeWidth is not specified).
    final double? strokeWidth = style.foreground?.strokeWidth;
    final double adaptedWidth = strokeWidth != null && strokeWidth > 0
        ? strokeWidth
        : 1.0 / ui.window.devicePixelRatio;
    cssStyle.textStroke = '${adaptedWidth}px ${colorToCssString(color)}';
  } else if (color != null) {
    cssStyle.color = colorToCssString(color);
  }
  final ui.Color? background = style.background?.color;
  if (background != null) {
    cssStyle.backgroundColor = colorToCssString(background);
  }
  if (style.height != null) {
    cssStyle.lineHeight = '${style.height}';
  }
  final double? fontSize = style.fontSize;
  if (fontSize != null) {
    cssStyle.fontSize = '${fontSize.floor()}px';
  }
  if (style.fontWeight != null) {
    cssStyle.fontWeight = fontWeightToCss(style.fontWeight);
  }
  if (style.fontStyle != null) {
    cssStyle.fontStyle =
        style.fontStyle == ui.FontStyle.normal ? 'normal' : 'italic';
  }
  // For test environment use effectiveFontFamily since we need to
  // consistently use Ahem font.
  if (isSpan && !ui.debugEmulateFlutterTesterEnvironment) {
    cssStyle.fontFamily = canonicalizeFontFamily(style.fontFamily);
  } else {
    cssStyle.fontFamily = canonicalizeFontFamily(style.effectiveFontFamily);
  }
  if (style.letterSpacing != null) {
    cssStyle.letterSpacing = '${style.letterSpacing}px';
  }
  if (style.wordSpacing != null) {
    cssStyle.wordSpacing = '${style.wordSpacing}px';
  }
  if (style.decoration != null) {
    updateDecoration = true;
  }
  final List<ui.Shadow>? shadows = style.shadows;
  if (shadows != null) {
    cssStyle.textShadow = _shadowListToCss(shadows);
  }

  if (updateDecoration) {
    if (style.decoration != null) {
      final String? textDecoration =
          _textDecorationToCssString(style.decoration, style.decorationStyle);
      if (textDecoration != null) {
        if (browserEngine == BrowserEngine.webkit) {
          setElementStyle(
              element, '-webkit-text-decoration', textDecoration);
        } else {
          cssStyle.textDecoration = textDecoration;
        }
        final ui.Color? decorationColor = style.decorationColor;
        if (decorationColor != null) {
          cssStyle.textDecorationColor = colorToCssString(decorationColor)!;
        }
      }
    }
  }

  final List<ui.FontFeature>? fontFeatures = style.fontFeatures;
  if (fontFeatures != null && fontFeatures.isNotEmpty) {
    cssStyle.fontFeatureSettings = _fontFeatureListToCss(fontFeatures);
  }
}

html.Element createPlaceholderElement({
  required ParagraphPlaceholder placeholder,
}) {
  final html.Element element = html.document.createElement('span');
  final html.CssStyleDeclaration style = element.style;
  style
    ..display = 'inline-block'
    ..width = '${placeholder.width}px'
    ..height = '${placeholder.height}px'
    ..verticalAlign = _placeholderAlignmentToCssVerticalAlign(placeholder);

  return element;
}

String _placeholderAlignmentToCssVerticalAlign(
  ParagraphPlaceholder placeholder,
) {
  // For more details about the vertical-align CSS property, see:
  // - https://developer.mozilla.org/en-US/docs/Web/CSS/vertical-align
  switch (placeholder.alignment) {
    case ui.PlaceholderAlignment.top:
      return 'top';

    case ui.PlaceholderAlignment.middle:
      return 'middle';

    case ui.PlaceholderAlignment.bottom:
      return 'bottom';

    case ui.PlaceholderAlignment.aboveBaseline:
      return 'baseline';

    case ui.PlaceholderAlignment.belowBaseline:
      return '-${placeholder.height}px';

    case ui.PlaceholderAlignment.baseline:
      // In CSS, the placeholder is already placed above the baseline. But
      // Flutter's `baselineOffset` assumes the placeholder is placed below the
      // baseline. That's why we need to subtract the placeholder's height from
      // `baselineOffset`.
      final double offset = placeholder.baselineOffset - placeholder.height;
      return '${offset}px';
  }
}

String _shadowListToCss(List<ui.Shadow> shadows) {
  if (shadows.isEmpty) {
    return '';
  }
  // CSS text-shadow is a comma separated list of shadows.
  // <offsetx> <offsety> <blur-radius> <color>.
  // Shadows are applied front-to-back with first shadow on top.
  // Color is optional. offsetx,y are required. blur-radius is optional as well
  // and defaults to 0.
  final StringBuffer sb = StringBuffer();
  final int len = shadows.length;
  for (int i = 0; i < len; i++) {
    if (i != 0) {
      sb.write(',');
    }
    final ui.Shadow shadow = shadows[i];
    sb.write('${shadow.offset.dx}px ${shadow.offset.dy}px '
        '${shadow.blurRadius}px ${colorToCssString(shadow.color)}');
  }
  return sb.toString();
}

String _fontFeatureListToCss(List<ui.FontFeature> fontFeatures) {
  assert(fontFeatures.isNotEmpty);

  // For more details, see:
  // * https://developer.mozilla.org/en-US/docs/Web/CSS/font-feature-settings
  final StringBuffer sb = StringBuffer();
  final int len = fontFeatures.length;
  for (int i = 0; i < len; i++) {
    if (i != 0) {
      sb.write(',');
    }
    final ui.FontFeature fontFeature = fontFeatures[i];
    sb.write('"${fontFeature.feature}" ${fontFeature.value}');
  }
  return sb.toString();
}

/// Converts text decoration style to CSS text-decoration-style value.
String? _textDecorationToCssString(
    ui.TextDecoration? decoration, ui.TextDecorationStyle? decorationStyle) {
  final StringBuffer decorations = StringBuffer();
  if (decoration != null) {
    if (decoration.contains(ui.TextDecoration.underline)) {
      decorations.write('underline ');
    }
    if (decoration.contains(ui.TextDecoration.overline)) {
      decorations.write('overline ');
    }
    if (decoration.contains(ui.TextDecoration.lineThrough)) {
      decorations.write('line-through ');
    }
  }
  if (decorationStyle != null) {
    decorations.write(_decorationStyleToCssString(decorationStyle));
  }
  return decorations.isEmpty ? null : decorations.toString();
}

String? _decorationStyleToCssString(ui.TextDecorationStyle decorationStyle) {
  switch (decorationStyle) {
    case ui.TextDecorationStyle.dashed:
      return 'dashed';
    case ui.TextDecorationStyle.dotted:
      return 'dotted';
    case ui.TextDecorationStyle.double:
      return 'double';
    case ui.TextDecorationStyle.solid:
      return 'solid';
    case ui.TextDecorationStyle.wavy:
      return 'wavy';
    default:
      return null;
  }
}

/// Converts [textDirection] to its corresponding CSS value.
///
/// This value is used for the "direction" CSS property, e.g.:
///
/// ```css
/// direction: rtl;
/// ```
String? textDirectionToCss(ui.TextDirection? textDirection) {
  if (textDirection == null) {
    return null;
  }
  return textDirectionIndexToCss(textDirection.index);
}

String? textDirectionIndexToCss(int textDirectionIndex) {
  switch (textDirectionIndex) {
    case 0:
      return 'rtl';
    case 1:
      return null; // ltr is the default
  }

  assert(() {
    throw AssertionError(
      'Failed to convert text direction $textDirectionIndex to CSS',
    );
  }());

  return null;
}

/// Converts [align] to its corresponding CSS value.
///
/// This value is used as the "text-align" CSS property, e.g.:
///
/// ```css
/// text-align: right;
/// ```
String textAlignToCssValue(
    ui.TextAlign? align, ui.TextDirection textDirection) {
  switch (align) {
    case ui.TextAlign.left:
      return 'left';
    case ui.TextAlign.right:
      return 'right';
    case ui.TextAlign.center:
      return 'center';
    case ui.TextAlign.justify:
      return 'justify';
    case ui.TextAlign.end:
      switch (textDirection) {
        case ui.TextDirection.ltr:
          return 'end';
        case ui.TextDirection.rtl:
          return 'left';
      }
    case ui.TextAlign.start:
      switch (textDirection) {
        case ui.TextDirection.ltr:
          return ''; // it's the default
        case ui.TextDirection.rtl:
          return 'right';
      }
    case null:
      // If align is not specified return default.
      return '';
  }
}
