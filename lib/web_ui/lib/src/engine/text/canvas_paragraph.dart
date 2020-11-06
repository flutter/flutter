// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
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
    required this.placeholderCount,
  });

  /// The flat list of spans that make up this paragraph.
  final List<ParagraphSpan> spans;

  /// General styling information for this paragraph.
  final EngineParagraphStyle paragraphStyle;

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

  String? _cachedPlainText;

  @override
  String toPlainText() {
    final String? plainText = _cachedPlainText;
    if (plainText == null) {
      return _cachedPlainText ??= _computePlainText();
    }
    return plainText;
  }

  String _computePlainText() {
    final StringBuffer buffer = StringBuffer();
    for (final ParagraphSpan span in spans) {
      if (span is FlatTextSpan) {
        buffer.write(span.text);
      }
    }
    return buffer.toString();
  }

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
  /// Creates a [FlatTextSpan] with the given [text] and [style].
  const FlatTextSpan({required this.text, required this.style});

  /// The textual content of the span.
  final String text;

  /// The resolved style of the span.
  final EngineTextStyle style;
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
    // TODO(mdebbar): combine all styles from the parent hierarchy.
    return style;
  }
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
}

/// Builds a [CanvasParagraph] containing text with the given styling
/// information.
class CanvasParagraphBuilder implements ui.ParagraphBuilder {
  /// Creates a [CanvasParagraphBuilder] object, which is used to create a
  /// [CanvasParagraph].
  CanvasParagraphBuilder(EngineParagraphStyle style)
      : _paragraphStyle = style,
        _rootStyleNode = RootStyleNode(style);

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
    _spans
        .add(FlatTextSpan(text: text, style: _currentStyleNode.resolveStyle()));
  }

  @override
  CanvasParagraph build() {
    return CanvasParagraph(
      _spans,
      paragraphStyle: _paragraphStyle,
      placeholderCount: _placeholderCount,
    );
  }
}
