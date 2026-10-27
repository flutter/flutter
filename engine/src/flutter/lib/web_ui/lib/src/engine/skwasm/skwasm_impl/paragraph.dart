// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

int _getFourByteTag(String s) {
  assert(s.length == 4);
  return s.codeUnitAt(0) << 24 | s.codeUnitAt(1) << 16 | s.codeUnitAt(2) << 8 | s.codeUnitAt(3);
}

EngineLineMetrics _createLineMetricsFromHandle(LineMetricsHandle handle) {
  return EngineLineMetrics(
    hardBreak: lineMetricsGetHardBreak(handle),
    ascent: lineMetricsGetAscent(handle),
    descent: lineMetricsGetDescent(handle),
    unscaledAscent: lineMetricsGetUnscaledAscent(handle),
    height: lineMetricsGetHeight(handle),
    width: lineMetricsGetWidth(handle),
    left: lineMetricsGetLeft(handle),
    baseline: lineMetricsGetBaseline(handle),
    lineNumber: lineMetricsGetLineNumber(handle),
    startIndex: lineMetricsGetStartIndex(handle),
    endIndex: lineMetricsGetEndIndex(handle),
  );
}

class SkwasmParagraph implements BackendParagraph {
  SkwasmParagraph(this.handle);

  final ParagraphHandle handle;

  @override
  void dispose() {
    paragraphDispose(handle);
  }

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
  int get numberOfLines => paragraphGetLineCount(handle);

  @override
  int? getLineNumberAt(int codeUnitOffset) {
    final int lineNumber = paragraphGetLineNumberAt(handle, codeUnitOffset);
    return lineNumber >= 0 ? lineNumber : null;
  }

  @override
  void layout(double width) {
    paragraphLayout(handle, width);
  }

  @override
  List<int> getUnresolvedCodePoints() {
    final int missingCodePointCount = paragraphGetUnresolvedCodePoints(handle, nullptr, 0);
    if (missingCodePointCount == 0) {
      return const <int>[];
    }
    return withStackScope((StackScope scope) {
      final Pointer<Uint32> codePointBuffer = scope.allocUint32Array(missingCodePointCount);
      final int returnedCodePointCount = paragraphGetUnresolvedCodePoints(
        handle,
        codePointBuffer,
        missingCodePointCount,
      );
      assert(missingCodePointCount == returnedCodePointCount);
      return codePointBuffer.toUint32List(missingCodePointCount);
    });
  }

  List<ui.TextBox> _convertTextBoxList(TextBoxListHandle listHandle) {
    final int length = textBoxListGetLength(listHandle);
    return withStackScope((StackScope scope) {
      final RawRect tempRect = scope.allocFloatArray(4);
      return List<ui.TextBox>.generate(length, (int index) {
        final int textDirectionIndex = textBoxListGetBoxAtIndex(listHandle, index, tempRect);
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
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    final TextBoxListHandle listHandle = paragraphGetBoxesForRange(
      handle,
      start,
      end,
      boxHeightStyle.index,
      boxWidthStyle.index,
    );
    final List<ui.TextBox> boxes = _convertTextBoxList(listHandle);
    textBoxListDispose(listHandle);
    return boxes;
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) => withStackScope((StackScope scope) {
    final Pointer<Int32> outAffinity = scope.allocInt32Array(1);
    final int position = paragraphGetPositionForOffset(handle, offset.dx, offset.dy, outAffinity);
    return ui.TextPosition(offset: position, affinity: ui.TextAffinity.values[outAffinity[0]]);
  });

  @override
  ui.GlyphInfo? getGlyphInfoAt(int codeUnitOffset) {
    return withStackScope((StackScope scope) {
      final Pointer<Float> outRect = scope.allocFloatArray(4);
      final Pointer<Uint32> outRange = scope.allocUint32Array(2);
      final Pointer<Bool> outBooleanFlags = scope.allocBoolArray(1);
      return paragraphGetGlyphInfoAt(handle, codeUnitOffset, outRect, outRange, outBooleanFlags)
          ? ui.GlyphInfo(
              scope.convertRectFromNative(outRect),
              ui.TextRange(start: outRange[0], end: outRange[1]),
              outBooleanFlags[0] ? ui.TextDirection.ltr : ui.TextDirection.rtl,
            )
          : null;
    });
  }

  @override
  ui.GlyphInfo? getClosestGlyphInfoForOffset(ui.Offset offset) {
    return withStackScope((StackScope scope) {
      final Pointer<Float> outRect = scope.allocFloatArray(4);
      final Pointer<Uint32> outRange = scope.allocUint32Array(2);
      final Pointer<Bool> outBooleanFlags = scope.allocBoolArray(1);
      return paragraphGetClosestGlyphInfoAtCoordinate(
            handle,
            offset.dx,
            offset.dy,
            outRect,
            outRange,
            outBooleanFlags,
          )
          ? ui.GlyphInfo(
              scope.convertRectFromNative(outRect),
              ui.TextRange(start: outRange[0], end: outRange[1]),
              outBooleanFlags[0] ? ui.TextDirection.ltr : ui.TextDirection.rtl,
            )
          : null;
    });
  }

  @override
  ui.TextRange getWordBoundary(int characterPosition) => withStackScope((StackScope scope) {
    final Pointer<Int32> outRange = scope.allocInt32Array(2);
    paragraphGetWordBoundary(handle, characterPosition, outRange);
    return ui.TextRange(start: outRange[0], end: outRange[1]);
  });

  @override
  List<ui.TextBox> getBoxesForPlaceholders() {
    final TextBoxListHandle listHandle = paragraphGetBoxesForPlaceholders(handle);
    final List<ui.TextBox> boxes = _convertTextBoxList(listHandle);
    textBoxListDispose(listHandle);
    return boxes;
  }

  @override
  List<EngineLineMetrics> computeLineMetrics() {
    final int lineCount = paragraphGetLineCount(handle);
    return List<EngineLineMetrics>.generate(lineCount, (int index) {
      final LineMetricsHandle metricsHandle = paragraphGetLineMetricsAtIndex(handle, index);
      final EngineLineMetrics metrics = _createLineMetricsFromHandle(metricsHandle);
      lineMetricsDispose(metricsHandle);
      return metrics;
    });
  }

  @override
  EngineLineMetrics? getLineMetricsAt(int lineNumber) {
    final LineMetricsHandle metricsHandle = paragraphGetLineMetricsAtIndex(handle, lineNumber);
    if (metricsHandle == nullptr) {
      return null;
    }
    final EngineLineMetrics metrics = _createLineMetricsFromHandle(metricsHandle);
    lineMetricsDispose(metricsHandle);
    return metrics;
  }
}

void _withScopedFontList(
  List<String> fontFamilies,
  void Function(Pointer<SkStringHandle>, int) callback,
) {
  withStackScope((StackScope scope) {
    final Pointer<SkStringHandle> familiesPtr = scope
        .allocPointerArray(fontFamilies.length)
        .cast<SkStringHandle>();
    var nativeIndex = 0;
    for (var i = 0; i < fontFamilies.length; i++) {
      familiesPtr[nativeIndex] = skStringFromDartString(fontFamilies[i]);
      nativeIndex++;
    }
    callback(familiesPtr, fontFamilies.length);
    for (var i = 0; i < fontFamilies.length; i++) {
      skStringFree(familiesPtr[i]);
    }
  });
}

class SkwasmNativeTextStyle extends SkwasmObjectWrapper<RawTextStyle> {
  SkwasmNativeTextStyle(TextStyleHandle handle)
    : super(handle, (TextStyleHandle h) => textStyleDispose(h), 'TextStyle');

  factory SkwasmNativeTextStyle.defaultTextStyle() => SkwasmNativeTextStyle(textStyleCreate());

  SkwasmNativeTextStyle copy() {
    return SkwasmNativeTextStyle(textStyleCopy(handle));
  }
}

void _applyTextStyleToNative(EngineTextStyle style, SkwasmNativeTextStyle nativeStyle) {
  final TextStyleHandle handle = nativeStyle.handle;
  if (style.color != null) {
    textStyleSetColor(handle, style.color!.value);
  }
  if (style.decoration != null) {
    textStyleSetDecoration(handle, style.decoration!.maskValue);
  }
  if (style.decorationColor != null) {
    textStyleSetDecorationColor(handle, style.decorationColor!.value);
  }
  if (style.decorationStyle != null) {
    textStyleSetDecorationStyle(handle, style.decorationStyle!.index);
  }
  if (style.decorationThickness != null) {
    textStyleSetDecorationThickness(handle, style.decorationThickness!);
  }
  if (style.fontWeight != null || style.fontStyle != null) {
    textStyleSetFontStyle(
      handle,
      (style.fontWeight ?? ui.FontWeight.normal).value,
      (style.fontStyle ?? ui.FontStyle.normal).index,
    );
  }
  if (style.textBaseline != null) {
    textStyleSetTextBaseline(handle, style.textBaseline!.index);
  }

  final List<String> effectiveFontFamilies = style.effectiveFontFamilies;
  if (effectiveFontFamilies.isNotEmpty) {
    _withScopedFontList(
      effectiveFontFamilies,
      (Pointer<SkStringHandle> families, int count) =>
          textStyleAddFontFamilies(handle, families, count),
    );
  }

  if (style.fontSize != null) {
    textStyleSetFontSize(handle, style.fontSize!);
  }
  if (style.letterSpacing != null) {
    textStyleSetLetterSpacing(handle, style.letterSpacing!);
  }
  if (style.wordSpacing != null) {
    textStyleSetWordSpacing(handle, style.wordSpacing!);
  }
  if (style.height != null) {
    textStyleSetHeight(handle, style.height!);
  }
  if (style.halfLeading != null) {
    textStyleSetHalfLeading(handle, style.halfLeading!);
  }
  if (style.locale != null) {
    final SkStringHandle localeHandle = skStringFromDartString(style.locale!.toLanguageTag());
    textStyleSetLocale(handle, localeHandle);
    skStringFree(localeHandle);
  }
  if (style.background != null) {
    final PaintHandle backgroundPaint = (style.background! as SkwasmPaint).toRawPaint();
    textStyleSetBackground(handle, backgroundPaint);
    paintDispose(backgroundPaint);
  }
  if (style.foreground != null) {
    final PaintHandle foregroundPaint = (style.foreground! as SkwasmPaint).toRawPaint();
    textStyleSetForeground(handle, foregroundPaint);
    paintDispose(foregroundPaint);
  }
  if (style.shadows != null) {
    for (final ui.Shadow shadow in style.shadows!) {
      textStyleAddShadow(
        handle,
        shadow.color.value,
        shadow.offset.dx,
        shadow.offset.dy,
        shadow.blurSigma,
      );
    }
  }
  if (style.fontFeatures != null) {
    for (final ui.FontFeature feature in style.fontFeatures!) {
      final SkStringHandle featureName = skStringFromDartString(feature.feature);
      textStyleAddFontFeature(handle, featureName, feature.value);
      skStringFree(featureName);
    }
  }

  final List<ui.FontVariation> effectiveFontVariations = style.effectiveFontVariations;
  final int variationCount = effectiveFontVariations.length;
  withStackScope((StackScope scope) {
    final Pointer<Uint32> axisBuffer = scope.allocUint32Array(variationCount);
    final Pointer<Float> valueBuffer = scope.allocFloatArray(variationCount);
    for (var i = 0; i < variationCount; i++) {
      final ui.FontVariation variation = effectiveFontVariations[i];
      axisBuffer[i] = _getFourByteTag(variation.axis);
      valueBuffer[i] = variation.value;
    }
    textStyleSetFontVariations(handle, axisBuffer, valueBuffer, variationCount);
  });
}

StrutStyleHandle _createNativeStrutStyle(EngineStrutStyle style) {
  final StrutStyleHandle handle = strutStyleCreate();
  final List<String> effectiveFontFamilies = style.effectiveFontFamilies;
  if (effectiveFontFamilies.isNotEmpty) {
    _withScopedFontList(
      effectiveFontFamilies,
      (Pointer<SkStringHandle> families, int count) =>
          strutStyleSetFontFamilies(handle, families, count),
    );
  }
  if (style.fontSize != null) {
    strutStyleSetFontSize(handle, style.fontSize!);
  }
  if (style.height != null) {
    strutStyleSetHeight(handle, style.height!);
  }
  if (style.halfLeading != null) {
    strutStyleSetHalfLeading(handle, style.halfLeading!);
  }
  if (style.leading != null) {
    strutStyleSetLeading(handle, style.leading!);
  }
  if (style.fontWeight != null || style.fontStyle != null) {
    strutStyleSetFontStyle(
      handle,
      (style.fontWeight ?? ui.FontWeight.normal).value,
      (style.fontStyle ?? ui.FontStyle.normal).index,
    );
  }
  if (style.forceStrutHeight != null) {
    strutStyleSetForceStrutHeight(handle, style.forceStrutHeight!);
  }
  return handle;
}

ParagraphStyleHandle _createNativeParagraphStyle(
  EngineParagraphStyle style,
  SkwasmFontCollection collection,
) {
  final ParagraphStyleHandle handle = paragraphStyleCreate();
  if (style.textAlign != null) {
    paragraphStyleSetTextAlign(handle, style.textAlign!.index);
  }
  if (style.textDirection != null) {
    paragraphStyleSetTextDirection(handle, style.textDirection!.index);
  }
  if (style.maxLines != null) {
    paragraphStyleSetMaxLines(handle, style.maxLines!);
  }
  if (style.height != null) {
    paragraphStyleSetHeight(handle, style.height!);
  }
  if (style.textHeightBehavior != null) {
    paragraphStyleSetTextHeightBehavior(
      handle,
      style.textHeightBehavior!.applyHeightToFirstAscent,
      style.textHeightBehavior!.applyHeightToLastDescent,
    );
  }
  if (style.ellipsis != null) {
    final SkStringHandle ellipsisHandle = skStringFromDartString(style.ellipsis!);
    paragraphStyleSetEllipsis(handle, ellipsisHandle);
    skStringFree(ellipsisHandle);
  }
  final EngineStrutStyle? strutStyle = style.effectiveStrutStyle;
  if (strutStyle != null) {
    final StrutStyleHandle strutStyleHandle = _createNativeStrutStyle(strutStyle);
    paragraphStyleSetStrutStyle(handle, strutStyleHandle);
    strutStyleDispose(strutStyleHandle);
  }
  final SkwasmNativeTextStyle textStyle = collection.defaultTextStyle.copy();
  _applyTextStyleToNative(style.getTextStyle(), textStyle);
  paragraphStyleSetTextStyle(handle, textStyle.handle);
  textStyle.dispose();
  paragraphStyleSetApplyRoundingHack(handle, false);
  // Like the native engine, render soft hyphens unless they are hidden.
  paragraphStyleSetRenderSoftHyphens(handle, style.hyphens != ui.Hyphens.hidden);
  return handle;
}

class SkwasmParagraphBuilder implements BackendParagraphBuilder {
  factory SkwasmParagraphBuilder(EngineParagraphStyle style, SkwasmFontCollection collection) {
    final ParagraphStyleHandle paragraphStyleHandle = _createNativeParagraphStyle(
      style,
      collection,
    );
    final builder = SkwasmParagraphBuilder._(
      paragraphBuilderCreate(paragraphStyleHandle, collection.handle),
      collection,
    );
    paragraphStyleDispose(paragraphStyleHandle);
    return builder;
  }

  SkwasmParagraphBuilder._(this.handle, this.fontCollection);

  final ParagraphBuilderHandle handle;
  final SkwasmFontCollection fontCollection;

  @override
  void dispose() {
    paragraphBuilderDispose(handle);
  }

  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment,
    double baselineOffset,
    ui.TextBaseline baseline,
  ) {
    paragraphBuilderAddPlaceholder(
      handle,
      width,
      height,
      alignment.index,
      baselineOffset,
      baseline.index,
    );
  }

  @override
  void addText(String text) {
    final SkString16Handle stringHandle = skString16FromDartString(text);
    paragraphBuilderAddText(handle, stringHandle);
    skString16Free(stringHandle);
  }

  static final DomV8BreakIterator _v8BreakIterator = createV8BreakIterator();
  static final DomSegmenter _graphemeSegmenter = createIntlSegmenter(granularity: 'grapheme');
  static final DomSegmenter _wordSegmenter = createIntlSegmenter(granularity: 'word');
  static final DomTextDecoder _utf8Decoder = DomTextDecoder();

  void _addSegmenterData() => withStackScope((StackScope scope) {
    // Because some of the string processing is dealt with manually in dart,
    // and some is handled by the browser, we actually need both a dart string
    // and a JS string. Converting from linear memory to Dart strings or JS
    // strings is more efficient than directly converting to each other, so we
    // just create both up front here.
    final Pointer<Uint32> outSize = scope.allocUint32Array(1);
    final Pointer<Uint8> utf8Data = paragraphBuilderGetUtf8Text(handle, outSize);

    final String text;
    final JSString jsText;
    if (utf8Data == nullptr) {
      text = '';
      jsText = ''.toJS;
    } else {
      text = utf8.decode(utf8Data.toUint8List(outSize.value));
      jsText = _utf8Decoder.decode(
        // In an ideal world we would just use a subview of wasm memory rather
        // than a slice, but the TextDecoder API doesn't work on shared buffer
        // sources yet.
        // See https://bugs.chromium.org/p/chromium/issues/detail?id=1012656
        JSUint8Array(skwasmInstance.wasmMemory.buffer)
            .slice(utf8Data.address, utf8Data.address + outSize.value),
      );
    }

    _addGraphemeBreakData(text, jsText);
    _addWordBreakData(text, jsText);
    _addLineBreakData(text, jsText);
  });

  UnicodePositionBufferHandle _createBreakPositionBuffer(
    String text,
    JSString jsText,
    DomSegmenter segmenter,
  ) {
    final DomIteratorWrapper<DomSegment> iterator = segmenter.segmentRaw(jsText).iterator();
    final breaks = <int>[];
    while (iterator.moveNext()) {
      breaks.add(iterator.current.index);
    }
    breaks.add(text.length);

    final UnicodePositionBufferHandle positionBuffer = unicodePositionBufferCreate(breaks.length);
    final Pointer<Uint32> buffer = unicodePositionBufferGetDataPointer(positionBuffer);
    for (var i = 0; i < breaks.length; i++) {
      buffer[i] = breaks[i];
    }
    return positionBuffer;
  }

  void _addGraphemeBreakData(String text, JSString jsText) {
    final UnicodePositionBufferHandle positionBuffer = _createBreakPositionBuffer(
      text,
      jsText,
      _graphemeSegmenter,
    );
    paragraphBuilderSetGraphemeBreaksUtf16(handle, positionBuffer);
    unicodePositionBufferFree(positionBuffer);
  }

  void _addWordBreakData(String text, JSString jsText) {
    final UnicodePositionBufferHandle positionBuffer = _createBreakPositionBuffer(
      text,
      jsText,
      _wordSegmenter,
    );
    paragraphBuilderSetWordBreaksUtf16(handle, positionBuffer);
    unicodePositionBufferFree(positionBuffer);
  }

  void _addLineBreakData(String text, JSString jsText) {
    final List<LineBreakFragment> lineBreaks = breakLinesUsingV8BreakIterator(
      text,
      jsText,
      _v8BreakIterator,
    );
    final LineBreakBufferHandle lineBreakBuffer = lineBreakBufferCreate(lineBreaks.length + 1);
    final Pointer<LineBreak> lineBreakPointer = lineBreakBufferGetDataPointer(lineBreakBuffer);

    // First line break is always zero. The buffer is zero initialized, so we can just
    // skip the first one.
    for (var i = 0; i < lineBreaks.length; i++) {
      final LineBreakFragment fragment = lineBreaks[i];
      lineBreakPointer[i + 1].position = fragment.end;
      lineBreakPointer[i + 1].lineBreakType = fragment.type == LineBreakType.mandatory
          ? kHardLineBreak
          : kSoftLineBreak;
    }
    paragraphBuilderSetLineBreaksUtf16(handle, lineBreakBuffer);
    lineBreakBufferFree(lineBreakBuffer);
  }

  @override
  SkwasmParagraph build() {
    if (!skwasmIsHeavy()) {
      _addSegmenterData();
    }
    return SkwasmParagraph(paragraphBuilderBuild(handle));
  }

  @override
  void pop() {
    paragraphBuilderPop(handle);
  }

  @override
  void pushStyle(EngineTextStyle mergedStyle) {
    final SkwasmNativeTextStyle nativeStyle = fontCollection.defaultTextStyle.copy();
    _applyTextStyleToNative(mergedStyle, nativeStyle);
    paragraphBuilderPushStyle(handle, nativeStyle.handle);
    nativeStyle.dispose();
  }
}

/// Using a specialized local extension rather than a generic List<int>.generate
/// prevents dart2wasm from dynamically boxing the primitive integers into
/// heap-allocated objects ($BoxedInt / struct allocations) during copy blocks.
extension on Pointer<Uint8> {
  Uint8List toUint8List(int length) {
    final list = Uint8List(length);
    for (int i = length - 1; i >= 0; i--) {
      list[i] = this[i];
    }
    return list;
  }
}

/// Using a specialized local extension rather than a generic List<int>.generate
/// prevents dart2wasm from dynamically boxing the primitive integers into
/// heap-allocated objects ($BoxedInt / struct allocations) during copy blocks.
extension on Pointer<Uint32> {
  Uint32List toUint32List(int length) {
    final list = Uint32List(length);
    for (int i = length - 1; i >= 0; i--) {
      list[i] = this[i];
    }
    return list;
  }
}
