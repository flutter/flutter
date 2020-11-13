// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// A paragraph made up of a flat list of text spans and placeholders.
///
/// As opposed to [DomParagraph], a [CanvasParagraph] doesn't use a DOM element
/// to represent the structure of its spans and styles. Instead it uses a flat
/// list of [ParagraphSpan] objects.
class CanvasParagraph implements EngineParagraph {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a [CanvasParagraph] object, use a [CanvasParagraphBuilder].
  CanvasParagraph(
    this.spans, {
    required this.paragraphStyle,
    required this.plainText,
    required this.placeholderCount,
  });

  /// The flat list of spans that make up this paragraph.
  final List<ParagraphSpan> spans;

  /// General styling information for this paragraph.
  final EngineParagraphStyle paragraphStyle;

  /// The full textual content of the paragraph.
  final String plainText;

  /// The number of placeholders in this paragraph.
  final int placeholderCount;

  // Defaulting to -1 for non-laid-out paragraphs like the native engine does.
  @override
  double width = -1.0;

  @override
  double height = 0.0;

  @override
  double get longestLine {
    assert(isLaidOut);
    // TODO(mdebbar): Use the line metrics generated during layout to find out
    // the longest line.
    return 0.0;
  }

  @override
  double minIntrinsicWidth = 0.0;

  @override
  double maxIntrinsicWidth = 0.0;

  @override
  double alphabeticBaseline = -1.0;

  @override
  double ideographicBaseline = -1.0;

  @override
  bool get didExceedMaxLines => _didExceedMaxLines;
  bool _didExceedMaxLines = false;

  ui.ParagraphConstraints? _lastUsedConstraints;

  @override
  void layout(ui.ParagraphConstraints constraints) {
    // When constraint width has a decimal place, we floor it to avoid getting
    // a layout width that's higher than the constraint width.
    //
    // For example, if constraint width is `30.8` and the text has a width of
    // `30.5` then the TextPainter in the framework will ceil the `30.5` width
    // which will result in a width of `40.0` that's higher than the constraint
    // width.
    constraints = ui.ParagraphConstraints(
      width: constraints.width.floorToDouble(),
    );

    if (constraints == _lastUsedConstraints) {
      return;
    }

    late Stopwatch stopwatch;
    if (Profiler.isBenchmarkMode) {
      stopwatch = Stopwatch()..start();
    }
    // TODO(mdebbar): Perform the layout using a new rich text measurement service.
    // TODO(mdebbar): Don't forget to update `_didExceedMaxLines`.
    if (Profiler.isBenchmarkMode) {
      stopwatch.stop();
      Profiler.instance
          .benchmark('text_layout', stopwatch.elapsedMicroseconds.toDouble());
    }

    _lastUsedConstraints = constraints;
  }

  // TODO(mdebbar): Returning true means we always require a bitmap canvas. Revisit
  // this decision once `CanvasParagraph` is fully implemented.
  @override
  bool get hasArbitraryPaint => true;

  @override
  void paint(BitmapCanvas canvas, ui.Offset offset) {
    // TODO(mdebbar): Loop through the spans and for each box in the span:
    // 1. Paint the background rect.
    // 2. Paint the text shadows?
    // 3. Paint the text.
  }

  @override
  String toPlainText() => plainText;

  html.HtmlElement? _cachedDomElement;

  @override
  html.HtmlElement toDomElement() {
    final html.HtmlElement? domElement = _cachedDomElement;
    if (domElement == null) {
      return _cachedDomElement ??= _createDomElement();
    }
    return domElement.clone(true) as html.HtmlElement;
  }

  html.HtmlElement _createDomElement() {
    final html.HtmlElement element =
        domRenderer.createElement('p') as html.HtmlElement;

    // 1. Set paragraph-level styles.
    final html.CssStyleDeclaration cssStyle = element.style;
    final ui.TextDirection direction =
        paragraphStyle._textDirection ?? ui.TextDirection.ltr;
    final ui.TextAlign align = paragraphStyle._textAlign ?? ui.TextAlign.start;
    cssStyle
      ..direction = _textDirectionToCss(direction)
      ..textAlign = textAlignToCssValue(align, direction)
      ..position = 'absolute'
      ..whiteSpace = 'pre-wrap'
      ..overflowWrap = 'break-word'
      ..overflow = 'hidden';

    if (paragraphStyle._ellipsis != null &&
        (paragraphStyle._maxLines == null || paragraphStyle._maxLines == 1)) {
      cssStyle
        ..whiteSpace = 'pre'
        ..textOverflow = 'ellipsis';
    }

    // 2. Append all spans to the paragraph.
    for (final ParagraphSpan span in spans) {
      if (span is FlatTextSpan) {
        final html.HtmlElement spanElement =
            domRenderer.createElement('span') as html.HtmlElement;
        _applyTextStyleToElement(
          element: spanElement,
          style: span.style,
          isSpan: true,
        );
        domRenderer.append(element, spanElement);
      } else if (span is ParagraphPlaceholder) {
        domRenderer.append(
          element,
          _createPlaceholderElement(placeholder: span),
        );
      }
    }
    return element;
  }

  @override
  List<ui.TextBox> getBoxesForPlaceholders() {
    // TODO(mdebbar): After layout, placeholders positions should've been
    // determined and can be used to compute their boxes.
    return <ui.TextBox>[];
  }

  // TODO(mdebbar): Check for child spans if any has styles that can't be drawn
  // on a canvas. e.g:
  // - decoration
  // - word-spacing
  // - shadows (may be possible? https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/shadowBlur)
  // - font features
  @override
  final bool drawOnCanvas = true;

  @override
  bool isLaidOut = false;

  @override
  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    // TODO(mdebbar): After layout, each paragraph span should have info about
    // its position and dimensions.
    //
    // 1. Find the spans where the `start` and `end` indices fall.
    // 2. If it's the same span, find the sub-box from `start` to `end`.
    // 3. Else, find the trailing box(es) of the `start` span, and the `leading`
    //    box(es) of the `end` span.
    // 4. Include the boxes of all the spans in between.
    return <ui.TextBox>[];
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    // TODO(mdebbar): After layout, each paragraph span should have info about
    // its position and dimensions. Use that information to find which span the
    // offset belongs to, then search within that span for the exact character.
    return const ui.TextPosition(offset: 0);
  }

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    final String text = toPlainText();

    final int start = WordBreaker.prevBreakIndex(text, position.offset + 1);
    final int end = WordBreaker.nextBreakIndex(text, position.offset);
    return ui.TextRange(start: start, end: end);
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    // TODO(mdebbar): After layout, line metrics should be available and can be
    // used to determine the line boundary of the given `position`.
    return ui.TextRange.empty;
  }

  @override
  List<ui.LineMetrics> computeLineMetrics() {
    // TODO(mdebbar): After layout, line metrics should be available.
    return <ui.LineMetrics>[];
  }
}

/// A common interface for all types of spans that make up a paragraph.
///
/// These spans are stored as a flat list in the paragraph object.
abstract class ParagraphSpan {
  const ParagraphSpan();
}

/// Represent a span of text in the paragraph.
///
/// It's a "flat" text span as opposed to the framework text spans that are
/// hierarchical.
///
/// Instead of keeping spans and styles in a tree hierarchy like the framework
/// does, we flatten the structure and resolve/merge all the styles from parent
/// nodes.
class FlatTextSpan extends ParagraphSpan {
  /// Creates a [FlatTextSpan] with the given [style], representing the span of
  /// text in the range between [start] and [end].
  FlatTextSpan({
    required this.style,
    required this.start,
    required this.end,
  });

  /// The resolved style of the span.
  final EngineTextStyle style;

  /// The index of the beginning of the range of text represented by this span.
  final int start;

  /// The index of the end of the range of text represented by this span.
  final int end;

  String textOf(CanvasParagraph paragraph) {
    final String text = paragraph.toPlainText();
    assert(end <= text.length);
    return text.substring(start, end);
  }
}

/// Represents a node in the tree of text styles pushed to [ui.ParagraphBuilder].
///
/// The [ui.ParagraphBuilder.pushText] and [ui.ParagraphBuilder.pop] operations
/// represent the entire tree of styles in the paragraph. In our implementation,
/// we don't need to keep the entire tree structure in memory. At any point in
/// time, we only need a stack of nodes that represent the current branch in the
/// tree. The items in the stack are [StyleNode] objects.
abstract class StyleNode {
  /// Create a child for this style node.
  ///
  /// We are not creating a tree structure, hence there's no need to keep track
  /// of the children.
  ChildStyleNode createChild(EngineTextStyle style) {
    return ChildStyleNode(parent: this, style: style);
  }

  /// Generates the final text style to be applied to the text span.
  ///
  /// The resolved text style is equivalent to the entire ascendent chain of
  /// parent style nodes.
  EngineTextStyle resolveStyle();

  ui.Color? get _color;
  ui.TextDecoration? get _decoration;
  ui.Color? get _decorationColor;
  ui.TextDecorationStyle? get _decorationStyle;
  double? get _decorationThickness;
  ui.FontWeight? get _fontWeight;
  ui.FontStyle? get _fontStyle;
  ui.TextBaseline? get _textBaseline;
  String? get _fontFamily;
  List<String>? get _fontFamilyFallback;
  List<ui.FontFeature>? get _fontFeatures;
  double? get _fontSize;
  double? get _letterSpacing;
  double? get _wordSpacing;
  double? get _height;
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
  final EngineTextStyle style;

  @override
  EngineTextStyle resolveStyle() {
    return EngineTextStyle(
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
      fontSize: _fontSize,
      letterSpacing: _letterSpacing,
      wordSpacing: _wordSpacing,
      height: _height,
      locale: _locale,
      background: _background,
      foreground: _foreground,
      shadows: _shadows,
    );
  }

  // Read these properties from the TextStyle associated with this node. If the
  // property isn't defined, go to the parent node.

  @override
  ui.Color? get _color => style._color ?? parent._color;

  @override
  ui.TextDecoration? get _decoration => style._decoration ?? parent._decoration;

  @override
  ui.Color? get _decorationColor => style._decorationColor ?? parent._decorationColor;

  @override
  ui.TextDecorationStyle? get _decorationStyle => style._decorationStyle ?? parent._decorationStyle;

  @override
  double? get _decorationThickness => style._decorationThickness ?? parent._decorationThickness;

  @override
  ui.FontWeight? get _fontWeight => style._fontWeight ?? parent._fontWeight;

  @override
  ui.FontStyle? get _fontStyle => style._fontStyle ?? parent._fontStyle;

  @override
  ui.TextBaseline? get _textBaseline => style._textBaseline ?? parent._textBaseline;

  @override
  List<String>? get _fontFamilyFallback => style._fontFamilyFallback ?? parent._fontFamilyFallback;

  @override
  List<ui.FontFeature>? get _fontFeatures => style._fontFeatures ?? parent._fontFeatures;

  @override
  double? get _fontSize => style._fontSize ?? parent._fontSize;

  @override
  double? get _letterSpacing => style._letterSpacing ?? parent._letterSpacing;

  @override
  double? get _wordSpacing => style._wordSpacing ?? parent._wordSpacing;

  @override
  double? get _height => style._height ?? parent._height;

  @override
  ui.Locale? get _locale => style._locale ?? parent._locale;

  @override
  ui.Paint? get _background => style._background ?? parent._background;

  @override
  ui.Paint? get _foreground => style._foreground ?? parent._foreground;

  @override
  List<ui.Shadow>? get _shadows => style._shadows ?? parent._shadows;

  // Font family is slightly different from the other properties above. It's
  // never null on the TextStyle object, so we use `_isFontFamilyProvided` to
  // check if font family is defined or not.
  @override
  String? get _fontFamily => style._isFontFamilyProvided ? style._fontFamily : parent._fontFamily;
}

/// The root style node for the paragraph.
///
/// The style of the root is derived from a [ui.ParagraphStyle] and is the root
/// style for all spans in the paragraph.
class RootStyleNode extends StyleNode {
  /// Creates a [RootStyleNode] from [paragraphStyle].
  RootStyleNode(this.paragraphStyle);

  /// The style of the paragraph being built.
  final EngineParagraphStyle paragraphStyle;

  EngineTextStyle? _cachedStyle;

  @override
  EngineTextStyle resolveStyle() {
    final EngineTextStyle? style = _cachedStyle;
    if (style == null) {
      return _cachedStyle ??=
          EngineTextStyle.fromParagraphStyle(paragraphStyle);
    }
    return style;
  }

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
  ui.FontWeight? get _fontWeight => paragraphStyle._fontWeight;
  @override
  ui.FontStyle? get _fontStyle => paragraphStyle._fontStyle;

  @override
  ui.TextBaseline? get _textBaseline => null;

  @override
  String? get _fontFamily => paragraphStyle._fontFamily;

  @override
  List<String>? get _fontFamilyFallback => null;

  @override
  List<ui.FontFeature>? get _fontFeatures => null;

  @override
  double? get _fontSize => paragraphStyle._fontSize;

  @override
  double? get _letterSpacing => null;

  @override
  double? get _wordSpacing => null;

  @override
  double? get _height => paragraphStyle._height;

  @override
  ui.Locale? get _locale => paragraphStyle._locale;

  @override
  ui.Paint? get _background => null;

  @override
  ui.Paint? get _foreground => null;

  @override
  List<ui.Shadow>? get _shadows => null;
}

/// Builds a [CanvasParagraph] containing text with the given styling
/// information.
class CanvasParagraphBuilder implements ui.ParagraphBuilder {
  /// Creates a [CanvasParagraphBuilder] object, which is used to create a
  /// [CanvasParagraph].
  CanvasParagraphBuilder(EngineParagraphStyle style)
      : _paragraphStyle = style,
        _rootStyleNode = RootStyleNode(style);

  final StringBuffer _plainTextBuffer = StringBuffer();
  final EngineParagraphStyle _paragraphStyle;

  final List<ParagraphSpan> _spans = <ParagraphSpan>[];
  final List<StyleNode> _styleStack = <StyleNode>[];

  RootStyleNode _rootStyleNode;
  StyleNode get _currentStyleNode => _styleStack.isEmpty
      ? _rootStyleNode
      : _styleStack[_styleStack.length - 1];

  @override
  int get placeholderCount => _placeholderCount;
  int _placeholderCount = 0;

  @override
  List<double> get placeholderScales => _placeholderScales;
  final List<double> _placeholderScales = <double>[];

  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    double scale = 1.0,
    double? baselineOffset,
    ui.TextBaseline? baseline,
  }) {
    // TODO(mdebbar): for measurement of placeholders, look at:
    // - https://github.com/flutter/engine/blob/c0f7e8acf9318d264ad6a235facd097de597ffcc/third_party/txt/src/txt/paragraph_txt.cc#L325-L350

    // Require a baseline to be specified if using a baseline-based alignment.
    assert((alignment == ui.PlaceholderAlignment.aboveBaseline ||
            alignment == ui.PlaceholderAlignment.belowBaseline ||
            alignment == ui.PlaceholderAlignment.baseline)
        ? baseline != null
        : true);

    _placeholderCount++;
    _placeholderScales.add(scale);
    _spans.add(ParagraphPlaceholder(
      width * scale,
      height * scale,
      alignment,
      baselineOffset: (baselineOffset ?? height) * scale,
      baseline: baseline ?? ui.TextBaseline.alphabetic,
    ));
  }

  @override
  void pushStyle(ui.TextStyle style) {
    _styleStack.add(_currentStyleNode.createChild(style as EngineTextStyle));
  }

  @override
  void pop() {
    if (_styleStack.isNotEmpty) {
      _styleStack.removeLast();
    }
  }

  @override
  void addText(String text) {
    final EngineTextStyle style = _currentStyleNode.resolveStyle();
    final int start = _plainTextBuffer.length;
    _plainTextBuffer.write(text);
    final int end = _plainTextBuffer.length;

    _spans.add(FlatTextSpan(style: style, start: start, end: end));
  }

  @override
  CanvasParagraph build() {
    return CanvasParagraph(
      _spans,
      paragraphStyle: _paragraphStyle,
      plainText: _plainTextBuffer.toString(),
      placeholderCount: _placeholderCount,
    );
  }
}
