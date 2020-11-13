// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

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
  }) : skParagraphStyle = toSkParagraphStyle(
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
        ) {
    _textDirection = textDirection ?? ui.TextDirection.ltr;
    _fontFamily = fontFamily;
    _fontSize = fontSize;
    _fontWeight = fontWeight;
    _fontStyle = fontStyle;
  }

  SkParagraphStyle skParagraphStyle;
  ui.TextDirection? _textDirection;
  String? _fontFamily;
  double? _fontSize;
  ui.FontWeight? _fontWeight;
  ui.FontStyle? _fontStyle;

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

    if (fontFamily == null ||
        !skiaFontCollection.registeredFamilies.contains(fontFamily)) {
      fontFamily = 'Roboto';
    }
    skTextStyle.fontFamilies = [fontFamily];

    return skTextStyle;
  }

  static SkStrutStyleProperties toSkStrutStyleProperties(ui.StrutStyle value) {
    EngineStrutStyle style = value as EngineStrutStyle;
    final SkStrutStyleProperties skStrutStyle = SkStrutStyleProperties();
    if (style._fontFamily != null) {
      String fontFamily = style._fontFamily!;
      if (!skiaFontCollection.registeredFamilies.contains(fontFamily)) {
        fontFamily = 'Roboto';
      }
      final List<String> fontFamilies = <String>[fontFamily];
      if (style._fontFamilyFallback != null) {
        fontFamilies.addAll(style._fontFamilyFallback!);
      }
      skStrutStyle.fontFamilies = fontFamilies;
    } else {
      // If no strut font family is given, default to Roboto.
      skStrutStyle.fontFamilies = ['Roboto'];
    }

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

class CkTextStyle implements ui.TextStyle {
  SkTextStyle skTextStyle;

  ui.Color? color;
  ui.TextDecoration? decoration;
  ui.Color? decorationColor;
  ui.TextDecorationStyle? decorationStyle;
  double? decorationThickness;
  ui.FontWeight? fontWeight;
  ui.FontStyle? fontStyle;
  ui.TextBaseline? textBaseline;
  String? fontFamily;
  List<String>? fontFamilyFallback;
  double? fontSize;
  double? letterSpacing;
  double? wordSpacing;
  double? height;
  ui.Locale? locale;
  CkPaint? background;
  CkPaint? foreground;
  List<ui.Shadow>? shadows;
  List<ui.FontFeature>? fontFeatures;

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

    if (fontFamily == null ||
        !skiaFontCollection.registeredFamilies.contains(fontFamily)) {
      fontFamily = 'Roboto';
    }

    List<String> fontFamilies = <String>[fontFamily];
    if (fontFamilyFallback != null &&
        !fontFamilyFallback.every((font) => fontFamily == font)) {
      fontFamilies.addAll(fontFamilyFallback);
    }

    properties.fontFamilies = fontFamilies;

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
      List<SkFontFeature> ckFontFeatures = <SkFontFeature>[];
      for (ui.FontFeature fontFeature in fontFeatures) {
        SkFontFeature ckFontFeature = SkFontFeature();
        ckFontFeature.name = fontFeature.feature;
        ckFontFeature.value = fontFeature.value;
        ckFontFeatures.add(ckFontFeature);
      }
      properties.fontFeatures = ckFontFeatures;
    }

    return CkTextStyle._(
      canvasKit.TextStyle(properties),
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

  CkTextStyle._(
    this.skTextStyle,
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
    assert(constraints.width != null); // ignore: unnecessary_null_comparison
    _lastLayoutConstraints = constraints;

    // TODO(het): CanvasKit throws an exception when laid out with
    // a font that wasn't registered.
    try {
      skiaObject.layout(constraints.width);
    } catch (e) {
      html.window.console.warn('CanvasKit threw an exception while laying '
          'out the paragraph. The font was "${_paragraphStyle._fontFamily}". '
          'Exception:\n$e');
      rethrow;
    }
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    // TODO(hterkelsen): Implement this when it's added to CanvasKit
    throw UnimplementedError('getLineBoundary');
  }

  @override
  List<ui.LineMetrics> computeLineMetrics() {
    // TODO(hterkelsen): Implement this when it's added to CanvasKit
    throw UnimplementedError('computeLineMetrics');
  }
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
        );

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
    SkPlaceholderStyleProperties placeholderStyle = toSkPlaceholderStyle(
      width * scale,
      height * scale,
      alignment,
      (baselineOffset ?? height) * scale,
      baseline ?? ui.TextBaseline.alphabetic,
    );
    _addPlaceholder(placeholderStyle);
  }

  void _addPlaceholder(SkPlaceholderStyleProperties placeholderStyle) {
    _commands.add(_ParagraphCommand.addPlaceholder(placeholderStyle));
    _paragraphBuilder.addPlaceholder(placeholderStyle);
  }

  static SkPlaceholderStyleProperties toSkPlaceholderStyle(
    double width,
    double height,
    ui.PlaceholderAlignment alignment,
    double baselineOffset,
    ui.TextBaseline baseline,
  ) {
    final properties = SkPlaceholderStyleProperties();
    properties.width = width;
    properties.height = height;
    properties.alignment = toSkPlaceholderAlignment(alignment);
    properties.offset = baselineOffset;
    properties.baseline = toSkTextBaseline(baseline);
    return properties;
  }

  @override
  void addText(String text) {
    _commands.add(_ParagraphCommand.addText(text));
    _paragraphBuilder.addText(text);
  }

  @override
  ui.Paragraph build() {
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
    _commands.add(const _ParagraphCommand.pop());
    _styleStack.removeLast();
    _paragraphBuilder.pop();
  }

  CkTextStyle _peekStyle() =>
      _styleStack.isEmpty ? _style.getTextStyle() : _styleStack.last;

  @override
  void pushStyle(ui.TextStyle style) {
    final CkTextStyle baseStyle = _peekStyle();
    final CkTextStyle ckStyle = style as CkTextStyle;
    final CkTextStyle skStyle = baseStyle.mergeWith(ckStyle);
    _styleStack.add(skStyle);
    _commands.add(_ParagraphCommand.pushStyle(ckStyle));
    if (skStyle.foreground != null || skStyle.background != null) {
      final SkPaint foreground = skStyle.foreground?.skiaObject ?? SkPaint();
      final SkPaint background = skStyle.background?.skiaObject ?? SkPaint();
      _paragraphBuilder.pushPaintStyle(
          skStyle.skTextStyle, foreground, background);
    } else {
      _paragraphBuilder.pushStyle(skStyle.skTextStyle);
    }
  }
}

class _ParagraphCommand {
  final _ParagraphCommandType type;
  final String? text;
  final CkTextStyle? style;
  final SkPlaceholderStyleProperties? placeholderStyle;

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
      SkPlaceholderStyleProperties placeholderStyle)
      : this._(
            _ParagraphCommandType.addPlaceholder, null, null, placeholderStyle);
}

enum _ParagraphCommandType {
  addText,
  pop,
  pushStyle,
  addPlaceholder,
}
