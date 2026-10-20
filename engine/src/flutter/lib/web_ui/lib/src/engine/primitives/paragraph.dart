// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../backend/paragraph.dart';
import '../font_fallback_service.dart';
import '../native_memory.dart';
import '../renderer.dart';
import '../util.dart';

const String _kWeightAxisTag = 'wght';
const List<String> _testFonts = <String>['FlutterTest', 'Ahem'];

String? _computeEffectiveFontFamily(String? fontFamily) {
  return ui_web.TestEnvironment.instance.forceTestFonts && !_testFonts.contains(fontFamily)
      ? _testFonts.first
      : fontFamily;
}

List<String> _computeEffectiveFontFamilies(List<String> fontFamilies) {
  if (!ui_web.TestEnvironment.instance.forceTestFonts) {
    return fontFamilies;
  }
  final Iterable<String> filteredFonts = fontFamilies.where(_testFonts.contains);
  return filteredFonts.isEmpty ? _testFonts : filteredFonts.toList();
}

class EngineLineMetrics implements ui.LineMetrics {
  const EngineLineMetrics({
    required this.hardBreak,
    required this.ascent,
    required this.descent,
    required this.unscaledAscent,
    required this.height,
    required this.width,
    required this.left,
    required this.baseline,
    required this.lineNumber,
    this.startIndex = 0,
    this.endIndex = 0,
  });

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

  @override
  final double left;

  @override
  final double baseline;

  @override
  final int lineNumber;

  final int startIndex;

  final int endIndex;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineLineMetrics &&
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

@immutable
class EngineStrutStyle implements ui.StrutStyle {
  EngineStrutStyle({
    this.fontFamily,
    this.fontFamilyFallback,
    this.fontSize,
    double? height,
    this.leadingDistribution,
    this.leading,
    this.fontWeight,
    this.fontStyle,
    this.forceStrutHeight,
  }) : effectiveFontFamily = _computeEffectiveFontFamily(fontFamily),
       effectiveFontFamilyFallback = ui_web.TestEnvironment.instance.forceTestFonts
           ? null
           : fontFamilyFallback,
       height = height == ui.kTextHeightNone ? null : height;

  final String? fontFamily;
  final List<String>? fontFamilyFallback;
  final String? effectiveFontFamily;
  final List<String>? effectiveFontFamilyFallback;
  final double? fontSize;
  final double? height;
  final ui.TextLeadingDistribution? leadingDistribution;
  final double? leading;
  final ui.FontWeight? fontWeight;
  final ui.FontStyle? fontStyle;
  final bool? forceStrutHeight;

  List<String> get effectiveFontFamilies =>
      _computeEffectiveFontFamilies(<String>[?fontFamily, ...?fontFamilyFallback]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineStrutStyle &&
        other.effectiveFontFamily == effectiveFontFamily &&
        other.fontSize == fontSize &&
        other.height == height &&
        other.leading == leading &&
        other.leadingDistribution == leadingDistribution &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.forceStrutHeight == forceStrutHeight &&
        listEquals<String>(other.effectiveFontFamilyFallback, effectiveFontFamilyFallback);
  }

  @override
  int get hashCode => Object.hash(
    effectiveFontFamily,
    effectiveFontFamilyFallback != null ? Object.hashAll(effectiveFontFamilyFallback!) : null,
    fontSize,
    height,
    leading,
    leadingDistribution,
    fontWeight,
    fontStyle,
    forceStrutHeight,
  );

  @override
  String toString() {
    var result = super.toString();
    assert(() {
      result =
          'StrutStyle('
          'fontFamily: ${fontFamily ?? "unspecified"}, '
          'fontFamilyFallback: ${fontFamilyFallback ?? "unspecified"}, '
          'fontSize: ${fontSize ?? "unspecified"}, '
          'height: ${height != null ? "${height}x" : "unspecified"}, '
          'leading: ${leading != null ? "${leading}x" : "unspecified"}, '
          'fontWeight: ${fontWeight ?? "unspecified"}, '
          'fontStyle: ${fontStyle ?? "unspecified"}, '
          'forceStrutHeight: ${forceStrutHeight ?? "unspecified"}, '
          'leadingDistribution: ${leadingDistribution ?? "unspecified"}'
          ')';
      return true;
    }());
    return result;
  }
}

@immutable
class EngineParagraphStyle implements ui.ParagraphStyle {
  EngineParagraphStyle({
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.fontFamily,
    this.fontSize,
    double? height,
    this.textHeightBehavior,
    this.fontWeight,
    this.fontStyle,
    ui.StrutStyle? strutStyle,
    this.ellipsis,
    this.locale,
    this.hyphens,
  }) : effectiveFontFamily = _computeEffectiveFontFamily(fontFamily),
       height = height == ui.kTextHeightNone ? null : height,
       strutStyle = strutStyle as EngineStrutStyle?;

  final ui.TextAlign? textAlign;
  final ui.TextDirection? textDirection;
  final ui.FontWeight? fontWeight;
  final ui.FontStyle? fontStyle;
  final int? maxLines;
  final String? fontFamily;
  final String? effectiveFontFamily;
  final double? fontSize;
  final double? height;
  final ui.TextHeightBehavior? textHeightBehavior;
  final EngineStrutStyle? strutStyle;
  final String? ellipsis;
  final ui.Locale? locale;
  final ui.Hyphens? hyphens;

  List<String> get effectiveFontFamilies => _computeEffectiveFontFamilies(<String>[?fontFamily]);

  EngineTextStyle getTextStyle() {
    return EngineTextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: height,
      leadingDistribution: textHeightBehavior?.leadingDistribution,
      locale: locale,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
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
    return other is EngineParagraphStyle &&
        other.textAlign == textAlign &&
        other.textDirection == textDirection &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.maxLines == maxLines &&
        other.fontFamily == fontFamily &&
        other.fontSize == fontSize &&
        other.height == height &&
        other.textHeightBehavior == textHeightBehavior &&
        other.strutStyle == strutStyle &&
        other.ellipsis == ellipsis &&
        other.locale == locale &&
        other.hyphens == hyphens;
  }

  @override
  int get hashCode {
    return Object.hash(
      textAlign,
      textDirection,
      fontWeight,
      fontStyle,
      maxLines,
      fontFamily,
      fontSize,
      height,
      textHeightBehavior,
      strutStyle,
      ellipsis,
      locale,
      hyphens,
    );
  }

  @override
  String toString() {
    var result = super.toString();
    assert(() {
      final double? fontSize = this.fontSize;
      final double? height = this.height;
      result =
          'ParagraphStyle('
          'textAlign: ${textAlign ?? "unspecified"}, '
          'textDirection: ${textDirection ?? "unspecified"}, '
          'fontWeight: ${fontWeight ?? "unspecified"}, '
          'fontStyle: ${fontStyle ?? "unspecified"}, '
          'maxLines: ${maxLines ?? "unspecified"}, '
          'textHeightBehavior: ${textHeightBehavior ?? "unspecified"}, '
          'fontFamily: ${fontFamily ?? "unspecified"}, '
          'fontSize: ${fontSize != null ? fontSize.toStringAsFixed(1) : "unspecified"}, '
          'height: ${height != null ? "${height.toStringAsFixed(1)}x" : "unspecified"}, '
          'strutStyle: ${strutStyle ?? "unspecified"}, '
          'ellipsis: ${ellipsis != null ? '"$ellipsis"' : "unspecified"}, '
          'locale: ${locale ?? "unspecified"}, '
          'hyphens: ${hyphens ?? "unspecified"}'
          ')';
      return true;
    }());
    return result;
  }
}

@immutable
class EngineTextStyle implements ui.TextStyle {
  factory EngineTextStyle({
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
    ui.Paint? background,
    ui.Paint? foreground,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations,
  }) {
    assert(
      color == null || foreground == null,
      'Cannot provide both a color and a foreground\n'
      'The color argument is just a shorthand for "foreground: Paint()..color = color".',
    );
    return EngineTextStyle._(
      color: color,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      textBaseline: textBaseline,
      fontFamily: fontFamily,
      effectiveFontFamily: _computeEffectiveFontFamily(fontFamily),
      fontFamilyFallback: fontFamilyFallback,
      effectiveFontFamilyFallback: ui_web.TestEnvironment.instance.forceTestFonts
          ? null
          : fontFamilyFallback,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      leadingDistribution: leadingDistribution,
      locale: locale,
      background: background,
      foreground: foreground,
      shadows: shadows,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
    );
  }

  const EngineTextStyle._({
    required this.color,
    required this.decoration,
    required this.decorationColor,
    required this.decorationStyle,
    required this.decorationThickness,
    required this.fontWeight,
    required this.fontStyle,
    required this.textBaseline,
    required this.fontFamily,
    required this.effectiveFontFamily,
    required this.fontFamilyFallback,
    required this.effectiveFontFamilyFallback,
    required this.fontSize,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.height,
    required this.leadingDistribution,
    required this.locale,
    required this.background,
    required this.foreground,
    required this.shadows,
    required this.fontFeatures,
    required this.fontVariations,
  });

  final ui.Color? color;
  final ui.TextDecoration? decoration;
  final ui.Color? decorationColor;
  final ui.TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final ui.FontWeight? fontWeight;
  final ui.FontStyle? fontStyle;
  final ui.TextBaseline? textBaseline;
  final String? fontFamily;
  final String? effectiveFontFamily;
  final List<String>? fontFamilyFallback;
  final List<String>? effectiveFontFamilyFallback;
  final double? fontSize;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final ui.TextLeadingDistribution? leadingDistribution;
  final ui.Locale? locale;
  final ui.Paint? background;
  final ui.Paint? foreground;
  final List<ui.Shadow>? shadows;
  final List<ui.FontFeature>? fontFeatures;
  final List<ui.FontVariation>? fontVariations;

  List<String> get effectiveFontFamilies =>
      _computeEffectiveFontFamilies(<String>[?fontFamily, ...?fontFamilyFallback]);

  List<ui.FontVariation> get effectiveFontVariations {
    final List<ui.FontVariation>? fontVariations = this.fontVariations;
    if (fontVariations != null &&
        fontVariations.any((ui.FontVariation v) => v.axis == _kWeightAxisTag)) {
      return fontVariations;
    }
    final int weightValue = fontWeight?.value ?? ui.FontWeight.normal.value;
    final weightVariation = ui.FontVariation(_kWeightAxisTag, weightValue.toDouble());
    return <ui.FontVariation>[...?fontVariations, weightVariation];
  }

  EngineTextStyle mergeWith(EngineTextStyle other) {
    final double? textHeight = other.height == ui.kTextHeightNone ? null : (other.height ?? height);
    return EngineTextStyle._(
      color: other.color ?? color,
      decoration: other.decoration ?? decoration,
      decorationColor: other.decorationColor ?? decorationColor,
      decorationStyle: other.decorationStyle ?? decorationStyle,
      decorationThickness: other.decorationThickness ?? decorationThickness,
      fontWeight: other.fontWeight ?? fontWeight,
      fontStyle: other.fontStyle ?? fontStyle,
      textBaseline: other.textBaseline ?? textBaseline,
      fontFamily: other.fontFamily ?? fontFamily,
      effectiveFontFamily: other.fontFamily != null
          ? other.effectiveFontFamily
          : effectiveFontFamily,
      fontFamilyFallback: other.fontFamilyFallback ?? fontFamilyFallback,
      effectiveFontFamilyFallback: other.fontFamilyFallback != null
          ? other.effectiveFontFamilyFallback
          : effectiveFontFamilyFallback,
      fontSize: other.fontSize ?? fontSize,
      letterSpacing: other.letterSpacing ?? letterSpacing,
      wordSpacing: other.wordSpacing ?? wordSpacing,
      height: textHeight,
      leadingDistribution: other.leadingDistribution ?? leadingDistribution,
      locale: other.locale ?? locale,
      background: other.background ?? background,
      foreground: other.foreground ?? foreground,
      shadows: other.shadows ?? shadows,
      fontFeatures: other.fontFeatures ?? fontFeatures,
      fontVariations: other.fontVariations ?? fontVariations,
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
        other.decorationThickness == decorationThickness &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.textBaseline == textBaseline &&
        other.leadingDistribution == leadingDistribution &&
        other.fontFamily == fontFamily &&
        other.fontSize == fontSize &&
        other.letterSpacing == letterSpacing &&
        other.wordSpacing == wordSpacing &&
        other.height == height &&
        other.locale == locale &&
        other.background == background &&
        other.foreground == foreground &&
        listEquals<ui.Shadow>(other.shadows, shadows) &&
        listEquals<String>(other.fontFamilyFallback, fontFamilyFallback) &&
        listEquals<ui.FontFeature>(other.fontFeatures, fontFeatures) &&
        listEquals<ui.FontVariation>(other.fontVariations, fontVariations);
  }

  @override
  int get hashCode => Object.hash(
    color,
    decoration,
    decorationColor,
    decorationStyle,
    decorationThickness,
    fontWeight,
    fontStyle,
    textBaseline,
    leadingDistribution,
    fontFamily,
    fontFamilyFallback != null ? Object.hashAll(fontFamilyFallback!) : null,
    fontSize,
    letterSpacing,
    wordSpacing,
    height,
    locale,
    background,
    foreground,
    shadows != null ? Object.hashAll(shadows!) : null,
    Object.hash(
      fontFeatures != null ? Object.hashAll(fontFeatures!) : null,
      fontVariations != null ? Object.hashAll(fontVariations!) : null,
    ),
  );

  @override
  String toString() {
    var result = super.toString();
    assert(() {
      final List<String>? fontFamilyFallback = this.fontFamilyFallback;
      final double? fontSize = this.fontSize;
      final double? height = this.height;
      result =
          'TextStyle('
          'color: ${color ?? "unspecified"}, '
          'decoration: ${decoration ?? "unspecified"}, '
          'decorationColor: ${decorationColor ?? "unspecified"}, '
          'decorationStyle: ${decorationStyle ?? "unspecified"}, '
          'decorationThickness: ${decorationThickness ?? "unspecified"}, '
          'fontWeight: ${fontWeight ?? "unspecified"}, '
          'fontStyle: ${fontStyle ?? "unspecified"}, '
          'textBaseline: ${textBaseline ?? "unspecified"}, '
          'fontFamily: ${fontFamily ?? "unspecified"}, '
          'fontFamilyFallback: ${fontFamilyFallback != null && fontFamilyFallback.isNotEmpty ? fontFamilyFallback : "unspecified"}, '
          'fontSize: ${fontSize != null ? fontSize.toStringAsFixed(1) : "unspecified"}, '
          'letterSpacing: ${letterSpacing != null ? "${letterSpacing}x" : "unspecified"}, '
          'wordSpacing: ${wordSpacing != null ? "${wordSpacing}x" : "unspecified"}, '
          'height: ${height != null ? "${height.toStringAsFixed(1)}x" : "unspecified"}, '
          'leadingDistribution: ${leadingDistribution ?? "unspecified"}, '
          'locale: ${locale ?? "unspecified"}, '
          'background: ${background ?? "unspecified"}, '
          'foreground: ${foreground ?? "unspecified"}, '
          'shadows: ${shadows ?? "unspecified"}, '
          'fontFeatures: ${fontFeatures ?? "unspecified"}, '
          'fontVariations: ${fontVariations ?? "unspecified"}'
          ')';
      return true;
    }());
    return result;
  }
}

class EngineParagraph implements ui.Paragraph {
  EngineParagraph(BackendParagraph backendParagraph) {
    _ref = UniqueRef<BackendParagraph>(
      this,
      backendParagraph,
      'Paragraph',
      onDispose: (BackendParagraph p) => p.dispose(),
    );
  }

  late final UniqueRef<BackendParagraph> _ref;

  BackendParagraph get backendParagraph => _ref.nativeObject;

  double _lastLayoutConstraints = double.negativeInfinity;
  bool _hasCheckedForMissingCodePoints = false;

  @override
  double get width => backendParagraph.width;

  @override
  double get height => backendParagraph.height;

  @override
  double get longestLine => backendParagraph.longestLine;

  @override
  double get minIntrinsicWidth => backendParagraph.minIntrinsicWidth;

  @override
  double get maxIntrinsicWidth => backendParagraph.maxIntrinsicWidth;

  @override
  double get alphabeticBaseline => backendParagraph.alphabeticBaseline;

  @override
  double get ideographicBaseline => backendParagraph.ideographicBaseline;

  @override
  bool get didExceedMaxLines => backendParagraph.didExceedMaxLines;

  @override
  int get numberOfLines => backendParagraph.numberOfLines;

  @override
  int? getLineNumberAt(int codeUnitOffset) => backendParagraph.getLineNumberAt(codeUnitOffset);

  @override
  List<ui.TextBox> getBoxesForPlaceholders() => backendParagraph.getBoxesForPlaceholders();

  @override
  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    assert(!_ref.isDisposed, 'Paragraph has been disposed.');
    if (start < 0 || end < 0) {
      return const <ui.TextBox>[];
    }
    return backendParagraph.getBoxesForRange(
      start,
      end,
      boxHeightStyle: boxHeightStyle,
      boxWidthStyle: boxWidthStyle,
    );
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) =>
      backendParagraph.getPositionForOffset(offset);

  @override
  ui.GlyphInfo? getClosestGlyphInfoForOffset(ui.Offset offset) =>
      backendParagraph.getClosestGlyphInfoForOffset(offset);

  @override
  ui.GlyphInfo? getGlyphInfoAt(int codeUnitOffset) =>
      backendParagraph.getGlyphInfoAt(codeUnitOffset);

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    final int characterPosition = switch (position.affinity) {
      ui.TextAffinity.upstream => position.offset - 1,
      ui.TextAffinity.downstream => position.offset,
    };
    return backendParagraph.getWordBoundary(characterPosition);
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    final List<EngineLineMetrics> metrics = computeLineMetrics();
    final ui.TextRange line = _lineBoundaryAtOffset(metrics, position.offset);

    // A line's endIndex equals the next line's startIndex at a soft wrap, so
    // the lookup above cannot tell the two apart on its own and always answers
    // with the earlier line, as if the affinity were upstream. A downstream
    // position sitting exactly on that seam belongs to the next line instead.
    // This mirrors the native implementation in `lib/ui/text.dart`.
    final ui.TextRange nextLine = _lineBoundaryAtOffset(metrics, position.offset + 1);
    if (nextLine.isValid &&
        position.affinity == ui.TextAffinity.downstream &&
        line != nextLine &&
        position.offset == line.end &&
        line.end == nextLine.start) {
      return nextLine;
    }
    return line;
  }

  // The line containing [offset], treating both line bounds as inclusive.
  static ui.TextRange _lineBoundaryAtOffset(List<EngineLineMetrics> metrics, int offset) {
    for (final metric in metrics) {
      if (offset >= metric.startIndex && offset <= metric.endIndex) {
        return ui.TextRange(start: metric.startIndex, end: metric.endIndex);
      }
    }
    return ui.TextRange.empty;
  }

  @override
  List<EngineLineMetrics> computeLineMetrics() => backendParagraph.computeLineMetrics();

  @override
  EngineLineMetrics? getLineMetricsAt(int lineNumber) =>
      backendParagraph.getLineMetricsAt(lineNumber);

  @override
  void layout(ui.ParagraphConstraints constraints) {
    assert(!_ref.isDisposed, 'Paragraph has been disposed.');
    if (_lastLayoutConstraints == constraints.width) {
      return;
    }

    _lastLayoutConstraints = constraints.width;
    backendParagraph.layout(constraints.width);

    if (!ui_web.TestEnvironment.instance.disableFontFallbacks && !_hasCheckedForMissingCodePoints) {
      _hasCheckedForMissingCodePoints = true;
      final List<int> unresolvedCodePoints = backendParagraph.getUnresolvedCodePoints();
      if (unresolvedCodePoints.isNotEmpty) {
        FallbackFontService.instance.addMissingCodePoints(unresolvedCodePoints);
      }
    }
  }

  @override
  void dispose() {
    assert(!_ref.isDisposed, 'Paragraph has been disposed.');
    _ref.dispose();
  }

  @override
  bool get debugDisposed => _ref.debugDisposed;
}

class EngineParagraphBuilder implements ui.ParagraphBuilder {
  EngineParagraphBuilder(EngineParagraphStyle style) {
    _ref = UniqueRef<BackendParagraphBuilder>(
      this,
      renderer.createParagraphBuilder(style),
      'ParagraphBuilder',
      onDispose: (BackendParagraphBuilder builder) => builder.dispose(),
    );
    _styleStack.add(style.getTextStyle());
  }

  late final UniqueRef<BackendParagraphBuilder> _ref;

  BackendParagraphBuilder get _backendBuilder => _ref.nativeObject;

  final List<EngineTextStyle> _styleStack = <EngineTextStyle>[];

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
    assert(
      !(alignment == ui.PlaceholderAlignment.aboveBaseline ||
              alignment == ui.PlaceholderAlignment.belowBaseline ||
              alignment == ui.PlaceholderAlignment.baseline) ||
          baseline != null,
    );

    _placeholderCount++;
    _placeholderScales.add(scale);
    _backendBuilder.addPlaceholder(
      width * scale,
      height * scale,
      alignment,
      (baselineOffset ?? height) * scale,
      baseline ?? ui.TextBaseline.alphabetic,
    );
  }

  @override
  void addText(String text) {
    _backendBuilder.addText(text);
  }

  @override
  void pushStyle(ui.TextStyle style) {
    style as EngineTextStyle;
    final EngineTextStyle baseStyle = _styleStack.last;
    final EngineTextStyle mergedStyle = baseStyle.mergeWith(style);
    _styleStack.add(mergedStyle);
    _backendBuilder.pushStyle(mergedStyle);
  }

  @override
  void pop() {
    if (_styleStack.length <= 1) {
      // The top-level text style reflects the paragraph style and should not
      // be popped. Notice that the baseline SkParagraphBuilder implementation
      // checks only that the style stack is not empty, because it keeps the
      // paragraph style in a separate field rather than on the style stack.
      return;
    }
    _styleStack.removeLast();
    _backendBuilder.pop();
  }

  @override
  EngineParagraph build() {
    final BackendParagraph backendParagraph = _backendBuilder.build();
    // The backend builder is single-use; release it (and detach its
    // finalizer) as soon as the paragraph is built.
    _ref.dispose();
    return EngineParagraph(backendParagraph);
  }
}
