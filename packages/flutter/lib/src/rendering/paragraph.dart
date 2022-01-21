// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui show Gradient, Shader, TextBox, PlaceholderAlignment, TextHeightBehavior, BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';

import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'debug.dart';
import 'object.dart';

const String _kEllipsis = '\u2026';

/// Parent data for use with [RenderParagraph] and [RenderEditable].
class TextParentData extends ContainerBoxParentData<RenderBox> {
  /// The scaling of the text.
  double? scale;

  @override
  String toString() {
    final List<String> values = <String>[
      'offset=$offset',
      if (scale != null) 'scale=$scale',
      super.toString(),
    ];
    return values.join('; ');
  }
}

/// Used by the [RenderParagraph] to map its rendering children to their
/// corresponding semantics nodes.
///
/// The [RichText] uses this to tag the relation between its placeholder spans
/// and their semantics nodes.
@immutable
class PlaceholderSpanIndexSemanticsTag extends SemanticsTag {
  /// Creates a semantics tag with the input `index`.
  ///
  /// Different [PlaceholderSpanIndexSemanticsTag]s with the same `index` are
  /// consider the same.
  const PlaceholderSpanIndexSemanticsTag(this.index) : super('PlaceholderSpanIndexSemanticsTag($index)');

  /// The index of this tag.
  final int index;

  @override
  bool operator ==(Object other) {
    return other is PlaceholderSpanIndexSemanticsTag
        && other.index == index;
  }

  @override
  int get hashCode => hashValues(PlaceholderSpanIndexSemanticsTag, index);
}

/// A render object that displays a paragraph of text.
class RenderParagraph extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, TextParentData>,
             RenderBoxContainerDefaultsMixin<RenderBox, TextParentData>,
                  RelayoutWhenSystemFontsChangeMixin {
  /// Creates a paragraph render object.
  ///
  /// The [text], [textAlign], [textDirection], [overflow], [softWrap], and
  /// [textScaleFactor] arguments must not be null.
  ///
  /// The [maxLines] property may be null (and indeed defaults to null), but if
  /// it is not null, it must be greater than zero.
  RenderParagraph(InlineSpan text, {
    TextAlign textAlign = TextAlign.start,
    required TextDirection textDirection,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    double textScaleFactor = 1.0,
    int? maxLines,
    Locale? locale,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    ui.TextHeightBehavior? textHeightBehavior,
    List<RenderBox>? children,
  }) : assert(text != null),
       assert(text.debugAssertIsValid()),
       assert(textAlign != null),
       assert(textDirection != null),
       assert(softWrap != null),
       assert(overflow != null),
       assert(textScaleFactor != null),
       assert(maxLines == null || maxLines > 0),
       assert(textWidthBasis != null),
       _softWrap = softWrap,
       _overflow = overflow,
       _textPainter = TextPainter(
         text: text,
         textAlign: textAlign,
         textDirection: textDirection,
         textScaleFactor: textScaleFactor,
         maxLines: maxLines,
         ellipsis: overflow == TextOverflow.ellipsis ? _kEllipsis : null,
         locale: locale,
         strutStyle: strutStyle,
         textWidthBasis: textWidthBasis,
         textHeightBehavior: textHeightBehavior,
       ) {
    addAll(children);
    _extractPlaceholderSpans(text);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TextParentData)
      child.parentData = TextParentData();
  }

  final TextPainter _textPainter;
  AttributedString? _cachedAttributedLabel;
  List<InlineSpanSemanticsInformation>? _cachedCombinedSemanticsInfos;

  /// The text to display.
  InlineSpan get text => _textPainter.text!;
  set text(InlineSpan value) {
    assert(value != null);
    switch (_textPainter.text!.compareTo(value)) {
      case RenderComparison.identical:
      case RenderComparison.metadata:
        return;
      case RenderComparison.paint:
        _textPainter.text = value;
        _cachedAttributedLabel = null;
        _cachedCombinedSemanticsInfos = null;
        _extractPlaceholderSpans(value);
        markNeedsPaint();
        markNeedsSemanticsUpdate();
        break;
      case RenderComparison.layout:
        _textPainter.text = value;
        _overflowShader = null;
        _cachedAttributedLabel = null;
        _cachedCombinedSemanticsInfos = null;
        _extractPlaceholderSpans(value);
        markNeedsLayout();
        break;
    }
  }

  late List<PlaceholderSpan> _placeholderSpans;
  void _extractPlaceholderSpans(InlineSpan span) {
    _placeholderSpans = <PlaceholderSpan>[];
    span.visitChildren((InlineSpan span) {
      if (span is PlaceholderSpan) {
        _placeholderSpans.add(span);
      }
      return true;
    });
  }

  /// How the text should be aligned horizontally.
  TextAlign get textAlign => _textPainter.textAlign;
  set textAlign(TextAlign value) {
    assert(value != null);
    if (_textPainter.textAlign == value)
      return;
    _textPainter.textAlign = value;
    markNeedsPaint();
  }

  /// The directionality of the text.
  ///
  /// This decides how the [TextAlign.start], [TextAlign.end], and
  /// [TextAlign.justify] values of [textAlign] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// This must not be null.
  TextDirection get textDirection => _textPainter.textDirection!;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textPainter.textDirection == value)
      return;
    _textPainter.textDirection = value;
    markNeedsLayout();
  }

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was
  /// unlimited horizontal space.
  ///
  /// If [softWrap] is false, [overflow] and [textAlign] may have unexpected
  /// effects.
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
    markNeedsLayout();
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

  /// An optional maximum number of lines for the text to span, wrapping if
  /// necessary. If the text exceeds the given number of lines, it will be
  /// truncated according to [overflow] and [softWrap].
  int? get maxLines => _textPainter.maxLines;
  /// The value may be null. If it is not null, then it must be greater than
  /// zero.
  set maxLines(int? value) {
    assert(value == null || value > 0);
    if (_textPainter.maxLines == value)
      return;
    _textPainter.maxLines = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  /// Used by this paragraph's internal [TextPainter] to select a
  /// locale-specific font.
  ///
  /// In some cases, the same Unicode character may be rendered differently
  /// depending on the locale. For example, the '骨' character is rendered
  /// differently in the Chinese and Japanese locales. In these cases, the
  /// [locale] may be used to select a locale-specific font.
  Locale? get locale => _textPainter.locale;
  /// The value may be null.
  set locale(Locale? value) {
    if (_textPainter.locale == value)
      return;
    _textPainter.locale = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  /// {@macro flutter.painting.textPainter.strutStyle}
  StrutStyle? get strutStyle => _textPainter.strutStyle;
  /// The value may be null.
  set strutStyle(StrutStyle? value) {
    if (_textPainter.strutStyle == value)
      return;
    _textPainter.strutStyle = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  TextWidthBasis get textWidthBasis => _textPainter.textWidthBasis;
  set textWidthBasis(TextWidthBasis value) {
    assert(value != null);
    if (_textPainter.textWidthBasis == value)
      return;
    _textPainter.textWidthBasis = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  /// {@macro dart.ui.textHeightBehavior}
  ui.TextHeightBehavior? get textHeightBehavior => _textPainter.textHeightBehavior;
  set textHeightBehavior(ui.TextHeightBehavior? value) {
    if (_textPainter.textHeightBehavior == value)
      return;
    _textPainter.textHeightBehavior = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (!_canComputeIntrinsics()) {
      return 0.0;
    }
    _computeChildrenWidthWithMinIntrinsics(height);
    _layoutText(); // layout with infinite width.
    return _textPainter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (!_canComputeIntrinsics()) {
      return 0.0;
    }
    _computeChildrenWidthWithMaxIntrinsics(height);
    _layoutText(); // layout with infinite width.
    return _textPainter.maxIntrinsicWidth;
  }

  double _computeIntrinsicHeight(double width) {
    if (!_canComputeIntrinsics()) {
      return 0.0;
    }
    _computeChildrenHeightWithMinIntrinsics(width);
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
    assert(!debugNeedsLayout);
    assert(constraints != null);
    assert(constraints.debugAssertIsValid());
    _layoutTextWithConstraints(constraints);
    // TODO(garyq): Since our metric for ideographic baseline is currently
    // inaccurate and the non-alphabetic baselines are based off of the
    // alphabetic baseline, we use the alphabetic for now to produce correct
    // layouts. We should eventually change this back to pass the `baseline`
    // property when the ideographic baseline is properly implemented
    // (https://github.com/flutter/flutter/issues/22625).
    return _textPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  }

  // Intrinsics cannot be calculated without a full layout for
  // alignments that require the baseline (baseline, aboveBaseline,
  // belowBaseline).
  bool _canComputeIntrinsics() {
    for (final PlaceholderSpan span in _placeholderSpans) {
      switch (span.alignment) {
        case ui.PlaceholderAlignment.baseline:
        case ui.PlaceholderAlignment.aboveBaseline:
        case ui.PlaceholderAlignment.belowBaseline: {
          assert(
            RenderObject.debugCheckingIntrinsics,
            'Intrinsics are not available for PlaceholderAlignment.baseline, '
            'PlaceholderAlignment.aboveBaseline, or PlaceholderAlignment.belowBaseline.',
          );
          return false;
        }
        case ui.PlaceholderAlignment.top:
        case ui.PlaceholderAlignment.middle:
        case ui.PlaceholderAlignment.bottom: {
          continue;
        }
      }
    }
    return true;
  }

  void _computeChildrenWidthWithMaxIntrinsics(double height) {
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions = List<PlaceholderDimensions>.filled(childCount, PlaceholderDimensions.empty);
    int childIndex = 0;
    while (child != null) {
      // Height and baseline is irrelevant as all text will be laid
      // out in a single line. Therefore, using 0.0 as a dummy for the height.
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(child.getMaxIntrinsicWidth(double.infinity), 0.0),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    _textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  void _computeChildrenWidthWithMinIntrinsics(double height) {
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions = List<PlaceholderDimensions>.filled(childCount, PlaceholderDimensions.empty);
    int childIndex = 0;
    while (child != null) {
      // Height and baseline is irrelevant; only looking for the widest word or
      // placeholder. Therefore, using 0.0 as a dummy for height.
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(child.getMinIntrinsicWidth(double.infinity), 0.0),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    _textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  void _computeChildrenHeightWithMinIntrinsics(double width) {
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions = List<PlaceholderDimensions>.filled(childCount, PlaceholderDimensions.empty);
    int childIndex = 0;
    // Takes textScaleFactor into account because the content of the placeholder
    // span will be scaled up when it paints.
    width = width / textScaleFactor;
    while (child != null) {
      final Size size = child.getDryLayout(BoxConstraints(maxWidth: width));
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: size,
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    _textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    // Hit test text spans.
    bool hitText = false;
    final TextPosition textPosition = _textPainter.getPositionForOffset(position);
    final InlineSpan? span = _textPainter.text!.getSpanForPosition(textPosition);
    if (span != null && span is HitTestTarget) {
      result.add(HitTestEntry(span as HitTestTarget));
      hitText = true;
    }

    // Hit test render object children
    RenderBox? child = firstChild;
    int childIndex = 0;
    while (child != null && childIndex < _textPainter.inlinePlaceholderBoxes!.length) {
      final TextParentData textParentData = child.parentData! as TextParentData;
      final Matrix4 transform = Matrix4.translationValues(
        textParentData.offset.dx,
        textParentData.offset.dy,
        0.0,
      )..scale(
        textParentData.scale,
        textParentData.scale,
        textParentData.scale,
      );
      final bool isHit = result.addWithPaintTransform(
        transform: transform,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(() {
            final Offset manualPosition = (position - textParentData.offset) / textParentData.scale!;
            return (transformed.dx - manualPosition.dx).abs() < precisionErrorTolerance
              && (transformed.dy - manualPosition.dy).abs() < precisionErrorTolerance;
          }());
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
      child = childAfter(child);
      childIndex += 1;
    }
    return hitText;
  }

  bool _needsClipping = false;
  ui.Shader? _overflowShader;

  /// Whether this paragraph currently has a [dart:ui.Shader] for its overflow
  /// effect.
  ///
  /// Used to test this object. Not for use in production.
  @visibleForTesting
  bool get debugHasOverflowShader => _overflowShader != null;

  void _layoutText({ double minWidth = 0.0, double maxWidth = double.infinity }) {
    final bool widthMatters = softWrap || overflow == TextOverflow.ellipsis;
    _textPainter.layout(
      minWidth: minWidth,
      maxWidth: widthMatters ?
        maxWidth :
        double.infinity,
    );
  }

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    _textPainter.markNeedsLayout();
  }

  // Placeholder dimensions representing the sizes of child inline widgets.
  //
  // These need to be cached because the text painter's placeholder dimensions
  // will be overwritten during intrinsic width/height calculations and must be
  // restored to the original values before final layout and painting.
  List<PlaceholderDimensions>? _placeholderDimensions;

  void _layoutTextWithConstraints(BoxConstraints constraints) {
    _textPainter.setPlaceholderDimensions(_placeholderDimensions);
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }

  // Layout the child inline widgets. We then pass the dimensions of the
  // children to _textPainter so that appropriate placeholders can be inserted
  // into the LibTxt layout. This does not do anything if no inline widgets were
  // specified.
  List<PlaceholderDimensions> _layoutChildren(BoxConstraints constraints, {bool dry = false}) {
    if (childCount == 0) {
      return <PlaceholderDimensions>[];
    }
    RenderBox? child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions = List<PlaceholderDimensions>.filled(childCount, PlaceholderDimensions.empty);
    int childIndex = 0;
    // Only constrain the width to the maximum width of the paragraph.
    // Leave height unconstrained, which will overflow if expanded past.
    BoxConstraints boxConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    // The content will be enlarged by textScaleFactor during painting phase.
    // We reduce constraints by textScaleFactor, so that the content will fit
    // into the box once it is enlarged.
    boxConstraints = boxConstraints / textScaleFactor;
    while (child != null) {
      double? baselineOffset;
      final Size childSize;
      if (!dry) {
        child.layout(
          boxConstraints,
          parentUsesSize: true,
        );
        childSize = child.size;
        switch (_placeholderSpans[childIndex].alignment) {
          case ui.PlaceholderAlignment.baseline:
            baselineOffset = child.getDistanceToBaseline(
              _placeholderSpans[childIndex].baseline!,
            );
            break;
          case ui.PlaceholderAlignment.aboveBaseline:
          case ui.PlaceholderAlignment.belowBaseline:
          case ui.PlaceholderAlignment.bottom:
          case ui.PlaceholderAlignment.middle:
          case ui.PlaceholderAlignment.top:
            baselineOffset = null;
            break;
        }
      } else {
        assert(_placeholderSpans[childIndex].alignment != ui.PlaceholderAlignment.baseline);
        childSize = child.getDryLayout(boxConstraints);
      }
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: childSize,
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
        baselineOffset: baselineOffset,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    return placeholderDimensions;
  }

  // Iterate through the laid-out children and set the parentData offsets based
  // off of the placeholders inserted for each child.
  void _setParentData() {
    RenderBox? child = firstChild;
    int childIndex = 0;
    while (child != null && childIndex < _textPainter.inlinePlaceholderBoxes!.length) {
      final TextParentData textParentData = child.parentData! as TextParentData;
      textParentData.offset = Offset(
        _textPainter.inlinePlaceholderBoxes![childIndex].left,
        _textPainter.inlinePlaceholderBoxes![childIndex].top,
      );
      textParentData.scale = _textPainter.inlinePlaceholderScales![childIndex];
      child = childAfter(child);
      childIndex += 1;
    }
  }

  bool _canComputeDryLayout() {
    // Dry layout cannot be calculated without a full layout for
    // alignments that require the baseline (baseline, aboveBaseline,
    // belowBaseline).
    for (final PlaceholderSpan span in _placeholderSpans) {
      switch (span.alignment) {
        case ui.PlaceholderAlignment.baseline:
        case ui.PlaceholderAlignment.aboveBaseline:
        case ui.PlaceholderAlignment.belowBaseline:
          return false;
        case ui.PlaceholderAlignment.top:
        case ui.PlaceholderAlignment.middle:
        case ui.PlaceholderAlignment.bottom:
          continue;
      }
    }
    return true;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (!_canComputeDryLayout()) {
      assert(debugCannotComputeDryLayout(
        reason: 'Dry layout not available for alignments that require baseline.',
      ));
      return Size.zero;
    }
    _textPainter.setPlaceholderDimensions(_layoutChildren(constraints, dry: true));
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
    return constraints.constrain(_textPainter.size);
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    _placeholderDimensions = _layoutChildren(constraints);
    _layoutTextWithConstraints(constraints);
    _setParentData();

    // We grab _textPainter.size and _textPainter.didExceedMaxLines here because
    // assigning to `size` will trigger us to validate our intrinsic sizes,
    // which will change _textPainter's layout because the intrinsic size
    // calculations are destructive. Other _textPainter state will also be
    // affected. See also RenderEditable which has a similar issue.
    final Size textSize = _textPainter.size;
    final bool textDidExceedMaxLines = _textPainter.didExceedMaxLines;
    size = constraints.constrain(textSize);

    final bool didOverflowHeight = size.height < textSize.height || textDidExceedMaxLines;
    final bool didOverflowWidth = size.width < textSize.width;
    // TODO(abarth): We're only measuring the sizes of the line boxes here. If
    // the glyphs draw outside the line boxes, we might think that there isn't
    // visual overflow when there actually is visual overflow. This can become
    // a problem if we start having horizontal overflow and introduce a clip
    // that affects the actual (but undetected) vertical overflow.
    final bool hasVisualOverflow = didOverflowWidth || didOverflowHeight;
    if (hasVisualOverflow) {
      switch (_overflow) {
        case TextOverflow.visible:
          _needsClipping = false;
          _overflowShader = null;
          break;
        case TextOverflow.clip:
        case TextOverflow.ellipsis:
          _needsClipping = true;
          _overflowShader = null;
          break;
        case TextOverflow.fade:
          assert(textDirection != null);
          _needsClipping = true;
          final TextPainter fadeSizePainter = TextPainter(
            text: TextSpan(style: _textPainter.text!.style, text: '\u2026'),
            textDirection: textDirection,
            textScaleFactor: textScaleFactor,
            locale: locale,
          )..layout();
          if (didOverflowWidth) {
            double fadeEnd, fadeStart;
            switch (textDirection) {
              case TextDirection.rtl:
                fadeEnd = 0.0;
                fadeStart = fadeSizePainter.width;
                break;
              case TextDirection.ltr:
                fadeEnd = size.width;
                fadeStart = fadeEnd - fadeSizePainter.width;
                break;
            }
            _overflowShader = ui.Gradient.linear(
              Offset(fadeStart, 0.0),
              Offset(fadeEnd, 0.0),
              <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
            );
          } else {
            final double fadeEnd = size.height;
            final double fadeStart = fadeEnd - fadeSizePainter.height / 2.0;
            _overflowShader = ui.Gradient.linear(
              Offset(0.0, fadeStart),
              Offset(0.0, fadeEnd),
              <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
            );
          }
          break;
      }
    } else {
      _needsClipping = false;
      _overflowShader = null;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Ideally we could compute the min/max intrinsic width/height with a
    // non-destructive operation. However, currently, computing these values
    // will destroy state inside the painter. If that happens, we need to get
    // back the correct state by calling _layout again.
    //
    // TODO(abarth): Make computing the min/max intrinsic width/height a
    //  non-destructive operation.
    //
    // If you remove this call, make sure that changing the textAlign still
    // works properly.
    _layoutTextWithConstraints(constraints);

    assert(() {
      if (debugRepaintTextRainbowEnabled) {
        final Paint paint = Paint()
          ..color = debugCurrentRepaintColor.toColor();
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    }());

    if (_needsClipping) {
      final Rect bounds = offset & size;
      if (_overflowShader != null) {
        // This layer limits what the shader below blends with to be just the
        // text (as opposed to the text and its background).
        context.canvas.saveLayer(bounds, Paint());
      } else {
        context.canvas.save();
      }
      context.canvas.clipRect(bounds);
    }
    _textPainter.paint(context.canvas, offset);

    RenderBox? child = firstChild;
    int childIndex = 0;
    // childIndex might be out of index of placeholder boxes. This can happen
    // if engine truncates children due to ellipsis. Sadly, we would not know
    // it until we finish layout, and RenderObject is in immutable state at
    // this point.
    while (child != null && childIndex < _textPainter.inlinePlaceholderBoxes!.length) {
      final TextParentData textParentData = child.parentData! as TextParentData;

      final double scale = textParentData.scale!;
      context.pushTransform(
        needsCompositing,
        offset + textParentData.offset,
        Matrix4.diagonal3Values(scale, scale, scale),
        (PaintingContext context, Offset offset) {
          context.paintChild(
            child!,
            offset,
          );
        },
      );
      child = childAfter(child);
      childIndex += 1;
    }
    if (_needsClipping) {
      if (_overflowShader != null) {
        context.canvas.translate(offset.dx, offset.dy);
        final Paint paint = Paint()
          ..blendMode = BlendMode.modulate
          ..shader = _overflowShader;
        context.canvas.drawRect(Offset.zero & size, paint);
      }
      context.canvas.restore();
    }
  }

  /// Returns the offset at which to paint the caret.
  ///
  /// Valid only after [layout].
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getOffsetForCaret(position, caretPrototype);
  }

  /// {@macro flutter.painting.textPainter.getFullHeightForCaret}
  ///
  /// Valid only after [layout].
  double? getFullHeightForCaret(TextPosition position) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getFullHeightForCaret(position, Rect.zero);
  }

  /// Returns a list of rects that bound the given selection.
  ///
  /// The [boxHeightStyle] and [boxWidthStyle] arguments may be used to select
  /// the shape of the [TextBox]es. These properties default to
  /// [ui.BoxHeightStyle.tight] and [ui.BoxWidthStyle.tight] respectively and
  /// must not be null.
  ///
  /// A given selection might have more than one rect if the [RenderParagraph]
  /// contains multiple [InlineSpan]s or bidirectional text, because logically
  /// contiguous text might not be visually contiguous.
  ///
  /// Valid only after [layout].
  ///
  /// See also:
  ///
  ///  * [TextPainter.getBoxesForSelection], the method in TextPainter to get
  ///    the equivalent boxes.
  List<ui.TextBox> getBoxesForSelection(
    TextSelection selection, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    assert(!debugNeedsLayout);
    assert(boxHeightStyle != null);
    assert(boxWidthStyle != null);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getBoxesForSelection(
      selection,
      boxHeightStyle: boxHeightStyle,
      boxWidthStyle: boxWidthStyle,
    );
  }

  /// Returns the position within the text for the given pixel offset.
  ///
  /// Valid only after [layout].
  TextPosition getPositionForOffset(Offset offset) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getPositionForOffset(offset);
  }

  /// Returns the text range of the word at the given offset. Characters not
  /// part of a word, such as spaces, symbols, and punctuation, have word breaks
  /// on both sides. In such cases, this method will return a text range that
  /// contains the given text position.
  ///
  /// Word boundaries are defined more precisely in Unicode Standard Annex #29
  /// <http://www.unicode.org/reports/tr29/#Word_Boundaries>.
  ///
  /// Valid only after [layout].
  TextRange getWordBoundary(TextPosition position) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getWordBoundary(position);
  }

  /// Returns the size of the text as laid out.
  ///
  /// This can differ from [size] if the text overflowed or if the [constraints]
  /// provided by the parent [RenderObject] forced the layout to be bigger than
  /// necessary for the given [text].
  ///
  /// This returns the [TextPainter.size] of the underlying [TextPainter].
  ///
  /// Valid only after [layout].
  Size get textSize {
    assert(!debugNeedsLayout);
    return _textPainter.size;
  }

  /// Collected during [describeSemanticsConfiguration], used by
  /// [assembleSemanticsNode] and [_combineSemanticsInfo].
  List<InlineSpanSemanticsInformation>? _semanticsInfo;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    _semanticsInfo = text.getSemanticsInformation();

    if (_semanticsInfo!.any((InlineSpanSemanticsInformation info) => info.recognizer != null)) {
      config.explicitChildNodes = true;
      config.isSemanticBoundary = true;
    } else {
      if (_cachedAttributedLabel == null) {
        final StringBuffer buffer = StringBuffer();
        int offset = 0;
        final List<StringAttribute> attributes = <StringAttribute>[];
        for (final InlineSpanSemanticsInformation info in _semanticsInfo!) {
          final String label = info.semanticsLabel ?? info.text;
          for (final StringAttribute infoAttribute in info.stringAttributes) {
            final TextRange originalRange = infoAttribute.range;
            attributes.add(
              infoAttribute.copy(
                  range: TextRange(start: offset + originalRange.start,
                      end: offset + originalRange.end)
              ),
            );
          }
          buffer.write(label);
          offset += label.length;
        }
        _cachedAttributedLabel = AttributedString(buffer.toString(), attributes: attributes);
      }
      config.attributedLabel = _cachedAttributedLabel!;
      config.textDirection = textDirection;
    }
  }

  // Caches [SemanticsNode]s created during [assembleSemanticsNode] so they
  // can be re-used when [assembleSemanticsNode] is called again. This ensures
  // stable ids for the [SemanticsNode]s of [TextSpan]s across
  // [assembleSemanticsNode] invocations.
  Queue<SemanticsNode>? _cachedChildNodes;

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config, Iterable<SemanticsNode> children) {
    assert(_semanticsInfo != null && _semanticsInfo!.isNotEmpty);
    final List<SemanticsNode> newChildren = <SemanticsNode>[];
    TextDirection currentDirection = textDirection;
    Rect currentRect;
    double ordinal = 0.0;
    int start = 0;
    int placeholderIndex = 0;
    int childIndex = 0;
    RenderBox? child = firstChild;
    final Queue<SemanticsNode> newChildCache = Queue<SemanticsNode>();
    _cachedCombinedSemanticsInfos ??= combineSemanticsInfo(_semanticsInfo!);
    for (final InlineSpanSemanticsInformation info in _cachedCombinedSemanticsInfos!) {
      final TextSelection selection = TextSelection(
        baseOffset: start,
        extentOffset: start + info.text.length,
      );
      start += info.text.length;

      if (info.isPlaceholder) {
        // A placeholder span may have 0 to multiple semantics nodes, we need
        // to annotate all of the semantics nodes belong to this span.
        while (children.length > childIndex &&
               children.elementAt(childIndex).isTagged(PlaceholderSpanIndexSemanticsTag(placeholderIndex))) {
          final SemanticsNode childNode = children.elementAt(childIndex);
          final TextParentData parentData = child!.parentData! as TextParentData;
          assert(parentData.scale != null || parentData.offset == Offset.zero);
          // parentData.scale may be null if the render object is truncated.
          if (parentData.scale != null) {
            childNode.rect = Rect.fromLTWH(
              childNode.rect.left,
              childNode.rect.top,
              childNode.rect.width * parentData.scale!,
              childNode.rect.height * parentData.scale!,
            );
            newChildren.add(childNode);
          }
          childIndex += 1;
        }
        child = childAfter(child!);
        placeholderIndex += 1;
      } else {
        final TextDirection initialDirection = currentDirection;
        final List<ui.TextBox> rects = getBoxesForSelection(selection);
        if (rects.isEmpty) {
          continue;
        }
        Rect rect = rects.first.toRect();
        currentDirection = rects.first.direction;
        for (final ui.TextBox textBox in rects.skip(1)) {
          rect = rect.expandToInclude(textBox.toRect());
          currentDirection = textBox.direction;
        }
        // Any of the text boxes may have had infinite dimensions.
        // We shouldn't pass infinite dimensions up to the bridges.
        rect = Rect.fromLTWH(
          math.max(0.0, rect.left),
          math.max(0.0, rect.top),
          math.min(rect.width, constraints.maxWidth),
          math.min(rect.height, constraints.maxHeight),
        );
        // round the current rectangle to make this API testable and add some
        // padding so that the accessibility rects do not overlap with the text.
        currentRect = Rect.fromLTRB(
          rect.left.floorToDouble() - 4.0,
          rect.top.floorToDouble() - 4.0,
          rect.right.ceilToDouble() + 4.0,
          rect.bottom.ceilToDouble() + 4.0,
        );
        final SemanticsConfiguration configuration = SemanticsConfiguration()
          ..sortKey = OrdinalSortKey(ordinal++)
          ..textDirection = initialDirection
          ..attributedLabel = AttributedString(info.semanticsLabel ?? info.text, attributes: info.stringAttributes);
        final GestureRecognizer? recognizer = info.recognizer;
        if (recognizer != null) {
          if (recognizer is TapGestureRecognizer) {
            if (recognizer.onTap != null) {
              configuration.onTap = recognizer.onTap;
              configuration.isLink = true;
            }
          } else if (recognizer is DoubleTapGestureRecognizer) {
            if (recognizer.onDoubleTap != null) {
              configuration.onTap = recognizer.onDoubleTap;
              configuration.isLink = true;
            }
          } else if (recognizer is LongPressGestureRecognizer) {
            if (recognizer.onLongPress != null) {
              configuration.onLongPress = recognizer.onLongPress;
            }
          } else {
            assert(false, '${recognizer.runtimeType} is not supported.');
          }
        }
        final SemanticsNode newChild = (_cachedChildNodes?.isNotEmpty == true)
            ? _cachedChildNodes!.removeFirst()
            : SemanticsNode();
        newChild
          ..updateWith(config: configuration)
          ..rect = currentRect;
        newChildCache.addLast(newChild);
        newChildren.add(newChild);
      }
    }
    // Makes sure we annotated all of the semantics children.
    assert(childIndex == children.length);
    assert(child == null);

    _cachedChildNodes = newChildCache;
    node.updateWith(config: config, childrenInInversePaintOrder: newChildren);
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _cachedChildNodes = null;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      text.toDiagnosticsNode(
        name: 'text',
        style: DiagnosticsTreeStyle.transition,
      ),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
    properties.add(
      FlagProperty(
        'softWrap',
        value: softWrap,
        ifTrue: 'wrapping at box width',
        ifFalse: 'no wrapping except at line break characters',
        showName: true,
      ),
    );
    properties.add(EnumProperty<TextOverflow>('overflow', overflow));
    properties.add(
      DoubleProperty(
        'textScaleFactor',
        textScaleFactor,
        defaultValue: 1.0,
      ),
    );
    properties.add(
      DiagnosticsProperty<Locale>(
        'locale',
        locale,
        defaultValue: null,
      ),
    );
    properties.add(IntProperty('maxLines', maxLines, ifNull: 'unlimited'));
  }
}
