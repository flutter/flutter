// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';

import 'box.dart';
import 'object.dart';
import 'semantics.dart';

/// How overflowing text should be handled.
enum TextOverflow {
  /// Clip the overflowing text to fix its container.
  clip,

  /// Fade the overflowing text to transparent.
  fade,

  /// Use an ellipsis to indicate that the text has overflowed.
  ellipsis,
}

const String _kEllipsis = '\u2026';

/// A render object that displays a paragraph of text
class RenderParagraph extends RenderBox {
  /// Creates a paragraph render object.
  ///
  /// The [text], [overflow], and [softWrap] arguments must not be null.
  RenderParagraph(TextSpan text, {
    TextAlign textAlign,
    bool softWrap: true,
    TextOverflow overflow: TextOverflow.clip,
    double textScaleFactor: 1.0
  }) : _softWrap = softWrap,
       _overflow = overflow,
       _textPainter = new TextPainter(
           text: text,
           textAlign: textAlign,
           textScaleFactor: textScaleFactor,
           ellipsis: overflow == TextOverflow.ellipsis ? _kEllipsis : null,
       ) {
    assert(text != null);
    assert(text.debugAssertIsValid());
    assert(softWrap != null);
    assert(overflow != null);
    assert(textScaleFactor != null);
  }

  final TextPainter _textPainter;

  /// The text to display
  TextSpan get text => _textPainter.text;
  set text(TextSpan value) {
    assert(value != null);
    if (_textPainter.text == value)
      return;
    _textPainter.text = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  /// How the text should be aligned horizontally.
  TextAlign get textAlign => _textPainter.textAlign;
  set textAlign(TextAlign value) {
    if (_textPainter.textAlign == value)
      return;
    _textPainter.textAlign = value;
    markNeedsPaint();
  }

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  bool get softWrap => _softWrap;
  bool _softWrap;
  set softWrap(bool value) {
    assert(value != null);
    if (_softWrap == value)
      return;
    _softWrap = value;
    markNeedsLayout();
  }

  /// How visual overflow should be handled.
  TextOverflow get overflow => _overflow;
  TextOverflow _overflow;
  set overflow(TextOverflow value) {
    assert(value != null);
    if (_overflow == value)
      return;
    _overflow = value;
    _textPainter.ellipsis = value == TextOverflow.ellipsis ? _kEllipsis : null;
    markNeedsPaint();
  }

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  double get textScaleFactor => _textPainter.textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_textPainter.textScaleFactor == value)
      return;
    _textPainter.textScaleFactor = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  void _layoutText({ double minWidth: 0.0, double maxWidth: double.INFINITY }) {
    bool wrap = _softWrap || _overflow == TextOverflow.ellipsis;
    _textPainter.layout(minWidth: minWidth, maxWidth: wrap ? maxWidth : double.INFINITY);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _layoutText();
    return _textPainter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layoutText();
    return _textPainter.maxIntrinsicWidth;
  }

  double _computeIntrinsicHeight(double width) {
    _layoutText(minWidth: width, maxWidth: width);
    return _textPainter.height;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!needsLayout);
    assert(constraints != null);
    assert(constraints.debugAssertIsValid());
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Point position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is! PointerDownEvent)
      return;
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    Offset offset = entry.localPosition.toOffset();
    TextPosition position = _textPainter.getPositionForOffset(offset);
    TextSpan span = _textPainter.text.getSpanForPosition(position);
    span?.recognizer?.addPointer(event);
  }

  bool _hasVisualOverflow = false;
  ui.Shader _overflowShader;

  @override
  void performLayout() {
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    // We grab _textPainter.size here because assigning to `size` will trigger
    // us to validate our intrinsic sizes, which will change _textPainter's
    // layout because the intrinsic size calculations are destructive.
    final Size textSize = _textPainter.size;
    size = constraints.constrain(textSize);

    final bool didOverflowWidth = size.width < textSize.width;
    // TODO(abarth): We're only measuring the sizes of the line boxes here. If
    // the glyphs draw outside the line boxes, we might think that there isn't
    // visual overflow when there actually is visual overflow. This can become
    // a problem if we start having horizontal overflow and introduce a clip
    // that affects the actual (but undetected) vertical overflow.
    _hasVisualOverflow = didOverflowWidth || size.height < textSize.height;
    if (didOverflowWidth) {
      switch (_overflow) {
        case TextOverflow.clip:
        case TextOverflow.ellipsis:
          _overflowShader = null;
          break;
        case TextOverflow.fade:
          TextPainter fadeWidthPainter = new TextPainter(
            text: new TextSpan(style: _textPainter.text.style, text: '\u2026'),
            textScaleFactor: textScaleFactor
          )..layout();
          final double fadeEnd = size.width;
          final double fadeStart = fadeEnd - fadeWidthPainter.width;
          // TODO(abarth): This shader has an LTR bias.
          _overflowShader = new ui.Gradient.linear(
            <Point>[new Point(fadeStart, 0.0), new Point(fadeEnd, 0.0)],
            <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)]
          );
          break;
      }
    } else {
      _overflowShader = null;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Ideally we could compute the min/max intrinsic width/height with a
    // non-destructive operation. However, currently, computing these values
    // will destroy state inside the painter. If that happens, we need to
    // get back the correct state by calling _layout again.
    //
    // TODO(abarth): Make computing the min/max intrinsic width/height
    // a non-destructive operation.
    //
    // If you remove this call, make sure that changing the textAlign still
    // works properly.
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    final Canvas canvas = context.canvas;
    if (_hasVisualOverflow) {
      final Rect bounds = offset & size;
      if (_overflowShader != null)
        canvas.saveLayer(bounds, new Paint());
      else
        canvas.save();
      canvas.clipRect(bounds);
    }
    _textPainter.paint(canvas, offset);
    if (_hasVisualOverflow) {
      if (_overflowShader != null) {
        canvas.translate(offset.dx, offset.dy);
        Paint paint = new Paint()
          ..transferMode = TransferMode.modulate
          ..shader = _overflowShader;
        canvas.drawRect(Point.origin & size, paint);
      }
      canvas.restore();
    }
  }

  @override
  SemanticsAnnotator get semanticsAnnotator => _annotate;

  void _annotate(SemanticsNode node) {
    node.label = text.toPlainText();
  }

  @override
  String debugDescribeChildren(String prefix) {
    return '$prefix \u2558\u2550\u2566\u2550\u2550 text \u2550\u2550\u2550\n'
           '${text.toString("$prefix   \u2551 ")}' // TextSpan includes a newline
           '$prefix   \u255A\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\n'
           '$prefix\n';
  }
}
