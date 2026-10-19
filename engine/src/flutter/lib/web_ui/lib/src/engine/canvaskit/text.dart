// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

const String _kWeightAxisTag = 'wght';

SkTextStyleProperties _toParagraphSkTextStyleProperties(
  String? fontFamily,
  double? fontSize,
  double? height,
  ui.FontWeight? fontWeight,
  ui.FontStyle? fontStyle,
) {
  final skTextStyle = SkTextStyleProperties();
  if (fontWeight != null || fontStyle != null) {
    skTextStyle.fontStyle = toSkFontStyle(fontWeight, fontStyle);
  }

  final int weightValue = fontWeight?.value ?? ui.FontWeight.normal.value;
  final skFontVariation = SkFontVariation();
  skFontVariation.axis = _kWeightAxisTag;
  skFontVariation.value = weightValue.toDouble();
  skTextStyle.fontVariations = <SkFontVariation>[skFontVariation];

  if (fontSize != null) {
    skTextStyle.fontSize = fontSize;
  }

  if (height != null) {
    skTextStyle.heightMultiplier = height;
  }

  skTextStyle.fontFamilies = _computeCombinedFontFamilies(fontFamily);

  return skTextStyle;
}

SkStrutStyleProperties _toSkStrutStyleProperties(
  EngineStrutStyle style,
  ui.TextHeightBehavior? paragraphHeightBehavior,
) {
  final skStrutStyle = SkStrutStyleProperties();
  skStrutStyle.fontFamilies = _computeCombinedFontFamilies(
    style.effectiveFontFamily,
    style.effectiveFontFamilyFallback,
  );

  if (style.fontSize != null) {
    skStrutStyle.fontSize = style.fontSize;
  }

  if (style.height != null) {
    skStrutStyle.heightMultiplier = style.height;
  }

  final ui.TextLeadingDistribution? effectiveLeadingDistribution =
      style.leadingDistribution ?? paragraphHeightBehavior?.leadingDistribution;
  switch (effectiveLeadingDistribution) {
    case null:
      break;
    case ui.TextLeadingDistribution.even:
      skStrutStyle.halfLeading = true;
    case ui.TextLeadingDistribution.proportional:
      skStrutStyle.halfLeading = false;
  }

  if (style.leading != null) {
    skStrutStyle.leading = style.leading;
  }

  if (style.fontWeight != null || style.fontStyle != null) {
    skStrutStyle.fontStyle = toSkFontStyle(style.fontWeight, style.fontStyle);
  }

  if (style.forceStrutHeight != null) {
    skStrutStyle.forceStrutHeight = style.forceStrutHeight;
  }

  skStrutStyle.strutEnabled = true;

  return skStrutStyle;
}

SkParagraphStyle _toSkParagraphStyle(EngineParagraphStyle style) {
  final properties = SkParagraphStyleProperties();

  final ui.TextAlign? textAlign = style.textAlign;
  if (textAlign != null) {
    properties.textAlign = toSkTextAlign(textAlign);
  }

  final ui.TextDirection? textDirection = style.textDirection;
  if (textDirection != null) {
    properties.textDirection = toSkTextDirection(textDirection);
  }

  final int? maxLines = style.maxLines;
  if (maxLines != null) {
    properties.maxLines = maxLines;
  }

  final double? height = style.height;
  if (height != null) {
    properties.heightMultiplier = height;
  }

  final ui.TextHeightBehavior? textHeightBehavior = style.textHeightBehavior;
  if (textHeightBehavior != null) {
    properties.textHeightBehavior = toSkTextHeightBehavior(textHeightBehavior);
  }

  final String? ellipsis = style.ellipsis;
  if (ellipsis != null) {
    properties.ellipsis = ellipsis;
  }

  final EngineStrutStyle? strutStyle = style.strutStyle;
  if (strutStyle != null) {
    properties.strutStyle = _toSkStrutStyleProperties(strutStyle, textHeightBehavior);
  }

  properties.replaceTabCharacters = true;
  properties.textStyle = _toParagraphSkTextStyleProperties(
    style.effectiveFontFamily,
    style.fontSize,
    style.height,
    style.fontWeight,
    style.fontStyle,
  );
  properties.applyRoundingHack = false;

  return canvasKit.ParagraphStyle(properties);
}

SkTextStyle _toSkTextStyle(EngineTextStyle style) {
  final ui.Color? color = style.color;
  final ui.TextDecoration? decoration = style.decoration;
  final ui.Color? decorationColor = style.decorationColor;
  final ui.TextDecorationStyle? decorationStyle = style.decorationStyle;
  final double? decorationThickness = style.decorationThickness;
  final ui.FontWeight? fontWeight = style.fontWeight;
  final ui.FontStyle? fontStyle = style.fontStyle;
  final ui.TextBaseline? textBaseline = style.textBaseline;
  final double? fontSize = style.fontSize;
  final double? letterSpacing = style.letterSpacing;
  final double? wordSpacing = style.wordSpacing;
  final double? height = style.height;
  final ui.Locale? locale = style.locale;
  final background = style.background as CkPaint?;
  final foreground = style.foreground as CkPaint?;
  final List<ui.Shadow>? shadows = style.shadows;
  final List<ui.FontFeature>? fontFeatures = style.fontFeatures;
  final List<ui.FontVariation>? fontVariations = style.fontVariations;

  final properties = SkTextStyleProperties();

  if (background != null) {
    properties.backgroundColor = makeFreshSkColor(background.color);
  }

  if (color != null) {
    properties.color = makeFreshSkColor(color);
  }

  if (decoration != null) {
    int decorationValue = canvasKit.NoDecoration.toInt();
    if (decoration.contains(ui.TextDecoration.underline)) {
      decorationValue |= canvasKit.UnderlineDecoration.toInt();
    }
    if (decoration.contains(ui.TextDecoration.overline)) {
      decorationValue |= canvasKit.OverlineDecoration.toInt();
    }
    if (decoration.contains(ui.TextDecoration.lineThrough)) {
      decorationValue |= canvasKit.LineThroughDecoration.toInt();
    }
    properties.decoration = decorationValue;
  }

  if (decorationThickness != null) {
    properties.decorationThickness = decorationThickness;
  }

  if (decorationColor != null) {
    properties.decorationColor = makeFreshSkColor(decorationColor);
  }

  if (decorationStyle != null) {
    properties.decorationStyle = toSkTextDecorationStyle(decorationStyle);
  }

  if (textBaseline != null) {
    properties.textBaseline = toSkTextBaseline(textBaseline);
  }

  if (fontSize != null) {
    properties.fontSize = fontSize;
  }

  if (letterSpacing != null) {
    properties.letterSpacing = letterSpacing;
  }

  if (wordSpacing != null) {
    properties.wordSpacing = wordSpacing;
  }

  if (height != null) {
    properties.heightMultiplier = height;
  }

  switch (style.leadingDistribution) {
    case null:
      break;
    case ui.TextLeadingDistribution.even:
      properties.halfLeading = true;
    case ui.TextLeadingDistribution.proportional:
      properties.halfLeading = false;
  }

  if (locale != null) {
    properties.locale = locale.toLanguageTag();
  }

  properties.fontFamilies = _computeCombinedFontFamilies(
    style.effectiveFontFamily,
    style.effectiveFontFamilyFallback,
  );

  if (fontWeight != null || fontStyle != null) {
    properties.fontStyle = toSkFontStyle(fontWeight, fontStyle);
  }

  if (foreground != null) {
    properties.foregroundColor = makeFreshSkColor(foreground.color);
  }

  if (shadows != null) {
    final ckShadows = <SkTextShadow>[];
    for (final ui.Shadow shadow in shadows) {
      final ckShadow = SkTextShadow();
      ckShadow.color = makeFreshSkColor(shadow.color);
      ckShadow.offset = toSkPoint(shadow.offset);
      ckShadow.blurRadius = shadow.blurRadius;
      ckShadows.add(ckShadow);
    }
    properties.shadows = ckShadows;
  }

  if (fontFeatures != null) {
    final skFontFeatures = <SkFontFeature>[];
    for (final ui.FontFeature fontFeature in fontFeatures) {
      final skFontFeature = SkFontFeature();
      skFontFeature.name = fontFeature.feature;
      skFontFeature.value = fontFeature.value;
      skFontFeatures.add(skFontFeature);
    }
    properties.fontFeatures = skFontFeatures;
  }

  final skFontVariations = <SkFontVariation>[];
  var weightAxisSet = false;
  if (fontVariations != null) {
    for (final ui.FontVariation fontVariation in fontVariations) {
      final skFontVariation = SkFontVariation();
      skFontVariation.axis = fontVariation.axis;
      skFontVariation.value = fontVariation.value;
      skFontVariations.add(skFontVariation);
      if (fontVariation.axis == _kWeightAxisTag) {
        weightAxisSet = true;
      }
    }
  }
  if (!weightAxisSet) {
    final int weightValue = fontWeight?.value ?? ui.FontWeight.normal.value;
    final skFontVariation = SkFontVariation();
    skFontVariation.axis = _kWeightAxisTag;
    skFontVariation.value = weightValue.toDouble();
    skFontVariations.add(skFontVariation);
  }
  properties.fontVariations = skFontVariations;

  return canvasKit.TextStyle(properties);
}

SkFontStyle toSkFontStyle(ui.FontWeight? fontWeight, ui.FontStyle? fontStyle) {
  final style = SkFontStyle();
  if (fontWeight != null) {
    style.weight = toSkFontWeight(fontWeight);
  }
  if (fontStyle != null) {
    style.slant = toSkFontSlant(fontStyle);
  }
  return style;
}

/// The CanvasKit implementation of [BackendParagraph].
class CkParagraph implements BackendParagraph {
  CkParagraph(this.skiaObject, this._paragraphStyle);

  final SkParagraph skiaObject;

  /// The paragraph style used to build this paragraph.
  final EngineParagraphStyle _paragraphStyle;

  @override
  double get alphabeticBaseline => _alphabeticBaseline;
  double _alphabeticBaseline = 0;

  @override
  bool get didExceedMaxLines => _didExceedMaxLines;
  bool _didExceedMaxLines = false;

  @override
  double get height => _height;
  double _height = 0;

  @override
  double get ideographicBaseline => _ideographicBaseline;
  double _ideographicBaseline = 0;

  @override
  double get longestLine => _longestLine;
  double _longestLine = 0;

  @override
  double get maxIntrinsicWidth => _maxIntrinsicWidth;
  double _maxIntrinsicWidth = 0;

  @override
  double get minIntrinsicWidth => _minIntrinsicWidth;
  double _minIntrinsicWidth = 0;

  @override
  double get width => _width;
  double _width = 0;

  @override
  List<ui.TextBox> getBoxesForPlaceholders() => _boxesForPlaceholders;
  late List<ui.TextBox> _boxesForPlaceholders;

  @override
  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    final List<SkRectWithDirection> skRects = skiaObject.getRectsForRange(
      start.toDouble(),
      end.toDouble(),
      toSkRectHeightStyle(boxHeightStyle),
      toSkRectWidthStyle(boxWidthStyle),
    );

    return skRectsToTextBoxes(skRects);
  }

  List<ui.TextBox> skRectsToTextBoxes(List<SkRectWithDirection> skRects) {
    final result = <ui.TextBox>[];

    for (var i = 0; i < skRects.length; i++) {
      final SkRectWithDirection skRect = skRects[i];
      final Float32List rect = skRect.rect;
      final int skTextDirection = skRect.dir.value.toInt();
      result.add(
        ui.TextBox.fromLTRBD(
          rect[0],
          rect[1],
          rect[2],
          rect[3],
          ui.TextDirection.values[skTextDirection],
        ),
      );
    }

    return result;
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    final SkTextPosition positionWithAffinity = skiaObject.getGlyphPositionAtCoordinate(
      offset.dx,
      offset.dy,
    );
    return fromPositionWithAffinity(positionWithAffinity);
  }

  @override
  ui.GlyphInfo? getClosestGlyphInfoForOffset(ui.Offset offset) {
    return skiaObject.getClosestGlyphInfoAt(offset.dx, offset.dy);
  }

  @override
  ui.GlyphInfo? getGlyphInfoAt(int codeUnitOffset) {
    return skiaObject.getGlyphInfoAt(codeUnitOffset.toDouble());
  }

  @override
  ui.TextRange getWordBoundary(int characterPosition) {
    final SkTextRange skRange = skiaObject.getWordBoundary(characterPosition.toDouble());
    return ui.TextRange(start: skRange.start.toInt(), end: skRange.end.toInt());
  }

  @override
  void layout(double width) {
    // TODO(het): CanvasKit throws an exception when laid out with
    // a font that wasn't registered.
    try {
      skiaObject.layout(width);
      _alphabeticBaseline = skiaObject.getAlphabeticBaseline();
      _didExceedMaxLines = skiaObject.didExceedMaxLines();
      _height = skiaObject.getHeight();
      _ideographicBaseline = skiaObject.getIdeographicBaseline();
      _longestLine = skiaObject.getLongestLine();
      _maxIntrinsicWidth = skiaObject.getMaxIntrinsicWidth();
      _minIntrinsicWidth = skiaObject.getMinIntrinsicWidth();
      _width = skiaObject.getMaxWidth();
      _boxesForPlaceholders = skRectsToTextBoxes(skiaObject.getRectsForPlaceholders());
    } catch (e) {
      printWarning(
        'CanvasKit threw an exception while laying '
        'out the paragraph. The font was "${_paragraphStyle.fontFamily}". '
        'Exception:\n$e',
      );
      rethrow;
    }
  }

  @override
  List<int> getUnresolvedCodePoints() => skiaObject.getUnresolvedCodePoints();

  static EngineLineMetrics _toEngineLineMetrics(SkLineMetrics skLineMetrics) {
    return EngineLineMetrics(
      hardBreak: skLineMetrics.isHardBreak,
      ascent: skLineMetrics.ascent,
      descent: skLineMetrics.descent,
      // TODO(hterkelsen): Implement this correctly once SkParagraph does.
      unscaledAscent: skLineMetrics.ascent,
      height: (skLineMetrics.ascent + skLineMetrics.descent).round().toDouble(),
      width: skLineMetrics.width,
      left: skLineMetrics.left,
      baseline: skLineMetrics.baseline,
      lineNumber: skLineMetrics.lineNumber.toInt(),
      startIndex: skLineMetrics.startIndex.toInt(),
      endIndex: skLineMetrics.endIndex.toInt(),
    );
  }

  @override
  List<EngineLineMetrics> computeLineMetrics() {
    final List<SkLineMetrics> skLineMetrics = skiaObject.getLineMetrics();
    final result = <EngineLineMetrics>[];
    for (final metric in skLineMetrics) {
      result.add(_toEngineLineMetrics(metric));
    }
    return result;
  }

  @override
  EngineLineMetrics? getLineMetricsAt(int lineNumber) {
    final SkLineMetrics? metrics = skiaObject.getLineMetricsAt(lineNumber.toDouble());
    return metrics == null ? null : _toEngineLineMetrics(metrics);
  }

  @override
  int get numberOfLines => skiaObject.getNumberOfLines().toInt();

  @override
  int? getLineNumberAt(int codeUnitOffset) {
    final int lineNumber = skiaObject.getLineNumberAt(codeUnitOffset.toDouble()).toInt();
    return lineNumber >= 0 ? lineNumber : null;
  }

  @override
  void dispose() {
    final deletable = skiaObject as SkDeletable;
    if (!deletable.isDeleted()) {
      deletable.delete();
    }
  }
}

class CkParagraphBuilder implements BackendParagraphBuilder {
  CkParagraphBuilder(EngineParagraphStyle style)
    : _style = style,
      _paragraphBuilder = canvasKit.ParagraphBuilder.MakeFromFontCollection(
        _toSkParagraphStyle(style),
        (CanvasKitRenderer.instance.fontCollection as SkiaFontCollection).skFontCollection,
      );

  final SkParagraphBuilder _paragraphBuilder;
  final EngineParagraphStyle _style;

  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment,
    double baselineOffset,
    ui.TextBaseline baseline,
  ) {
    _paragraphBuilder.addPlaceholder(
      width,
      height,
      toSkPlaceholderAlignment(alignment),
      toSkTextBaseline(baseline),
      baselineOffset,
    );
  }

  @override
  void addText(String text) {
    _paragraphBuilder.addText(text);
  }

  @override
  CkParagraph build() {
    _paragraphBuilder.injectClientICUIfNeeded();
    final SkParagraph builtParagraph = _paragraphBuilder.build();
    return CkParagraph(builtParagraph, _style);
  }

  @override
  void dispose() {
    _paragraphBuilder.delete();
  }

  @override
  void pop() {
    _paragraphBuilder.pop();
  }

  static SkPaint _createForegroundPaint(EngineTextStyle style) {
    final ui.Paint? foreground = style.foreground;
    if (foreground != null) {
      return (foreground as CkPaint).toSkPaint();
    }
    final skPaint = SkPaint();
    skPaint.setColorInt(style.color?.value ?? 0xFF000000);
    return skPaint;
  }

  static SkPaint _createBackgroundPaint(EngineTextStyle style) {
    final ui.Paint? background = style.background;
    if (background != null) {
      return (background as CkPaint).toSkPaint();
    }
    return SkPaint()..setColorInt(0x00000000);
  }

  @override
  void pushStyle(EngineTextStyle style, {required EngineTextStyle mergedStyle}) {
    final SkTextStyle skTextStyle = _toSkTextStyle(mergedStyle);
    if (mergedStyle.foreground != null || mergedStyle.background != null) {
      final SkPaint foreground = _createForegroundPaint(mergedStyle);
      final SkPaint background = _createBackgroundPaint(mergedStyle);
      _paragraphBuilder.pushPaintStyle(skTextStyle, foreground, background);
      foreground.delete();
      background.delete();
    } else {
      _paragraphBuilder.pushStyle(skTextStyle);
    }
  }
}

List<String> _computeCombinedFontFamilies(String? fontFamily, [List<String>? fontFamilyFallback]) {
  final fontFamilies = <String>[];
  if (fontFamily != null) {
    fontFamilies.add(fontFamily);
  }
  if (fontFamilyFallback != null &&
      !fontFamilyFallback.every((String font) => fontFamily == font)) {
    fontFamilies.addAll(fontFamilyFallback);
  }
  fontFamilies.addAll(renderer.fontCollection.fontFallbackManager.globalFontFallbacks);
  return fontFamilies;
}
