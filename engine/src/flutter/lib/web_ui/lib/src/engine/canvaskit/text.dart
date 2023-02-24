// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../util.dart';
import 'canvaskit_api.dart';
import 'font_fallbacks.dart';
import 'painting.dart';
import 'renderer.dart';
import 'skia_object_cache.dart';
import 'text_fragmenter.dart';
import 'util.dart';

@immutable
class CkParagraphStyle implements ui.ParagraphStyle {
  CkParagraphStyle({
    ui.TextAlign? textAlign,
    ui.TextDirection? textDirection,
    int? maxLines,
    String? fontFamily,
    double? fontSize,
    double? height,
    ui.TextHeightBehavior? textHeightBehavior,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.StrutStyle? strutStyle,
    String? ellipsis,
    ui.Locale? locale,
  })  : skParagraphStyle = toSkParagraphStyle(
          textAlign,
          textDirection,
          maxLines,
          ui.debugEmulateFlutterTesterEnvironment ? 'Ahem' : fontFamily,
          fontSize,
          height,
          textHeightBehavior,
          fontWeight,
          fontStyle,
          strutStyle,
          ellipsis,
          locale,
        ),
        _fontFamily = ui.debugEmulateFlutterTesterEnvironment ? 'Ahem' : fontFamily,
        _fontSize = fontSize,
        _height = height,
        _leadingDistribution = textHeightBehavior?.leadingDistribution,
        _fontWeight = fontWeight,
        _fontStyle = fontStyle;

  final SkParagraphStyle skParagraphStyle;
  final String? _fontFamily;
  final double? _fontSize;
  final double? _height;
  final ui.FontWeight? _fontWeight;
  final ui.FontStyle? _fontStyle;
  final ui.TextLeadingDistribution? _leadingDistribution;

  static SkTextStyleProperties toSkTextStyleProperties(
    String? fontFamily,
    double? fontSize,
    double? height,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
  ) {
    final SkTextStyleProperties skTextStyle = SkTextStyleProperties();
    if (fontWeight != null || fontStyle != null) {
      skTextStyle.fontStyle = toSkFontStyle(fontWeight, fontStyle);
    }

    if (fontSize != null) {
      skTextStyle.fontSize = fontSize;
    }

    if (height != null) {
      skTextStyle.heightMultiplier = height;
    }

    skTextStyle.fontFamilies = _getEffectiveFontFamilies(fontFamily);

    return skTextStyle;
  }

  static SkStrutStyleProperties toSkStrutStyleProperties(
      ui.StrutStyle value, ui.TextHeightBehavior? paragraphHeightBehavior) {
    final CkStrutStyle style = value as CkStrutStyle;
    final SkStrutStyleProperties skStrutStyle = SkStrutStyleProperties();
    skStrutStyle.fontFamilies =
        _getEffectiveFontFamilies(style._fontFamily, style._fontFamilyFallback);

    if (style._fontSize != null) {
      skStrutStyle.fontSize = style._fontSize;
    }

    if (style._height != null) {
      skStrutStyle.heightMultiplier = style._height;
    }

    final ui.TextLeadingDistribution? effectiveLeadingDistribution =
        style._leadingDistribution ??
            paragraphHeightBehavior?.leadingDistribution;
    switch (effectiveLeadingDistribution) {
      case null:
        break;
      case ui.TextLeadingDistribution.even:
        skStrutStyle.halfLeading = true;
        break;
      case ui.TextLeadingDistribution.proportional:
        skStrutStyle.halfLeading = false;
        break;
    }

    if (style._leading != null) {
      skStrutStyle.leading = style._leading;
    }

    if (style._fontWeight != null || style._fontStyle != null) {
      skStrutStyle.fontStyle =
          toSkFontStyle(style._fontWeight, style._fontStyle);
    }

    if (style._forceStrutHeight != null) {
      skStrutStyle.forceStrutHeight = style._forceStrutHeight;
    }

    skStrutStyle.strutEnabled = true;

    return skStrutStyle;
  }

  static SkParagraphStyle toSkParagraphStyle(
    ui.TextAlign? textAlign,
    ui.TextDirection? textDirection,
    int? maxLines,
    String? fontFamily,
    double? fontSize,
    double? height,
    ui.TextHeightBehavior? textHeightBehavior,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.StrutStyle? strutStyle,
    String? ellipsis,
    ui.Locale? locale,
  ) {
    final SkParagraphStyleProperties properties = SkParagraphStyleProperties();

    if (textAlign != null) {
      properties.textAlign = toSkTextAlign(textAlign);
    }

    if (textDirection != null) {
      properties.textDirection = toSkTextDirection(textDirection);
    }

    if (maxLines != null) {
      properties.maxLines = maxLines;
    }

    if (height != null) {
      properties.heightMultiplier = height;
    }

    if (textHeightBehavior != null) {
      properties.textHeightBehavior =
          toSkTextHeightBehavior(textHeightBehavior);
    }

    if (ellipsis != null) {
      properties.ellipsis = ellipsis;
    }

    if (strutStyle != null) {
      properties.strutStyle =
          toSkStrutStyleProperties(strutStyle, textHeightBehavior);
    }

    properties.replaceTabCharacters = true;
    properties.textStyle = toSkTextStyleProperties(
        fontFamily, fontSize, height, fontWeight, fontStyle);

    return canvasKit.ParagraphStyle(properties);
  }

  CkTextStyle getTextStyle() {
    return CkTextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize,
      height: _height,
      leadingDistribution: _leadingDistribution,
      fontWeight: _fontWeight,
      fontStyle: _fontStyle,
    );
  }
}

@immutable
class CkTextStyle implements ui.TextStyle {
  factory CkTextStyle({
    ui.Color? color,
    ui.TextDecoration? decoration,
    ui.Color? decorationColor,
    ui.TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.TextBaseline? textBaseline,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    ui.Locale? locale,
    CkPaint? background,
    CkPaint? foreground,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations,
  }) {
    return CkTextStyle._(
      color,
      decoration,
      decorationColor,
      decorationStyle,
      decorationThickness,
      fontWeight,
      fontStyle,
      textBaseline,
      ui.debugEmulateFlutterTesterEnvironment ? 'Ahem' : fontFamily,
      ui.debugEmulateFlutterTesterEnvironment ? null : fontFamilyFallback,
      fontSize,
      letterSpacing,
      wordSpacing,
      height,
      leadingDistribution,
      locale,
      background,
      foreground,
      shadows,
      fontFeatures,
      fontVariations,
    );
  }

  CkTextStyle._(
    this.color,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.fontWeight,
    this.fontStyle,
    this.textBaseline,
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontSize,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.leadingDistribution,
    this.locale,
    this.background,
    this.foreground,
    this.shadows,
    this.fontFeatures,
    this.fontVariations,
  );

  final ui.Color? color;
  final ui.TextDecoration? decoration;
  final ui.Color? decorationColor;
  final ui.TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final ui.FontWeight? fontWeight;
  final ui.FontStyle? fontStyle;
  final ui.TextBaseline? textBaseline;
  final String? fontFamily;
  final List<String>? fontFamilyFallback;
  final double? fontSize;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final ui.TextLeadingDistribution? leadingDistribution;
  final ui.Locale? locale;
  final CkPaint? background;
  final CkPaint? foreground;
  final List<ui.Shadow>? shadows;
  final List<ui.FontFeature>? fontFeatures;
  final List<ui.FontVariation>? fontVariations;

  /// Merges this text style with [other] and returns the new text style.
  ///
  /// The values in this text style are used unless [other] specifically
  /// overrides it.
  CkTextStyle mergeWith(CkTextStyle other) {
    return CkTextStyle(
      color: other.color ?? color,
      decoration: other.decoration ?? decoration,
      decorationColor: other.decorationColor ?? decorationColor,
      decorationStyle: other.decorationStyle ?? decorationStyle,
      decorationThickness: other.decorationThickness ?? decorationThickness,
      fontWeight: other.fontWeight ?? fontWeight,
      fontStyle: other.fontStyle ?? fontStyle,
      textBaseline: other.textBaseline ?? textBaseline,
      fontFamily: other.fontFamily ?? fontFamily,
      fontFamilyFallback: other.fontFamilyFallback ?? fontFamilyFallback,
      fontSize: other.fontSize ?? fontSize,
      letterSpacing: other.letterSpacing ?? letterSpacing,
      wordSpacing: other.wordSpacing ?? wordSpacing,
      height: other.height ?? height,
      leadingDistribution: other.leadingDistribution ?? leadingDistribution,
      locale: other.locale ?? locale,
      background: other.background ?? background,
      foreground: other.foreground ?? foreground,
      shadows: other.shadows ?? shadows,
      fontFeatures: other.fontFeatures ?? fontFeatures,
      fontVariations: other.fontVariations ?? fontVariations,
    );
  }

  /// Lazy-initialized list of font families sent to Skia.
  late final List<String> effectiveFontFamilies =
      _getEffectiveFontFamilies(fontFamily, fontFamilyFallback);

  /// Lazy-initialized Skia style used to pass the style to Skia.
  ///
  /// This is lazy because not every style ends up being passed to Skia, so the
  /// conversion would be wasteful.
  late final SkTextStyle skTextStyle = () {
    // Write field values to locals so null checks promote types to non-null.
    final ui.Color? color = this.color;
    final ui.TextDecoration? decoration = this.decoration;
    final ui.Color? decorationColor = this.decorationColor;
    final ui.TextDecorationStyle? decorationStyle = this.decorationStyle;
    final double? decorationThickness = this.decorationThickness;
    final ui.FontWeight? fontWeight = this.fontWeight;
    final ui.FontStyle? fontStyle = this.fontStyle;
    final ui.TextBaseline? textBaseline = this.textBaseline;
    final double? fontSize = this.fontSize;
    final double? letterSpacing = this.letterSpacing;
    final double? wordSpacing = this.wordSpacing;
    final double? height = this.height;
    final ui.Locale? locale = this.locale;
    final CkPaint? background = this.background;
    final CkPaint? foreground = this.foreground;
    final List<ui.Shadow>? shadows = this.shadows;
    final List<ui.FontFeature>? fontFeatures = this.fontFeatures;
    final List<ui.FontVariation>? fontVariations = this.fontVariations;

    final SkTextStyleProperties properties = SkTextStyleProperties();

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

    switch (leadingDistribution) {
      case null:
        break;
      case ui.TextLeadingDistribution.even:
        properties.halfLeading = true;
        break;
      case ui.TextLeadingDistribution.proportional:
        properties.halfLeading = false;
        break;
    }

    if (locale != null) {
      properties.locale = locale.toLanguageTag();
    }

    properties.fontFamilies = effectiveFontFamilies;

    if (fontWeight != null || fontStyle != null) {
      properties.fontStyle = toSkFontStyle(fontWeight, fontStyle);
    }

    if (foreground != null) {
      properties.foregroundColor = makeFreshSkColor(foreground.color);
    }

    if (shadows != null) {
      final List<SkTextShadow> ckShadows = <SkTextShadow>[];
      for (final ui.Shadow shadow in shadows) {
        final SkTextShadow ckShadow = SkTextShadow();
        ckShadow.color = makeFreshSkColor(shadow.color);
        ckShadow.offset = toSkPoint(shadow.offset);
        ckShadow.blurRadius = shadow.blurRadius;
        ckShadows.add(ckShadow);
      }
      properties.shadows = ckShadows;
    }

    if (fontFeatures != null) {
      final List<SkFontFeature> skFontFeatures = <SkFontFeature>[];
      for (final ui.FontFeature fontFeature in fontFeatures) {
        final SkFontFeature skFontFeature = SkFontFeature();
        skFontFeature.name = fontFeature.feature;
        skFontFeature.value = fontFeature.value;
        skFontFeatures.add(skFontFeature);
      }
      properties.fontFeatures = skFontFeatures;
    }

    if (fontVariations != null) {
      final List<SkFontVariation> skFontVariations = <SkFontVariation>[];
      for (final ui.FontVariation fontVariation in fontVariations) {
        final SkFontVariation skFontVariation = SkFontVariation();
        skFontVariation.axis = fontVariation.axis;
        skFontVariation.value = fontVariation.value;
        skFontVariations.add(skFontVariation);
      }
      properties.fontVariations = skFontVariations;
    }

    return canvasKit.TextStyle(properties);
  }();
}

class CkStrutStyle implements ui.StrutStyle {
  CkStrutStyle({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? height,
    // TODO(mdebbar): implement leadingDistribution.
    ui.TextLeadingDistribution? leadingDistribution,
    double? leading,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    bool? forceStrutHeight,
  })  : _fontFamily = ui.debugEmulateFlutterTesterEnvironment ? 'Ahem' : fontFamily,
        _fontFamilyFallback = ui.debugEmulateFlutterTesterEnvironment ? null : fontFamilyFallback,
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
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CkStrutStyle &&
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
  int get hashCode => Object.hash(
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

SkFontStyle toSkFontStyle(ui.FontWeight? fontWeight, ui.FontStyle? fontStyle) {
  final SkFontStyle style = SkFontStyle();
  if (fontWeight != null) {
    style.weight = toSkFontWeight(fontWeight);
  }
  if (fontStyle != null) {
    style.slant = toSkFontSlant(fontStyle);
  }
  return style;
}

/// The CanvasKit implementation of [ui.Paragraph].
///
/// This class does not use [ManagedSkiaObject] because it requires that its
/// memory is reclaimed synchronously. This protects our memory usage from
/// blowing up if within a single frame the framework needs to layout a lot of
/// paragraphs. One common use-case is `ListView.builder`, which needs to layout
/// more of its content than it actually renders to compute the scroll position.
/// More generally, this protects from the pattern of laying out a lot of text
/// while painting a small subset of it. To achieve this a
/// [SynchronousSkiaObjectCache] is used that limits the number of live laid out
/// paragraphs at any point in time within or outside the frame.
class CkParagraph extends SkiaObject<SkParagraph> implements ui.Paragraph {
  CkParagraph(this._skParagraph, this._paragraphStyle, this._paragraphCommands);

  /// The result of calling `build()` on the JS CkParagraphBuilder.
  ///
  /// This may be invalidated later.
  SkParagraph? _skParagraph;

  /// The paragraph style used to build this paragraph.
  ///
  /// This is used to resurrect the paragraph if the initial paragraph
  /// is deleted.
  final CkParagraphStyle _paragraphStyle;

  /// The paragraph builder commands used to build this paragraph.
  ///
  /// This is used to resurrect the paragraph if the initial paragraph
  /// is deleted.
  final List<_ParagraphCommand> _paragraphCommands;

  /// The constraints from the last time we laid the paragraph out.
  ///
  /// This is used to resurrect the paragraph if the initial paragraph
  /// is deleted.
  ui.ParagraphConstraints? _lastLayoutConstraints;

  @override
  SkParagraph get skiaObject => _ensureInitialized(_lastLayoutConstraints!);

  SkParagraph _ensureInitialized(ui.ParagraphConstraints constraints) {
    SkParagraph? paragraph = _skParagraph;

    // Paragraph objects are immutable. It's OK to skip initialization and reuse
    // existing object.
    bool didRebuildSkiaObject = false;
    if (paragraph == null) {
      final CkParagraphBuilder builder = CkParagraphBuilder(_paragraphStyle);
      for (final _ParagraphCommand command in _paragraphCommands) {
        switch (command.type) {
          case _ParagraphCommandType.addText:
            builder.addText(command.text!);
            break;
          case _ParagraphCommandType.pop:
            builder.pop();
            break;
          case _ParagraphCommandType.pushStyle:
            builder.pushStyle(command.style!);
            break;
          case _ParagraphCommandType.addPlaceholder:
            builder._addPlaceholder(command.placeholderStyle!);
            break;
        }
      }
      paragraph = builder._buildSkParagraph();
      _skParagraph = paragraph;
      didRebuildSkiaObject = true;
    }

    final bool constraintsChanged = _lastLayoutConstraints != constraints;
    if (didRebuildSkiaObject || constraintsChanged) {
      _lastLayoutConstraints = constraints;
      // TODO(het): CanvasKit throws an exception when laid out with
      // a font that wasn't registered.
      try {
        paragraph.layout(constraints.width);
        _alphabeticBaseline = paragraph.getAlphabeticBaseline();
        _didExceedMaxLines = paragraph.didExceedMaxLines();
        _height = paragraph.getHeight();
        _ideographicBaseline = paragraph.getIdeographicBaseline();
        _longestLine = paragraph.getLongestLine();
        _maxIntrinsicWidth = paragraph.getMaxIntrinsicWidth();
        _minIntrinsicWidth = paragraph.getMinIntrinsicWidth();
        _width = paragraph.getMaxWidth();
        _boxesForPlaceholders =
            skRectsToTextBoxes(
                paragraph.getRectsForPlaceholders().cast<SkRectWithDirection>());
      } catch (e) {
        printWarning('CanvasKit threw an exception while laying '
            'out the paragraph. The font was "${_paragraphStyle._fontFamily}". '
            'Exception:\n$e');
        rethrow;
      }
    }

    return paragraph;
  }

  // Caches laid out paragraphs and synchronously reclaims memory if there's
  // memory pressure.
  //
  // On May 26, 2021, 500 seemed like a reasonable number to pick for the cache
  // size. At the time a single laid out SkParagraph used 100KB of memory. So,
  // 500 items in the cache is roughly 50MB of memory, which is not too high,
  // while at the same time enough for most use-cases.
  //
  // TODO(yjbanov): this strategy is not sufficient for the use-case where a
  //                lot of paragraphs are laid out _and_ rendered. To support
  //                this use-case without blowing up memory usage we need this:
  //                https://github.com/flutter/flutter/issues/81224
  static final SynchronousSkiaObjectCache _paragraphCache =
      SynchronousSkiaObjectCache(500);

  /// Marks this paragraph as having been used this frame.
  ///
  /// Puts this paragraph in a [SynchronousSkiaObjectCache], which will delete it
  /// if there's memory pressure to do so. This protects our memory usage from
  /// blowing up if within a single frame the framework needs to layout a lot of
  /// paragraphs. One common use-case is `ListView.builder`, which needs to layout
  /// more of its content than it actually renders to compute the scroll position.
  void markUsed() {
    // If the paragraph is already in the cache, just mark it as most recently
    // used. Otherwise, add to cache.
    if (!_paragraphCache.markUsed(this)) {
      _paragraphCache.add(this);
    }
  }

  @override
  void delete() {
    _skParagraph?.delete();
    _skParagraph = null;
  }

  @override
  void didDelete() {
    _skParagraph = null;
  }

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
    if (start < 0 || end < 0) {
      return const <ui.TextBox>[];
    }

    final SkParagraph paragraph = _ensureInitialized(_lastLayoutConstraints!);
    final List<SkRectWithDirection> skRects = paragraph.getRectsForRange(
      start.toDouble(),
      end.toDouble(),
      toSkRectHeightStyle(boxHeightStyle),
      toSkRectWidthStyle(boxWidthStyle),
    ).cast<SkRectWithDirection>();

    return skRectsToTextBoxes(skRects);
  }

  List<ui.TextBox> skRectsToTextBoxes(List<SkRectWithDirection> skRects) {
    final List<ui.TextBox> result = <ui.TextBox>[];

    for (int i = 0; i < skRects.length; i++) {
      final SkRectWithDirection skRect = skRects[i];
      final Float32List rect = skRect.rect;
      final int skTextDirection = skRect.dir.value.toInt();
      result.add(ui.TextBox.fromLTRBD(
        rect[0],
        rect[1],
        rect[2],
        rect[3],
        ui.TextDirection.values[skTextDirection],
      ));
    }

    return result;
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    final SkParagraph paragraph = _ensureInitialized(_lastLayoutConstraints!);
    final SkTextPosition positionWithAffinity =
        paragraph.getGlyphPositionAtCoordinate(
      offset.dx,
      offset.dy,
    );
    return fromPositionWithAffinity(positionWithAffinity);
  }

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    final SkParagraph paragraph = _ensureInitialized(_lastLayoutConstraints!);
    final int characterPosition;
    switch (position.affinity) {
      case ui.TextAffinity.upstream:
        characterPosition = position.offset - 1;
        break;
      case ui.TextAffinity.downstream:
        characterPosition = position.offset;
        break;
    }
    final SkTextRange skRange = paragraph.getWordBoundary(characterPosition.toDouble());
    return ui.TextRange(start: skRange.start.toInt(), end: skRange.end.toInt());
  }

  @override
  void layout(ui.ParagraphConstraints constraints) {
    if (_lastLayoutConstraints == constraints) {
      return;
    }
    _ensureInitialized(constraints);

    // See class-level and _paragraphCache doc comments for why we're releasing
    // the paragraph immediately after layout.
    markUsed();
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    final SkParagraph paragraph = _ensureInitialized(_lastLayoutConstraints!);
    final List<SkLineMetrics> metrics =
        paragraph.getLineMetrics().cast<SkLineMetrics>();
    final int offset = position.offset;
    for (final SkLineMetrics metric in metrics) {
      if (offset >= metric.startIndex && offset <= metric.endIndex) {
        return ui.TextRange(start: metric.startIndex.toInt(), end: metric.endIndex.toInt());
      }
    }
    return ui.TextRange.empty;
  }

  @override
  List<ui.LineMetrics> computeLineMetrics() {
    final SkParagraph paragraph = _ensureInitialized(_lastLayoutConstraints!);
    final List<SkLineMetrics> skLineMetrics =
        paragraph.getLineMetrics().cast<SkLineMetrics>();
    final List<ui.LineMetrics> result = <ui.LineMetrics>[];
    for (final SkLineMetrics metric in skLineMetrics) {
      result.add(CkLineMetrics._(metric));
    }
    return result;
  }

  bool _disposed = false;

  @override
  void dispose() {
    delete();
    didDelete();
    _disposed = true;
  }

  @override
  bool get debugDisposed {
    if (assertionsEnabled) {
      return _disposed;
    }
    throw StateError('Paragraph.debugDisposed is only available when asserts are enabled.');
  }
}

class CkLineMetrics implements ui.LineMetrics {
  CkLineMetrics._(this.skLineMetrics);

  final SkLineMetrics skLineMetrics;

  @override
  double get ascent => skLineMetrics.ascent;

  @override
  double get descent => skLineMetrics.descent;

  // TODO(hterkelsen): Implement this correctly once SkParagraph does.
  @override
  double get unscaledAscent => skLineMetrics.ascent;

  @override
  bool get hardBreak => skLineMetrics.isHardBreak;

  @override
  double get baseline => skLineMetrics.baseline;

  @override
  double get height =>
      (skLineMetrics.ascent + skLineMetrics.descent).round().toDouble();

  @override
  double get left => skLineMetrics.left;

  @override
  double get width => skLineMetrics.width;

  @override
  int get lineNumber => skLineMetrics.lineNumber.toInt();
}

class CkParagraphBuilder implements ui.ParagraphBuilder {
  CkParagraphBuilder(ui.ParagraphStyle style)
      : _commands = <_ParagraphCommand>[],
        _style = style as CkParagraphStyle,
        _placeholderCount = 0,
        _placeholderScales = <double>[],
        _styleStack = <CkTextStyle>[],
        _paragraphBuilder = canvasKit.ParagraphBuilder.MakeFromFontProvider(
          style.skParagraphStyle,
          CanvasKitRenderer.instance.fontCollection.fontProvider,
        ) {
    _styleStack.add(_style.getTextStyle());
  }

  final SkParagraphBuilder _paragraphBuilder;
  final CkParagraphStyle _style;
  final List<_ParagraphCommand> _commands;
  int _placeholderCount;
  final List<double> _placeholderScales;
  final List<CkTextStyle> _styleStack;

  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    double scale = 1.0,
    double? baselineOffset,
    ui.TextBaseline? baseline,
  }) {
    // Require a baseline to be specified if using a baseline-based alignment.
    assert(!(alignment == ui.PlaceholderAlignment.aboveBaseline ||
            alignment == ui.PlaceholderAlignment.belowBaseline ||
            alignment == ui.PlaceholderAlignment.baseline) || baseline != null);

    _placeholderCount++;
    _placeholderScales.add(scale);
    final _CkParagraphPlaceholder placeholderStyle = toSkPlaceholderStyle(
      width * scale,
      height * scale,
      alignment,
      (baselineOffset ?? height) * scale,
      baseline ?? ui.TextBaseline.alphabetic,
    );
    _addPlaceholder(placeholderStyle);
  }

  void _addPlaceholder(_CkParagraphPlaceholder placeholderStyle) {
    _commands.add(_ParagraphCommand.addPlaceholder(placeholderStyle));
    _paragraphBuilder.addPlaceholder(
      placeholderStyle.width,
      placeholderStyle.height,
      placeholderStyle.alignment,
      placeholderStyle.baseline,
      placeholderStyle.offset,
    );
  }

  static _CkParagraphPlaceholder toSkPlaceholderStyle(
    double width,
    double height,
    ui.PlaceholderAlignment alignment,
    double baselineOffset,
    ui.TextBaseline baseline,
  ) {
    final _CkParagraphPlaceholder properties = _CkParagraphPlaceholder(
      width: width,
      height: height,
      alignment: toSkPlaceholderAlignment(alignment),
      offset: baselineOffset,
      baseline: toSkTextBaseline(baseline),
    );
    return properties;
  }

  @override
  void addText(String text) {
    final List<String> fontFamilies = <String>[];
    final CkTextStyle style = _peekStyle();
    if (style.fontFamily != null) {
      fontFamilies.add(style.fontFamily!);
    }
    if (style.fontFamilyFallback != null) {
      fontFamilies.addAll(style.fontFamilyFallback!);
    }
    FontFallbackData.instance.ensureFontsSupportText(text, fontFamilies);
    _commands.add(_ParagraphCommand.addText(text));
    _paragraphBuilder.addText(text);
  }

  @override
  CkParagraph build() {
    final SkParagraph builtParagraph = _buildSkParagraph();
    return CkParagraph(builtParagraph, _style, _commands);
  }

  /// Builds the CkParagraph with the builder and deletes the builder.
  SkParagraph _buildSkParagraph() {
    if (browserSupportsCanvaskitChromium) {
      final String text = _paragraphBuilder.getText();
      _paragraphBuilder.setWordsUtf16(
        fragmentUsingIntlSegmenter(text, IntlSegmenterGranularity.word),
      );
      _paragraphBuilder.setGraphemeBreaksUtf16(
        fragmentUsingIntlSegmenter(text, IntlSegmenterGranularity.grapheme),
      );
      _paragraphBuilder.setLineBreaksUtf16(fragmentUsingV8LineBreaker(text));
    }
    final SkParagraph result = _paragraphBuilder.build();
    _paragraphBuilder.delete();
    return result;
  }

  @override
  int get placeholderCount => _placeholderCount;

  @override
  List<double> get placeholderScales => _placeholderScales;

  @override
  void pop() {
    if (_styleStack.length <= 1) {
      // The top-level text style is paragraph-level. We don't pop it off.
      if (assertionsEnabled) {
        printWarning(
          'Cannot pop text style in ParagraphBuilder. '
          'Already popped all text styles from the style stack.',
        );
      }
      return;
    }
    _commands.add(const _ParagraphCommand.pop());
    _styleStack.removeLast();
    _paragraphBuilder.pop();
  }

  CkTextStyle _peekStyle() {
    assert(_styleStack.isNotEmpty);
    return _styleStack.last;
  }

  // Used as the paint for background or foreground in the text style when
  // the other one is not specified. CanvasKit either both background and
  // foreground paints specified, or neither, but Flutter allows one of them
  // to go unspecified.
  //
  // This object is never deleted. It is effectively a static global constant.
  // Therefore it doesn't need to be wrapped in CkPaint.
  static final SkPaint _defaultTextForeground = SkPaint();
  static final SkPaint _defaultTextBackground = SkPaint()
    ..setColorInt(0x00000000);

  @override
  void pushStyle(ui.TextStyle style) {
    final CkTextStyle baseStyle = _peekStyle();
    final CkTextStyle ckStyle = style as CkTextStyle;
    final CkTextStyle skStyle = baseStyle.mergeWith(ckStyle);
    _styleStack.add(skStyle);
    _commands.add(_ParagraphCommand.pushStyle(ckStyle));
    if (skStyle.foreground != null || skStyle.background != null) {
      SkPaint? foreground = skStyle.foreground?.skiaObject;
      if (foreground == null) {
        _defaultTextForeground.setColorInt(
          (skStyle.color?.value ?? 0xFF000000).toDouble(),
        );
        foreground = _defaultTextForeground;
      }

      final SkPaint background =
          skStyle.background?.skiaObject ?? _defaultTextBackground;
      _paragraphBuilder.pushPaintStyle(
          skStyle.skTextStyle, foreground, background);
    } else {
      _paragraphBuilder.pushStyle(skStyle.skTextStyle);
    }
  }
}

class _CkParagraphPlaceholder {
  _CkParagraphPlaceholder({
    required this.width,
    required this.height,
    required this.alignment,
    required this.baseline,
    required this.offset,
  });

  final double width;
  final double height;
  final SkPlaceholderAlignment alignment;
  final SkTextBaseline baseline;
  final double offset;
}

class _ParagraphCommand {
  const _ParagraphCommand._(
    this.type,
    this.text,
    this.style,
    this.placeholderStyle,
  );

  const _ParagraphCommand.addText(String text)
      : this._(_ParagraphCommandType.addText, text, null, null);

  const _ParagraphCommand.pop()
      : this._(_ParagraphCommandType.pop, null, null, null);

  const _ParagraphCommand.pushStyle(CkTextStyle style)
      : this._(_ParagraphCommandType.pushStyle, null, style, null);

  const _ParagraphCommand.addPlaceholder(
      _CkParagraphPlaceholder placeholderStyle)
      : this._(
            _ParagraphCommandType.addPlaceholder, null, null, placeholderStyle);

  final _ParagraphCommandType type;
  final String? text;
  final CkTextStyle? style;
  final _CkParagraphPlaceholder? placeholderStyle;
}

enum _ParagraphCommandType {
  addText,
  pop,
  pushStyle,
  addPlaceholder,
}

List<String> _getEffectiveFontFamilies(String? fontFamily,
    [List<String>? fontFamilyFallback]) {
  final List<String> fontFamilies = <String>[];
  if (fontFamily != null) {
    fontFamilies.add(fontFamily);
  }
  if (fontFamilyFallback != null &&
      !fontFamilyFallback.every((String font) => fontFamily == font)) {
    fontFamilies.addAll(fontFamilyFallback);
  }
  fontFamilies.addAll(FontFallbackData.instance.globalFontFallbacks);
  return fontFamilies;
}
