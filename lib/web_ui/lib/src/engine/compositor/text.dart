// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
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
          ellipsis,
        ) {
    assert(skParagraphStyle != null);
    _textDirection = textDirection ?? ui.TextDirection.ltr;
    _fontFamily = fontFamily;
  }

  SkParagraphStyle skParagraphStyle;
  ui.TextDirection? _textDirection;
  String? _fontFamily;

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
    String? ellipsis,
  ) {
    final SkParagraphStyleProperties properties = SkParagraphStyleProperties();

    if (textAlign != null) {
      properties.textAlign = toSkTextAlign(textAlign);
    }

    if (textDirection != null) {
      properties.textDirection = toSkTextDirection(textDirection);
    }

    if (height != null) {
      properties.heightMultiplier = height;
    }

    if (textHeightBehavior != null) {
      properties.textHeightBehavior = textHeightBehavior.encode();
    }

    if (maxLines != null) {
      properties.maxLines = maxLines;
    }

    if (ellipsis != null) {
      properties.ellipsis = ellipsis;
    }

    properties.textStyle =
        toSkTextStyleProperties(fontFamily, fontSize, fontWeight, fontStyle);

    return canvasKit.ParagraphStyle(properties);
  }
}

class CkTextStyle implements ui.TextStyle {
  SkTextStyle skTextStyle;
  CkPaint? background;
  CkPaint? foreground;

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

    if (fontSize != null) {
      properties.fontSize = fontSize;
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

    // TODO(hterkelsen): Add support for
    //   - decorationColor
    //   - decorationStyle
    //   - textBaseline
    //   - letterSpacing
    //   - wordSpacing
    //   - height
    //   - locale
    //   - shadows
    //   - fontFeatures
    return CkTextStyle._(
        canvasKit.TextStyle(properties), foreground, background);
  }

  CkTextStyle._(this.skTextStyle, this.foreground, this.background);
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

  // TODO(hterkelsen): Implement placeholders once it's in CanvasKit
  @override
  List<ui.TextBox> getBoxesForPlaceholders() {
    return const <ui.TextBox>[];
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

    List<SkRect> skRects = skiaObject.getRectsForRange(
      start,
      end,
      toSkRectHeightStyle(boxHeightStyle),
      toSkRectWidthStyle(boxWidthStyle),
    );

    List<ui.TextBox> result = <ui.TextBox>[];

    for (int i = 0; i < skRects.length; i++) {
      final SkRect rect = skRects[i];
      result.add(ui.TextBox.fromLTRBD(
        rect.fLeft,
        rect.fTop,
        rect.fRight,
        rect.fBottom,
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

    // Infinite width breaks layout, just use a very large number instead.
    // TODO(het): Remove this once https://bugs.chromium.org/p/skia/issues/detail?id=9874
    //            is fixed.
    double width;
    const double largeFiniteWidth = 1000000;
    if (constraints.width.isInfinite) {
      width = largeFiniteWidth;
    } else {
      width = constraints.width;
    }
    // TODO(het): CanvasKit throws an exception when laid out with
    // a font that wasn't registered.
    try {
      skiaObject.layout(width);
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

  CkParagraphBuilder(ui.ParagraphStyle style)
      : _commands = <_ParagraphCommand>[],
        _style = style as CkParagraphStyle,
        _paragraphBuilder = canvasKit.ParagraphBuilder.MakeFromFontProvider(
          style.skParagraphStyle,
          skiaFontCollection.fontProvider,
        );

  // TODO(hterkelsen): Implement placeholders.
  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    double scale = 1.0,
    double? baselineOffset,
    ui.TextBaseline? baseline,
  }) {
    throw UnimplementedError('addPlaceholder');
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
  int get placeholderCount => throw UnimplementedError('placeholderCount');

  // TODO(hterkelsen): Implement this once CanvasKit exposes placeholders.
  @override
  List<double> get placeholderScales => const <double>[];

  @override
  void pop() {
    _commands.add(const _ParagraphCommand.pop());
    _paragraphBuilder.pop();
  }

  @override
  void pushStyle(ui.TextStyle style) {
    final CkTextStyle skStyle = style as CkTextStyle;
    _commands.add(_ParagraphCommand.pushStyle(skStyle));
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

  const _ParagraphCommand._(this.type, this.text, this.style);

  const _ParagraphCommand.addText(String text)
      : this._(_ParagraphCommandType.addText, text, null);

  const _ParagraphCommand.pop() : this._(_ParagraphCommandType.pop, null, null);

  const _ParagraphCommand.pushStyle(CkTextStyle style)
      : this._(_ParagraphCommandType.pushStyle, null, style);
}

enum _ParagraphCommandType {
  addText,
  pop,
  pushStyle,
}
