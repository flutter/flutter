// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../text/paragraph.dart';
import '../util.dart';
import '../view_embedder/style_manager.dart';
import 'debug.dart';
import 'layout.dart';
import 'paint.dart';
import 'painter.dart';

@visibleForTesting
const String kPlaceholderChar = '\uFFFC';

/// A single canvas2d context to use for text layout.
@visibleForTesting
final DomCanvasRenderingContext2D layoutContext =
    // We don't use this canvas to draw anything, so let's make it as small as
    // possible to save memory.
    createDomCanvasElement(width: 0, height: 0).context2D;

/// The web implementation of  [ui.ParagraphStyle]
@immutable
class WebParagraphStyle implements ui.ParagraphStyle {
  // TODO(mdebbar): Make all params required to avoid future bugs.
  WebParagraphStyle({
    ui.TextDirection? textDirection,
    ui.TextAlign? textAlign,
    String? fontFamily,
    double? fontSize,
    ui.FontStyle? fontStyle,
    ui.FontWeight? fontWeight,
    double? height,
    ui.Locale? locale,
    this.maxLines,
    this.ellipsis,
    ui.Color? color,
    ui.StrutStyle? strutStyle,
    this.textHeightBehavior,
  }) : _strutStyle = strutStyle as WebStrutStyle?,
       _textStyle = WebTextStyle(
         fontFamily: fontFamily,
         fontSize: fontSize,
         fontStyle: fontStyle,
         fontWeight: fontWeight,
         height: height,
         locale: locale,
         color: color,
       ),
       textDirection = textDirection ?? ui.TextDirection.ltr,
       textAlign = textAlign ?? ui.TextAlign.start;

  WebTextStyle get textStyle => _textStyle;
  final WebTextStyle _textStyle;

  final ui.TextDirection textDirection;
  final ui.TextAlign textAlign;

  final int? maxLines;
  final String? ellipsis;

  final ui.TextHeightBehavior? textHeightBehavior;

  WebStrutStyle? get strutStyle => _strutStyle;
  final WebStrutStyle? _strutStyle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is WebParagraphStyle &&
        textDirection == other.textDirection &&
        textAlign == other.textAlign &&
        maxLines == other.maxLines &&
        ellipsis == other.ellipsis &&
        textHeightBehavior == other.textHeightBehavior &&
        _strutStyle == other._strutStyle &&
        _textStyle == other._textStyle;
  }

  @override
  int get hashCode {
    return Object.hash(
      textDirection,
      textAlign,
      maxLines,
      ellipsis,
      textHeightBehavior,
      _strutStyle,
      _textStyle,
    );
  }

  @override
  String toString() {
    var result = super.toString();
    assert(() {
      result =
          'WebParagraphStyle('
          'textDirection: $textDirection, '
          'textAlign: $textAlign, '
          'maxLines: $maxLines, '
          'ellipsis: $ellipsis, '
          'textHeightBehavior: $textHeightBehavior, '
          'strutStyle: $_strutStyle, '
          'textAlign: $textAlign'
          'textStyle: $_textStyle'
          ')';
      return true;
    }());
    return result;
  }

  ui.TextAlign effectiveAlign() {
    if (textAlign == ui.TextAlign.start) {
      return (textDirection == ui.TextDirection.ltr) ? ui.TextAlign.left : ui.TextAlign.right;
    } else if (textAlign == ui.TextAlign.end) {
      return (textDirection == ui.TextDirection.ltr) ? ui.TextAlign.right : ui.TextAlign.left;
    } else {
      return textAlign;
    }
  }
}

// TODO(mdebbar): Rename to `PaintElements`?
enum StyleElements {
  // Background for a text clusters block
  background,
  // Shadows for a single text cluster
  shadows,
  // Text decorations for a text clusters block
  decorations,
  // Text cluster
  text,
}

class WebTextStyle implements ui.TextStyle {
  factory WebTextStyle({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    ui.FontStyle? fontStyle,
    ui.FontWeight? fontWeight,
    ui.Color? color,
    ui.Paint? foreground,
    ui.Paint? background,
    List<ui.Shadow>? shadows,
    ui.TextDecoration? decoration,
    ui.Color? decorationColor,
    ui.TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    ui.TextBaseline? textBaseline,
    ui.TextLeadingDistribution? leadingDistribution,
    ui.Locale? locale,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations,
  }) {
    return WebTextStyle._(
      originalFontFamily: fontFamily, // ?? 'Arial',
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize, // ?? 14.0,
      fontStyle: fontStyle, // ?? ui.FontStyle.normal,
      fontWeight: fontWeight, // ?? ui.FontWeight.normal,
      color: color,
      foreground: foreground, // ?? (ui.Paint()..color = const ui.Color(0xFF000000)),
      background: background, // ?? (ui.Paint()..color = const ui.Color(0x00000000)),
      shadows: shadows,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      textBaseline: textBaseline,
      leadingDistribution: leadingDistribution,
      locale: locale,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
    );
  }

  WebTextStyle._({
    required this.originalFontFamily,
    required this.fontFamilyFallback,
    required this.fontSize,
    required this.fontStyle,
    required this.fontWeight,
    required this.color,
    required this.foreground,
    required this.background,
    required this.shadows,
    required this.decoration,
    required this.decorationColor,
    required this.decorationStyle,
    required this.decorationThickness,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.height,
    required this.textBaseline,
    required this.leadingDistribution,
    required this.locale,
    required this.fontFeatures,
    required this.fontVariations,
  });

  final String? originalFontFamily;
  final List<String>? fontFamilyFallback;
  final double? fontSize;
  final ui.FontStyle? fontStyle;
  final ui.FontWeight? fontWeight;
  final ui.Color? color;
  final ui.Paint? foreground;
  final ui.Paint? background;
  final List<ui.Shadow>? shadows;
  final ui.TextDecoration? decoration;
  final ui.Color? decorationColor; // Defaults to foreground color
  final ui.TextDecorationStyle? decorationStyle; // Defaults to none
  final double? decorationThickness; // Defaults to 1
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final ui.TextBaseline? textBaseline;
  final ui.TextLeadingDistribution? leadingDistribution;
  final ui.Locale? locale;
  final List<ui.FontFeature>? fontFeatures;
  final List<ui.FontVariation>? fontVariations;

  /// Merges this text style with [other] and returns the new text style.
  ///
  /// The values in this text style are used unless [other] specifically
  /// overrides it.
  WebTextStyle mergeWith(WebTextStyle other) {
    return WebTextStyle._(
      originalFontFamily: other.originalFontFamily ?? originalFontFamily,
      fontFamilyFallback: other.fontFamilyFallback ?? fontFamilyFallback,
      fontSize: other.fontSize ?? fontSize,
      fontStyle: other.fontStyle ?? fontStyle,
      fontWeight: other.fontWeight ?? fontWeight,
      color: other.color ?? color,
      foreground: other.foreground ?? foreground,
      background: other.background ?? background,
      shadows: other.shadows ?? shadows,
      decoration: other.decoration ?? decoration,
      decorationColor: other.decorationColor ?? decorationColor,
      decorationStyle: other.decorationStyle ?? decorationStyle,
      decorationThickness: other.decorationThickness ?? decorationThickness,
      letterSpacing: other.letterSpacing ?? letterSpacing,
      wordSpacing: other.wordSpacing ?? wordSpacing,
      height: other.height ?? height,
      textBaseline: other.textBaseline ?? textBaseline,
      leadingDistribution: other.leadingDistribution ?? leadingDistribution,
      locale: other.locale ?? locale,
      fontFeatures: other.fontFeatures ?? fontFeatures,
      fontVariations: other.fontVariations ?? fontVariations,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! WebTextStyle) {
      return false;
    }
    return other.originalFontFamily == originalFontFamily &&
        listEquals<String>(other.fontFamilyFallback, fontFamilyFallback) &&
        other.fontSize == fontSize &&
        other.fontStyle == fontStyle &&
        other.fontWeight == fontWeight &&
        other.color == color &&
        paintEquals(other.foreground, foreground) &&
        paintEquals(other.background, background) &&
        listEquals<ui.Shadow>(other.shadows, shadows) &&
        other.decoration == decoration &&
        other.decorationColor == decorationColor &&
        other.decorationStyle == decorationStyle &&
        other.decorationThickness == decorationThickness &&
        other.letterSpacing == letterSpacing &&
        other.wordSpacing == wordSpacing &&
        other.height == height &&
        other.textBaseline == textBaseline &&
        other.leadingDistribution == leadingDistribution &&
        other.locale == locale &&
        listEquals<ui.FontFeature>(other.fontFeatures, fontFeatures) &&
        listEquals<ui.FontVariation>(other.fontVariations, fontVariations);
  }

  @override
  int get hashCode {
    final List<String>? fontFamilyFallback = this.fontFamilyFallback;
    final List<ui.Shadow>? shadows = this.shadows;
    final List<ui.FontFeature>? fontFeatures = this.fontFeatures;
    final List<ui.FontVariation>? fontVariations = this.fontVariations;
    return Object.hash(
      originalFontFamily,
      fontFamilyFallback == null ? null : Object.hashAll(fontFamilyFallback),
      fontSize,
      fontStyle,
      fontWeight,
      color,
      foreground,
      background,
      shadows == null ? null : Object.hashAll(shadows),
      decoration,
      decorationColor,
      decorationStyle,
      decorationThickness,
      letterSpacing,
      wordSpacing,
      height,
      textBaseline,
      leadingDistribution,
      locale,
      // Object.hash goes up to 20 arguments, but we have 21
      Object.hash(
        fontFeatures == null ? null : Object.hashAll(fontFeatures),
        fontVariations == null ? null : Object.hashAll(fontVariations),
      ),
    );
  }

  ui.Color getForegroundColor() {
    return foreground != null
        ? foreground!.color
        : (color != null ? color! : const ui.Color(0xFFFFFFFF));
  }

  String _debugPaintToString(ui.Paint? paint) {
    if (paint == null) {
      return '';
    }
    return paint.color.toCssString();
  }

  @override
  String toString() {
    var result = super.toString();
    assert(() {
      final double? fontSize = this.fontSize;
      result =
          'fontFamily: ${originalFontFamily ?? ""} '
          'fontSize: ${fontSize != null ? fontSize.toStringAsFixed(1) : ""}px '
          'fontStyle: ${fontStyle != null ? fontStyle.toString().replaceFirst("FontStyle.", "") : ""} '
          'fontWeight: ${fontWeight != null ? fontWeight.toString().replaceFirst("FontWeight.", "") : ""} '
          'color: ${color != null ? color!.toCssString() : ""} '
          'foreground: ${_debugPaintToString(foreground)} '
          'background: ${_debugPaintToString(background)} ';
      if (shadows != null && shadows!.isNotEmpty) {
        result += 'shadows(${shadows!.length}) ';
        for (final ui.Shadow shadow in shadows!) {
          result += '[${shadow.color} ${shadow.blurRadius} ${shadow.blurSigma}]';
        }
      }
      if (decoration != null && decoration! != ui.TextDecoration.none) {
        result +=
            'decoration: $decoration'
            'decorationColor: ${decorationColor != null ? decorationColor.toString() : ""} '
            'decorationStyle: ${decorationStyle != null ? decorationStyle.toString() : ""} '
            'decorationThickness: ${decorationThickness != null ? decorationThickness.toString() : ""} ';
      }
      if (letterSpacing != null) {
        result += 'letterSpacing: $letterSpacing ';
      }
      if (wordSpacing != null) {
        result += 'wordSpacing: $wordSpacing ';
      }
      if (height != null) {
        result += 'height: $height ';
      }
      if (fontFeatures != null && fontFeatures!.isNotEmpty) {
        result += 'fontFeatures(${fontFeatures!.length}) ';
        for (final ui.FontFeature feature in fontFeatures!) {
          result += '[${feature.feature} ${feature.value}]';
        }
      }
      if (fontVariations != null && fontVariations!.isNotEmpty) {
        result += 'fontVariations(${fontVariations!.length}) ';
        for (final ui.FontVariation variation in fontVariations!) {
          result += '[${variation.axis} ${variation.value}]';
        }
      }
      result += ')';
      return true;
    }());
    return result;
  }

  String _buildCssFontString() {
    final String cssFontStyle = fontStyle?.toCssString() ?? StyleManager.defaultFontStyle;
    final String cssFontWeight = fontWeight?.toCssString() ?? StyleManager.defaultFontWeight;
    final int cssFontSize = (fontSize ?? StyleManager.defaultFontSize).floor();
    final String cssFontFamily = canonicalizeFontFamily(originalFontFamily)!;

    return '$cssFontStyle $cssFontWeight ${cssFontSize}px $cssFontFamily';
  }

  String _buildLetterSpacingString() {
    return (letterSpacing != null) ? '${letterSpacing}px' : '0px';
  }

  String _buildWordSpacingString() {
    return (wordSpacing != null) ? '${wordSpacing}px' : '0px';
  }

  void _applyFontFeatures(DomCanvasRenderingContext2D context) {
    if (fontFeatures == null) {
      return;
    }

    final fontFeatureSettings = <ui.FontFeature>[];
    var optimizeLegibility = false;

    for (final ui.FontFeature feature in fontFeatures!) {
      switch (feature.feature) {
        case 'smcp':
          context.fontVariantCaps = feature.value != 0 ? 'small-caps' : 'normal';
        case 'c2sc':
          context.fontVariantCaps = feature.value != 0 ? 'all-small-caps' : 'normal';
        case 'pcap':
          context.fontVariantCaps = feature.value != 0 ? 'petite-caps' : 'normal';
        case 'c2pc':
          context.fontVariantCaps = feature.value != 0 ? 'all-petite-caps' : 'normal';
        case 'unic':
          context.fontVariantCaps = feature.value != 0 ? 'unicase' : 'normal';
        case 'titl':
          context.fontVariantCaps = feature.value != 0 ? 'titling-caps' : 'normal';
        default:
          fontFeatureSettings.add(feature);
          if (feature.value != 0) {
            optimizeLegibility = true;
          }
      }
    }

    if (fontFeatureSettings.isNotEmpty) {
      // TODO(jlavrova): Do we really need to set this?
      context.textRendering = optimizeLegibility ? 'optimizeLegibility' : 'optimizeSpeed';
      context.canvas!.style.fontFeatureSettings = fontFeatureListToCss(fontFeatureSettings);
    }
  }

  void applyToContext(DomCanvasRenderingContext2D context) {
    // Setup all the font-affecting attributes
    // TODO(jlavrova): set 'lang' attribute as a combination of locale+language
    context.font = _buildCssFontString();
    context.letterSpacing = _buildLetterSpacingString();
    context.wordSpacing = _buildWordSpacingString();
    _applyFontFeatures(context);
  }

  bool hasElement(StyleElements element) {
    switch (element) {
      case StyleElements.background:
        // Transparent background is equivalent to no background
        // We do not check for transparency in other paints (like foreground) because
        // it seems unnatural to have a transparent paint on them
        return background != null && background!.color.a != 0;
      case StyleElements.shadows:
        return shadows != null && shadows!.isNotEmpty;
      case StyleElements.decorations:
        return decoration != null &&
            decoration! != ui.TextDecoration.none &&
            decorationStyle != null &&
            decorationColor != null;
      case StyleElements.text:
        return true;
    }
  }
}

class ClusterRange {
  ClusterRange({required this.start, required this.end})
    : assert(start >= -1, 'Start index cannot be negative: $start'),
      assert(end >= -1, 'End index cannot be negative: $end');

  ClusterRange.collapsed(int offset) : this(start: offset, end: offset);

  final int start;
  final int end;

  int get size => end - start;

  bool get isEmpty => start == end;
  bool get isNotEmpty => !isEmpty;

  ClusterRange intersect(ClusterRange other) {
    return ClusterRange(start: math.max(start, other.start), end: math.min(end, other.end));
  }

  ClusterRange merge(ClusterRange other) {
    if (other.size < 0) {
      return this;
    } else if (size < 0) {
      return other;
    }
    assert(end == other.start || other.end == start);
    return ClusterRange(start: math.min(start, other.start), end: math.max(end, other.end));
  }

  bool isBefore(int index) {
    // `end` is exclusive.
    return end <= index;
  }

  bool isAfter(int index) {
    return start > index;
  }

  /// Whether this range overlaps with the given range from [start] to [end].
  bool overlapsWith(int start, int end) {
    // `end` is exclusive.
    return !isBefore(start) && !isAfter(end - 1);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ClusterRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode {
    return Object.hash(start, end);
  }

  @override
  String toString() {
    return 'ClusterRange [$start:$end)';
  }
}

abstract class ParagraphSpan extends ui.TextRange {
  ParagraphSpan({required super.start, required super.end, required this.style});
  ParagraphSpan.collapsed(super.offset, this.style) : super.collapsed();

  final WebTextStyle style;

  int get size => end - start;

  bool get isEmpty => start == end;
  bool get isNotEmpty => !isEmpty;

  double get fontBoundingBoxAscent;
  double get fontBoundingBoxDescent;

  List<WebCluster> extractClusters();
}

class PlaceholderSpan extends ParagraphSpan {
  PlaceholderSpan({
    required super.start,
    required super.end,
    required super.style,
    required this.width,
    required this.height,
    required this.alignment,
    required this.baseline,
    required this.baselineOffset,
  });

  final double width;
  final double height;
  final ui.PlaceholderAlignment alignment;
  final ui.TextBaseline baseline;
  final double baselineOffset;

  @override
  double get fontBoundingBoxAscent => height;

  @override
  double get fontBoundingBoxDescent => 0.0;

  @override
  List<PlaceholderCluster> extractClusters() {
    return <PlaceholderCluster>[PlaceholderCluster(this)];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PlaceholderSpan &&
        other.start == start &&
        other.end == end &&
        other.style == style &&
        other.width == width &&
        other.height == height &&
        other.alignment == alignment &&
        other.baseline == baseline &&
        other.baselineOffset == baselineOffset;
  }

  @override
  int get hashCode => Object.hash(start, end, style, width, height, alignment, baseline);
}

class TextSpan extends ParagraphSpan {
  TextSpan({
    required super.start,
    required super.end,
    required super.style,
    required this.text,
    required this.textDirection,
  });

  final String text;
  // We use TextSpan to get metrics from Chrome in many places,
  // including empty spans (for example when measuring strut) and
  // ellipsis span (which inherits textDirection from the span it attaches to).
  final ui.TextDirection? textDirection;

  late final DomTextMetrics _metrics = _getMetrics();

  @override
  late final double fontBoundingBoxAscent = _metrics.fontBoundingBoxAscent;

  @override
  late final double fontBoundingBoxDescent = _metrics.fontBoundingBoxDescent;

  DomTextMetrics _getMetrics() {
    style.applyToContext(layoutContext);
    // We need to set in up because we otherwise in RTL text without textDirection
    // Canvas2D will return all clusters placed right to left starting from 0.
    // Also, we have a separate (possibly, different) textDirection for the ellipsis.
    layoutContext.direction = textDirection == ui.TextDirection.ltr ? 'ltr' : 'rtl';
    return layoutContext.measureText(text);
  }

  double? advanceWidth() {
    return _metrics.width;
  }

  @override
  List<TextCluster> extractClusters() {
    final clusters = <TextCluster>[];
    for (final DomTextCluster cluster in _metrics.getTextClusters()) {
      clusters.add(TextCluster(this, cluster));
    }
    return clusters;
  }

  ui.Rect getClusterBounds(TextCluster cluster) {
    return _metrics.getBounds(cluster.startInSpan, cluster.endInSpan);
  }

  ui.Rect getClusterSelection(TextCluster cluster) {
    return _metrics.getSelection(cluster.startInSpan, cluster.endInSpan);
  }

  ui.Rect getTextRangeSelectionInBlock(LineBlock block, ui.TextRange textRange) {
    // Let's normalize the ranges
    final ui.TextRange intersect = block.textRange.intersect(textRange);
    if (intersect.isEmpty) {
      return ui.Rect.zero;
    }
    // This `selection` is relative to the span, but blocks should be positioned relative to the line.
    final ui.Rect beforeSelection = _metrics.getSelection(
      block.textRange.start - start,
      intersect.start - start,
    );
    final ui.Rect intersectSelection = _metrics.getSelection(
      intersect.start - start,
      intersect.end - start,
    );

    // We need 2 selections to calculate the distance between the beginning of the line block and the intersection
    return ui.Rect.fromLTWH(
      block.shiftFromLineStart + intersectSelection.left - beforeSelection.left,
      intersectSelection.top,
      intersectSelection.width,
      intersectSelection.height,
    );
  }

  ui.Rect getBlockSelection(LineBlock block) {
    // This `selection` is relative to the span, but blocks should be positioned relative to the line.
    final ui.Rect selection = _metrics.getSelection(
      block.textRange.start - start,
      block.textRange.end - start,
    );

    // TODO(mdebbar): Consider moving this block-aware code to `TextBlock`.

    // `metrics.getSelection` calculates the rect relative to the span. It has no idea about the
    // span's position within the line or the paragraph. In order to make the rect's position relative
    // to the line, we need to add `block.shiftFromLineStart`.
    //
    // See [LineBlock.shiftFromLineStart] for a clarifying diagram.
    return ui.Rect.fromLTWH(
      block.shiftFromLineStart,
      selection.top,
      selection.width,
      selection.height,
    );
  }

  @override
  String toString() {
    return 'TextSpan($start, $end, "$text", $style)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TextSpan &&
        other.start == start &&
        other.end == end &&
        other.style == style &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(start, end, style, text);
}

class WebStrutStyle implements ui.StrutStyle {
  WebStrutStyle({
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontSize,
    double? height,
    // TODO(mdebbar): implement leadingDistribution.
    this.leadingDistribution,
    this.leading,
    this.fontWeight,
    this.fontStyle,
    this.forceStrutHeight,
  }) : height = height == ui.kTextHeightNone ? null : height;

  final String? fontFamily;
  final List<String>? fontFamilyFallback;
  final double? fontSize;
  final double? height;
  final double? leading;
  final ui.FontWeight? fontWeight;
  final ui.FontStyle? fontStyle;
  final bool? forceStrutHeight;
  final ui.TextLeadingDistribution? leadingDistribution;
  double strutAscent = 0;
  double strutDescent = 0;
  double strutLeading = 0;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is WebStrutStyle &&
        other.fontFamily == fontFamily &&
        other.fontSize == fontSize &&
        other.height == height &&
        other.leading == leading &&
        other.leadingDistribution == leadingDistribution &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.forceStrutHeight == forceStrutHeight &&
        listEquals<String>(other.fontFamilyFallback, fontFamilyFallback);
  }

  @override
  int get hashCode {
    return Object.hash(
      fontFamily,
      fontFamilyFallback != null ? Object.hashAll(fontFamilyFallback!) : null,
      fontSize,
      height,
      leading,
      leadingDistribution,
      fontWeight,
      fontStyle,
      forceStrutHeight,
    );
  }

  void calculateMetrics() {
    if (fontSize == null || fontSize! < 0) {
      return;
    }

    final String cssFontStyle = fontStyle?.toCssString() ?? StyleManager.defaultFontStyle;
    final String cssFontWeight = fontWeight?.toCssString() ?? StyleManager.defaultFontWeight;
    final int cssFontSize = (fontSize ?? StyleManager.defaultFontSize).floor();
    final String cssFontFamily = canonicalizeFontFamily(fontFamily)!;

    layoutContext.font = '$cssFontStyle $cssFontWeight ${cssFontSize}px $cssFontFamily';
    final DomTextMetrics strutTextMetrics = layoutContext.measureText('');

    strutLeading = leading == null ? 0 : leading! * fontSize!;

    if (height != null) {
      // The half leading flag doesn't take effect unless there's height override.
      if (leadingDistribution == ui.TextLeadingDistribution.even) {
        final double occupiedHeight =
            strutTextMetrics.fontBoundingBoxAscent + strutTextMetrics.fontBoundingBoxDescent;
        // Distribute the flexible height evenly over and under.
        final double flexibleHeight = (height! * fontSize! - occupiedHeight) / 2;
        strutAscent = strutTextMetrics.fontBoundingBoxAscent + flexibleHeight;
        strutDescent = strutTextMetrics.fontBoundingBoxDescent + flexibleHeight;
      } else {
        final double strutMetricsHeight =
            strutTextMetrics.fontBoundingBoxAscent + strutTextMetrics.fontBoundingBoxDescent;
        final double strutHeightMultiplier = strutMetricsHeight == 0
            ? height!
            : height! * fontSize! / strutMetricsHeight;
        strutAscent = strutTextMetrics.fontBoundingBoxAscent * strutHeightMultiplier;
        strutDescent = strutTextMetrics.fontBoundingBoxDescent * strutHeightMultiplier;
      }
    } else {
      strutAscent = strutTextMetrics.fontBoundingBoxAscent;
      strutDescent = strutTextMetrics.fontBoundingBoxDescent;
    }
  }
}

/// An implementation of [ui.Paragraph] based on the new Enhanced TextMetrics API.
///
/// See: https://chromestatus.com/feature/5075532483657728
class WebParagraph implements ui.Paragraph {
  WebParagraph(this.paragraphStyle, this.spans, this.text);

  final WebParagraphStyle paragraphStyle;
  final List<ParagraphSpan> spans;
  final String text;

  // TODO(jlavrova): Implement.
  @override
  double alphabeticBaseline = 0;

  // TODO(jlavrova): Implement.
  @override
  bool didExceedMaxLines = false;

  @override
  double height = 0;

  // TODO(jlavrova): Implement. Maybe use the same hack from the HTML renderer?
  @override
  double ideographicBaseline = 0;

  @override
  double longestLine = 0;

  @override
  double maxIntrinsicWidth = 0;

  @override
  double minIntrinsicWidth = 0;

  @override
  double width = 0;

  double maxLineWidthWithTrailingSpaces = 0; // without trailing spaces it would be longestLine

  List<TextLine> get lines => _layout.lines;

  @override
  List<ui.TextBox> getBoxesForPlaceholders() => _layout.getBoxesForPlaceholders();

  @override
  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    final List<ui.TextBox> result = _layout.getBoxesForRange(
      start,
      end,
      boxHeightStyle,
      boxWidthStyle,
    );
    WebParagraphDebug.apiTrace(
      'getBoxesForRange("$text", $start, $end, $boxHeightStyle, $boxWidthStyle): $result ($longestLine, $maxLineWidthWithTrailingSpaces)',
    );
    return result;
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    final ui.TextPosition result = text.isEmpty
        ? const ui.TextPosition(offset: 0)
        : _layout.getPositionForOffset(offset);
    WebParagraphDebug.apiTrace('getPositionForOffset("$text", $offset): $result');
    return result;
  }

  @override
  ui.GlyphInfo? getClosestGlyphInfoForOffset(ui.Offset offset) {
    final ui.TextPosition position = getPositionForOffset(offset);
    assert(position.offset < text.length || text.isEmpty);
    final ui.GlyphInfo? result = getGlyphInfoAt(position.offset);
    if (result == null) {
      WebParagraphDebug.apiTrace(
        'getClosestGlyphInfoForOffset("$text", ${offset.dx}, ${offset.dy}): '
        'TextPosition(${position.offset},${position.affinity.toString().replaceFirst('TextAffinity.', '')}) Glyph: null',
      );
      return null;
    }

    WebParagraphDebug.apiTrace(
      'getClosestGlyphInfoForOffset("$text", ${offset.dx}, ${offset.dy}): '
      'TextPosition(${position.offset},${position.affinity.toString().replaceFirst('TextAffinity.', '')} '
      '${result.graphemeClusterLayoutBounds} '
      'TextRange: [${result.graphemeClusterCodeUnitRange.start}:${result.graphemeClusterCodeUnitRange.end}) '
      'TextDirection: ${result.writingDirection.toString().replaceFirst('TextDirection.', '')} ',
    );

    return result;
  }

  @override
  ui.GlyphInfo? getGlyphInfoAt(int codeUnitOffset) {
    if (codeUnitOffset < 0 || codeUnitOffset >= text.length) {
      return null;
    }
    final ui.GlyphInfo? result = _layout.getGlyphInfoAt(codeUnitOffset);
    WebParagraphDebug.apiTrace('getGlyphInfoAt("$text", $codeUnitOffset): $result');
    return result;
  }

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    final int codepointPosition = switch (position.affinity) {
      ui.TextAffinity.upstream => position.offset - 1,
      ui.TextAffinity.downstream => position.offset,
    };
    if (codepointPosition < 0) {
      return const ui.TextRange(start: 0, end: 0);
    }
    if (codepointPosition >= text.length) {
      return ui.TextRange(start: text.length, end: text.length);
    }
    final ui.TextRange result = _layout.getWordBoundary(codepointPosition);
    WebParagraphDebug.apiTrace('getWordBoundary("$text", $position): $result');
    return result;
  }

  @override
  void layout(ui.ParagraphConstraints constraints) {
    _layout.performLayout(constraints.width);
    WebParagraphDebug.apiTrace(
      'layout("$text", ${constraints.width.toStringAsFixed(4)}}): '
      'width=${width.toStringAsFixed(4)} height=${height.toStringAsFixed(4)} '
      'minIntrinsicWidth=${minIntrinsicWidth.toStringAsFixed(4)} maxIntrinsicWidth=${maxIntrinsicWidth.toStringAsFixed(4)} '
      'longestLine=${longestLine.toStringAsFixed(4)} '
      'maxLineWidthWithTrailingSpaces=${maxLineWidthWithTrailingSpaces.toStringAsFixed(4)} lines=${_layout.lines.length}',
    );
  }

  void paint(ui.Canvas canvas, ui.Offset offset) {
    _paint.painter.resizePaintCanvas(ui.window.devicePixelRatio);
    for (final TextLine line in _layout.lines) {
      _paint.paintLine(canvas, _layout, line, offset.dx, offset.dy);
    }
  }

  void paintOnCanvas2D(DomHTMLCanvasElement canvas, ui.Offset offset) {
    _paint.painter.resizePaintCanvas(ui.window.devicePixelRatio);
    for (final TextLine line in _layout.lines) {
      _paint.paintLineOnCanvas2D(canvas, _layout, line, offset.dx, offset.dy);
    }
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    final int codepointPosition = switch (position.affinity) {
      ui.TextAffinity.upstream => position.offset - 1,
      ui.TextAffinity.downstream => position.offset,
    };

    final ui.TextRange result = _layout.getLineBoundary(codepointPosition);
    WebParagraphDebug.apiTrace('getLineBoundary("$text", $position): $result');
    return result;
  }

  @override
  List<ui.LineMetrics> computeLineMetrics() {
    final metrics = <ui.LineMetrics>[];
    for (final TextLine line in _layout.lines) {
      metrics.add(line.getMetrics());
    }
    WebParagraphDebug.apiTrace('computeLineMetrics("$text": $metrics');
    return metrics;
  }

  @override
  ui.LineMetrics? getLineMetricsAt(int lineNumber) {
    if (lineNumber < 0 || lineNumber >= _layout.lines.length) {
      WebParagraphDebug.apiTrace('getLineMetricsAt("$text", $lineNumber): null (out of range)');
      return null;
    }
    WebParagraphDebug.apiTrace(
      'getLineMetricsAt($lineNumber): ${_layout.lines[lineNumber].getMetrics()}',
    );
    return _layout.lines[lineNumber].getMetrics();
  }

  @override
  int get numberOfLines {
    return _layout.lines.length;
  }

  @override
  int? getLineNumberAt(int codeUnitOffset) {
    if (codeUnitOffset < 0 || codeUnitOffset >= text.length) {
      // When the offset is outside of the paragraph's range, we know it doesn't belong to any of
      // the lines.
      WebParagraphDebug.apiTrace(
        'getLineNumberAt("$text", $codeUnitOffset): null (out of text range)',
      );
      return null;
    }

    for (final TextLine line in _layout.lines) {
      if (line.allLineTextRange.isBefore(codeUnitOffset)) {
        continue;
      }
      if (line.allLineTextRange.isAfter(codeUnitOffset)) {
        // We haven't reached the offset yet, keep going.
        break;
      }

      WebParagraphDebug.apiTrace('getLineNumberAt("$text", $codeUnitOffset): ${line.lineNumber}');
      return line.lineNumber;
    }

    assert(
      false,
      'getLineNumberAt("$text", $codeUnitOffset): null (out of range, should not happen)',
    );
    return null;
  }

  bool _disposed = false;

  @override
  void dispose() {
    assert(!_disposed, 'Paragraph has been disposed.');
    _disposed = true;
  }

  @override
  bool get debugDisposed {
    bool? result;
    assert(() {
      result = _disposed;
      return true;
    }());

    if (result != null) {
      return result!;
    }

    throw StateError('Paragraph.debugDisposed is only available when asserts are enabled.');
  }

  TextLayout getLayout() {
    return _layout;
  }

  String getText(int start, int end) {
    if (text.isEmpty) {
      return text;
    }
    assert(start >= 0);
    assert(end <= text.length);
    return text.substring(start, end);
  }

  late final TextLayout _layout = TextLayout(this);
  late final TextPaint _paint = TextPaint(this, CanvasKitPainter());
}

class WebLineMetrics implements ui.LineMetrics {
  @override
  double get ascent => 0.0;

  @override
  double get descent => 0.0;

  @override
  double get unscaledAscent => 0.0;

  @override
  bool get hardBreak => false;

  @override
  double get baseline => 0.0;

  @override
  double get height => 0.0;

  @override
  double get left => 0.0;

  @override
  double get width => 0.0;

  @override
  int get lineNumber => 0;

  @override
  int get hashCode => Object.hash(
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
    return other is WebLineMetrics &&
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
    var result = super.toString();
    assert(() {
      result =
          'LineMetrics(hardBreak: $hardBreak, '
          'ascent: $ascent, '
          'descent: $descent, '
          'unscaledAscent: $unscaledAscent, '
          'height: $height, '
          'width: $width, '
          'left: $left, '
          'baseline: $baseline, '
          'lineNumber: $lineNumber)';
      return true;
    }());
    return result;
  }
}

class WebParagraphBuilder implements ui.ParagraphBuilder {
  WebParagraphBuilder(ui.ParagraphStyle paragraphStyle)
    : _paragraphStyle = paragraphStyle as WebParagraphStyle,
      _styleStack = <StyleNode>[RootStyleNode(paragraphStyle)];

  final WebParagraphStyle _paragraphStyle;

  final _spans = <ParagraphSpan>[];
  final List<StyleNode> _styleStack;

  final StringBuffer _fullTextBuffer = StringBuffer();

  WebTextStyle? _spanStyle;
  StringBuffer _spanTextBuffer = StringBuffer();

  WebTextStyle get _currentStyle => _styleStack.last.mergedStyle();

  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    double scale = 1.0,
    double? baselineOffset,
    ui.TextBaseline? baseline,
  }) {
    WebParagraphDebug.apiTrace(
      'WebParagraphBuilder.addPlaceholder('
      'width: $width, height: $height, alignment: $alignment, '
      'scale: $scale, baselineOffset: $baselineOffset, baseline: $baseline',
    );

    assert(
      !(alignment == ui.PlaceholderAlignment.aboveBaseline ||
              alignment == ui.PlaceholderAlignment.belowBaseline ||
              alignment == ui.PlaceholderAlignment.baseline) ||
          baseline != null,
    );

    _closeTextSpan();

    final int start = _fullTextBuffer.length;
    addText(kPlaceholderChar);
    final int end = _fullTextBuffer.length;

    _spans.add(
      PlaceholderSpan(
        start: start,
        end: end,
        style: _currentStyle,
        width: width * scale,
        height: height * scale,
        alignment: alignment,
        baseline: baseline ?? ui.TextBaseline.alphabetic,
        baselineOffset: (baselineOffset ?? height) * scale,
      ),
    );

    _resetTextSpan();

    _placeholderCount++;
    _placeholderScales.add(scale);
  }

  @override
  void addText(String text) {
    if (text.isEmpty) {
      return;
    }

    if (_shouldCloseTextSpan()) {
      _closeTextSpan();
    }

    // Remember the style that the span started at.
    _spanStyle = _currentStyle;
    _spanTextBuffer.write(text);

    _fullTextBuffer.write(text);
  }

  bool _shouldCloseTextSpan() {
    if (_spanStyle == null) {
      // No span has started yet, there's nothing to close.
      return false;
    }

    // When the current style is different from the style of the span being built, then we
    // should close that span and start a new one.
    return _spanStyle != _currentStyle;
  }

  void _closeTextSpan() {
    if (_spanStyle == null) {
      // No span has started yet, there's nothing to close.
      return;
    }

    assert(_spanTextBuffer.isNotEmpty);
    _spans.add(
      TextSpan(
        start: _fullTextBuffer.length - _spanTextBuffer.length,
        end: _fullTextBuffer.length,
        style: _spanStyle!,
        text: _spanTextBuffer.toString(),
        textDirection: _paragraphStyle.textDirection,
      ),
    );

    _resetTextSpan();
  }

  void _resetTextSpan() {
    _spanStyle = null;
    _spanTextBuffer = StringBuffer();
  }

  @override
  WebParagraph build() {
    _closeTextSpan();
    final text = _fullTextBuffer.toString();

    final paragraph = WebParagraph(_paragraphStyle, _spans, text);
    WebParagraphDebug.apiTrace('WebParagraphBuilder.build(): "$text" ${_spans.length}');
    for (var i = 0; i < _spans.length; ++i) {
      WebParagraphDebug.log('$i: ${_spans[i]}');
    }
    return paragraph;
  }

  @override
  int get placeholderCount => _placeholderCount;
  int _placeholderCount = 0;

  @override
  List<double> get placeholderScales => _placeholderScales;
  final List<double> _placeholderScales = <double>[];

  @override
  void pop() {
    // Don't pop the the first style node that represents `paragraphStyle`.
    if (_styleStack.length > 1) {
      _styleStack.removeLast();
    }
  }

  @override
  void pushStyle(ui.TextStyle textStyle) {
    final ChildStyleNode newNode = _styleStack.last.createChild(textStyle as WebTextStyle);
    _styleStack.add(newNode);
  }
}

/// Represents a node in the tree of text styles pushed to [ui.ParagraphBuilder].
///
/// The [ui.ParagraphBuilder.pushStyle] and [ui.ParagraphBuilder.pop] operations
/// represent the entire tree of styles in the paragraph. In our implementation,
/// we don't need to keep the entire tree structure in memory. At any point in
/// time, we only need a stack of nodes that represent the current branch in the
/// tree. The items in the stack are [StyleNode] objects.
abstract class StyleNode {
  /// Create a child for this style node.
  ///
  /// We are not creating a tree structure, hence there's no need to keep track
  /// of the children.
  ChildStyleNode createChild(WebTextStyle style) {
    return ChildStyleNode(parent: this, style: style);
  }

  WebTextStyle? _cachedMergedStyle;

  /// Generates the final text style to be applied to the text span.
  ///
  /// The resolved text style is equivalent to the entire ascendent chain of
  /// parent style nodes.
  WebTextStyle mergedStyle() {
    return _cachedMergedStyle ??= WebTextStyle(
      color: _color,
      decoration: _decoration,
      decorationColor: _decorationColor,
      decorationStyle: _decorationStyle,
      decorationThickness: _decorationThickness,
      fontWeight: _fontWeight,
      fontStyle: _fontStyle,
      textBaseline: _textBaseline,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFamilyFallback,
      fontFeatures: _fontFeatures,
      fontVariations: _fontVariations,
      fontSize: _fontSize,
      letterSpacing: _letterSpacing,
      wordSpacing: _wordSpacing,
      height: _height,
      leadingDistribution: _leadingDistribution,
      locale: _locale,
      background: _background,
      foreground: _foreground,
      shadows: _shadows,
    );
  }

  ui.Color? get _color;
  ui.TextDecoration? get _decoration;
  ui.Color? get _decorationColor;
  ui.TextDecorationStyle? get _decorationStyle;
  double? get _decorationThickness;
  ui.FontWeight? get _fontWeight;
  ui.FontStyle? get _fontStyle;
  ui.TextBaseline? get _textBaseline;
  String get _fontFamily;
  List<String>? get _fontFamilyFallback;
  List<ui.FontFeature>? get _fontFeatures;
  List<ui.FontVariation>? get _fontVariations;
  double get _fontSize;
  double? get _letterSpacing;
  double? get _wordSpacing;
  double? get _height;
  ui.TextLeadingDistribution? get _leadingDistribution;
  ui.Locale? get _locale;
  ui.Paint? get _background;
  ui.Paint? get _foreground;
  List<ui.Shadow>? get _shadows;
}

/// Represents a non-root [StyleNode].
class ChildStyleNode extends StyleNode {
  /// Creates a [ChildStyleNode] with the given [parent] and [style].
  ChildStyleNode({required this.parent, required this.style});

  /// The parent node to be used when resolving text styles.
  final StyleNode parent;

  /// The text style associated with the current node.
  final WebTextStyle style;

  // Read these properties from the TextStyle associated with this node. If the
  // property isn't defined, go to the parent node.

  @override
  ui.Color? get _color => style.color ?? parent._color;

  @override
  ui.TextDecoration? get _decoration => style.decoration ?? parent._decoration;

  @override
  ui.Color? get _decorationColor => style.decorationColor ?? parent._decorationColor;

  @override
  ui.TextDecorationStyle? get _decorationStyle => style.decorationStyle ?? parent._decorationStyle;

  @override
  double? get _decorationThickness => style.decorationThickness ?? parent._decorationThickness;

  @override
  ui.FontWeight? get _fontWeight => style.fontWeight ?? parent._fontWeight;

  @override
  ui.FontStyle? get _fontStyle => style.fontStyle ?? parent._fontStyle;

  @override
  ui.TextBaseline? get _textBaseline => style.textBaseline ?? parent._textBaseline;

  @override
  List<String>? get _fontFamilyFallback => style.fontFamilyFallback ?? parent._fontFamilyFallback;

  @override
  List<ui.FontFeature>? get _fontFeatures => style.fontFeatures ?? parent._fontFeatures;

  @override
  List<ui.FontVariation>? get _fontVariations => style.fontVariations ?? parent._fontVariations;

  @override
  double get _fontSize => style.fontSize ?? parent._fontSize;

  @override
  double? get _letterSpacing => style.letterSpacing ?? parent._letterSpacing;

  @override
  double? get _wordSpacing => style.wordSpacing ?? parent._wordSpacing;

  @override
  double? get _height {
    return style.height == ui.kTextHeightNone ? null : (style.height ?? parent._height);
  }

  @override
  ui.TextLeadingDistribution? get _leadingDistribution =>
      style.leadingDistribution ?? parent._leadingDistribution;

  @override
  ui.Locale? get _locale => style.locale ?? parent._locale;

  @override
  ui.Paint? get _background => style.background ?? parent._background;

  @override
  ui.Paint? get _foreground => style.foreground ?? parent._foreground;

  @override
  List<ui.Shadow>? get _shadows => style.shadows ?? parent._shadows;

  // Font family is slightly different from the other properties above. It's
  // never null on the TextStyle object, so we use `isFontFamilyProvided` to
  // check if font family is defined or not.
  @override
  String get _fontFamily => style.originalFontFamily ?? parent._fontFamily;
}

/// The root style node for the paragraph.
///
/// The style of the root is derived from a [ui.ParagraphStyle] and is the root
/// style for all spans in the paragraph.
class RootStyleNode extends StyleNode {
  /// Creates a [RootStyleNode] from [paragraphStyle].
  RootStyleNode(WebParagraphStyle paragraphStyle) : style = paragraphStyle.textStyle;

  /// The style for the current node.
  final WebTextStyle style;

  @override
  ui.Color? get _color => null;

  @override
  ui.TextDecoration? get _decoration => null;

  @override
  ui.Color? get _decorationColor => null;

  @override
  ui.TextDecorationStyle? get _decorationStyle => null;

  @override
  double? get _decorationThickness => null;

  @override
  ui.FontWeight? get _fontWeight => style.fontWeight;
  @override
  ui.FontStyle? get _fontStyle => style.fontStyle;

  @override
  ui.TextBaseline? get _textBaseline => null;

  @override
  String get _fontFamily => style.originalFontFamily ?? StyleManager.defaultFontFamily;

  @override
  List<String>? get _fontFamilyFallback => null;

  @override
  List<ui.FontFeature>? get _fontFeatures => null;

  @override
  List<ui.FontVariation>? get _fontVariations => null;

  @override
  double get _fontSize => style.fontSize ?? StyleManager.defaultFontSize;

  @override
  double? get _letterSpacing => null;

  @override
  double? get _wordSpacing => null;

  @override
  double? get _height => style.height;

  @override
  ui.TextLeadingDistribution? get _leadingDistribution => null;

  @override
  ui.Locale? get _locale => style.locale;

  @override
  ui.Paint? get _background => style.background ?? ui.Paint()
    ..color = const ui.Color(0x00000000);

  @override
  ui.Paint? get _foreground => null;

  @override
  List<ui.Shadow>? get _shadows => null;
}
