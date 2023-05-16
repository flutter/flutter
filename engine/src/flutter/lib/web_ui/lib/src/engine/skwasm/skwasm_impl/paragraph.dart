// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmLineMetrics implements ui.LineMetrics {
  factory SkwasmLineMetrics({
    required bool hardBreak,
    required double ascent,
    required double descent,
    required double unscaledAscent,
    required double height,
    required double width,
    required double left,
    required double baseline,
    required int lineNumber,
  }) => SkwasmLineMetrics._(lineMetricsCreate(
    hardBreak,
    ascent,
    descent,
    unscaledAscent,
    height,
    width,
    left,
    baseline,
    lineNumber,
  ));

  SkwasmLineMetrics._(this.handle);

  final LineMetricsHandle handle;
  bool _isDisposed = false;

  @override
  bool get hardBreak => lineMetricsGetHardBreak(handle);

  @override
  double get ascent => lineMetricsGetAscent(handle);

  @override
  double get descent => lineMetricsGetDescent(handle);

  @override
  double get unscaledAscent => lineMetricsGetUnscaledAscent(handle);

  @override
  double get height => lineMetricsGetHeight(handle);

  @override
  double get width => lineMetricsGetWidth(handle);

  @override
  double get left => lineMetricsGetLeft(handle);

  @override
  double get baseline => lineMetricsGetBaseline(handle);

  @override
  int get lineNumber => lineMetricsGetLineNumber(handle);

  void dispose() {
    if (_isDisposed) {
      lineMetricsDispose(handle);
      _isDisposed = true;
    }
  }
}

class SkwasmParagraph implements ui.Paragraph {
  SkwasmParagraph(this.handle);

  final ParagraphHandle handle;
  bool _isDisposed = false;
  bool _hasCheckedForMissingCodePoints = false;

  @override
  double get width => paragraphGetWidth(handle);

  @override
  double get height => paragraphGetHeight(handle);

  @override
  double get longestLine => paragraphGetLongestLine(handle);

  @override
  double get minIntrinsicWidth => paragraphGetMinIntrinsicWidth(handle);

  @override
  double get maxIntrinsicWidth => paragraphGetMaxIntrinsicWidth(handle);

  @override
  double get alphabeticBaseline => paragraphGetAlphabeticBaseline(handle);

  @override
  double get ideographicBaseline => paragraphGetIdeographicBaseline(handle);

  @override
  bool get didExceedMaxLines => paragraphGetDidExceedMaxLines(handle);

  @override
  void layout(ui.ParagraphConstraints constraints) {
    paragraphLayout(handle, constraints.width);
    if (!_hasCheckedForMissingCodePoints) {
      _hasCheckedForMissingCodePoints = true;
      final int missingCodePointCount = paragraphGetUnresolvedCodePoints(handle, nullptr, 0);
      if (missingCodePointCount > 0) {
        withStackScope((StackScope scope) {
          final Pointer<Uint32> codePointBuffer = scope.allocUint32Array(missingCodePointCount);
          final int returnedCodePointCount = paragraphGetUnresolvedCodePoints(
            handle,
            codePointBuffer,
            missingCodePointCount
          );
          assert(missingCodePointCount == returnedCodePointCount);
          renderer.fontCollection.fontFallbackManager!.addMissingCodePoints(
            List<int>.generate(
              missingCodePointCount,
              (int index) => codePointBuffer[index]
            )
          );
        });
      }
    }
  }

  List<ui.TextBox> _convertTextBoxList(TextBoxListHandle listHandle) {
    final int length = textBoxListGetLength(listHandle);
    return withStackScope((StackScope scope) {
      final RawRect tempRect = scope.allocFloatArray(4);
      return List<ui.TextBox>.generate(length, (int index) {
        final int textDirectionIndex =
          textBoxListGetBoxAtIndex(listHandle, index, tempRect);
        return ui.TextBox.fromLTRBD(
          tempRect[0],
          tempRect[1],
          tempRect[2],
          tempRect[3],
          ui.TextDirection.values[textDirectionIndex],
        );
      });
    });
  }

  @override
  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight
  }) {
    final TextBoxListHandle listHandle = paragraphGetBoxesForRange(
      handle,
      start,
      end,
      boxHeightStyle.index,
      boxWidthStyle.index
    );
    final List<ui.TextBox> boxes = _convertTextBoxList(listHandle);
    textBoxListDispose(listHandle);
    return boxes;
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) => withStackScope((StackScope scope) {
    final Pointer<Int32> outAffinity = scope.allocInt32Array(1);
    final int position = paragraphGetPositionForOffset(
      handle,
      offset.dx,
      offset.dy,
      outAffinity
    );
    return ui.TextPosition(
      offset: position,
      affinity: ui.TextAffinity.values[outAffinity[0]],
    );
  });

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) => withStackScope((StackScope scope) {
    final Pointer<Int32> outRange = scope.allocInt32Array(2);
    paragraphGetWordBoundary(handle, position.offset, outRange);
    return ui.TextRange(start: outRange[0], end: outRange[1]);
  });

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    final int lineNumber = paragraphGetLineNumberAt(handle, position.offset);
    final LineMetricsHandle metricsHandle =
      paragraphGetLineMetricsAtIndex(handle, lineNumber);
    final ui.TextRange range = ui.TextRange(
      start: lineMetricsGetStartIndex(metricsHandle),
      end: lineMetricsGetEndIndex(metricsHandle),
    );
    lineMetricsDispose(metricsHandle);
    return range;
  }

  @override
  List<ui.TextBox> getBoxesForPlaceholders() {
    final TextBoxListHandle listHandle = paragraphGetBoxesForPlaceholders(handle);
    final List<ui.TextBox> boxes = _convertTextBoxList(listHandle);
    textBoxListDispose(listHandle);
    return boxes;
  }

  @override
  List<SkwasmLineMetrics> computeLineMetrics() {
    final int lineCount = paragraphGetLineCount(handle);
    return List<SkwasmLineMetrics>.generate(lineCount,
      (int index) => SkwasmLineMetrics._(paragraphGetLineMetricsAtIndex(handle, index))
    );
  }

  @override
  bool get debugDisposed => _isDisposed;

  @override
  void dispose() {
    if (!_isDisposed) {
      paragraphDispose(handle);
      _isDisposed = true;
    }
  }
}

void withScopedFontList(
    List<String> fontFamilies,
  void Function(Pointer<SkStringHandle>, int) callback) {
  withStackScope((StackScope scope) {
    final Pointer<SkStringHandle> familiesPtr =
      scope.allocPointerArray(fontFamilies.length).cast<SkStringHandle>();
    int nativeIndex = 0;
    for (int i = 0; i < fontFamilies.length; i++) {
      familiesPtr[nativeIndex] = skStringFromDartString(fontFamilies[i]);
      nativeIndex++;
    }
    callback(familiesPtr, fontFamilies.length);
    for (int i = 0; i < fontFamilies.length; i++) {
      skStringFree(familiesPtr[i]);
    }
  });
}

class SkwasmTextStyle implements ui.TextStyle {
  SkwasmTextStyle({
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
  });

  void applyToHandle(TextStyleHandle handle) {
    if (color != null) {
      textStyleSetColor(handle, color!.value);
    }
    if (decoration != null) {
      textStyleSetDecoration(handle, decoration!.maskValue);
    }
    if (decorationColor != null) {
      textStyleSetDecorationColor(handle, decorationColor!.value);
    }
    if (decorationStyle != null) {
      textStyleSetDecorationStyle(handle, decorationStyle!.index);
    }
    if (decorationThickness != null) {
      textStyleSetDecorationThickness(handle, decorationThickness!);
    }
    if (fontWeight != null || fontStyle != null) {
      textStyleSetFontStyle(
        handle,
        (fontWeight ?? ui.FontWeight.normal).value,
        (fontStyle ?? ui.FontStyle.normal).index
      );
    }
    if (textBaseline != null) {
      textStyleSetTextBaseline(handle, textBaseline!.index);
    }

    final List<String> effectiveFontFamilies = fontFamilies;
    if (effectiveFontFamilies.isNotEmpty) {
      withScopedFontList(effectiveFontFamilies,
        (Pointer<SkStringHandle> families, int count) =>
          textStyleAddFontFamilies(handle, families, count));
    }

    if (fontSize != null) {
      textStyleSetFontSize(handle, fontSize!);
    }
    if (letterSpacing != null) {
      textStyleSetLetterSpacing(handle, letterSpacing!);
    }
    if (wordSpacing != null) {
      textStyleSetWordSpacing(handle, wordSpacing!);
    }
    if (height != null) {
      textStyleSetHeight(handle, height!);
    }
    if (leadingDistribution != null) {
      textStyleSetHalfLeading(
        handle,
        leadingDistribution == ui.TextLeadingDistribution.even
      );
    }
    if (locale != null) {
      final SkStringHandle localeHandle =
        skStringFromDartString(locale!.toLanguageTag());
      textStyleSetLocale(handle, localeHandle);
      skStringFree(localeHandle);
    }
    if (background != null) {
      textStyleSetBackground(handle, (background! as SkwasmPaint).handle);
    }
    if (foreground != null) {
      textStyleSetForeground(handle, (foreground! as SkwasmPaint).handle);
    }
    if (shadows != null) {
      for (final ui.Shadow shadow in shadows!) {
        textStyleAddShadow(
          handle,
          shadow.color.value,
          shadow.offset.dx,
          shadow.offset.dy,
          shadow.blurSigma,
        );
      }
    }
    if (fontFeatures != null) {
      for (final ui.FontFeature feature in fontFeatures!) {
        final SkStringHandle featureName = skStringFromDartString(feature.feature);
        textStyleAddFontFeature(handle, featureName, feature.value);
        skStringFree(featureName);
      }
    }

    if (fontVariations != null && fontVariations!.isNotEmpty) {
      final int variationCount = fontVariations!.length;
      withStackScope((StackScope scope) {
        final Pointer<Uint32> axisBuffer = scope.allocUint32Array(variationCount);
        final Pointer<Float> valueBuffer = scope.allocFloatArray(variationCount);
        for (int i = 0; i < variationCount; i++) {
          final ui.FontVariation variation = fontVariations![i];
          final String axis = variation.axis;
          assert(axis.length == 4); // 4 byte code
          final int axisNumber =
            axis.codeUnitAt(0) << 24 |
            axis.codeUnitAt(1) << 16 |
            axis.codeUnitAt(2) << 8 |
            axis.codeUnitAt(3);
          axisBuffer[i] = axisNumber;
          valueBuffer[i] = variation.value;
        }
        textStyleSetFontVariations(handle, axisBuffer, valueBuffer, variationCount);
      });
    }
  }

  List<String> get fontFamilies => <String>[
    if (fontFamily != null) fontFamily!,
    if (fontFamilyFallback != null) ...fontFamilyFallback!,
  ];

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
  final ui.Paint? background;
  final ui.Paint? foreground;
  final List<ui.Shadow>? shadows;
  final List<ui.FontFeature>? fontFeatures;
  final List<ui.FontVariation>? fontVariations;
}

class SkwasmStrutStyle implements ui.StrutStyle {
  factory SkwasmStrutStyle({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    double? leading,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    bool? forceStrutHeight,
  }) {
    final StrutStyleHandle handle = strutStyleCreate();
    if (fontFamily != null || fontFamilyFallback != null) {
      final List<String> fontFamilies = <String>[
        if (fontFamily != null) fontFamily,
        if (fontFamilyFallback != null) ...fontFamilyFallback,
      ];
      if (fontFamilies.isNotEmpty) {
        withScopedFontList(fontFamilies,
          (Pointer<SkStringHandle> families, int count) =>
            strutStyleSetFontFamilies(handle, families, count));
      }
    }
    if (fontSize != null) {
      strutStyleSetFontSize(handle, fontSize);
    }
    if (height != null) {
      strutStyleSetHeight(handle, height);
    }
    if (leadingDistribution != null) {
      strutStyleSetHalfLeading(
        handle,
        leadingDistribution == ui.TextLeadingDistribution.even);
    }
    if (leading != null) {
      strutStyleSetLeading(handle, leading);
    }
    if (fontWeight != null || fontStyle != null) {
      fontWeight ??= ui.FontWeight.normal;
      fontStyle ??= ui.FontStyle.normal;
      strutStyleSetFontStyle(handle, fontWeight.value, fontStyle.index);
    }
    if (forceStrutHeight != null) {
      strutStyleSetForceStrutHeight(handle, forceStrutHeight);
    }
    return SkwasmStrutStyle._(handle);
  }

  SkwasmStrutStyle._(this.handle);

  final StrutStyleHandle handle;
}

class SkwasmParagraphStyle implements ui.ParagraphStyle {
  factory SkwasmParagraphStyle({
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
    final ParagraphStyleHandle handle = paragraphStyleCreate();
    if (textAlign != null) {
      paragraphStyleSetTextAlign(handle, textAlign.index);
    }
    if (textDirection != null) {
      paragraphStyleSetTextDirection(handle, textDirection.index);
    }
    if (maxLines != null) {
      paragraphStyleSetMaxLines(handle, maxLines);
    }
    if (height != null) {
      paragraphStyleSetHeight(handle, height);
    }
    if (textHeightBehavior != null) {
      paragraphStyleSetTextHeightBehavior(
        handle,
        textHeightBehavior.applyHeightToFirstAscent,
        textHeightBehavior.applyHeightToLastDescent,
      );
    }
    if (ellipsis != null) {
      final SkStringHandle ellipsisHandle = skStringFromDartString(ellipsis);
      paragraphStyleSetEllipsis(handle, ellipsisHandle);
      skStringFree(ellipsisHandle);
    }
    if (strutStyle != null) {
      strutStyle as SkwasmStrutStyle;
      paragraphStyleSetStrutStyle(handle, strutStyle.handle);
    }
    final TextStyleHandle textStyleHandle = textStyleCopy(
      (renderer.fontCollection as SkwasmFontCollection).defaultTextStyle,
    );
    if (fontFamily != null) {
      withScopedFontList(<String>[fontFamily],
        (Pointer<SkStringHandle> families, int count) =>
          textStyleAddFontFamilies(textStyleHandle, families, count));
    }
    if (fontSize != null) {
      textStyleSetFontSize(textStyleHandle, fontSize);
    }
    if (fontWeight != null || fontStyle != null) {
      fontWeight ??= ui.FontWeight.normal;
      fontStyle ??= ui.FontStyle.normal;
      textStyleSetFontStyle(textStyleHandle, fontWeight.value, fontStyle.index);
    }
    if (textHeightBehavior != null) {
      textStyleSetHalfLeading(
        textStyleHandle,
        textHeightBehavior.leadingDistribution == ui.TextLeadingDistribution.even,
      );
    }
    if (locale != null) {
      final SkStringHandle localeHandle =
      skStringFromDartString(locale.toLanguageTag());
      textStyleSetLocale(textStyleHandle, localeHandle);
      skStringFree(localeHandle);
    }
    paragraphStyleSetTextStyle(handle, textStyleHandle);
    return SkwasmParagraphStyle._(handle, textStyleHandle, fontFamily);
  }

  SkwasmParagraphStyle._(this.handle, this.textStyleHandle, this.defaultFontFamily);

  final ParagraphStyleHandle handle;
  final TextStyleHandle textStyleHandle;
  final String? defaultFontFamily;
}

class _TextStyleStackEntry {
  _TextStyleStackEntry(this.style, this.handle);

  SkwasmTextStyle style;
  TextStyleHandle handle;
}

class SkwasmParagraphBuilder implements ui.ParagraphBuilder {
  factory SkwasmParagraphBuilder(
    SkwasmParagraphStyle style,
    SkwasmFontCollection collection,
  ) => SkwasmParagraphBuilder._(paragraphBuilderCreate(
      style.handle,
      collection.handle,
    ), style);

  SkwasmParagraphBuilder._(this.handle, this.style);
  final ParagraphBuilderHandle handle;
  final SkwasmParagraphStyle style;
  final List<_TextStyleStackEntry> textStyleStack = <_TextStyleStackEntry>[];

  @override
  List<double> placeholderScales = <double>[];

  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    double scale = 1.0,
    double? baselineOffset,
    ui.TextBaseline? baseline
  }) {
    paragraphBuilderAddPlaceholder(
      handle,
      width * scale,
      height * scale,
      alignment.index,
      (baselineOffset ?? height) * scale,
      (baseline ?? ui.TextBaseline.alphabetic).index,
    );
    placeholderScales.add(scale);
  }

  @override
  void addText(String text) {
    final SkString16Handle stringHandle = skString16FromDartString(text);
    paragraphBuilderAddText(handle, stringHandle);
    skString16Free(stringHandle);
  }

  @override
  ui.Paragraph build() {
    return SkwasmParagraph(paragraphBuilderBuild(handle));
  }

  @override
  int get placeholderCount => placeholderScales.length;

  @override
  void pop() {
    final TextStyleHandle textStyleHandle = textStyleStack.removeLast().handle;
    textStyleDispose(textStyleHandle);
    paragraphBuilderPop(handle);
  }

  @override
  void pushStyle(ui.TextStyle textStyle) {
    textStyle as SkwasmTextStyle;
    TextStyleHandle sourceStyleHandle = nullptr;
    if (textStyleStack.isNotEmpty) {
      sourceStyleHandle = textStyleStack.last.handle;
    }
    if (sourceStyleHandle == nullptr) {
      sourceStyleHandle = style.textStyleHandle;
    }
    if (sourceStyleHandle == nullptr) {
      sourceStyleHandle =
        (renderer.fontCollection as SkwasmFontCollection).defaultTextStyle;
    }
    final TextStyleHandle styleHandle = textStyleCopy(sourceStyleHandle);
    textStyle.applyToHandle(styleHandle);
    textStyleStack.add(_TextStyleStackEntry(textStyle, styleHandle));
    paragraphBuilderPushStyle(handle, styleHandle);
  }
}
