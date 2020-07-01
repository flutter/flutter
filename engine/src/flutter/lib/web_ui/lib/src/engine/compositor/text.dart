// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  }) {
    skParagraphStyle = toCkParagraphStyle(
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
    );
    assert(skParagraphStyle != null);
    _textDirection = textDirection ?? ui.TextDirection.ltr;
    _fontFamily = fontFamily;
  }

  js.JsObject? skParagraphStyle;
  ui.TextDirection? _textDirection;
  String? _fontFamily;

  static Map<String, dynamic> toCkTextStyle(
    String? fontFamily,
    double? fontSize,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
  ) {
    final Map<String, dynamic> skTextStyle = <String, dynamic>{};
    if (fontWeight != null || fontStyle != null) {
      skTextStyle['fontStyle'] = toSkFontStyle(fontWeight, fontStyle);
    }

    if (fontSize != null) {
      skTextStyle['fontSize'] = fontSize;
    }

    if (fontFamily == null ||
        !skiaFontCollection.registeredFamilies.contains(fontFamily)) {
      fontFamily = 'Roboto';
    }
    if (skiaFontCollection.fontFamilyOverrides.containsKey(fontFamily)) {
      fontFamily = skiaFontCollection.fontFamilyOverrides[fontFamily];
    }
    skTextStyle['fontFamilies'] = [fontFamily];

    return skTextStyle;
  }

  static js.JsObject? toCkParagraphStyle(
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
    final Map<String, dynamic> skParagraphStyle = <String, dynamic>{};

    if (textAlign != null) {
      switch (textAlign) {
        case ui.TextAlign.left:
          skParagraphStyle['textAlign'] = canvasKit['TextAlign']['Left'];
          break;
        case ui.TextAlign.right:
          skParagraphStyle['textAlign'] = canvasKit['TextAlign']['Right'];
          break;
        case ui.TextAlign.center:
          skParagraphStyle['textAlign'] = canvasKit['TextAlign']['Center'];
          break;
        case ui.TextAlign.justify:
          skParagraphStyle['textAlign'] = canvasKit['TextAlign']['Justify'];
          break;
        case ui.TextAlign.start:
          skParagraphStyle['textAlign'] = canvasKit['TextAlign']['Start'];
          break;
        case ui.TextAlign.end:
          skParagraphStyle['textAlign'] = canvasKit['TextAlign']['End'];
          break;
      }
    }

    if (textDirection != null) {
      switch (textDirection) {
        case ui.TextDirection.ltr:
          skParagraphStyle['textDirection'] = canvasKit['TextDirection']['LTR'];
          break;
        case ui.TextDirection.rtl:
          skParagraphStyle['textDirection'] = canvasKit['TextDirection']['RTL'];
          break;
      }
    }

    if (height != null) {
      skParagraphStyle['heightMultiplier'] = height;
    }

    if (textHeightBehavior != null) {
      skParagraphStyle['textHeightBehavior'] = textHeightBehavior.encode();
    }

    if (maxLines != null) {
      skParagraphStyle['maxLines'] = maxLines;
    }

    if (ellipsis != null) {
      skParagraphStyle['ellipsis'] = ellipsis;
    }

    skParagraphStyle['textStyle'] =
        toCkTextStyle(fontFamily, fontSize, fontWeight, fontStyle);

    return canvasKit.callMethod(
        'ParagraphStyle', <js.JsObject>[js.JsObject.jsify(skParagraphStyle)]);
  }
}

class CkTextStyle implements ui.TextStyle {
  js.JsObject? skTextStyle;

  CkTextStyle({
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
    final js.JsObject style = js.JsObject(js.context['Object']);

    if (background != null) {
      style['backgroundColor'] = makeFreshSkColor(background.color);
    }

    if (color != null) {
      style['color'] = makeFreshSkColor(color);
    }

    if (decoration != null) {
      int decorationValue = canvasKit['NoDecoration'];
      if (decoration.contains(ui.TextDecoration.underline)) {
        decorationValue |= canvasKit['UnderlineDecoration'];
      }
      if (decoration.contains(ui.TextDecoration.overline)) {
        decorationValue |= canvasKit['OverlineDecoration'];
      }
      if (decoration.contains(ui.TextDecoration.lineThrough)) {
        decorationValue |= canvasKit['LineThroughDecoration'];
      }
      style['decoration'] = decorationValue;
    }

    if (decorationThickness != null) {
      style['decorationThickness'] = decorationThickness;
    }

    if (fontSize != null) {
      style['fontSize'] = fontSize;
    }

    if (fontFamily == null ||
        !skiaFontCollection.registeredFamilies.contains(fontFamily)) {
      fontFamily = 'Roboto';
    }

    if (skiaFontCollection.fontFamilyOverrides.containsKey(fontFamily)) {
      fontFamily = skiaFontCollection.fontFamilyOverrides[fontFamily];
    }
    List<String?> fontFamilies = <String?>[fontFamily];
    if (fontFamilyFallback != null &&
        !fontFamilyFallback.every((font) => fontFamily == font)) {
      fontFamilies.addAll(fontFamilyFallback);
    }

    style['fontFamilies'] = js.JsArray.from(fontFamilies);

    if (fontWeight != null || fontStyle != null) {
      style['fontStyle'] = toSkFontStyle(fontWeight, fontStyle);
    }

    if (foreground != null) {
      style['foregroundColor'] = makeFreshSkColor(foreground.color);
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
    skTextStyle = canvasKit.callMethod('TextStyle', <js.JsObject>[style]);
    assert(skTextStyle != null);
  }
}

Map<String, js.JsObject?> toSkFontStyle(
    ui.FontWeight? fontWeight, ui.FontStyle? fontStyle) {
  Map<String, js.JsObject?> style = <String, js.JsObject?>{};
  if (fontWeight != null) {
    switch (fontWeight) {
      case ui.FontWeight.w100:
        style['weight'] = canvasKit['FontWeight']['Thin'];
        break;
      case ui.FontWeight.w200:
        style['weight'] = canvasKit['FontWeight']['ExtraLight'];
        break;
      case ui.FontWeight.w300:
        style['weight'] = canvasKit['FontWeight']['Light'];
        break;
      case ui.FontWeight.w400:
        style['weight'] = canvasKit['FontWeight']['Normal'];
        break;
      case ui.FontWeight.w500:
        style['weight'] = canvasKit['FontWeight']['Medium'];
        break;
      case ui.FontWeight.w600:
        style['weight'] = canvasKit['FontWeight']['SemiBold'];
        break;
      case ui.FontWeight.w700:
        style['weight'] = canvasKit['FontWeight']['Bold'];
        break;
      case ui.FontWeight.w800:
        style['weight'] = canvasKit['FontWeight']['ExtraBold'];
        break;
      case ui.FontWeight.w900:
        style['weight'] = canvasKit['FontWeight']['ExtraBlack'];
        break;
    }
  }

  if (fontStyle != null) {
    switch (fontStyle) {
      case ui.FontStyle.normal:
        style['slant'] = canvasKit['FontSlant']['Upright'];
        break;
      case ui.FontStyle.italic:
        style['slant'] = canvasKit['FontSlant']['Italic'];
        break;
    }
  }
  return style;
}

class CkParagraph extends ResurrectableSkiaObject implements ui.Paragraph {
  CkParagraph(
      this._initialParagraph, this._paragraphStyle, this._paragraphCommands);

  /// The result of calling `build()` on the JS CkParagraphBuilder.
  ///
  /// This may be invalidated later.
  final js.JsObject _initialParagraph;

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
  js.JsObject createDefault() => _initialParagraph;

  @override
  js.JsObject resurrect() {
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

    final js.JsObject result = builder._buildCkParagraph();
    if (_lastLayoutConstraints != null) {
      // We need to set the Skia object early so layout works.
      _skiaObject = result;
      this.layout(_lastLayoutConstraints!);
    }
    return result;
  }

  @override
  bool get isResurrectionExpensive => true;

  @override
  double get alphabeticBaseline =>
      skiaObject.callMethod('getAlphabeticBaseline');

  @override
  bool get didExceedMaxLines => skiaObject.callMethod('didExceedMaxLines');

  @override
  double get height => skiaObject.callMethod('getHeight');

  @override
  double get ideographicBaseline =>
      skiaObject.callMethod('getIdeographicBaseline');

  @override
  double get longestLine => skiaObject.callMethod('getLongestLine');

  @override
  double get maxIntrinsicWidth => skiaObject.callMethod('getMaxIntrinsicWidth');

  @override
  double get minIntrinsicWidth => skiaObject.callMethod('getMinIntrinsicWidth');

  @override
  double get width => skiaObject.callMethod('getMaxWidth');

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

    js.JsObject? heightStyle;
    switch (boxHeightStyle) {
      case ui.BoxHeightStyle.tight:
        heightStyle = canvasKit['RectHeightStyle']['Tight'];
        break;
      case ui.BoxHeightStyle.max:
        heightStyle = canvasKit['RectHeightStyle']['Max'];
        break;
      default:
        // TODO(hterkelsen): Support all height styles
        html.window.console.warn(
            'We do not support $boxHeightStyle. Defaulting to BoxHeightStyle.tight');
        heightStyle = canvasKit['RectHeightStyle']['Tight'];
        break;
    }

    js.JsObject? widthStyle;
    switch (boxWidthStyle) {
      case ui.BoxWidthStyle.tight:
        widthStyle = canvasKit['RectWidthStyle']['Tight'];
        break;
      case ui.BoxWidthStyle.max:
        widthStyle = canvasKit['RectWidthStyle']['Max'];
        break;
    }

    List<js.JsObject> skRects =
        skiaObject.callMethod('getRectsForRange', <dynamic>[
      start,
      end,
      heightStyle,
      widthStyle,
    ]);

    List<ui.TextBox> result = <ui.TextBox>[];

    for (int i = 0; i < skRects.length; i++) {
      final js.JsObject rect = skRects[i];
      result.add(ui.TextBox.fromLTRBD(
        rect['fLeft'],
        rect['fTop'],
        rect['fRight'],
        rect['fBottom'],
        _paragraphStyle._textDirection!,
      ));
    }

    return result;
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    js.JsObject positionWithAffinity =
        skiaObject.callMethod('getGlyphPositionAtCoordinate', <double>[
      offset.dx,
      offset.dy,
    ]);
    return fromPositionWithAffinity(positionWithAffinity);
  }

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    js.JsObject skRange =
        skiaObject.callMethod('getWordBoundary', <int>[position.offset]);
    return ui.TextRange(start: skRange['start'], end: skRange['end']);
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
      skiaObject.callMethod('layout', <double>[width]);
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
  js.JsObject? _paragraphBuilder;
  final CkParagraphStyle _style;
  final List<_ParagraphCommand> _commands;

  CkParagraphBuilder(ui.ParagraphStyle style)
      : _commands = <_ParagraphCommand>[],
        _style = style as CkParagraphStyle {
    _paragraphBuilder = canvasKit['ParagraphBuilder'].callMethod(
      'Make',
      <js.JsObject?>[
        _style.skParagraphStyle,
        skiaFontCollection.skFontMgr,
      ],
    );
  }

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
    _paragraphBuilder!.callMethod('addText', <String>[text]);
  }

  @override
  ui.Paragraph build() {
    final builtParagraph = _buildCkParagraph();
    return CkParagraph(builtParagraph, _style, _commands);
  }

  /// Builds the CkParagraph with the builder and deletes the builder.
  js.JsObject _buildCkParagraph() {
    final js.JsObject result = _paragraphBuilder!.callMethod('build');
    _paragraphBuilder!.callMethod('delete');
    _paragraphBuilder = null;
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
    _paragraphBuilder!.callMethod('pop');
  }

  @override
  void pushStyle(ui.TextStyle style) {
    final CkTextStyle skStyle = style as CkTextStyle;
    _commands.add(_ParagraphCommand.pushStyle(skStyle));
    _paragraphBuilder!
        .callMethod('pushStyle', <js.JsObject?>[skStyle.skTextStyle]);
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
