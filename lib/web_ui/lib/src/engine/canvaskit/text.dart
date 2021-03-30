// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

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
          fontFamily,
          fontSize,
          height,
          textHeightBehavior,
          fontWeight,
          fontStyle,
          strutStyle,
          ellipsis,
          locale,
        ),
        _textDirection = textDirection ?? ui.TextDirection.ltr,
        _fontFamily = fontFamily,
        _fontSize = fontSize,
        _fontWeight = fontWeight,
        _fontStyle = fontStyle;

  final SkParagraphStyle skParagraphStyle;
  final ui.TextDirection? _textDirection;
  final String? _fontFamily;
  final double? _fontSize;
  final ui.FontWeight? _fontWeight;
  final ui.FontStyle? _fontStyle;

  static SkTextStyleProperties toSkTextStyleProperties(
    String? fontFamily,
    double? fontSize,
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

    skTextStyle.fontFamilies = _getEffectiveFontFamilies(fontFamily);

    return skTextStyle;
  }

  static SkStrutStyleProperties toSkStrutStyleProperties(ui.StrutStyle value) {
    EngineStrutStyle style = value as EngineStrutStyle;
    final SkStrutStyleProperties skStrutStyle = SkStrutStyleProperties();
    skStrutStyle.fontFamilies =
        _getEffectiveFontFamilies(style._fontFamily, style._fontFamilyFallback);

    if (style._fontSize != null) {
      skStrutStyle.fontSize = style._fontSize;
    }

    if (style._height != null) {
      skStrutStyle.heightMultiplier = style._height;
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
      properties.textHeightBehavior = textHeightBehavior.encode();
    }

    if (ellipsis != null) {
      properties.ellipsis = ellipsis;
    }

    if (strutStyle != null) {
      properties.strutStyle = toSkStrutStyleProperties(strutStyle);
    }

    properties.textStyle =
        toSkTextStyleProperties(fontFamily, fontSize, fontWeight, fontStyle);

    return canvasKit.ParagraphStyle(properties);
  }

  CkTextStyle getTextStyle() {
    return CkTextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize,
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
    ui.Locale? locale,
    CkPaint? background,
    CkPaint? foreground,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
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
      fontFeatures,
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
    this.locale,
    this.background,
    this.foreground,
    this.shadows,
    this.fontFeatures,
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
  final ui.Locale? locale;
  final CkPaint? background;
  final CkPaint? foreground;
  final List<ui.Shadow>? shadows;
  final List<ui.FontFeature>? fontFeatures;

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
      locale: other.locale ?? locale,
      background: other.background ?? background,
      foreground: other.foreground ?? foreground,
      shadows: other.shadows ?? shadows,
      fontFeatures: other.fontFeatures ?? fontFeatures,
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

    final SkTextStyleProperties properties = SkTextStyleProperties();

    if (background != null) {
      properties.backgroundColor = makeFreshSkColor(background.color);
    }

    if (color != null) {
      properties.color = makeFreshSkColor(color);
    }

    if (decoration != null) {
      int decorationValue = canvasKit.NoDecoration;
      if (decoration.contains(ui.TextDecoration.underline)) {
        decorationValue |= canvasKit.UnderlineDecoration;
      }
      if (decoration.contains(ui.TextDecoration.overline)) {
        decorationValue |= canvasKit.OverlineDecoration;
      }
      if (decoration.contains(ui.TextDecoration.lineThrough)) {
        decorationValue |= canvasKit.LineThroughDecoration;
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
      List<SkTextShadow> ckShadows = <SkTextShadow>[];
      for (ui.Shadow shadow in shadows) {
        final ckShadow = SkTextShadow();
        ckShadow.color = makeFreshSkColor(shadow.color);
        ckShadow.offset = toSkPoint(shadow.offset);
        ckShadow.blurRadius = shadow.blurRadius;
        ckShadows.add(ckShadow);
      }
      properties.shadows = ckShadows;
    }

    if (fontFeatures != null) {
      List<SkFontFeature> skFontFeatures = <SkFontFeature>[];
      for (ui.FontFeature fontFeature in fontFeatures) {
        SkFontFeature skFontFeature = SkFontFeature();
        skFontFeature.name = fontFeature.feature;
        skFontFeature.value = fontFeature.value;
        skFontFeatures.add(skFontFeature);
      }
      properties.fontFeatures = skFontFeatures;
    }

    return canvasKit.TextStyle(properties);
  }();
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

class CkParagraph extends ManagedSkiaObject<SkParagraph>
    implements ui.Paragraph {
  CkParagraph(
      this._initialParagraph, this._paragraphStyle, this._paragraphCommands);

  /// The result of calling `build()` on the JS CkParagraphBuilder.
  ///
  /// This may be invalidated later.
  final SkParagraph _initialParagraph;

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

  /// The constraints from the last time we layed the paragraph out.
  ///
  /// This is used to resurrect the paragraph if the initial paragraph
  /// is deleted.
  ui.ParagraphConstraints? _lastLayoutConstraints;

  @override
  SkParagraph createDefault() => _initialParagraph;

  @override
  SkParagraph resurrect() {
    final builder = CkParagraphBuilder(_paragraphStyle);
    for (_ParagraphCommand command in _paragraphCommands) {
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

    final SkParagraph result = builder._buildCkParagraph();
    if (_lastLayoutConstraints != null) {
      // We need to set the Skia object early so layout works.
      rawSkiaObject = result;
      this.layout(_lastLayoutConstraints!);
    }
    return result;
  }

  @override
  void delete() {
    rawSkiaObject?.delete();
  }

  @override
  bool get isResurrectionExpensive => true;

  @override
  double get alphabeticBaseline => skiaObject.getAlphabeticBaseline();

  @override
  bool get didExceedMaxLines => skiaObject.didExceedMaxLines();

  @override
  double get height => skiaObject.getHeight();

  @override
  double get ideographicBaseline => skiaObject.getIdeographicBaseline();

  @override
  double get longestLine => skiaObject.getLongestLine();

  @override
  double get maxIntrinsicWidth => skiaObject.getMaxIntrinsicWidth();

  @override
  double get minIntrinsicWidth => skiaObject.getMinIntrinsicWidth();

  @override
  double get width => skiaObject.getMaxWidth();

  @override
  List<ui.TextBox> getBoxesForPlaceholders() {
    List<List<double>> skRects = skiaObject.getRectsForPlaceholders();
    return skRectsToTextBoxes(skRects);
  }

  @override
  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle boxHeightStyle: ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle: ui.BoxWidthStyle.tight,
  }) {
    if (start < 0 || end < 0) {
      return const <ui.TextBox>[];
    }

    List<List<double>> skRects = skiaObject.getRectsForRange(
      start,
      end,
      toSkRectHeightStyle(boxHeightStyle),
      toSkRectWidthStyle(boxWidthStyle),
    );

    return skRectsToTextBoxes(skRects);
  }

  List<ui.TextBox> skRectsToTextBoxes(List<List<double>> skRects) {
    List<ui.TextBox> result = <ui.TextBox>[];

    for (int i = 0; i < skRects.length; i++) {
      final List<double> rect = skRects[i];
      result.add(ui.TextBox.fromLTRBD(
        rect[0],
        rect[1],
        rect[2],
        rect[3],
        _paragraphStyle._textDirection!,
      ));
    }

    return result;
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    final SkTextPosition positionWithAffinity =
        skiaObject.getGlyphPositionAtCoordinate(
      offset.dx,
      offset.dy,
    );
    return fromPositionWithAffinity(positionWithAffinity);
  }

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    final SkTextRange skRange = skiaObject.getWordBoundary(position.offset);
    return ui.TextRange(start: skRange.start, end: skRange.end);
  }

  @override
  void layout(ui.ParagraphConstraints constraints) {
    _lastLayoutConstraints = constraints;

    // TODO(het): CanvasKit throws an exception when laid out with
    // a font that wasn't registered.
    try {
      skiaObject.layout(constraints.width);
    } catch (e) {
      printWarning('CanvasKit threw an exception while laying '
          'out the paragraph. The font was "${_paragraphStyle._fontFamily}". '
          'Exception:\n$e');
      rethrow;
    }
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    final List<SkLineMetrics> metrics = skiaObject.getLineMetrics();
    final int offset = position.offset;
    for (final SkLineMetrics metric in metrics) {
      if (offset >= metric.startIndex && offset <= metric.endIndex) {
        return ui.TextRange(start: metric.startIndex, end: metric.endIndex);
      }
    }
    return ui.TextRange(start: -1, end: -1);
  }

  @override
  List<ui.LineMetrics> computeLineMetrics() {
    final List<SkLineMetrics> skLineMetrics = skiaObject.getLineMetrics();
    final List<ui.LineMetrics> result = <ui.LineMetrics>[];
    for (final SkLineMetrics metric in skLineMetrics) {
      result.add(CkLineMetrics._(metric));
    }
    return result;
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
  int get lineNumber => skLineMetrics.lineNumber;
}

class CkParagraphBuilder implements ui.ParagraphBuilder {
  final SkParagraphBuilder _paragraphBuilder;
  final CkParagraphStyle _style;
  final List<_ParagraphCommand> _commands;
  int _placeholderCount;
  final List<double> _placeholderScales;
  final List<CkTextStyle> _styleStack;

  CkParagraphBuilder(ui.ParagraphStyle style)
      : _commands = <_ParagraphCommand>[],
        _style = style as CkParagraphStyle,
        _placeholderCount = 0,
        _placeholderScales = <double>[],
        _styleStack = <CkTextStyle>[],
        _paragraphBuilder = canvasKit.ParagraphBuilder.MakeFromFontProvider(
          style.skParagraphStyle,
          skiaFontCollection.fontProvider,
        ) {
    _styleStack.add(_style.getTextStyle());
  }

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
    assert((alignment == ui.PlaceholderAlignment.aboveBaseline ||
            alignment == ui.PlaceholderAlignment.belowBaseline ||
            alignment == ui.PlaceholderAlignment.baseline)
        ? baseline != null
        : true);

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
    final properties = _CkParagraphPlaceholder(
      width: width,
      height: height,
      alignment: toSkPlaceholderAlignment(alignment),
      offset: baselineOffset,
      baseline: toSkTextBaseline(baseline),
    );
    return properties;
  }

  /// Determines if the given [text] contains any code points which are not
  /// supported by the current set of fonts.
  void _ensureFontsSupportText(String text) {
    // TODO(hterkelsen): Make this faster for the common case where the text
    // is supported by the given fonts.

    // A list of unique code units in the text.
    final List<int> codeUnits = text.runes.toSet().toList();

    // First, check if every code unit in the text is known to be covered by one
    // of our global fallback fonts. We cache the set of code units covered by
    // the global fallback fonts since this set is growing monotonically over
    // the lifetime of the app.
    if (_checkIfGlobalFallbacksSupport(codeUnits)) {
      return;
    }

    // Next, check if all of the remaining code units are ones which are known
    // to have no global font fallback. This means we know of no font we can
    // download which will cover the remaining code units. In this case we can
    // just skip the checks below, since we know there's nothing we can do to
    // cover the code units.
    if (_checkIfNoFallbackFontSupports(codeUnits)) {
      return;
    }

    // If the text is ASCII, then skip this check.
    bool isAscii = true;
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) >= 160) {
        isAscii = false;
        break;
      }
    }
    if (isAscii) {
      return;
    }

    CkTextStyle style = _peekStyle();
    List<String> fontFamilies = <String>[];
    if (style.fontFamily != null) {
      fontFamilies.add(style.fontFamily!);
    }
    if (style.fontFamilyFallback != null) {
      fontFamilies.addAll(style.fontFamilyFallback!);
    }
    List<SkTypeface> typefaces = <SkTypeface>[];
    for (var font in fontFamilies) {
      List<SkTypeface>? typefacesForFamily =
          skiaFontCollection.familyToTypefaceMap[font];
      if (typefacesForFamily != null) {
        typefaces.addAll(typefacesForFamily);
      }
    }
    List<bool> codeUnitsSupported = List<bool>.filled(codeUnits.length, false);
    String testString = String.fromCharCodes(codeUnits);
    for (SkTypeface typeface in typefaces) {
      SkFont font = SkFont(typeface);
      Uint8List glyphs = font.getGlyphIDs(testString);
      assert(glyphs.length == codeUnitsSupported.length);
      for (int i = 0; i < glyphs.length; i++) {
        codeUnitsSupported[i] |= glyphs[i] != 0 || _isControlCode(codeUnits[i]);
      }
    }

    if (codeUnitsSupported.any((x) => !x)) {
      List<int> missingCodeUnits = <int>[];
      for (int i = 0; i < codeUnitsSupported.length; i++) {
        if (!codeUnitsSupported[i]) {
          missingCodeUnits.add(codeUnits[i]);
        }
      }
      findFontsForMissingCodeunits(missingCodeUnits);
    }
  }

  /// Returns [true] if [codepoint] is a Unicode control code.
  bool _isControlCode(int codepoint) {
    return codepoint < 32 || (codepoint > 127 && codepoint < 160);
  }

  /// Returns `true` if every code unit in [codeUnits] is covered by a global
  /// fallback font.
  ///
  /// Calling this method has 2 side effects:
  ///   1. Updating the cache of known covered code units in the
  ///      [FontFallbackData] instance.
  ///   2. Removing known covered code units from [codeUnits]. When the list
  ///      is used again in [_ensureFontsSupportText]
  bool _checkIfGlobalFallbacksSupport(List<int> codeUnits) {
    final FontFallbackData fallbackData = FontFallbackData.instance;
    codeUnits.removeWhere((int codeUnit) =>
        fallbackData.knownCoveredCodeUnits.contains(codeUnit));
    if (codeUnits.isEmpty) {
      return true;
    }

    // We don't know if the remaining code units are covered by our fallback
    // fonts. Check them and update the cache.
    List<bool> codeUnitsSupported = List<bool>.filled(codeUnits.length, false);
    String testString = String.fromCharCodes(codeUnits);

    for (String font in fallbackData.globalFontFallbacks) {
      List<SkTypeface>? typefacesForFamily =
          skiaFontCollection.familyToTypefaceMap[font];
      if (typefacesForFamily == null) {
        printWarning('A fallback font was registered but we '
            'cannot retrieve the typeface for it.');
        continue;
      }
      for (SkTypeface typeface in typefacesForFamily) {
        SkFont font = SkFont(typeface);
        Uint8List glyphs = font.getGlyphIDs(testString);
        assert(glyphs.length == codeUnitsSupported.length);
        for (int i = 0; i < glyphs.length; i++) {
          bool codeUnitSupported = glyphs[i] != 0;
          if (codeUnitSupported) {
            fallbackData.knownCoveredCodeUnits.add(codeUnits[i]);
          }
          codeUnitsSupported[i] |=
              codeUnitSupported || _isControlCode(codeUnits[i]);
        }
      }

      // Once we've checked every typeface for this family, check to see if
      // every code unit has been covered in order to avoid unnecessary checks.
      bool keepGoing = false;
      for (bool supported in codeUnitsSupported) {
        if (!supported) {
          keepGoing = true;
          break;
        }
      }

      if (!keepGoing) {
        // Every code unit is supported, clear [codeUnits] and return `true`.
        codeUnits.clear();
        return true;
      }
    }

    // If we reached here, then there are some code units which aren't covered
    // by the global fallback fonts. Remove the ones which were covered and
    // return false.
    for (int i = codeUnits.length - 1; i >= 0; i--) {
      if (codeUnitsSupported[i]) {
        codeUnits.removeAt(i);
      }
    }
    return false;
  }

  /// Returns `true` if every code unit in [codeUnits] is known to not have any
  /// fallback font which can cover it.
  ///
  /// This method has a side effect of removing every code unit from [codeUnits]
  /// which is known not to have a fallback font which covers it.
  bool _checkIfNoFallbackFontSupports(List<int> codeUnits) {
    final FontFallbackData fallbackData = FontFallbackData.instance;
    codeUnits.removeWhere((int codeUnit) =>
        fallbackData.codeUnitsWithNoKnownFont.contains(codeUnit));
    return codeUnits.isEmpty;
  }

  @override
  void addText(String text) {
    _ensureFontsSupportText(text);
    _commands.add(_ParagraphCommand.addText(text));
    _paragraphBuilder.addText(text);
  }

  @override
  CkParagraph build() {
    final builtParagraph = _buildCkParagraph();
    return CkParagraph(builtParagraph, _style, _commands);
  }

  /// Builds the CkParagraph with the builder and deletes the builder.
  SkParagraph _buildCkParagraph() {
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
          skStyle.color?.value ?? 0xFF000000,
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
  final _ParagraphCommandType type;
  final String? text;
  final CkTextStyle? style;
  final _CkParagraphPlaceholder? placeholderStyle;

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
}

enum _ParagraphCommandType {
  addText,
  pop,
  pushStyle,
  addPlaceholder,
}

List<String> _getEffectiveFontFamilies(String? fontFamily,
    [List<String>? fontFamilyFallback]) {
  List<String> fontFamilies = <String>[];
  if (fontFamily != null) {
    fontFamilies.add(fontFamily);
  }
  if (fontFamilyFallback != null &&
      !fontFamilyFallback.every((font) => fontFamily == font)) {
    fontFamilies.addAll(fontFamilyFallback);
  }
  fontFamilies.addAll(FontFallbackData.instance.globalFontFallbacks);
  return fontFamilies;
}
