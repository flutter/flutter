// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
///
/// @docImport 'editable.dart';
library;

import 'dart:math' as math;
import 'dart:ui'
    as ui
    show
        BoxHeightStyle,
        BoxWidthStyle,
        Color,
        Gradient,
        Hyphens,
        LineMetrics,
        PlaceholderAlignment,
        Shader,
        TextBox,
        TextHeightBehavior;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'debug.dart';
import 'layer.dart';
import 'layout_helper.dart';
import 'object.dart';
import 'selection.dart';

class _TextShrinkState {
  final LayerHandle<OpacityLayer> opacityLayer = LayerHandle<OpacityLayer>();
  double? lockedMaxWidth;
  double? fallbackReferenceWidth;
  double? currentWidth;
  double? lockedMaxHeight;
  double? currentHeight;
  int lastAlpha = 255;

  double effectiveReferenceWidth(double intrinsicMaxWidth) {
    final double locked = lockedMaxWidth ?? 0.0;
    if (locked > 0.0) {
      return locked;
    }
    final double fallback = fallbackReferenceWidth ?? intrinsicMaxWidth;
    return fallback.isFinite && fallback > 0.0 ? fallback : 0.0;
  }

  double effectiveReferenceHeight(double textHeight) {
    final double locked = lockedMaxHeight ?? 0.0;
    if (locked > 0.0) {
      return locked;
    }
    return textHeight.isFinite && textHeight > 0.0 ? textHeight : 0.0;
  }

  int computeAlpha(double intrinsicMaxWidth, double textHeight) {
    const fadeEndFraction = 0.5;
    var opacity = 1.0;

    final double? curW = currentWidth;
    final double rawRefW = effectiveReferenceWidth(intrinsicMaxWidth);
    final double refW = (intrinsicMaxWidth.isFinite && intrinsicMaxWidth > 0.0 && rawRefW > 0.0)
        ? math.min(rawRefW, intrinsicMaxWidth)
        : rawRefW;
    if (curW != null && refW > 0.0 && curW.isFinite && curW < refW) {
      final double widthProgress = clampDouble((refW - curW) / refW, 0.0, 1.0);
      opacity = math.min(opacity, clampDouble(1.0 - (widthProgress / fadeEndFraction), 0.0, 1.0));
    }

    final double? curH = currentHeight;
    final double rawRefH = effectiveReferenceHeight(textHeight);
    final double refH = (textHeight.isFinite && textHeight > 0.0 && rawRefH > 0.0)
        ? math.min(rawRefH, textHeight)
        : rawRefH;
    if (curH != null && refH > 0.0 && curH.isFinite && curH < refH) {
      final double heightProgress = clampDouble((refH - curH) / refH, 0.0, 1.0);
      opacity = math.min(opacity, clampDouble(1.0 - (heightProgress / fadeEndFraction), 0.0, 1.0));
    }

    return lastAlpha = ui.Color.getAlphaFromOpacity(opacity);
  }

  void updateVerticalConstraints(double incomingMaxHeight) {
    if (!incomingMaxHeight.isFinite) {
      currentHeight = null;
      return;
    }
    currentHeight = incomingMaxHeight;
    final double? locked = lockedMaxHeight;
    if (locked == null || incomingMaxHeight > locked) {
      lockedMaxHeight = incomingMaxHeight;
    }
  }

  double resolveLayoutMaxWidth(double incomingMaxWidth, double minIntrinsicLineExtent) {
    if (!incomingMaxWidth.isFinite) {
      return incomingMaxWidth;
    }
    if (minIntrinsicLineExtent.isFinite && minIntrinsicLineExtent > 0.0) {
      fallbackReferenceWidth = minIntrinsicLineExtent;
    }
    final double? locked = lockedMaxWidth;
    if (locked != null) {
      if (incomingMaxWidth > locked) {
        lockedMaxWidth = incomingMaxWidth;
        return incomingMaxWidth;
      }
      return locked;
    }
    if (minIntrinsicLineExtent.isFinite && incomingMaxWidth >= minIntrinsicLineExtent) {
      lockedMaxWidth = incomingMaxWidth;
      return incomingMaxWidth;
    }
    return minIntrinsicLineExtent.isFinite
        ? math.max(incomingMaxWidth, minIntrinsicLineExtent)
        : incomingMaxWidth;
  }

  void reset() {
    lockedMaxWidth = null;
    fallbackReferenceWidth = null;
    currentWidth = null;
    lockedMaxHeight = null;
    currentHeight = null;
    lastAlpha = 255;
  }

  void dispose() {
    opacityLayer.layer = null;
  }
}

/// The start and end positions for a text boundary.
typedef _TextBoundaryRecord = ({TextPosition boundaryStart, TextPosition boundaryEnd});

/// Signature for a function that determines the [_TextBoundaryRecord] at the given
/// [TextPosition].
typedef _TextBoundaryAtPosition = _TextBoundaryRecord Function(TextPosition position);

/// Signature for a function that determines the [_TextBoundaryRecord] at the given
/// [TextPosition], for the given [String].
typedef _TextBoundaryAtPositionInText = _TextBoundaryRecord Function(
  TextPosition position,
  String text,
);

const String _kEllipsis = '\u2026';

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
  const PlaceholderSpanIndexSemanticsTag(this.index)
    : super('PlaceholderSpanIndexSemanticsTag($index)');

  /// The index of this tag.
  final int index;

  @override
  bool operator ==(Object other) {
    return other is PlaceholderSpanIndexSemanticsTag && other.index == index;
  }

  @override
  int get hashCode => Object.hash(PlaceholderSpanIndexSemanticsTag, index);
}

/// Parent data used by [RenderParagraph] and [RenderEditable] to annotate
/// inline contents (such as [WidgetSpan]s) with.
class TextParentData extends ParentData with ContainerParentDataMixin<RenderBox> {
  /// The offset at which to paint the child in the parent's coordinate system.
  ///
  /// A `null` value indicates this inline widget is not laid out. For instance,
  /// when the inline widget has never been laid out, or the inline widget is
  /// ellipsized away.
  Offset? get offset => _offset;
  Offset? _offset;

  /// The [PlaceholderSpan] associated with this render child.
  ///
  /// This field is usually set by a [ParentDataWidget], and is typically not
  /// null when `performLayout` is called.
  PlaceholderSpan? span;

  @override
  void detach() {
    span = null;
    _offset = null;
    super.detach();
  }

  @override
  String toString() => 'widget: $span, ${offset == null ? "not laid out" : "offset: $offset"}';
}

/// A mixin that provides useful default behaviors for text [RenderBox]es
/// ([RenderParagraph] and [RenderEditable] for example) with inline content
/// children managed by the [ContainerRenderObjectMixin] mixin.
///
/// This mixin assumes every child managed by the [ContainerRenderObjectMixin]
/// mixin corresponds to a [PlaceholderSpan], and they are organized in logical
/// order of the text (the order each [PlaceholderSpan] is encountered when the
/// user reads the text).
///
/// To use this mixin in a [RenderBox] class:
///
///  * Call [layoutInlineChildren] in the `performLayout` and `computeDryLayout`
///    implementation, and during intrinsic size calculations, to get the size
///    information of the inline widgets as a `List` of `PlaceholderDimensions`.
///    Determine the positioning of the inline widgets (which is usually done by
///    a [TextPainter] using its line break algorithm).
///
///  * Call [positionInlineChildren] with the positioning information of the
///    inline widgets.
///
///  * Implement [RenderBox.applyPaintTransform], optionally with
///    [defaultApplyPaintTransform].
///
///  * Call [paintInlineChildren] in [RenderBox.paint] to paint the inline widgets.
///
///  * Call [hitTestInlineChildren] in [RenderBox.hitTestChildren] to hit test the
///    inline widgets.
///
/// See also:
///
///  * [WidgetSpan.extractFromInlineSpan], a helper function for extracting
///    [WidgetSpan]s from an [InlineSpan] tree.
mixin RenderInlineChildrenContainerDefaults
    on RenderBox, ContainerRenderObjectMixin<RenderBox, TextParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TextParentData) {
      child.parentData = TextParentData();
    }
  }

  static PlaceholderDimensions _layoutChild(
    RenderBox child,
    BoxConstraints childConstraints,
    ChildLayouter layoutChild,
    ChildBaselineGetter getBaseline,
  ) {
    final parentData = child.parentData! as TextParentData;
    final PlaceholderSpan? span = parentData.span;
    assert(span != null);
    return span == null
        ? PlaceholderDimensions.empty
        : PlaceholderDimensions(
            size: layoutChild(child, childConstraints),
            alignment: span.alignment,
            baseline: span.baseline,
            baselineOffset: switch (span.alignment) {
              ui.PlaceholderAlignment.aboveBaseline ||
              ui.PlaceholderAlignment.belowBaseline ||
              ui.PlaceholderAlignment.bottom ||
              ui.PlaceholderAlignment.middle ||
              ui.PlaceholderAlignment.top => null,
              ui.PlaceholderAlignment.baseline => getBaseline(
                child,
                childConstraints,
                span.baseline!,
              ),
            },
          );
  }

  /// Computes the layout for every inline child using the `maxWidth` constraint.
  ///
  /// Returns a list of [PlaceholderDimensions], representing the layout results
  /// for each child managed by the [ContainerRenderObjectMixin] mixin.
  ///
  /// The `getChildBaseline` parameter and the `layoutChild` parameter must be
  /// consistent: if `layoutChild` computes the size of the child without
  /// modifying the actual layout of that child, then `getChildBaseline` must
  /// also be "dry", and vice versa.
  ///
  /// Since this method does not impose a maximum height constraint on the
  /// inline children, some children may become taller than this [RenderBox].
  ///
  /// See also:
  ///
  ///  * [TextPainter.setPlaceholderDimensions], the method that usually takes
  ///    the layout results from this method as the input.
  @protected
  List<PlaceholderDimensions> layoutInlineChildren(
    double maxWidth,
    ChildLayouter layoutChild,
    ChildBaselineGetter getChildBaseline,
  ) {
    final constraints = BoxConstraints(maxWidth: maxWidth);
    return <PlaceholderDimensions>[
      for (RenderBox? child = firstChild; child != null; child = childAfter(child))
        _layoutChild(child, constraints, layoutChild, getChildBaseline),
    ];
  }

  /// Positions each inline child according to the coordinates provided in the
  /// `boxes` list.
  ///
  /// The `boxes` list must be in logical order, which is the order each child
  /// is encountered when the user reads the text. Usually the length of the
  /// list equals [childCount], but it can be less than that, when some children
  /// are omitted due to ellipsing. It never exceeds [childCount].
  ///
  /// See also:
  ///
  ///  * [TextPainter.inlinePlaceholderBoxes], the method that can be used to
  ///    get the input `boxes`.
  @protected
  void positionInlineChildren(List<ui.TextBox> boxes) {
    RenderBox? child = firstChild;
    for (final box in boxes) {
      if (child == null) {
        assert(() {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Invalid number of boxes provided to positionInlineChildren.'),
            ErrorDescription(
              'The number of boxes (${boxes.length}) exceeds the number of child render objects ($childCount). '
              'Each box corresponds to a child, but there are not enough children to position all boxes.',
            ),
            ErrorHint(
              'This error typically occurs when a custom InlineSpan implementation returns a list of boxes '
              'that is longer than the number of inline children. Ensure that the number of boxes returned '
              'by `computeLineMetrics` or similar methods does not exceed the number of children.',
            ),
            DiagnosticsProperty<RenderObject>(
              'The RenderParagraph receiving the boxes',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            ),
          ]);
        }());
        return;
      }
      final textParentData = child.parentData! as TextParentData;
      textParentData._offset = Offset(box.left, box.top);
      child = childAfter(child);
    }
    while (child != null) {
      final textParentData = child.parentData! as TextParentData;
      textParentData._offset = null;
      child = childAfter(child);
    }
  }

  /// Applies the transform that would be applied when painting the given child
  /// to the given matrix.
  ///
  /// Render children whose [TextParentData.offset] is null zeros out the
  /// `transform` to indicate they're invisible thus should not be painted.
  @protected
  void defaultApplyPaintTransform(RenderBox child, Matrix4 transform) {
    final childParentData = child.parentData! as TextParentData;
    final Offset? offset = childParentData.offset;
    if (offset == null) {
      transform.setZero();
    } else {
      transform.translateByDouble(offset.dx, offset.dy, 0, 1);
    }
  }

  /// Paints each inline child.
  ///
  /// Render children whose [TextParentData.offset] is null will be skipped by
  /// this method.
  @protected
  void paintInlineChildren(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as TextParentData;
      final Offset? childOffset = childParentData.offset;
      if (childOffset == null) {
        return;
      }
      context.paintChild(child, childOffset + offset);
      child = childAfter(child);
    }
  }

  /// Performs a hit test on each inline child.
  ///
  /// Render children whose [TextParentData.offset] is null will be skipped by
  /// this method.
  @protected
  bool hitTestInlineChildren(BoxHitTestResult result, Offset position) {
    RenderBox? child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as TextParentData;
      final Offset? childOffset = childParentData.offset;
      if (childOffset == null) {
        return false;
      }
      final bool isHit = result.addWithPaintOffset(
        offset: childOffset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) =>
            child!.hitTest(result, position: transformed),
      );
      if (isHit) {
        return true;
      }
      child = childAfter(child);
    }
    return false;
  }
}

class _UnspecifiedTextScaler extends TextScaler {
  const _UnspecifiedTextScaler();

  @override
  Never get textScaleFactor => throw UnimplementedError();

  @override
  Never scale(double fontSize) => throw UnimplementedError();
}

/// A render object that displays a paragraph of text.
class RenderParagraph extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TextParentData>,
        RenderInlineChildrenContainerDefaults,
        RelayoutWhenSystemFontsChangeMixin {
  /// Creates a paragraph render object.
  ///
  /// The [maxLines] property may be null (and indeed defaults to null), but if
  /// it is not null, it must be greater than zero.
  RenderParagraph(
    InlineSpan text, {
    TextAlign textAlign = TextAlign.start,
    required TextDirection textDirection,
    this._softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    TextOverflowPosition overflowPosition = TextOverflowPosition.end,
    TextScrollOverflow scrollOverflow = TextScrollOverflow.wrap,
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
      'This feature was deprecated after v3.12.0-2.0.pre.',
    )
    double textScaleFactor = 1.0,
    TextScaler textScaler = const _UnspecifiedTextScaler(),
    int? maxLines,
    Locale? locale,
    StrutStyle? strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    ui.TextHeightBehavior? textHeightBehavior,
    ui.Hyphens hyphens = ui.Hyphens.manual,
    List<RenderBox>? children,
    this._selectionColor,
    SelectionRegistrar? registrar,
    this._devicePixelRatio = 1.0,
  }) : assert(text.debugAssertIsValid()),
       assert(maxLines == null || maxLines > 0),
       assert(
         identical(textScaler, const _UnspecifiedTextScaler()) || textScaleFactor == 1.0,
         'textScaleFactor is deprecated and cannot be specified when textScaler is specified.',
       ),
       _overflow = overflow,
       _overflowPosition = overflowPosition,
       _scrollOverflow = scrollOverflow,
       _rawText = text,
       _textPainter = TextPainter(
         text: text,
         textAlign: textAlign,
         textDirection: textDirection,
         textScaler: textScaler == const _UnspecifiedTextScaler()
             ? TextScaler.linear(textScaleFactor)
             : textScaler,
         maxLines: maxLines,
         ellipsis: overflow == TextOverflow.ellipsis && overflowPosition == TextOverflowPosition.end
             ? _kEllipsis
             : null,
         locale: locale,
         strutStyle: strutStyle,
         textWidthBasis: textWidthBasis,
         textHeightBehavior: textHeightBehavior,
         hyphens: hyphens,
       ) {
    addAll(children);
    this.registrar = registrar;
    if (scrollOverflow != TextScrollOverflow.wrap) {
      _shrinkState = _TextShrinkState();
    }
  }

  static final String _placeholderCharacter = String.fromCharCode(
    PlaceholderSpan.placeholderCodeUnit,
  );

  final TextPainter _textPainter;
  InlineSpan _rawText;

  // Currently, computing min/max intrinsic width/height will destroy state
  // inside the painter. Instead of calling _layout again to get back the correct
  // state, use a separate TextPainter for intrinsics calculation.
  //
  // TODO(abarth): Make computing the min/max intrinsic width/height a
  //  non-destructive operation.
  TextPainter? _textIntrinsicsCache;

  TextPainter get _textIntrinsics {
    return (_textIntrinsicsCache ??= TextPainter())
      ..text = _rawText
      ..textAlign = _textPainter.textAlign
      ..textDirection = _textPainter.textDirection
      ..textScaler = _textPainter.textScaler
      ..maxLines = _textPainter.maxLines
      ..ellipsis = _textPainter.ellipsis
      ..locale = _textPainter.locale
      ..strutStyle = _textPainter.strutStyle
      ..textWidthBasis = _textPainter.textWidthBasis
      ..textHeightBehavior = _textPainter.textHeightBehavior
      ..hyphens = _textPainter.hyphens;
  }

  List<AttributedString>? _cachedAttributedLabels;

  List<InlineSpanSemanticsInformation>? _cachedCombinedSemanticsInfos;

  /// The text to display.
  InlineSpan get text => _rawText;

  set text(InlineSpan value) {
    final RenderComparison comparison = _rawText.compareTo(value);
    _rawText = value;
    switch (comparison) {
      case RenderComparison.identical:
        return;
      case RenderComparison.metadata:
        _textPainter.text = value;
        _invalidateShrinkAndEllipsisCaches(resetShrinkLock: false);
        _cachedCombinedSemanticsInfos = null;
        markNeedsSemanticsUpdate();
      case RenderComparison.paint:
        _textPainter.text = value;
        _invalidateShrinkAndEllipsisCaches(resetShrinkLock: false);
        _cachedAttributedLabels = null;
        _cachedCombinedSemanticsInfos = null;
        markNeedsPaint();
        markNeedsSemanticsUpdate();
      case RenderComparison.layout:
        _textPainter.text = value;
        _overflowShader = null;
        _invalidateShrinkAndEllipsisCaches();
        _cachedAttributedLabels = null;
        _cachedCombinedSemanticsInfos = null;
        markNeedsLayout();
        _removeSelectionRegistrarSubscription();
        _disposeSelectableFragments();
        _updateSelectionRegistrarSubscription();
    }
  }

  /// The ongoing selections in this paragraph.
  ///
  /// The selection does not include selections in [PlaceholderSpan] if there
  /// are any.
  @visibleForTesting
  List<TextSelection> get selections {
    if (_lastSelectableFragments == null) {
      return const <TextSelection>[];
    }
    final results = <TextSelection>[];
    for (final _SelectableFragment fragment in _lastSelectableFragments!) {
      if (fragment._textSelectionStart != null && fragment._textSelectionEnd != null) {
        results.add(
          TextSelection(
            baseOffset: fragment._textSelectionStart!.offset,
            extentOffset: fragment._textSelectionEnd!.offset,
          ),
        );
      }
    }
    return results;
  }

  // Should be null if selection is not enabled, i.e. _registrar = null. The
  // paragraph splits on [PlaceholderSpan.placeholderCodeUnit], and stores each
  // fragment in this list.
  List<_SelectableFragment>? _lastSelectableFragments;

  /// The [SelectionRegistrar] this paragraph will be, or is, registered to.
  SelectionRegistrar? get registrar => _registrar;
  SelectionRegistrar? _registrar;

  set registrar(SelectionRegistrar? value) {
    if (value == _registrar) {
      return;
    }
    _removeSelectionRegistrarSubscription();
    _disposeSelectableFragments();
    _registrar = value;
    _updateSelectionRegistrarSubscription();
  }

  void _updateSelectionRegistrarSubscription() {
    if (_registrar == null) {
      return;
    }
    _lastSelectableFragments ??= _getSelectableFragments();
    _lastSelectableFragments!.forEach(_registrar!.add);
    if (_lastSelectableFragments!.isNotEmpty) {
      markNeedsCompositingBitsUpdate();
    }
  }

  void _removeSelectionRegistrarSubscription() {
    if (_registrar == null || _lastSelectableFragments == null) {
      return;
    }
    _lastSelectableFragments!.forEach(_registrar!.remove);
  }

  List<_SelectableFragment> _getSelectableFragments() {
    final String plainText = text.toPlainText(includeSemanticsLabels: false);
    final result = <_SelectableFragment>[];
    var start = 0;
    while (start < plainText.length) {
      int end = plainText.indexOf(_placeholderCharacter, start);
      if (start != end) {
        if (end == -1) {
          end = plainText.length;
        }
        result.add(
          _SelectableFragment(
            paragraph: this,
            range: TextRange(start: start, end: end),
            fullText: plainText,
          ),
        );
        start = end;
      }
      start += 1;
    }
    return result;
  }

  /// Determines whether the given [Selectable] was created by this
  /// [RenderParagraph].
  ///
  /// The [RenderParagraph] splits its text into multiple [Selectable]s,
  /// delimited by [PlaceholderSpan]s or [WidgetSpan]s.
  bool selectableBelongsToParagraph(Selectable selectable) {
    if (_lastSelectableFragments == null) {
      return false;
    }
    return _lastSelectableFragments!.contains(selectable);
  }

  void _disposeSelectableFragments() {
    if (_lastSelectableFragments == null) {
      return;
    }
    for (final _SelectableFragment fragment in _lastSelectableFragments!) {
      fragment.dispose();
    }
    _lastSelectableFragments = null;
  }

  @override
  bool get alwaysNeedsCompositing =>
      (_lastSelectableFragments?.isNotEmpty ?? false) ||
      (_shrinkFadesOpacity && _effectiveShrinkAlpha > 0 && _effectiveShrinkAlpha < 255);

  bool get _shrinkFreezesLayout => _scrollOverflow != TextScrollOverflow.wrap;

  bool get _shrinkFadesOpacity => _scrollOverflow == TextScrollOverflow.fade;

  int get _effectiveShrinkAlpha {
    if (!_shrinkFadesOpacity || _shrinkState == null) {
      return 255;
    }
    return _shrinkState!.lastAlpha;
  }

  _TextShrinkState? _shrinkState;
  BoxConstraints? _cachedShrinkLayoutConstraints;
  InlineSpan? _cachedEllipsisSpan;
  double? _cachedEllipsisMaxWidth;

  void _invalidateShrinkAndEllipsisCaches({bool resetShrinkLock = true}) {
    if (resetShrinkLock) {
      _shrinkState?.reset();
    }
    _cachedShrinkLayoutConstraints = null;
    _cachedEllipsisSpan = null;
    _cachedEllipsisMaxWidth = null;
    _overflowShaderRect = null;
  }

  @override
  void detach() {
    _shrinkState?.opacityLayer.layer = null;
    super.detach();
  }

  @override
  void markNeedsLayout() {
    _lastSelectableFragments?.forEach(
      (_SelectableFragment element) => element.didChangeParagraphLayout(),
    );
    super.markNeedsLayout();
  }

  @override
  void dispose() {
    _shrinkState?.dispose();
    _shrinkState = null;
    _removeSelectionRegistrarSubscription();
    _disposeSelectableFragments();
    _textPainter.dispose();
    _textIntrinsicsCache?.dispose();
    super.dispose();
  }

  /// How the text should be aligned horizontally.
  TextAlign get textAlign => _textPainter.textAlign;

  set textAlign(TextAlign value) {
    if (_textPainter.textAlign == value) {
      return;
    }
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
  TextDirection get textDirection => _textPainter.textDirection!;

  set textDirection(TextDirection value) {
    if (_textPainter.textDirection == value) {
      return;
    }
    _textPainter.textDirection = value;
    _invalidateShrinkAndEllipsisCaches();
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
    if (_softWrap == value) {
      return;
    }
    _softWrap = value;
    _invalidateShrinkAndEllipsisCaches();
    markNeedsLayout();
  }

  /// How visual overflow should be handled.
  TextOverflow get overflow => _overflow;
  TextOverflow _overflow;

  set overflow(TextOverflow value) {
    if (_overflow == value) {
      return;
    }
    _overflow = value;
    _textPainter.ellipsis =
        value == TextOverflow.ellipsis && _overflowPosition == TextOverflowPosition.end
        ? _kEllipsis
        : null;
    _overflowShader = null;
    _invalidateShrinkAndEllipsisCaches();
    markNeedsLayout();
  }

  /// Where within the text visual overflow truncation or fading should occur.
  ///
  /// Defaults to [TextOverflowPosition.end].
  TextOverflowPosition get overflowPosition => _overflowPosition;
  TextOverflowPosition _overflowPosition;

  set overflowPosition(TextOverflowPosition value) {
    if (_overflowPosition == value) {
      return;
    }
    _overflowPosition = value;
    _textPainter.ellipsis = _overflow == TextOverflow.ellipsis && value == TextOverflowPosition.end
        ? _kEllipsis
        : null;
    _overflowShader = null;
    _invalidateShrinkAndEllipsisCaches();
    markNeedsLayout();
  }

  /// How this paragraph behaves when its incoming layout constraints shrink
  /// below its expanded width during scrolling or layout transitions.
  ///
  /// Defaults to [TextScrollOverflow.wrap].
  TextScrollOverflow get scrollOverflow => _scrollOverflow;
  TextScrollOverflow _scrollOverflow;

  set scrollOverflow(TextScrollOverflow value) {
    if (_scrollOverflow == value) {
      return;
    }
    final bool didNeedCompositing = alwaysNeedsCompositing;
    final int oldAlpha = _effectiveShrinkAlpha;
    _scrollOverflow = value;
    if (value == TextScrollOverflow.wrap) {
      _shrinkState?.dispose();
      _shrinkState = null;
    } else {
      _shrinkState ??= _TextShrinkState();
    }
    _invalidateShrinkAndEllipsisCaches(resetShrinkLock: false);
    final int newAlpha = _effectiveShrinkAlpha;
    if (didNeedCompositing != alwaysNeedsCompositing) {
      markNeedsCompositingBitsUpdate();
    }
    markNeedsLayout();
    markNeedsPaint();
    if ((oldAlpha == 0) != (newAlpha == 0)) {
      markNeedsSemanticsUpdate();
    }
  }

  /// Deprecated. Will be removed in a future version of Flutter. Use
  /// [textScaler] instead.
  ///
  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  @Deprecated(
    'Use textScaler instead. '
    'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
    'This feature was deprecated after v3.12.0-2.0.pre.',
  )
  double get textScaleFactor => _textPainter.textScaleFactor;

  @Deprecated(
    'Use textScaler instead. '
    'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
    'This feature was deprecated after v3.12.0-2.0.pre.',
  )
  set textScaleFactor(double value) {
    textScaler = TextScaler.linear(value);
  }

  /// {@macro flutter.painting.textPainter.textScaler}
  TextScaler get textScaler => _textPainter.textScaler;

  set textScaler(TextScaler value) {
    if (_textPainter.textScaler == value) {
      return;
    }
    _textPainter.textScaler = value;
    _overflowShader = null;
    _invalidateShrinkAndEllipsisCaches();
    markNeedsLayout();
  }

  /// The number of device pixels for each logical pixel.
  ///
  /// This is used by some renderers (like WebParagraph on the web) to
  /// regenerate the text bitmap when the scale changes.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;

  set devicePixelRatio(double value) {
    if (_devicePixelRatio == value) {
      return;
    }
    _devicePixelRatio = value;
    if (kIsWeb) {
      // The `WebParagraph` implementation renders the paragraph as an image. After a
      // `devicePixelRatio` change, the image needs to be regenerated or it would look blurry.
      markNeedsPaint();
    }
  }

  /// An optional maximum number of lines for the text to span, wrapping if
  /// necessary. If the text exceeds the given number of lines, it will be
  /// truncated according to [overflow] and [softWrap].
  int? get maxLines => _textPainter.maxLines;

  /// The value may be null. If it is not null, then it must be greater than
  /// zero.
  set maxLines(int? value) {
    assert(value == null || value > 0);
    if (_textPainter.maxLines == value) {
      return;
    }
    _textPainter.maxLines = value;
    _overflowShader = null;
    _invalidateShrinkAndEllipsisCaches();
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
    if (_textPainter.locale == value) {
      return;
    }
    _textPainter.locale = value;
    _overflowShader = null;
    _invalidateShrinkAndEllipsisCaches();
    markNeedsLayout();
  }

  /// {@macro flutter.painting.textPainter.strutStyle}
  StrutStyle? get strutStyle => _textPainter.strutStyle;

  /// The value may be null.
  set strutStyle(StrutStyle? value) {
    if (_textPainter.strutStyle == value) {
      return;
    }
    _textPainter.strutStyle = value;
    _overflowShader = null;
    _invalidateShrinkAndEllipsisCaches();
    markNeedsLayout();
  }

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  TextWidthBasis get textWidthBasis => _textPainter.textWidthBasis;

  set textWidthBasis(TextWidthBasis value) {
    if (_textPainter.textWidthBasis == value) {
      return;
    }
    _textPainter.textWidthBasis = value;
    _overflowShader = null;
    _invalidateShrinkAndEllipsisCaches();
    markNeedsLayout();
  }

  /// {@macro dart.ui.textHeightBehavior}
  ui.TextHeightBehavior? get textHeightBehavior => _textPainter.textHeightBehavior;

  set textHeightBehavior(ui.TextHeightBehavior? value) {
    if (_textPainter.textHeightBehavior == value) {
      return;
    }
    _textPainter.textHeightBehavior = value;
    _overflowShader = null;
    _invalidateShrinkAndEllipsisCaches();
    markNeedsLayout();
  }

  /// {@macro flutter.painting.textPainter.hyphens}
  ui.Hyphens get hyphens => _textPainter.hyphens;

  set hyphens(ui.Hyphens value) {
    if (_textPainter.hyphens == value) {
      return;
    }
    _textPainter.hyphens = value;
    _overflowShader = null;
    _invalidateShrinkAndEllipsisCaches();
    // The rendered hyphen doesn't change where lines break, but it makes its
    // line wider, which changes the paragraph's longest line and so its size
    // with TextWidthBasis.longestLine. Hence markNeedsLayout, not markNeedsPaint.
    markNeedsLayout();
  }

  /// The color to use when painting the selection.
  ///
  /// Ignored if the text is not selectable (e.g. if [registrar] is null).
  Color? get selectionColor => _selectionColor;
  Color? _selectionColor;

  set selectionColor(Color? value) {
    if (_selectionColor == value) {
      return;
    }
    _selectionColor = value;
    if (_lastSelectableFragments?.any(
          (_SelectableFragment fragment) => fragment.value.hasSelection,
        ) ??
        false) {
      markNeedsPaint();
    }
  }

  Offset _getOffsetForPosition(TextPosition position) {
    return getOffsetForCaret(position, Rect.zero) + Offset(0, getFullHeightForCaret(position));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final List<PlaceholderDimensions> placeholderDimensions = layoutInlineChildren(
      double.infinity,
      (RenderBox child, BoxConstraints constraints) =>
          Size(child.getMinIntrinsicWidth(double.infinity), 0.0),
      ChildLayoutHelper.getDryBaseline,
    );
    return (_textIntrinsics
          ..setPlaceholderDimensions(placeholderDimensions)
          ..layout())
        .minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final List<PlaceholderDimensions> placeholderDimensions = layoutInlineChildren(
      double.infinity,
      // Height and baseline is irrelevant as all text will be laid
      // out in a single line. Therefore, using 0.0 as a dummy for the height.
      (RenderBox child, BoxConstraints constraints) =>
          Size(child.getMaxIntrinsicWidth(double.infinity), 0.0),
      ChildLayoutHelper.getDryBaseline,
    );
    return (_textIntrinsics
          ..setPlaceholderDimensions(placeholderDimensions)
          ..layout())
        .maxIntrinsicWidth;
  }

  /// An estimate of the height of a line in the text. See [TextPainter.preferredLineHeight].
  ///
  /// This does not require the layout to be updated.
  @visibleForTesting
  double get preferredLineHeight => _textPainter.preferredLineHeight;

  double _computeIntrinsicHeight(double width) {
    final double effectiveWidth = (_shrinkFreezesLayout && _shrinkState != null && width.isFinite)
        ? math.max(width, _shrinkState!.lockedMaxWidth ?? width)
        : width;
    return (_textIntrinsics
          ..setPlaceholderDimensions(
            layoutInlineChildren(
              effectiveWidth,
              ChildLayoutHelper.dryLayoutChild,
              ChildLayoutHelper.getDryBaseline,
            ),
          )
          ..layout(minWidth: width, maxWidth: _adjustMaxWidth(effectiveWidth)))
        .height;
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
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_effectiveShrinkAlpha == 0) {
      return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  @protected
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final Offset adjustedPosition = position - Offset(_computeShrinkAlignmentOffset(), 0.0);
    final GlyphInfo? glyph = _textPainter.getClosestGlyphForOffset(adjustedPosition);
    // The hit-test can't fall through the horizontal gaps between visually
    // adjacent characters on the same line, even with a large letter-spacing or
    // text justification, as graphemeClusterLayoutBounds.width is the advance
    // width to the next character, so there's no gap between their
    // graphemeClusterLayoutBounds rects.
    final InlineSpan? spanHit =
        glyph != null && glyph.graphemeClusterLayoutBounds.contains(adjustedPosition)
        ? _textPainter.text!.getSpanForPosition(
            TextPosition(offset: glyph.graphemeClusterCodeUnitRange.start),
          )
        : null;
    switch (spanHit) {
      case final HitTestTarget span:
        result.add(HitTestEntry(span));
        return true;
      case _:
        return hitTestInlineChildren(result, adjustedPosition);
    }
  }

  bool _needsClipping = false;
  ui.Shader? _overflowShader;
  Rect? _overflowShaderRect;

  /// Whether this paragraph currently has a [dart:ui.Shader] for its overflow
  /// effect.
  ///
  /// Used to test this object. Not for use in production.
  @visibleForTesting
  bool get debugHasOverflowShader => _overflowShader != null;

  /// The current scroll-shrink fade opacity (`0.0` to `1.0`) when
  /// [scrollOverflow] is [TextScrollOverflow.fade].
  ///
  /// Used to test this object. Not for use in production.
  @visibleForTesting
  double get debugScrollFadeOpacity =>
      _scrollOverflow == TextScrollOverflow.fade ? (_shrinkState?.lastAlpha ?? 255) / 255.0 : 1.0;

  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    _invalidateShrinkAndEllipsisCaches();
    _textPainter.markNeedsLayout();
  }

  // Placeholder dimensions representing the sizes of child inline widgets.
  //
  // These need to be cached because the text painter's placeholder dimensions
  // will be overwritten during intrinsic width/height calculations and must be
  // restored to the original values before final layout and painting.
  List<PlaceholderDimensions>? _placeholderDimensions;

  double _adjustMaxWidth(double maxWidth) {
    if (_overflowPosition != TextOverflowPosition.end &&
        _overflow != TextOverflow.ellipsis &&
        (maxLines == 1 || !softWrap)) {
      return double.infinity;
    }
    return softWrap || overflow == TextOverflow.ellipsis ? maxWidth : double.infinity;
  }

  BoxConstraints _resolveShrinkConstraints(
    BoxConstraints constraints, {
    bool updateHighWaterMark = false,
  }) {
    if (!_shrinkFreezesLayout) {
      return constraints;
    }
    final _TextShrinkState state = _shrinkState ??= _TextShrinkState();
    if (updateHighWaterMark) {
      state.updateVerticalConstraints(constraints.maxHeight);
    }
    if (!constraints.hasBoundedWidth) {
      return constraints;
    }
    final double incomingMaxWidth = constraints.maxWidth;
    // Measure single-line intrinsic width when starting in a narrow slot so words
    // never split mid-word or wrap into vertical stacks before expanding.
    final List<PlaceholderDimensions> dryPlaceholderDimensions = layoutInlineChildren(
      double.infinity,
      ChildLayoutHelper.dryLayoutChild,
      ChildLayoutHelper.getDryBaseline,
    );
    _textIntrinsics
      ..setPlaceholderDimensions(dryPlaceholderDimensions)
      ..layout();
    final double intrinsicMax = _textIntrinsics.maxIntrinsicWidth;
    final double intrinsicMin = _textIntrinsics.minIntrinsicWidth;
    final double singleLineOrWordFloor = (maxLines == null || maxLines == 1)
        ? intrinsicMax
        : math.max(intrinsicMin, intrinsicMax / maxLines!);
    if (updateHighWaterMark) {
      final double resolvedMaxWidth = state.resolveLayoutMaxWidth(
        incomingMaxWidth,
        singleLineOrWordFloor,
      );
      state.currentWidth = incomingMaxWidth;
      return constraints.copyWith(maxWidth: resolvedMaxWidth);
    }
    final double lockedMaxWidth = math.max(
      incomingMaxWidth,
      state.lockedMaxWidth ?? math.max(incomingMaxWidth, singleLineOrWordFloor),
    );
    return constraints.copyWith(maxWidth: lockedMaxWidth);
  }

  double _computeShrinkAlignmentOffset() {
    final double overflowWidth = _textPainter.width - size.width;
    if (overflowWidth <= 0.0) {
      return 0.0;
    }
    if (_overflowPosition == TextOverflowPosition.start) {
      return switch (textDirection) {
        TextDirection.ltr => -overflowWidth,
        TextDirection.rtl => 0.0,
      };
    }
    if (!_shrinkFreezesLayout) {
      return 0.0;
    }
    return switch ((textAlign, textDirection)) {
      (TextAlign.left, _) ||
      (TextAlign.start || TextAlign.justify, TextDirection.ltr) ||
      (TextAlign.end, TextDirection.rtl) => 0.0,
      (TextAlign.right, _) ||
      (TextAlign.start || TextAlign.justify, TextDirection.rtl) ||
      (TextAlign.end, TextDirection.ltr) => -overflowWidth,
      (TextAlign.center, _) => -overflowWidth / 2.0,
    };
  }

  InlineSpan _resolveEffectiveSpanForConstraints(BoxConstraints layoutConstraints) {
    if (_overflow != TextOverflow.ellipsis ||
        _overflowPosition == TextOverflowPosition.end ||
        firstChild != null ||
        (maxLines != 1 && softWrap)) {
      return _rawText;
    }
    final double maxWidth = layoutConstraints.maxWidth;
    if (!maxWidth.isFinite || maxWidth <= 0.0) {
      return _rawText;
    }
    final String fullString = _rawText.toPlainText(includeSemanticsLabels: false);
    if (fullString.isEmpty) {
      return _rawText;
    }
    final TextStyle? baseStyle = _rawText.style;
    // Shape the full span and ellipsis once, then query the already-shaped
    // glyph cluster layout bounds rather than re-shaping candidate substrings.
    final fullPainter = TextPainter(
      text: _rawText,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      hyphens: hyphens,
    )..layout();
    if (fullPainter.width <= maxWidth) {
      fullPainter.dispose();
      return _rawText;
    }

    final ellipsisPainter = TextPainter(
      text: TextSpan(style: baseStyle, text: _kEllipsis),
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
      strutStyle: strutStyle,
      textHeightBehavior: textHeightBehavior,
    )..layout();
    final double availableForGlyphs = maxWidth - ellipsisPainter.width;
    ellipsisPainter.dispose();
    if (availableForGlyphs <= 0.0) {
      fullPainter.dispose();
      return TextSpan(style: baseStyle, text: _kEllipsis);
    }

    final clusters = <(TextRange, double)>[];
    var offset = 0;
    while (offset < fullString.length) {
      final GlyphInfo? info = _getGlyphClusterAt(fullPainter, offset);
      if (info == null || info.graphemeClusterCodeUnitRange.end <= offset) {
        final int step =
            TextPainter.isHighSurrogate(fullString.codeUnitAt(offset)) &&
                offset + 1 < fullString.length
            ? 2
            : 1;
        final int nextOffset = offset + step;
        clusters.add((
          TextRange(start: offset, end: nextOffset),
          (fullPainter.width / fullString.length) * step,
        ));
        offset = nextOffset;
      } else {
        clusters.add((info.graphemeClusterCodeUnitRange, info.graphemeClusterLayoutBounds.width));
        offset = info.graphemeClusterCodeUnitRange.end;
      }
    }
    fullPainter.dispose();

    final bool isPlainSingleSpan =
        _rawText is TextSpan &&
        (_rawText as TextSpan).children == null &&
        (_rawText as TextSpan).recognizer == null;

    if (_overflowPosition == TextOverflowPosition.start) {
      var usedWidth = 0.0;
      int keepStartIndex = fullString.length;
      for (int i = clusters.length - 1; i >= 0; i--) {
        final (TextRange range, double clusterWidth) = clusters[i];
        if (usedWidth + clusterWidth > availableForGlyphs) {
          break;
        }
        usedWidth += clusterWidth;
        keepStartIndex = range.start;
      }
      if (isPlainSingleSpan) {
        return TextSpan(
          style: baseStyle,
          text: '$_kEllipsis${fullString.substring(keepStartIndex)}',
        );
      }
      final InlineSpan? tail = _sliceInlineSpan(_rawText, keepStartIndex, fullString.length, 0);
      return TextSpan(
        style: baseStyle,
        children: <InlineSpan>[
          const TextSpan(text: _kEllipsis),
          if (tail != null) tail,
        ],
      );
    }

    // TextOverflowPosition.middle: accumulate glyph clusters alternately from
    // start and end using already-shaped cluster widths.
    var usedWidth = 0.0;
    var leftClusterIdx = 0;
    int rightClusterIdx = clusters.length - 1;
    var headEndOffset = 0;
    int tailStartOffset = fullString.length;
    var takeFromLeft = true;
    while (leftClusterIdx <= rightClusterIdx) {
      if (takeFromLeft) {
        final (TextRange range, double w) = clusters[leftClusterIdx];
        if (usedWidth + w > availableForGlyphs) {
          break;
        }
        usedWidth += w;
        headEndOffset = range.end;
        leftClusterIdx += 1;
      } else {
        final (TextRange range, double w) = clusters[rightClusterIdx];
        if (usedWidth + w > availableForGlyphs) {
          break;
        }
        usedWidth += w;
        tailStartOffset = range.start;
        rightClusterIdx -= 1;
      }
      takeFromLeft = !takeFromLeft;
    }
    if (isPlainSingleSpan) {
      return TextSpan(
        style: baseStyle,
        text:
            '${fullString.substring(0, headEndOffset)}$_kEllipsis${fullString.substring(tailStartOffset)}',
      );
    }
    final InlineSpan? head = _sliceInlineSpan(_rawText, 0, headEndOffset, 0);
    final InlineSpan? tail = _sliceInlineSpan(_rawText, tailStartOffset, fullString.length, 0);
    return TextSpan(
      style: baseStyle,
      children: <InlineSpan>[
        if (head != null) head,
        const TextSpan(text: _kEllipsis),
        if (tail != null) tail,
      ],
    );
  }

  static InlineSpan? _sliceInlineSpan(InlineSpan span, int start, int end, int offset) {
    if (start >= end || span is! TextSpan) {
      return null;
    }
    var cursor = offset;
    String? slicedText;
    final String? text = span.text;
    if (text != null && text.isNotEmpty) {
      final int segStart = cursor;
      final int segEnd = cursor + text.length;
      cursor = segEnd;
      final int overlapStart = math.max(start, segStart);
      final int overlapEnd = math.min(end, segEnd);
      if (overlapStart < overlapEnd) {
        slicedText = text.substring(overlapStart - segStart, overlapEnd - segStart);
      }
    }
    List<InlineSpan>? slicedChildren;
    final List<InlineSpan>? children = span.children;
    if (children != null) {
      for (final InlineSpan child in children) {
        final int childLen = child.toPlainText(includeSemanticsLabels: false).length;
        if (cursor < end && cursor + childLen > start) {
          final InlineSpan? slicedChild = _sliceInlineSpan(child, start, end, cursor);
          if (slicedChild != null) {
            (slicedChildren ??= <InlineSpan>[]).add(slicedChild);
          }
        }
        cursor += childLen;
        if (cursor >= end) {
          break;
        }
      }
    }
    if (slicedText == null && (slicedChildren == null || slicedChildren.isEmpty)) {
      return null;
    }
    return TextSpan(
      text: slicedText,
      children: slicedChildren,
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      semanticsIdentifier: span.semanticsIdentifier,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }

  GlyphInfo? _getGlyphClusterAt(TextPainter painter, int codeUnitOffset) {
    final List<ui.TextBox> boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: codeUnitOffset, extentOffset: codeUnitOffset + 1),
    );
    if (boxes.isEmpty) {
      return null;
    }
    final Rect rect = boxes.first.toRect();
    return painter.getClosestGlyphForOffset(rect.center);
  }

  bool _didTruncateWithEllipsisPosition = false;

  void _layoutTextWithConstraints(
    BoxConstraints constraints, {
    bool useCachedShrinkConstraints = true,
    bool updateEllipsisCache = false,
  }) {
    final BoxConstraints layoutConstraints = useCachedShrinkConstraints
        ? (_shrinkFreezesLayout
              ? (_cachedShrinkLayoutConstraints ?? _resolveShrinkConstraints(constraints))
              : constraints)
        : constraints;
    final InlineSpan effectiveSpan;
    if (!updateEllipsisCache &&
        _cachedEllipsisSpan != null &&
        _cachedEllipsisMaxWidth == layoutConstraints.maxWidth) {
      effectiveSpan = _cachedEllipsisSpan!;
    } else {
      effectiveSpan = _resolveEffectiveSpanForConstraints(layoutConstraints);
      _cachedEllipsisSpan = effectiveSpan;
      _cachedEllipsisMaxWidth = layoutConstraints.maxWidth;
    }
    _didTruncateWithEllipsisPosition = !identical(effectiveSpan, _rawText);
    if (_textPainter.text != effectiveSpan) {
      _textPainter.text = effectiveSpan;
    }
    _textPainter
      ..setPlaceholderDimensions(_placeholderDimensions)
      ..layout(
        minWidth: layoutConstraints.minWidth,
        maxWidth: _adjustMaxWidth(layoutConstraints.maxWidth),
      );
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final BoxConstraints layoutConstraints = _resolveShrinkConstraints(constraints);
    final InlineSpan effectiveSpan = _resolveEffectiveSpanForConstraints(layoutConstraints);
    final Size size =
        (_textIntrinsics
              ..text = effectiveSpan
              ..setPlaceholderDimensions(
                layoutInlineChildren(
                  layoutConstraints.maxWidth,
                  ChildLayoutHelper.dryLayoutChild,
                  ChildLayoutHelper.getDryBaseline,
                ),
              )
              ..layout(
                minWidth: layoutConstraints.minWidth,
                maxWidth: _adjustMaxWidth(layoutConstraints.maxWidth),
              ))
            .size;
    return constraints.constrain(size);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
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

  @override
  double computeDryBaseline(covariant BoxConstraints constraints, TextBaseline baseline) {
    assert(constraints.debugAssertIsValid());
    final BoxConstraints layoutConstraints = _resolveShrinkConstraints(constraints);
    final InlineSpan effectiveSpan = _resolveEffectiveSpanForConstraints(layoutConstraints);
    _textIntrinsics
      ..text = effectiveSpan
      ..setPlaceholderDimensions(
        layoutInlineChildren(
          layoutConstraints.maxWidth,
          ChildLayoutHelper.dryLayoutChild,
          ChildLayoutHelper.getDryBaseline,
        ),
      )
      ..layout(
        minWidth: layoutConstraints.minWidth,
        maxWidth: _adjustMaxWidth(layoutConstraints.maxWidth),
      );
    return _textIntrinsics.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  }

  @override
  void performLayout() {
    _lastSelectableFragments?.forEach(
      (_SelectableFragment element) => element.didChangeParagraphLayout(),
    );
    final BoxConstraints constraints = this.constraints;
    final bool didNeedCompositing = alwaysNeedsCompositing;
    final int oldAlpha = _effectiveShrinkAlpha;
    final BoxConstraints layoutConstraints = _resolveShrinkConstraints(
      constraints,
      updateHighWaterMark: true,
    );
    _cachedShrinkLayoutConstraints = _shrinkFreezesLayout ? layoutConstraints : null;
    _placeholderDimensions = layoutInlineChildren(
      layoutConstraints.maxWidth,
      ChildLayoutHelper.layoutChild,
      ChildLayoutHelper.getBaseline,
    );
    _layoutTextWithConstraints(
      layoutConstraints,
      useCachedShrinkConstraints: false,
      updateEllipsisCache: true,
    );
    _shrinkState?.computeAlpha(_textPainter.maxIntrinsicWidth, _textPainter.height);
    final int newAlpha = _effectiveShrinkAlpha;
    if (didNeedCompositing != alwaysNeedsCompositing) {
      markNeedsCompositingBitsUpdate();
    }
    if ((oldAlpha == 0) != (newAlpha == 0)) {
      markNeedsSemanticsUpdate();
    }
    positionInlineChildren(_textPainter.inlinePlaceholderBoxes!);

    final Size textSize = _textPainter.size;
    size = constraints.constrain(textSize);

    final bool didOverflowHeight = size.height < textSize.height || _textPainter.didExceedMaxLines;
    final bool didOverflowWidth = size.width < textSize.width;
    // TODO(abarth): We're only measuring the sizes of the line boxes here. If
    // the glyphs draw outside the line boxes, we might think that there isn't
    // visual overflow when there actually is visual overflow. This can become
    // a problem if we start having horizontal overflow and introduce a clip
    // that affects the actual (but undetected) vertical overflow.
    final bool hasVisualOverflow = didOverflowWidth || didOverflowHeight;
    _overflowShaderRect = null;
    if (hasVisualOverflow) {
      switch (_overflow) {
        case TextOverflow.visible:
          _needsClipping = _scrollOverflow == TextScrollOverflow.clip;
          _overflowShader = null;
        case TextOverflow.clip:
        case TextOverflow.ellipsis:
          _needsClipping = true;
          _overflowShader = null;
        case TextOverflow.fade:
          _needsClipping = true;
          final fadeSizePainter = TextPainter(
            text: TextSpan(style: _textPainter.text!.style, text: '\u2026'),
            textDirection: textDirection,
            textScaler: textScaler,
            locale: locale,
          )..layout();
          final double fadeWidth = fadeSizePainter.width;
          if (didOverflowWidth) {
            switch (_overflowPosition) {
              case TextOverflowPosition.end:
                final (double fadeStart, double fadeEnd) = switch (textDirection) {
                  TextDirection.rtl => (fadeWidth, 0.0),
                  TextDirection.ltr => (size.width - fadeWidth, size.width),
                };
                _overflowShader = ui.Gradient.linear(
                  Offset(fadeStart, 0.0),
                  Offset(fadeEnd, 0.0),
                  <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
                );
              case TextOverflowPosition.start:
                final (double fadeStart, double fadeEnd) = switch (textDirection) {
                  TextDirection.rtl => (size.width - fadeWidth, size.width),
                  TextDirection.ltr => (fadeWidth, 0.0),
                };
                _overflowShader = ui.Gradient.linear(
                  Offset(fadeStart, 0.0),
                  Offset(fadeEnd, 0.0),
                  <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
                );
              case TextOverflowPosition.middle:
                final double halfWidth = size.width / 2.0;
                final double halfFade = math.min(fadeWidth, halfWidth);
                final double stop1 = size.width > 0.0
                    ? clampDouble((halfWidth - halfFade) / size.width, 0.0, 0.5)
                    : 0.0;
                final double stop2 = size.width > 0.0
                    ? clampDouble((halfWidth + halfFade) / size.width, 0.5, 1.0)
                    : 1.0;
                _overflowShader = ui.Gradient.linear(
                  Offset.zero,
                  Offset(size.width, 0.0),
                  <Color>[
                    const Color(0xFFFFFFFF),
                    const Color(0xFFFFFFFF),
                    const Color(0x00FFFFFF),
                    const Color(0xFFFFFFFF),
                    const Color(0xFFFFFFFF),
                  ],
                  <double>[0.0, stop1, 0.5, stop2, 1.0],
                );
            }
          } else {
            final List<ui.LineMetrics> lines = _textPainter.computeLineMetrics();
            final bool canApplyMultilineHorizontalFade =
                maxLines != null &&
                maxLines! > 1 &&
                lines.length > 1 &&
                _textPainter.didExceedMaxLines &&
                size.height >= textSize.height;
            if (canApplyMultilineHorizontalFade) {
              // When an explicit maxLines > 1 truncates the paragraph without
              // vertical box clipping, fade the trailing horizontal end of the
              // last visible line instead of fading the entire bottom line vertically.
              final ui.LineMetrics lastLine = lines.last;
              final double lineLeft = math.max(0.0, lastLine.left);
              final double lineRight = math.min(size.width, lastLine.left + lastLine.width);
              if (lineRight > lineLeft) {
                final double lineTop = math.max(
                  0.0,
                  math.min(lastLine.baseline - lastLine.ascent, size.height - lastLine.height),
                );
                _overflowShaderRect = Rect.fromLTRB(0.0, lineTop, size.width, size.height);
                final double effectiveFadeWidth = fadeWidth * 2.0;
                final (double fadeStart, double fadeEnd) = switch ((
                  _overflowPosition,
                  textDirection,
                )) {
                  (TextOverflowPosition.start, TextDirection.ltr) ||
                  (
                    TextOverflowPosition.end,
                    TextDirection.rtl,
                  ) => (math.min(lineRight, lineLeft + effectiveFadeWidth), lineLeft),
                  (TextOverflowPosition.end, TextDirection.ltr) ||
                  (TextOverflowPosition.start, TextDirection.rtl) ||
                  (
                    TextOverflowPosition.middle,
                    _,
                  ) => (math.max(lineLeft, lineRight - effectiveFadeWidth), lineRight),
                };
                _overflowShader = ui.Gradient.linear(
                  Offset(fadeStart, 0.0),
                  Offset(fadeEnd, 0.0),
                  <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
                );
              } else {
                _overflowShader = null;
              }
            } else {
              // When vertical height constraints (or maxLines == 1 with softWrap)
              // cause vertical overflow, apply the vertical bottom (or top) fade shader.
              final (double fadeStart, double fadeEnd) = switch (_overflowPosition) {
                TextOverflowPosition.start => (fadeSizePainter.height / 2.0, 0.0),
                TextOverflowPosition.end || TextOverflowPosition.middle => (
                  size.height - fadeSizePainter.height / 2.0,
                  size.height,
                ),
              };
              _overflowShader = ui.Gradient.linear(
                Offset(0.0, fadeStart),
                Offset(0.0, fadeEnd),
                <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
              );
            }
          }
          fadeSizePainter.dispose();
      }
    } else {
      _needsClipping = false;
      _overflowShader = null;
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final double shrinkOffset = _computeShrinkAlignmentOffset();
    if (shrinkOffset != 0.0) {
      transform.translateByDouble(shrinkOffset, 0.0, 0.0, 1.0);
    }
    defaultApplyPaintTransform(child, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final _TextShrinkState? shrinkState = _shrinkState;
    if (shrinkState != null && _shrinkFadesOpacity) {
      final int alpha = _effectiveShrinkAlpha;
      if (alpha == 0) {
        shrinkState.opacityLayer.layer = null;
        return;
      }
      if (alpha < 255) {
        shrinkState.opacityLayer.layer = context.pushOpacity(
          offset,
          alpha,
          _paintParagraphContent,
          oldLayer: shrinkState.opacityLayer.layer,
        );
        return;
      }
      shrinkState.opacityLayer.layer = null;
    } else if (shrinkState != null) {
      shrinkState.opacityLayer.layer = null;
    }
    _paintParagraphContent(context, offset);
  }

  void _paintParagraphContent(PaintingContext context, Offset offset) {
    // Text alignment only triggers repaint so it's possible the text layout has
    // been invalidated but performLayout wasn't called at this point. Make sure
    // the TextPainter has a valid layout.
    _layoutTextWithConstraints(constraints);
    assert(() {
      if (debugRepaintTextRainbowEnabled) {
        final paint = Paint()..color = debugCurrentRepaintColor.toColor();
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    }());

    final Offset alignedOffset = offset + Offset(_computeShrinkAlignmentOffset(), 0.0);

    if (_lastSelectableFragments != null) {
      if (_needsClipping) {
        context.canvas.save();
        context.canvas.clipRect(offset & size);
      }
      for (final _SelectableFragment fragment in _lastSelectableFragments!) {
        fragment.paintSelection(context, alignedOffset);
      }
      if (_needsClipping) {
        context.canvas.restore();
      }
    }

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

    assert(() {
      _textPainter.debugPaintTextLayoutBoxes = debugPaintTextLayoutBoxes;
      return true;
    }());

    final double overflowWidth = _textPainter.width - size.width;
    if (_overflowPosition == TextOverflowPosition.middle &&
        _overflow != TextOverflow.ellipsis &&
        _overflow != TextOverflow.visible &&
        overflowWidth > 0.0) {
      final double halfWidth = size.width / 2.0;
      context.canvas.save();
      context.canvas.clipRect(Rect.fromLTWH(offset.dx, offset.dy, halfWidth, size.height));
      _textPainter.paint(context.canvas, offset);
      paintInlineChildren(context, offset);
      context.canvas.restore();

      context.canvas.save();
      context.canvas.clipRect(
        Rect.fromLTWH(offset.dx + halfWidth, offset.dy, size.width - halfWidth, size.height),
      );
      final Offset trailingOffset = offset - Offset(overflowWidth, 0.0);
      _textPainter.paint(context.canvas, trailingOffset);
      paintInlineChildren(context, trailingOffset);
      context.canvas.restore();
    } else {
      _textPainter.paint(context.canvas, alignedOffset);
      paintInlineChildren(context, alignedOffset);
    }

    if (_needsClipping) {
      if (_overflowShader != null) {
        context.canvas.translate(offset.dx, offset.dy);
        final paint = Paint()
          ..blendMode = BlendMode.modulate
          ..shader = _overflowShader;
        context.canvas.drawRect(_overflowShaderRect ?? (Offset.zero & size), paint);
      }
      context.canvas.restore();
    }

    if (_lastSelectableFragments != null) {
      for (final _SelectableFragment fragment in _lastSelectableFragments!) {
        fragment.paintHandles(context, alignedOffset);
      }
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
  double getFullHeightForCaret(TextPosition position) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getFullHeightForCaret(position, Rect.zero);
  }

  /// Returns a list of rects that bound the given selection.
  ///
  /// The [boxHeightStyle] and [boxWidthStyle] arguments may be used to select
  /// the shape of the [TextBox]es. These properties default to
  /// [ui.BoxHeightStyle.tight] and [ui.BoxWidthStyle.tight] respectively.
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

  TextRange _getLineAtOffset(TextPosition position) => _textPainter.getLineBoundary(position);

  TextPosition _getTextPositionAbove(TextPosition position) {
    // -0.5 of preferredLineHeight points to the middle of the line above.
    final double preferredLineHeight = _textPainter.preferredLineHeight;
    final double verticalOffset = -0.5 * preferredLineHeight;
    return _getTextPositionVertical(position, verticalOffset);
  }

  TextPosition _getTextPositionBelow(TextPosition position) {
    // 1.5 of preferredLineHeight points to the middle of the line below.
    final double preferredLineHeight = _textPainter.preferredLineHeight;
    final double verticalOffset = 1.5 * preferredLineHeight;
    return _getTextPositionVertical(position, verticalOffset);
  }

  TextPosition _getTextPositionVertical(TextPosition position, double verticalOffset) {
    final Offset caretOffset = _textPainter.getOffsetForCaret(position, Rect.zero);
    final Offset caretOffsetTranslated = caretOffset.translate(0.0, verticalOffset);
    return _textPainter.getPositionForOffset(caretOffsetTranslated);
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

  /// Whether the text was truncated or ellipsized as laid out.
  ///
  /// This returns the [TextPainter.didExceedMaxLines] of the underlying [TextPainter].
  ///
  /// Valid only after [layout].
  bool get didExceedMaxLines {
    assert(!debugNeedsLayout);
    return _textPainter.didExceedMaxLines || _didTruncateWithEllipsisPosition;
  }

  /// Collected during [describeSemanticsConfiguration], used by
  /// [assembleSemanticsNode].
  List<InlineSpanSemanticsInformation>? _semanticsInfo;

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (_effectiveShrinkAlpha == 0) {
      return;
    }
    super.visitChildrenForSemantics(visitor);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (_effectiveShrinkAlpha == 0) {
      _semanticsInfo = const <InlineSpanSemanticsInformation>[];
      return;
    }
    _semanticsInfo = text.getSemanticsInformation();
    var needsAssembleSemanticsNode = false;
    var needsChildConfigurationsDelegate = false;
    for (final InlineSpanSemanticsInformation info in _semanticsInfo!) {
      if (info.recognizer != null || info.semanticsIdentifier != null) {
        needsAssembleSemanticsNode = true;
        break;
      }
      needsChildConfigurationsDelegate = needsChildConfigurationsDelegate || info.isPlaceholder;
    }

    if (needsAssembleSemanticsNode) {
      config.explicitChildNodes = true;
      config.isSemanticBoundary = true;
    } else if (needsChildConfigurationsDelegate) {
      config.childConfigurationsDelegate = _childSemanticsConfigurationsDelegate;
    } else {
      if (_cachedAttributedLabels == null) {
        final buffer = StringBuffer();
        var offset = 0;
        final attributes = <StringAttribute>[];
        for (final InlineSpanSemanticsInformation info in _semanticsInfo!) {
          final String label = info.semanticsLabel ?? info.text;
          for (final StringAttribute infoAttribute in info.stringAttributes) {
            final TextRange originalRange = infoAttribute.range;
            attributes.add(
              infoAttribute.copy(
                range: TextRange(
                  start: offset + originalRange.start,
                  end: offset + originalRange.end,
                ),
              ),
            );
          }
          buffer.write(label);
          offset += label.length;
        }
        _cachedAttributedLabels = <AttributedString>[
          AttributedString(buffer.toString(), attributes: attributes),
        ];
      }
      config.attributedLabel = _cachedAttributedLabels![0];
      config.textDirection = textDirection;
    }
  }

  ChildSemanticsConfigurationsResult _childSemanticsConfigurationsDelegate(
    List<SemanticsConfiguration> childConfigs,
  ) {
    final builder = ChildSemanticsConfigurationsResultBuilder();
    var placeholderIndex = 0;
    var childConfigsIndex = 0;
    var attributedLabelCacheIndex = 0;
    _cachedCombinedSemanticsInfos ??= combineSemanticsInfo(_semanticsInfo!);
    for (final InlineSpanSemanticsInformation info in _cachedCombinedSemanticsInfos!) {
      if (info.isPlaceholder) {
        // Mark every childConfig belongs to this placeholder to merge up group.
        while (childConfigsIndex < childConfigs.length &&
            _childConfigBelongsToPlaceholder(childConfigs[childConfigsIndex], placeholderIndex)) {
          builder.markAsMergeUp(childConfigs[childConfigsIndex]);
          childConfigsIndex += 1;
        }
        placeholderIndex += 1;
      } else {
        builder.markAsMergeUp(_createSemanticsConfigForTextInfo(info, attributedLabelCacheIndex));
        attributedLabelCacheIndex += 1;
      }
    }
    return builder.build();
  }

  /// Returns whether [childConfig] belongs to the placeholder at
  /// [placeholderIndex] in this paragraph.
  ///
  /// Nested paragraphs may inherit [PlaceholderSpanIndexSemanticsTag]s from
  /// ancestors with colliding indexes. The first placeholder tag is the one
  /// added by this paragraph, so later inherited tags must not decide ownership
  /// here.
  static bool _childConfigBelongsToPlaceholder(
    SemanticsConfiguration childConfig,
    int placeholderIndex,
  ) {
    final Iterable<SemanticsTag>? tags = childConfig.tagsForChildren;
    if (tags == null) {
      return false;
    }
    for (final SemanticsTag tag in tags) {
      if (tag is PlaceholderSpanIndexSemanticsTag) {
        return tag.index == placeholderIndex;
      }
    }
    return false;
  }

  SemanticsConfiguration _createSemanticsConfigForTextInfo(
    InlineSpanSemanticsInformation textInfo,
    int cacheIndex,
  ) {
    assert(!textInfo.requiresOwnNode);
    final List<AttributedString> cachedStrings = _cachedAttributedLabels ??= <AttributedString>[];
    assert(cacheIndex <= cachedStrings.length);
    final bool hasCache = cacheIndex < cachedStrings.length;

    late AttributedString attributedLabel;
    if (hasCache) {
      attributedLabel = cachedStrings[cacheIndex];
    } else {
      assert(cachedStrings.length == cacheIndex);
      attributedLabel = AttributedString(
        textInfo.semanticsLabel ?? textInfo.text,
        attributes: textInfo.stringAttributes,
      );
      cachedStrings.add(attributedLabel);
    }
    return SemanticsConfiguration()
      ..textDirection = textDirection
      ..attributedLabel = attributedLabel;
  }

  // Caches [SemanticsNode]s created during [assembleSemanticsNode] so they
  // can be re-used when [assembleSemanticsNode] is called again. This ensures
  // stable ids for the [SemanticsNode]s of [TextSpan]s across
  // [assembleSemanticsNode] invocations.
  Map<Key, SemanticsNode>? _cachedChildNodes;

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    assert(_semanticsInfo != null && _semanticsInfo!.isNotEmpty);
    final newChildren = <SemanticsNode>[];
    TextDirection currentDirection = textDirection;
    Rect currentRect;
    var ordinal = 0.0;
    var start = 0;
    var placeholderIndex = 0;
    var childIndex = 0;
    RenderBox? child = firstChild;
    final newChildCache = <Key, SemanticsNode>{};
    _cachedCombinedSemanticsInfos ??= combineSemanticsInfo(_semanticsInfo!);
    for (final InlineSpanSemanticsInformation info in _cachedCombinedSemanticsInfos!) {
      final selection = TextSelection(baseOffset: start, extentOffset: start + info.text.length);
      start += info.text.length;

      if (info.isPlaceholder) {
        // A placeholder span may have 0 to multiple semantics nodes, we need
        // to annotate all of the semantics nodes belong to this span.
        while (children.length > childIndex &&
            children
                .elementAt(childIndex)
                .isTagged(PlaceholderSpanIndexSemanticsTag(placeholderIndex))) {
          final SemanticsNode childNode = children.elementAt(childIndex);
          final parentData = child!.parentData! as TextParentData;
          // parentData.scale may be null if the render object is truncated.
          if (parentData.offset != null) {
            newChildren.add(childNode);
          }
          childIndex += 1;
        }
        child = childAfter(child!);
        placeholderIndex += 1;
      } else {
        final initialDirection = currentDirection;
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
        final configuration = SemanticsConfiguration()
          ..sortKey = OrdinalSortKey(ordinal++)
          ..textDirection = initialDirection
          ..identifier = info.semanticsIdentifier ?? ''
          ..attributedLabel = AttributedString(
            info.semanticsLabel ?? info.text,
            attributes: info.stringAttributes,
          );
        switch (info.recognizer) {
          case TapGestureRecognizer(onTap: final VoidCallback? handler):
          case DoubleTapGestureRecognizer(onDoubleTap: final VoidCallback? handler):
            if (handler != null) {
              configuration.onTap = handler;
              configuration.isLink = true;
            }
          case LongPressGestureRecognizer(onLongPress: final GestureLongPressCallback? onLongPress):
            if (onLongPress != null) {
              configuration.onLongPress = onLongPress;
            }
          case null:
            break;
          default:
            assert(false, '${info.recognizer.runtimeType} is not supported.');
        }
        if (node.parentPaintClipRect != null) {
          final Rect paintRect = node.parentPaintClipRect!.intersect(currentRect);
          configuration.isHidden = paintRect.isEmpty && !currentRect.isEmpty;
        }
        final SemanticsNode newChild;
        if (_cachedChildNodes?.isNotEmpty ?? false) {
          newChild = _cachedChildNodes!.remove(_cachedChildNodes!.keys.first)!;
        } else {
          final key = UniqueKey();
          newChild = SemanticsNode(key: key, showOnScreen: _createShowOnScreenFor(key));
        }
        newChild
          ..updateWith(config: configuration)
          ..rect = currentRect;
        newChildCache[newChild.key!] = newChild;
        newChildren.add(newChild);
      }
    }
    // Makes sure we annotated all of the semantics children.
    assert(childIndex == children.length);
    assert(child == null);

    _cachedChildNodes = newChildCache;
    node.updateWith(config: config, childrenInInversePaintOrder: newChildren);
  }

  VoidCallback? _createShowOnScreenFor(Key key) {
    return () {
      final SemanticsNode node = _cachedChildNodes![key]!;
      showOnScreen(descendant: this, rect: node.rect);
    };
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _cachedChildNodes = null;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      text.toDiagnosticsNode(name: 'text', style: DiagnosticsTreeStyle.transition),
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
      EnumProperty<TextOverflowPosition>(
        'overflowPosition',
        overflowPosition,
        defaultValue: TextOverflowPosition.end,
      ),
    );
    properties.add(
      EnumProperty<TextScrollOverflow>(
        'scrollOverflow',
        scrollOverflow,
        defaultValue: TextScrollOverflow.wrap,
      ),
    );
    properties.add(
      DiagnosticsProperty<TextScaler>('textScaler', textScaler, defaultValue: TextScaler.noScaling),
    );
    properties.add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, ifNull: 'unlimited'));
    properties.add(DoubleProperty('devicePixelRatio', devicePixelRatio, defaultValue: 1.0));
  }
}

/// A continuous, selectable piece of paragraph.
///
/// Since the selections in [PlaceholderSpan] are handled independently in its
/// subtree, a selection in [RenderParagraph] can't continue across a
/// [PlaceholderSpan]. The [RenderParagraph] splits itself on [PlaceholderSpan]
/// to create multiple `_SelectableFragment`s so that they can be selected
/// separately.
class _SelectableFragment
    with Selectable, Diagnosticable, ChangeNotifier
    implements TextLayoutMetrics {
  _SelectableFragment({required this.paragraph, required this.fullText, required this.range})
    : assert(range.isValid && !range.isCollapsed && range.isNormalized) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
    _selectionGeometry = _getSelectionGeometry();
  }

  final TextRange range;
  final RenderParagraph paragraph;
  final String fullText;

  TextPosition? _textSelectionStart;
  TextPosition? _textSelectionEnd;

  bool _selectableContainsOriginTextBoundary = false;

  LayerLink? _startHandleLayerLink;
  LayerLink? _endHandleLayerLink;

  @override
  SelectionGeometry get value => _selectionGeometry;
  late SelectionGeometry _selectionGeometry;

  void _updateSelectionGeometry() {
    final SelectionGeometry newValue = _getSelectionGeometry();

    if (_selectionGeometry == newValue) {
      return;
    }
    _selectionGeometry = newValue;
    notifyListeners();
  }

  SelectionGeometry _getSelectionGeometry() {
    if (_textSelectionStart == null || _textSelectionEnd == null) {
      return const SelectionGeometry(status: SelectionStatus.none, hasContent: true);
    }

    final int selectionStart = _textSelectionStart!.offset;
    final int selectionEnd = _textSelectionEnd!.offset;
    final bool isReversed = selectionStart > selectionEnd;
    final Offset startOffsetInParagraphCoordinates = paragraph._getOffsetForPosition(
      _textSelectionStart!,
    );
    final Offset endOffsetInParagraphCoordinates = selectionStart == selectionEnd
        ? startOffsetInParagraphCoordinates
        : paragraph._getOffsetForPosition(_textSelectionEnd!);
    final flipHandles = isReversed != (TextDirection.rtl == paragraph.textDirection);
    final selection = TextSelection(baseOffset: selectionStart, extentOffset: selectionEnd);
    final selectionRects = <Rect>[];
    for (final TextBox textBox in paragraph.getBoxesForSelection(selection)) {
      selectionRects.add(textBox.toRect());
    }
    final selectionCollapsed = selectionStart == selectionEnd;
    final (
      TextSelectionHandleType startSelectionHandleType,
      TextSelectionHandleType endSelectionHandleType,
    ) = switch ((selectionCollapsed, flipHandles)) {
      // Always prefer collapsed handle when selection is collapsed.
      (true, _) => (TextSelectionHandleType.collapsed, TextSelectionHandleType.collapsed),
      (false, true) => (TextSelectionHandleType.right, TextSelectionHandleType.left),
      (false, false) => (TextSelectionHandleType.left, TextSelectionHandleType.right),
    };
    return SelectionGeometry(
      startSelectionPoint: SelectionPoint(
        localPosition: startOffsetInParagraphCoordinates,
        lineHeight: paragraph._textPainter.preferredLineHeight,
        handleType: startSelectionHandleType,
      ),
      endSelectionPoint: SelectionPoint(
        localPosition: endOffsetInParagraphCoordinates,
        lineHeight: paragraph._textPainter.preferredLineHeight,
        handleType: endSelectionHandleType,
      ),
      selectionRects: selectionRects,
      status: selectionCollapsed ? SelectionStatus.collapsed : SelectionStatus.uncollapsed,
      hasContent: true,
    );
  }

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    late final SelectionResult result;
    final TextPosition? existingSelectionStart = _textSelectionStart;
    final TextPosition? existingSelectionEnd = _textSelectionEnd;
    switch (event.type) {
      case SelectionEventType.startEdgeUpdate:
      case SelectionEventType.endEdgeUpdate:
        final edgeUpdate = event as SelectionEdgeUpdateEvent;
        final TextGranularity granularity = event.granularity;

        switch (granularity) {
          case TextGranularity.character:
            result = _updateSelectionEdge(
              edgeUpdate.globalPosition,
              isEnd: edgeUpdate.type == SelectionEventType.endEdgeUpdate,
            );
          case TextGranularity.word:
            result = _updateSelectionEdgeByTextBoundary(
              edgeUpdate.globalPosition,
              isEnd: edgeUpdate.type == SelectionEventType.endEdgeUpdate,
              getTextBoundary: _getWordBoundaryAtPosition,
            );
          case TextGranularity.paragraph:
            result = _updateSelectionEdgeByMultiSelectableTextBoundary(
              edgeUpdate.globalPosition,
              isEnd: edgeUpdate.type == SelectionEventType.endEdgeUpdate,
              getTextBoundary: _getParagraphBoundaryAtPosition,
              getClampedTextBoundary: _getClampedParagraphBoundaryAtPosition,
            );
          case TextGranularity.document:
          case TextGranularity.line:
            assert(false, 'Moving the selection edge by line or document is not supported.');
        }
      case SelectionEventType.clear:
        result = _handleClearSelection();
      case SelectionEventType.selectAll:
        result = _handleSelectAll();
      case SelectionEventType.selectWord:
        final selectWord = event as SelectWordSelectionEvent;
        result = _handleSelectWord(selectWord.globalPosition);
      case SelectionEventType.selectParagraph:
        final selectParagraph = event as SelectParagraphSelectionEvent;
        if (selectParagraph.absorb) {
          _handleSelectAll();
          result = SelectionResult.next;
          _selectableContainsOriginTextBoundary = true;
        } else {
          result = _handleSelectParagraph(selectParagraph.globalPosition);
        }
      case SelectionEventType.granularlyExtendSelection:
        final granularlyExtendSelection = event as GranularlyExtendSelectionEvent;
        result = _handleGranularlyExtendSelection(
          granularlyExtendSelection.forward,
          granularlyExtendSelection.isEnd,
          granularlyExtendSelection.granularity,
        );
      case SelectionEventType.directionallyExtendSelection:
        final directionallyExtendSelection = event as DirectionallyExtendSelectionEvent;
        result = _handleDirectionallyExtendSelection(
          directionallyExtendSelection.dx,
          directionallyExtendSelection.isEnd,
          directionallyExtendSelection.direction,
        );
    }

    if (existingSelectionStart != _textSelectionStart ||
        existingSelectionEnd != _textSelectionEnd) {
      _didChangeSelection();
    }
    return result;
  }

  @override
  SelectedContent? getSelectedContent() {
    if (_textSelectionStart == null || _textSelectionEnd == null) {
      return null;
    }
    final int start = math.min(_textSelectionStart!.offset, _textSelectionEnd!.offset);
    final int end = math.max(_textSelectionStart!.offset, _textSelectionEnd!.offset);
    return SelectedContent(plainText: fullText.substring(start, end));
  }

  @override
  SelectedContentRange? getSelection() {
    if (_textSelectionStart == null || _textSelectionEnd == null) {
      return null;
    }
    return SelectedContentRange(
      startOffset: _textSelectionStart!.offset,
      endOffset: _textSelectionEnd!.offset,
    );
  }

  void _didChangeSelection() {
    paragraph.markNeedsPaint();
    _updateSelectionGeometry();
  }

  TextPosition _updateSelectionStartEdgeByTextBoundary(
    _TextBoundaryRecord? textBoundary,
    _TextBoundaryAtPosition getTextBoundary,
    TextPosition position,
    TextPosition? existingSelectionStart,
    TextPosition? existingSelectionEnd,
  ) {
    TextPosition? targetPosition;
    if (textBoundary != null) {
      assert(
        textBoundary.boundaryStart.offset >= range.start &&
            textBoundary.boundaryEnd.offset <= range.end,
      );
      if (_selectableContainsOriginTextBoundary &&
          existingSelectionStart != null &&
          existingSelectionEnd != null) {
        final isSamePosition = position.offset == existingSelectionEnd.offset;
        final bool isSelectionInverted =
            existingSelectionStart.offset > existingSelectionEnd.offset;
        final bool shouldSwapEdges =
            !isSamePosition &&
            (isSelectionInverted != (position.offset > existingSelectionEnd.offset));
        if (shouldSwapEdges) {
          if (position.offset < existingSelectionEnd.offset) {
            targetPosition = textBoundary.boundaryStart;
          } else {
            targetPosition = textBoundary.boundaryEnd;
          }
          // When the selection is inverted by the new position it is necessary to
          // swap the start edge (moving edge) with the end edge (static edge) to
          // maintain the origin text boundary within the selection.
          final _TextBoundaryRecord localTextBoundary = getTextBoundary(existingSelectionEnd);
          assert(
            localTextBoundary.boundaryStart.offset >= range.start &&
                localTextBoundary.boundaryEnd.offset <= range.end,
          );
          _setSelectionPosition(
            existingSelectionEnd.offset == localTextBoundary.boundaryStart.offset
                ? localTextBoundary.boundaryEnd
                : localTextBoundary.boundaryStart,
            isEnd: true,
          );
        } else {
          if (position.offset < existingSelectionEnd.offset) {
            targetPosition = textBoundary.boundaryStart;
          } else if (position.offset > existingSelectionEnd.offset) {
            targetPosition = textBoundary.boundaryEnd;
          } else {
            // Keep the origin text boundary in bounds when position is at the static edge.
            targetPosition = existingSelectionStart;
          }
        }
      } else {
        if (existingSelectionEnd != null) {
          // If the end edge exists and the start edge is being moved, then the
          // start edge is moved to encompass the entire text boundary at the new position.
          if (position.offset < existingSelectionEnd.offset) {
            targetPosition = textBoundary.boundaryStart;
          } else {
            targetPosition = textBoundary.boundaryEnd;
          }
        } else {
          // Move the start edge to the closest text boundary.
          targetPosition = _closestTextBoundary(textBoundary, position);
        }
      }
    } else {
      // The position is not contained within the current rect. The targetPosition
      // will either be at the end or beginning of the current rect. See [SelectionUtils.adjustDragOffset]
      // for a more in depth explanation on this adjustment.
      if (_selectableContainsOriginTextBoundary &&
          existingSelectionStart != null &&
          existingSelectionEnd != null) {
        // When the selection is inverted by the new position it is necessary to
        // swap the start edge (moving edge) with the end edge (static edge) to
        // maintain the origin text boundary within the selection.
        final isSamePosition = position.offset == existingSelectionEnd.offset;
        final bool isSelectionInverted =
            existingSelectionStart.offset > existingSelectionEnd.offset;
        final bool shouldSwapEdges =
            !isSamePosition &&
            (isSelectionInverted != (position.offset > existingSelectionEnd.offset));

        if (shouldSwapEdges) {
          final _TextBoundaryRecord localTextBoundary = getTextBoundary(existingSelectionEnd);
          assert(
            localTextBoundary.boundaryStart.offset >= range.start &&
                localTextBoundary.boundaryEnd.offset <= range.end,
          );
          _setSelectionPosition(
            isSelectionInverted ? localTextBoundary.boundaryEnd : localTextBoundary.boundaryStart,
            isEnd: true,
          );
        }
      }
    }
    return targetPosition ?? position;
  }

  TextPosition _updateSelectionEndEdgeByTextBoundary(
    _TextBoundaryRecord? textBoundary,
    _TextBoundaryAtPosition getTextBoundary,
    TextPosition position,
    TextPosition? existingSelectionStart,
    TextPosition? existingSelectionEnd,
  ) {
    TextPosition? targetPosition;
    if (textBoundary != null) {
      assert(
        textBoundary.boundaryStart.offset >= range.start &&
            textBoundary.boundaryEnd.offset <= range.end,
      );
      if (_selectableContainsOriginTextBoundary &&
          existingSelectionStart != null &&
          existingSelectionEnd != null) {
        final isSamePosition = position.offset == existingSelectionStart.offset;
        final bool isSelectionInverted =
            existingSelectionStart.offset > existingSelectionEnd.offset;
        final bool shouldSwapEdges =
            !isSamePosition &&
            (isSelectionInverted != (position.offset < existingSelectionStart.offset));
        if (shouldSwapEdges) {
          if (position.offset < existingSelectionStart.offset) {
            targetPosition = textBoundary.boundaryStart;
          } else {
            targetPosition = textBoundary.boundaryEnd;
          }
          // When the selection is inverted by the new position it is necessary to
          // swap the end edge (moving edge) with the start edge (static edge) to
          // maintain the origin text boundary within the selection.
          final _TextBoundaryRecord localTextBoundary = getTextBoundary(existingSelectionStart);
          assert(
            localTextBoundary.boundaryStart.offset >= range.start &&
                localTextBoundary.boundaryEnd.offset <= range.end,
          );
          _setSelectionPosition(
            existingSelectionStart.offset == localTextBoundary.boundaryStart.offset
                ? localTextBoundary.boundaryEnd
                : localTextBoundary.boundaryStart,
            isEnd: false,
          );
        } else {
          if (position.offset < existingSelectionStart.offset) {
            targetPosition = textBoundary.boundaryStart;
          } else if (position.offset > existingSelectionStart.offset) {
            targetPosition = textBoundary.boundaryEnd;
          } else {
            // Keep the origin text boundary in bounds when position is at the static edge.
            targetPosition = existingSelectionEnd;
          }
        }
      } else {
        if (existingSelectionStart != null) {
          // If the start edge exists and the end edge is being moved, then the
          // end edge is moved to encompass the entire text boundary at the new position.
          if (position.offset < existingSelectionStart.offset) {
            targetPosition = textBoundary.boundaryStart;
          } else {
            targetPosition = textBoundary.boundaryEnd;
          }
        } else {
          // Move the end edge to the closest text boundary.
          targetPosition = _closestTextBoundary(textBoundary, position);
        }
      }
    } else {
      // The position is not contained within the current rect. The targetPosition
      // will either be at the end or beginning of the current rect. See [SelectionUtils.adjustDragOffset]
      // for a more in depth explanation on this adjustment.
      if (_selectableContainsOriginTextBoundary &&
          existingSelectionStart != null &&
          existingSelectionEnd != null) {
        // When the selection is inverted by the new position it is necessary to
        // swap the end edge (moving edge) with the start edge (static edge) to
        // maintain the origin text boundary within the selection.
        final isSamePosition = position.offset == existingSelectionStart.offset;
        final bool isSelectionInverted =
            existingSelectionStart.offset > existingSelectionEnd.offset;
        final bool shouldSwapEdges =
            isSelectionInverted != (position.offset < existingSelectionStart.offset) ||
            isSamePosition;
        if (shouldSwapEdges) {
          final _TextBoundaryRecord localTextBoundary = getTextBoundary(existingSelectionStart);
          assert(
            localTextBoundary.boundaryStart.offset >= range.start &&
                localTextBoundary.boundaryEnd.offset <= range.end,
          );
          _setSelectionPosition(
            isSelectionInverted ? localTextBoundary.boundaryStart : localTextBoundary.boundaryEnd,
            isEnd: false,
          );
        }
      }
    }
    return targetPosition ?? position;
  }

  SelectionResult _updateSelectionEdgeByTextBoundary(
    Offset globalPosition, {
    required bool isEnd,
    required _TextBoundaryAtPosition getTextBoundary,
  }) {
    // When the start/end edges are swapped, i.e. the start is after the end, and
    // the scrollable synthesizes an event for the opposite edge, this will potentially
    // move the opposite edge outside of the origin text boundary and we are unable to recover.
    final TextPosition? existingSelectionStart = _textSelectionStart;
    final TextPosition? existingSelectionEnd = _textSelectionEnd;

    _setSelectionPosition(null, isEnd: isEnd);
    final Matrix4 transform = paragraph.getTransformTo(null);
    transform.invert();
    final Offset localPosition = MatrixUtils.transformPoint(transform, globalPosition);
    if (_rect.isEmpty) {
      final SelectionResult result = SelectionUtils.getResultBasedOnRect(_rect, localPosition);
      _setSelectionPosition(
        result == SelectionResult.next
            ? TextPosition(offset: range.end)
            : TextPosition(offset: range.start, affinity: TextAffinity.upstream),
        isEnd: isEnd,
      );
      return result;
    }
    final Offset adjustedOffset = SelectionUtils.adjustDragOffset(
      _rect,
      localPosition,
      direction: paragraph.textDirection,
    );

    final TextPosition position = paragraph.getPositionForOffset(adjustedOffset);
    // Check if the original local position is within the rect, if it is not then
    // we do not need to look up the text boundary for that position. This is to
    // maintain a selectables selection collapsed at 0 when the local position is
    // not located inside its rect.
    _TextBoundaryRecord? textBoundary = _rect.contains(localPosition)
        ? getTextBoundary(position)
        : null;
    if (textBoundary != null &&
        (textBoundary.boundaryStart.offset < range.start &&
                textBoundary.boundaryEnd.offset <= range.start ||
            textBoundary.boundaryStart.offset >= range.end &&
                textBoundary.boundaryEnd.offset > range.end)) {
      // When the position is located at a placeholder inside of the text, then we may compute
      // a text boundary that does not belong to the current selectable fragment. In this case
      // we should invalidate the text boundary so that it is not taken into account when
      // computing the target position.
      textBoundary = null;
    }
    final TextPosition targetPosition = _clampTextPosition(
      isEnd
          ? _updateSelectionEndEdgeByTextBoundary(
              textBoundary,
              getTextBoundary,
              position,
              existingSelectionStart,
              existingSelectionEnd,
            )
          : _updateSelectionStartEdgeByTextBoundary(
              textBoundary,
              getTextBoundary,
              position,
              existingSelectionStart,
              existingSelectionEnd,
            ),
    );

    _setSelectionPosition(targetPosition, isEnd: isEnd);
    if (targetPosition.offset == range.end) {
      return SelectionResult.next;
    }

    if (targetPosition.offset == range.start) {
      return SelectionResult.previous;
    }
    // TODO(chunhtai): The geometry information should not be used to determine
    // selection result. This is a workaround to RenderParagraph, where it does
    // not have a way to get accurate text length if its text is truncated due to
    // layout constraint.
    return SelectionUtils.getResultBasedOnRect(_rect, localPosition);
  }

  SelectionResult _updateSelectionEdge(Offset globalPosition, {required bool isEnd}) {
    _setSelectionPosition(null, isEnd: isEnd);
    final Matrix4 transform = paragraph.getTransformTo(null);
    transform.invert();
    final Offset localPosition = MatrixUtils.transformPoint(transform, globalPosition);
    if (_rect.isEmpty) {
      final SelectionResult result = SelectionUtils.getResultBasedOnRect(_rect, localPosition);
      _setSelectionPosition(
        result == SelectionResult.next
            ? TextPosition(offset: range.end)
            : TextPosition(offset: range.start, affinity: TextAffinity.upstream),
        isEnd: isEnd,
      );
      return result;
    }
    final Offset adjustedOffset = SelectionUtils.adjustDragOffset(
      _rect,
      localPosition,
      direction: paragraph.textDirection,
    );

    final TextPosition position = _clampTextPosition(
      paragraph.getPositionForOffset(adjustedOffset),
    );
    _setSelectionPosition(position, isEnd: isEnd);
    if (position.offset == range.end) {
      return SelectionResult.next;
    }
    if (position.offset == range.start) {
      return SelectionResult.previous;
    }
    // TODO(chunhtai): The geometry information should not be used to determine
    // selection result. This is a workaround to RenderParagraph, where it does
    // not have a way to get accurate text length if its text is truncated due to
    // layout constraint.
    return SelectionUtils.getResultBasedOnRect(_rect, localPosition);
  }

  // This method handles updating the start edge by a text boundary that may
  // not be contained within this selectable fragment. It is possible
  // that a boundary spans multiple selectable fragments when the text contains
  // [WidgetSpan]s.
  //
  // This method differs from [_updateSelectionStartEdgeByTextBoundary] in that
  // to pivot offset used to swap selection edges and maintain the origin
  // text boundary selected may be located outside of this selectable fragment.
  //
  // See [_updateSelectionEndEdgeByMultiSelectableTextBoundary] for the method
  // that handles updating the end edge.
  SelectionResult? _updateSelectionStartEdgeByMultiSelectableTextBoundary(
    _TextBoundaryAtPositionInText getTextBoundary,
    bool paragraphContainsPosition,
    TextPosition position,
    TextPosition? existingSelectionStart,
    TextPosition? existingSelectionEnd,
  ) {
    const isEnd = false;
    if (_selectableContainsOriginTextBoundary &&
        existingSelectionStart != null &&
        existingSelectionEnd != null) {
      // If this selectable contains the origin boundary, maintain the existing
      // selection.
      final bool forwardSelection = existingSelectionEnd.offset >= existingSelectionStart.offset;
      if (paragraphContainsPosition) {
        // When the position is within the root paragraph, swap the start and end
        // edges when the selection is inverted.
        final _TextBoundaryRecord boundaryAtPosition = getTextBoundary(position, fullText);
        // To accurately retrieve the origin text boundary when the selection
        // is forward, use existingSelectionEnd.offset - 1. This is necessary
        // because in a forwards selection, existingSelectionEnd marks the end
        // of the origin text boundary. Using the unmodified offset incorrectly
        // targets the subsequent text boundary.
        final _TextBoundaryRecord originTextBoundary = getTextBoundary(
          forwardSelection
              ? TextPosition(
                  offset: existingSelectionEnd.offset - 1,
                  affinity: existingSelectionEnd.affinity,
                )
              : existingSelectionEnd,
          fullText,
        );
        final TextPosition targetPosition;
        final int pivotOffset = forwardSelection
            ? originTextBoundary.boundaryEnd.offset
            : originTextBoundary.boundaryStart.offset;
        final shouldSwapEdges = !forwardSelection != (position.offset > pivotOffset);
        if (position.offset < pivotOffset) {
          targetPosition = boundaryAtPosition.boundaryStart;
        } else if (position.offset > pivotOffset) {
          targetPosition = boundaryAtPosition.boundaryEnd;
        } else {
          // Keep the origin text boundary in bounds when position is at the static edge.
          targetPosition = forwardSelection ? existingSelectionStart : existingSelectionEnd;
        }
        if (shouldSwapEdges) {
          _setSelectionPosition(
            _clampTextPosition(
              forwardSelection ? originTextBoundary.boundaryStart : originTextBoundary.boundaryEnd,
            ),
            isEnd: true,
          );
        }
        _setSelectionPosition(_clampTextPosition(targetPosition), isEnd: isEnd);
        final bool finalSelectionIsForward =
            _textSelectionEnd!.offset >= _textSelectionStart!.offset;
        if (boundaryAtPosition.boundaryStart.offset > range.end &&
            boundaryAtPosition.boundaryEnd.offset > range.end) {
          return SelectionResult.next;
        }
        if (boundaryAtPosition.boundaryStart.offset < range.start &&
            boundaryAtPosition.boundaryEnd.offset < range.start) {
          return SelectionResult.previous;
        }
        if (finalSelectionIsForward) {
          if (boundaryAtPosition.boundaryStart.offset >= originTextBoundary.boundaryStart.offset) {
            return SelectionResult.end;
          }
          if (boundaryAtPosition.boundaryStart.offset < originTextBoundary.boundaryStart.offset) {
            return SelectionResult.previous;
          }
        } else {
          if (boundaryAtPosition.boundaryEnd.offset <= originTextBoundary.boundaryEnd.offset) {
            return SelectionResult.end;
          }
          if (boundaryAtPosition.boundaryEnd.offset > originTextBoundary.boundaryEnd.offset) {
            return SelectionResult.next;
          }
        }
      } else {
        // When the drag position is not contained within the root paragraph,
        // swap the edges when the selection changes direction.
        final TextPosition clampedPosition = _clampTextPosition(position);
        // To accurately retrieve the origin text boundary when the selection
        // is forward, use existingSelectionEnd.offset - 1. This is necessary
        // because in a forwards selection, existingSelectionEnd marks the end
        // of the origin text boundary. Using the unmodified offset incorrectly
        // targets the subsequent text boundary.
        final _TextBoundaryRecord originTextBoundary = getTextBoundary(
          forwardSelection
              ? TextPosition(
                  offset: existingSelectionEnd.offset - 1,
                  affinity: existingSelectionEnd.affinity,
                )
              : existingSelectionEnd,
          fullText,
        );
        if (forwardSelection && clampedPosition.offset == range.start) {
          _setSelectionPosition(clampedPosition, isEnd: isEnd);
          return SelectionResult.previous;
        }
        if (!forwardSelection && clampedPosition.offset == range.end) {
          _setSelectionPosition(clampedPosition, isEnd: isEnd);
          return SelectionResult.next;
        }
        if (forwardSelection && clampedPosition.offset == range.end) {
          _setSelectionPosition(_clampTextPosition(originTextBoundary.boundaryStart), isEnd: true);
          _setSelectionPosition(clampedPosition, isEnd: isEnd);
          return SelectionResult.next;
        }
        if (!forwardSelection && clampedPosition.offset == range.start) {
          _setSelectionPosition(_clampTextPosition(originTextBoundary.boundaryEnd), isEnd: true);
          _setSelectionPosition(clampedPosition, isEnd: isEnd);
          return SelectionResult.previous;
        }
      }
    } else {
      // A paragraph boundary may not be completely contained within this root
      // selectable fragment. Keep searching until we find the end of the
      // boundary. Do not search when the current drag position is on a placeholder
      // to allow traversal to reach that placeholder.
      final positionOnPlaceholder =
          paragraph.getWordBoundary(position).textInside(fullText) == _placeholderCharacter;
      if (!paragraphContainsPosition || positionOnPlaceholder) {
        return null;
      }
      if (existingSelectionEnd != null) {
        final _TextBoundaryRecord boundaryAtPosition = getTextBoundary(position, fullText);
        final bool backwardSelection =
            existingSelectionStart == null && existingSelectionEnd.offset == range.start ||
            existingSelectionStart == existingSelectionEnd &&
                existingSelectionEnd.offset == range.start ||
            existingSelectionStart != null &&
                existingSelectionStart.offset > existingSelectionEnd.offset;
        if (boundaryAtPosition.boundaryStart.offset < range.start &&
            boundaryAtPosition.boundaryEnd.offset < range.start) {
          _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
          return SelectionResult.previous;
        }
        if (boundaryAtPosition.boundaryStart.offset > range.end &&
            boundaryAtPosition.boundaryEnd.offset > range.end) {
          _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
          return SelectionResult.next;
        }
        if (backwardSelection) {
          if (boundaryAtPosition.boundaryEnd.offset <= range.end) {
            _setSelectionPosition(_clampTextPosition(boundaryAtPosition.boundaryEnd), isEnd: isEnd);
            return SelectionResult.end;
          }
          if (boundaryAtPosition.boundaryEnd.offset > range.end) {
            _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
            return SelectionResult.next;
          }
        } else {
          _setSelectionPosition(_clampTextPosition(boundaryAtPosition.boundaryStart), isEnd: isEnd);
          if (boundaryAtPosition.boundaryStart.offset < range.start) {
            return SelectionResult.previous;
          }
          if (boundaryAtPosition.boundaryStart.offset >= range.start) {
            return SelectionResult.end;
          }
        }
      }
    }
    return null;
  }

  // This method handles updating the end edge by a text boundary that may
  // not be contained within this selectable fragment. It is possible
  // that a boundary spans multiple selectable fragments when the text contains
  // [WidgetSpan]s.
  //
  // This method differs from [_updateSelectionEndEdgeByTextBoundary] in that
  // to pivot offset used to swap selection edges and maintain the origin
  // text boundary selected may be located outside of this selectable fragment.
  //
  // See [_updateSelectionStartEdgeByMultiSelectableTextBoundary] for the method
  // that handles updating the end edge.
  SelectionResult? _updateSelectionEndEdgeByMultiSelectableTextBoundary(
    _TextBoundaryAtPositionInText getTextBoundary,
    bool paragraphContainsPosition,
    TextPosition position,
    TextPosition? existingSelectionStart,
    TextPosition? existingSelectionEnd,
  ) {
    const isEnd = true;
    if (_selectableContainsOriginTextBoundary &&
        existingSelectionStart != null &&
        existingSelectionEnd != null) {
      // If this selectable contains the origin boundary, maintain the existing
      // selection.
      final bool forwardSelection = existingSelectionEnd.offset >= existingSelectionStart.offset;
      if (paragraphContainsPosition) {
        // When the position is within the root paragraph, swap the start and end
        // edges when the selection is inverted.
        final _TextBoundaryRecord boundaryAtPosition = getTextBoundary(position, fullText);
        // To accurately retrieve the origin text boundary when the selection
        // is backwards, use existingSelectionStart.offset - 1. This is necessary
        // because in a backwards selection, existingSelectionStart marks the end
        // of the origin text boundary. Using the unmodified offset incorrectly
        // targets the subsequent text boundary.
        final _TextBoundaryRecord originTextBoundary = getTextBoundary(
          forwardSelection
              ? existingSelectionStart
              : TextPosition(
                  offset: existingSelectionStart.offset - 1,
                  affinity: existingSelectionStart.affinity,
                ),
          fullText,
        );
        final TextPosition targetPosition;
        final int pivotOffset = forwardSelection
            ? originTextBoundary.boundaryStart.offset
            : originTextBoundary.boundaryEnd.offset;
        final shouldSwapEdges = !forwardSelection != (position.offset < pivotOffset);
        if (position.offset < pivotOffset) {
          targetPosition = boundaryAtPosition.boundaryStart;
        } else if (position.offset > pivotOffset) {
          targetPosition = boundaryAtPosition.boundaryEnd;
        } else {
          // Keep the origin text boundary in bounds when position is at the static edge.
          targetPosition = forwardSelection ? existingSelectionEnd : existingSelectionStart;
        }
        if (shouldSwapEdges) {
          _setSelectionPosition(
            _clampTextPosition(
              forwardSelection ? originTextBoundary.boundaryEnd : originTextBoundary.boundaryStart,
            ),
            isEnd: false,
          );
        }
        _setSelectionPosition(_clampTextPosition(targetPosition), isEnd: isEnd);
        final bool finalSelectionIsForward =
            _textSelectionEnd!.offset >= _textSelectionStart!.offset;
        if (boundaryAtPosition.boundaryStart.offset > range.end &&
            boundaryAtPosition.boundaryEnd.offset > range.end) {
          return SelectionResult.next;
        }
        if (boundaryAtPosition.boundaryStart.offset < range.start &&
            boundaryAtPosition.boundaryEnd.offset < range.start) {
          return SelectionResult.previous;
        }
        if (finalSelectionIsForward) {
          if (boundaryAtPosition.boundaryEnd.offset <= originTextBoundary.boundaryEnd.offset) {
            return SelectionResult.end;
          }
          if (boundaryAtPosition.boundaryEnd.offset > originTextBoundary.boundaryEnd.offset) {
            return SelectionResult.next;
          }
        } else {
          if (boundaryAtPosition.boundaryStart.offset >= originTextBoundary.boundaryStart.offset) {
            return SelectionResult.end;
          }
          if (boundaryAtPosition.boundaryStart.offset < originTextBoundary.boundaryStart.offset) {
            return SelectionResult.previous;
          }
        }
      } else {
        // When the drag position is not contained within the root paragraph,
        // swap the edges when the selection changes direction.
        final TextPosition clampedPosition = _clampTextPosition(position);
        // To accurately retrieve the origin text boundary when the selection
        // is backwards, use existingSelectionStart.offset - 1. This is necessary
        // because in a backwards selection, existingSelectionStart marks the end
        // of the origin text boundary. Using the unmodified offset incorrectly
        // targets the subsequent text boundary.
        final _TextBoundaryRecord originTextBoundary = getTextBoundary(
          forwardSelection
              ? existingSelectionStart
              : TextPosition(
                  offset: existingSelectionStart.offset - 1,
                  affinity: existingSelectionStart.affinity,
                ),
          fullText,
        );
        if (forwardSelection && clampedPosition.offset == range.start) {
          _setSelectionPosition(_clampTextPosition(originTextBoundary.boundaryEnd), isEnd: false);
          _setSelectionPosition(clampedPosition, isEnd: isEnd);
          return SelectionResult.previous;
        }
        if (!forwardSelection && clampedPosition.offset == range.end) {
          _setSelectionPosition(_clampTextPosition(originTextBoundary.boundaryStart), isEnd: false);
          _setSelectionPosition(clampedPosition, isEnd: isEnd);
          return SelectionResult.next;
        }
        if (forwardSelection && clampedPosition.offset == range.end) {
          _setSelectionPosition(clampedPosition, isEnd: isEnd);
          return SelectionResult.next;
        }
        if (!forwardSelection && clampedPosition.offset == range.start) {
          _setSelectionPosition(clampedPosition, isEnd: isEnd);
          return SelectionResult.previous;
        }
      }
    } else {
      // A paragraph boundary may not be completely contained within this root
      // selectable fragment. Keep searching until we find the end of the
      // boundary. Do not search when the current drag position is on a placeholder
      // to allow traversal to reach that placeholder.
      final positionOnPlaceholder =
          paragraph.getWordBoundary(position).textInside(fullText) == _placeholderCharacter;
      if (!paragraphContainsPosition || positionOnPlaceholder) {
        return null;
      }
      if (existingSelectionStart != null) {
        final _TextBoundaryRecord boundaryAtPosition = getTextBoundary(position, fullText);
        final bool backwardSelection =
            existingSelectionEnd == null && existingSelectionStart.offset == range.end ||
            existingSelectionStart == existingSelectionEnd &&
                existingSelectionStart.offset == range.end ||
            existingSelectionEnd != null &&
                existingSelectionStart.offset > existingSelectionEnd.offset;
        if (boundaryAtPosition.boundaryStart.offset < range.start &&
            boundaryAtPosition.boundaryEnd.offset < range.start) {
          _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
          return SelectionResult.previous;
        }
        if (boundaryAtPosition.boundaryStart.offset > range.end &&
            boundaryAtPosition.boundaryEnd.offset > range.end) {
          _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
          return SelectionResult.next;
        }
        if (backwardSelection) {
          _setSelectionPosition(_clampTextPosition(boundaryAtPosition.boundaryStart), isEnd: isEnd);
          if (boundaryAtPosition.boundaryStart.offset < range.start) {
            return SelectionResult.previous;
          }
          if (boundaryAtPosition.boundaryStart.offset >= range.start) {
            return SelectionResult.end;
          }
        } else {
          if (boundaryAtPosition.boundaryEnd.offset <= range.end) {
            _setSelectionPosition(_clampTextPosition(boundaryAtPosition.boundaryEnd), isEnd: isEnd);
            return SelectionResult.end;
          }
          if (boundaryAtPosition.boundaryEnd.offset > range.end) {
            _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
            return SelectionResult.next;
          }
        }
      }
    }
    return null;
  }

  // The placeholder character used by [RenderParagraph].
  static final String _placeholderCharacter = String.fromCharCode(
    PlaceholderSpan.placeholderCodeUnit,
  );
  static final int _placeholderLength = _placeholderCharacter.length;

  // This method handles updating the start edge by a text boundary that may
  // not be contained within this selectable fragment. It is possible
  // that a boundary spans multiple selectable fragments when the text contains
  // [WidgetSpan]s.
  //
  // This method differs from [_updateSelectionStartEdgeByMultiSelectableBoundary]
  // in that to maintain the origin text boundary selected at a placeholder,
  // this selectable fragment must be aware of the [RenderParagraph] that closely
  // encompasses the complete origin text boundary.
  //
  // See [_updateSelectionEndEdgeAtPlaceholderByMultiSelectableTextBoundary] for the method
  // that handles updating the end edge.
  SelectionResult? _updateSelectionStartEdgeAtPlaceholderByMultiSelectableTextBoundary(
    _TextBoundaryAtPositionInText getTextBoundary,
    Offset globalPosition,
    bool paragraphContainsPosition,
    TextPosition position,
    TextPosition? existingSelectionStart,
    TextPosition? existingSelectionEnd,
  ) {
    const isEnd = false;
    if (_selectableContainsOriginTextBoundary &&
        existingSelectionStart != null &&
        existingSelectionEnd != null) {
      // If this selectable contains the origin boundary, maintain the existing
      // selection.
      final bool forwardSelection = existingSelectionEnd.offset >= existingSelectionStart.offset;
      final RenderParagraph originParagraph = _getOriginParagraph();
      final fragmentBelongsToOriginParagraph = originParagraph == paragraph;
      if (fragmentBelongsToOriginParagraph) {
        return _updateSelectionStartEdgeByMultiSelectableTextBoundary(
          getTextBoundary,
          paragraphContainsPosition,
          position,
          existingSelectionStart,
          existingSelectionEnd,
        );
      }
      final Matrix4 originTransform = originParagraph.getTransformTo(null);
      originTransform.invert();
      final Offset originParagraphLocalPosition = MatrixUtils.transformPoint(
        originTransform,
        globalPosition,
      );
      final bool positionWithinOriginParagraph = originParagraph.paintBounds.contains(
        originParagraphLocalPosition,
      );
      final TextPosition positionRelativeToOriginParagraph = originParagraph.getPositionForOffset(
        originParagraphLocalPosition,
      );
      if (positionWithinOriginParagraph) {
        // When the selection is inverted by the new position it is necessary to
        // swap the start edge (moving edge) with the end edge (static edge) to
        // maintain the origin text boundary within the selection.
        final String originText = originParagraph.text.toPlainText(includeSemanticsLabels: false);
        final _TextBoundaryRecord boundaryAtPosition = getTextBoundary(
          positionRelativeToOriginParagraph,
          originText,
        );
        final _TextBoundaryRecord originTextBoundary = getTextBoundary(
          _getPositionInParagraph(originParagraph),
          originText,
        );
        final TextPosition targetPosition;
        final int pivotOffset = forwardSelection
            ? originTextBoundary.boundaryEnd.offset
            : originTextBoundary.boundaryStart.offset;
        final shouldSwapEdges =
            !forwardSelection != (positionRelativeToOriginParagraph.offset > pivotOffset);
        if (positionRelativeToOriginParagraph.offset < pivotOffset) {
          targetPosition = boundaryAtPosition.boundaryStart;
        } else if (positionRelativeToOriginParagraph.offset > pivotOffset) {
          targetPosition = boundaryAtPosition.boundaryEnd;
        } else {
          // Keep the origin text boundary in bounds when position is at the static edge.
          targetPosition = existingSelectionStart;
        }
        if (shouldSwapEdges) {
          _setSelectionPosition(existingSelectionStart, isEnd: true);
        }
        _setSelectionPosition(_clampTextPosition(targetPosition), isEnd: isEnd);
        final bool finalSelectionIsForward =
            _textSelectionEnd!.offset >= _textSelectionStart!.offset;
        final TextPosition originParagraphPlaceholderTextPosition = _getPositionInParagraph(
          originParagraph,
        );
        final originParagraphPlaceholderRange = TextRange(
          start: originParagraphPlaceholderTextPosition.offset,
          end: originParagraphPlaceholderTextPosition.offset + _placeholderLength,
        );
        if (boundaryAtPosition.boundaryStart.offset > originParagraphPlaceholderRange.end &&
            boundaryAtPosition.boundaryEnd.offset > originParagraphPlaceholderRange.end) {
          return SelectionResult.next;
        }
        if (boundaryAtPosition.boundaryStart.offset < originParagraphPlaceholderRange.start &&
            boundaryAtPosition.boundaryEnd.offset < originParagraphPlaceholderRange.start) {
          return SelectionResult.previous;
        }
        if (finalSelectionIsForward) {
          if (boundaryAtPosition.boundaryEnd.offset <= originTextBoundary.boundaryEnd.offset) {
            return SelectionResult.end;
          }
          if (boundaryAtPosition.boundaryEnd.offset > originTextBoundary.boundaryEnd.offset) {
            return SelectionResult.next;
          }
        } else {
          if (boundaryAtPosition.boundaryStart.offset >= originTextBoundary.boundaryStart.offset) {
            return SelectionResult.end;
          }
          if (boundaryAtPosition.boundaryStart.offset < originTextBoundary.boundaryStart.offset) {
            return SelectionResult.previous;
          }
        }
      } else {
        // When the drag position is not contained within the origin paragraph,
        // swap the edges when the selection changes direction.
        //
        // [SelectionUtils.adjustDragOffset] will adjust the given [Offset] to the
        // beginning or end of the provided [Rect] based on whether the [Offset]
        // is located within the given [Rect].
        final Offset adjustedOffset = SelectionUtils.adjustDragOffset(
          originParagraph.paintBounds,
          originParagraphLocalPosition,
          direction: paragraph.textDirection,
        );
        final TextPosition adjustedPositionRelativeToOriginParagraph = originParagraph
            .getPositionForOffset(adjustedOffset);
        final TextPosition originParagraphPlaceholderTextPosition = _getPositionInParagraph(
          originParagraph,
        );
        final originParagraphPlaceholderRange = TextRange(
          start: originParagraphPlaceholderTextPosition.offset,
          end: originParagraphPlaceholderTextPosition.offset + _placeholderLength,
        );
        if (forwardSelection &&
            adjustedPositionRelativeToOriginParagraph.offset <=
                originParagraphPlaceholderRange.start) {
          _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
          return SelectionResult.previous;
        }
        if (!forwardSelection &&
            adjustedPositionRelativeToOriginParagraph.offset >=
                originParagraphPlaceholderRange.end) {
          _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
          return SelectionResult.next;
        }
        if (forwardSelection &&
            adjustedPositionRelativeToOriginParagraph.offset >=
                originParagraphPlaceholderRange.end) {
          _setSelectionPosition(existingSelectionStart, isEnd: true);
          _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
          return SelectionResult.next;
        }
        if (!forwardSelection &&
            adjustedPositionRelativeToOriginParagraph.offset <=
                originParagraphPlaceholderRange.start) {
          _setSelectionPosition(existingSelectionStart, isEnd: true);
          _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
          return SelectionResult.previous;
        }
      }
    } else {
      // When the drag position is somewhere on the root text and not a placeholder,
      // traverse the selectable fragments relative to the [RenderParagraph] that
      // contains the drag position.
      if (paragraphContainsPosition) {
        return _updateSelectionStartEdgeByMultiSelectableTextBoundary(
          getTextBoundary,
          paragraphContainsPosition,
          position,
          existingSelectionStart,
          existingSelectionEnd,
        );
      }
      if (existingSelectionEnd != null) {
        final ({RenderParagraph paragraph, Offset localPosition})? targetDetails =
            _getParagraphContainingPosition(globalPosition);
        if (targetDetails == null) {
          return null;
        }
        final RenderParagraph targetParagraph = targetDetails.paragraph;
        final TextPosition positionRelativeToTargetParagraph = targetParagraph.getPositionForOffset(
          targetDetails.localPosition,
        );
        final String targetText = targetParagraph.text.toPlainText(includeSemanticsLabels: false);
        final positionOnPlaceholder =
            targetParagraph
                .getWordBoundary(positionRelativeToTargetParagraph)
                .textInside(targetText) ==
            _placeholderCharacter;
        if (positionOnPlaceholder) {
          return null;
        }
        final bool backwardSelection =
            existingSelectionStart == null && existingSelectionEnd.offset == range.start ||
            existingSelectionStart == existingSelectionEnd &&
                existingSelectionEnd.offset == range.start ||
            existingSelectionStart != null &&
                existingSelectionStart.offset > existingSelectionEnd.offset;
        final _TextBoundaryRecord boundaryAtPositionRelativeToTargetParagraph = getTextBoundary(
          positionRelativeToTargetParagraph,
          targetText,
        );
        final TextPosition targetParagraphPlaceholderTextPosition = _getPositionInParagraph(
          targetParagraph,
        );
        final targetParagraphPlaceholderRange = TextRange(
          start: targetParagraphPlaceholderTextPosition.offset,
          end: targetParagraphPlaceholderTextPosition.offset + _placeholderLength,
        );
        if (boundaryAtPositionRelativeToTargetParagraph.boundaryStart.offset <
                targetParagraphPlaceholderRange.start &&
            boundaryAtPositionRelativeToTargetParagraph.boundaryEnd.offset <
                targetParagraphPlaceholderRange.start) {
          _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
          return SelectionResult.previous;
        }
        if (boundaryAtPositionRelativeToTargetParagraph.boundaryStart.offset >
                targetParagraphPlaceholderRange.end &&
            boundaryAtPositionRelativeToTargetParagraph.boundaryEnd.offset >
                targetParagraphPlaceholderRange.end) {
          _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
          return SelectionResult.next;
        }
        if (backwardSelection) {
          if (boundaryAtPositionRelativeToTargetParagraph.boundaryEnd.offset <=
              targetParagraphPlaceholderRange.end) {
            _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
            return SelectionResult.end;
          }
          if (boundaryAtPositionRelativeToTargetParagraph.boundaryEnd.offset >
              targetParagraphPlaceholderRange.end) {
            _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
            return SelectionResult.next;
          }
        } else {
          if (boundaryAtPositionRelativeToTargetParagraph.boundaryStart.offset >=
              targetParagraphPlaceholderRange.start) {
            _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
            return SelectionResult.end;
          }
          if (boundaryAtPositionRelativeToTargetParagraph.boundaryStart.offset <
              targetParagraphPlaceholderRange.start) {
            _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
            return SelectionResult.previous;
          }
        }
      }
    }
    return null;
  }

  // This method handles updating the end edge by a text boundary that may
  // not be contained within this selectable fragment. It is possible
  // that a boundary spans multiple selectable fragments when the text contains
  // [WidgetSpan]s.
  //
  // This method differs from [_updateSelectionEndEdgeByMultiSelectableBoundary]
  // in that to maintain the origin text boundary selected at a placeholder, this
  // selectable fragment must be aware of the [RenderParagraph] that closely
  // encompasses the complete origin text boundary.
  //
  // See [_updateSelectionStartEdgeAtPlaceholderByMultiSelectableTextBoundary]
  // for the method that handles updating the start edge.
  SelectionResult? _updateSelectionEndEdgeAtPlaceholderByMultiSelectableTextBoundary(
    _TextBoundaryAtPositionInText getTextBoundary,
    Offset globalPosition,
    bool paragraphContainsPosition,
    TextPosition position,
    TextPosition? existingSelectionStart,
    TextPosition? existingSelectionEnd,
  ) {
    const isEnd = true;
    if (_selectableContainsOriginTextBoundary &&
        existingSelectionStart != null &&
        existingSelectionEnd != null) {
      // If this selectable contains the origin boundary, maintain the existing
      // selection.
      final bool forwardSelection = existingSelectionEnd.offset >= existingSelectionStart.offset;
      final RenderParagraph originParagraph = _getOriginParagraph();
      final fragmentBelongsToOriginParagraph = originParagraph == paragraph;
      if (fragmentBelongsToOriginParagraph) {
        return _updateSelectionEndEdgeByMultiSelectableTextBoundary(
          getTextBoundary,
          paragraphContainsPosition,
          position,
          existingSelectionStart,
          existingSelectionEnd,
        );
      }
      final Matrix4 originTransform = originParagraph.getTransformTo(null);
      originTransform.invert();
      final Offset originParagraphLocalPosition = MatrixUtils.transformPoint(
        originTransform,
        globalPosition,
      );
      final bool positionWithinOriginParagraph = originParagraph.paintBounds.contains(
        originParagraphLocalPosition,
      );
      final TextPosition positionRelativeToOriginParagraph = originParagraph.getPositionForOffset(
        originParagraphLocalPosition,
      );
      if (positionWithinOriginParagraph) {
        // When the selection is inverted by the new position it is necessary to
        // swap the end edge (moving edge) with the start edge (static edge) to
        // maintain the origin text boundary within the selection.
        final String originText = originParagraph.text.toPlainText(includeSemanticsLabels: false);
        final _TextBoundaryRecord boundaryAtPosition = getTextBoundary(
          positionRelativeToOriginParagraph,
          originText,
        );
        final _TextBoundaryRecord originTextBoundary = getTextBoundary(
          _getPositionInParagraph(originParagraph),
          originText,
        );
        final TextPosition targetPosition;
        final int pivotOffset = forwardSelection
            ? originTextBoundary.boundaryStart.offset
            : originTextBoundary.boundaryEnd.offset;
        final shouldSwapEdges =
            !forwardSelection != (positionRelativeToOriginParagraph.offset < pivotOffset);
        if (positionRelativeToOriginParagraph.offset < pivotOffset) {
          targetPosition = boundaryAtPosition.boundaryStart;
        } else if (positionRelativeToOriginParagraph.offset > pivotOffset) {
          targetPosition = boundaryAtPosition.boundaryEnd;
        } else {
          // Keep the origin text boundary in bounds when position is at the static edge.
          targetPosition = existingSelectionEnd;
        }
        if (shouldSwapEdges) {
          _setSelectionPosition(existingSelectionEnd, isEnd: false);
        }
        _setSelectionPosition(_clampTextPosition(targetPosition), isEnd: isEnd);
        final bool finalSelectionIsForward =
            _textSelectionEnd!.offset >= _textSelectionStart!.offset;
        final TextPosition originParagraphPlaceholderTextPosition = _getPositionInParagraph(
          originParagraph,
        );
        final originParagraphPlaceholderRange = TextRange(
          start: originParagraphPlaceholderTextPosition.offset,
          end: originParagraphPlaceholderTextPosition.offset + _placeholderLength,
        );
        if (boundaryAtPosition.boundaryStart.offset > originParagraphPlaceholderRange.end &&
            boundaryAtPosition.boundaryEnd.offset > originParagraphPlaceholderRange.end) {
          return SelectionResult.next;
        }
        if (boundaryAtPosition.boundaryStart.offset < originParagraphPlaceholderRange.start &&
            boundaryAtPosition.boundaryEnd.offset < originParagraphPlaceholderRange.start) {
          return SelectionResult.previous;
        }
        if (finalSelectionIsForward) {
          if (boundaryAtPosition.boundaryEnd.offset <= originTextBoundary.boundaryEnd.offset) {
            return SelectionResult.end;
          }
          if (boundaryAtPosition.boundaryEnd.offset > originTextBoundary.boundaryEnd.offset) {
            return SelectionResult.next;
          }
        } else {
          if (boundaryAtPosition.boundaryStart.offset >= originTextBoundary.boundaryStart.offset) {
            return SelectionResult.end;
          }
          if (boundaryAtPosition.boundaryStart.offset < originTextBoundary.boundaryStart.offset) {
            return SelectionResult.previous;
          }
        }
      } else {
        // When the drag position is not contained within the origin paragraph,
        // swap the edges when the selection changes direction.
        //
        // [SelectionUtils.adjustDragOffset] will adjust the given [Offset] to the
        // beginning or end of the provided [Rect] based on whether the [Offset]
        // is located within the given [Rect].
        final Offset adjustedOffset = SelectionUtils.adjustDragOffset(
          originParagraph.paintBounds,
          originParagraphLocalPosition,
          direction: paragraph.textDirection,
        );
        final TextPosition adjustedPositionRelativeToOriginParagraph = originParagraph
            .getPositionForOffset(adjustedOffset);
        final TextPosition originParagraphPlaceholderTextPosition = _getPositionInParagraph(
          originParagraph,
        );
        final originParagraphPlaceholderRange = TextRange(
          start: originParagraphPlaceholderTextPosition.offset,
          end: originParagraphPlaceholderTextPosition.offset + _placeholderLength,
        );
        if (forwardSelection &&
            adjustedPositionRelativeToOriginParagraph.offset <=
                originParagraphPlaceholderRange.start) {
          _setSelectionPosition(existingSelectionEnd, isEnd: false);
          _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
          return SelectionResult.previous;
        }
        if (!forwardSelection &&
            adjustedPositionRelativeToOriginParagraph.offset >=
                originParagraphPlaceholderRange.end) {
          _setSelectionPosition(existingSelectionEnd, isEnd: false);
          _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
          return SelectionResult.next;
        }
        if (forwardSelection &&
            adjustedPositionRelativeToOriginParagraph.offset >=
                originParagraphPlaceholderRange.end) {
          _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
          return SelectionResult.next;
        }
        if (!forwardSelection &&
            adjustedPositionRelativeToOriginParagraph.offset <=
                originParagraphPlaceholderRange.start) {
          _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
          return SelectionResult.previous;
        }
      }
    } else {
      // When the drag position is somewhere on the root text and not a placeholder,
      // traverse the selectable fragments relative to the [RenderParagraph] that
      // contains the drag position.
      if (paragraphContainsPosition) {
        return _updateSelectionEndEdgeByMultiSelectableTextBoundary(
          getTextBoundary,
          paragraphContainsPosition,
          position,
          existingSelectionStart,
          existingSelectionEnd,
        );
      }
      if (existingSelectionStart != null) {
        final ({RenderParagraph paragraph, Offset localPosition})? targetDetails =
            _getParagraphContainingPosition(globalPosition);
        if (targetDetails == null) {
          return null;
        }
        final RenderParagraph targetParagraph = targetDetails.paragraph;
        final TextPosition positionRelativeToTargetParagraph = targetParagraph.getPositionForOffset(
          targetDetails.localPosition,
        );
        final String targetText = targetParagraph.text.toPlainText(includeSemanticsLabels: false);
        final positionOnPlaceholder =
            targetParagraph
                .getWordBoundary(positionRelativeToTargetParagraph)
                .textInside(targetText) ==
            _placeholderCharacter;
        if (positionOnPlaceholder) {
          return null;
        }
        final bool backwardSelection =
            existingSelectionEnd == null && existingSelectionStart.offset == range.end ||
            existingSelectionStart == existingSelectionEnd &&
                existingSelectionStart.offset == range.end ||
            existingSelectionEnd != null &&
                existingSelectionStart.offset > existingSelectionEnd.offset;
        final _TextBoundaryRecord boundaryAtPositionRelativeToTargetParagraph = getTextBoundary(
          positionRelativeToTargetParagraph,
          targetText,
        );
        final TextPosition targetParagraphPlaceholderTextPosition = _getPositionInParagraph(
          targetParagraph,
        );
        final targetParagraphPlaceholderRange = TextRange(
          start: targetParagraphPlaceholderTextPosition.offset,
          end: targetParagraphPlaceholderTextPosition.offset + _placeholderLength,
        );
        if (boundaryAtPositionRelativeToTargetParagraph.boundaryStart.offset <
                targetParagraphPlaceholderRange.start &&
            boundaryAtPositionRelativeToTargetParagraph.boundaryEnd.offset <
                targetParagraphPlaceholderRange.start) {
          _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
          return SelectionResult.previous;
        }
        if (boundaryAtPositionRelativeToTargetParagraph.boundaryStart.offset >
                targetParagraphPlaceholderRange.end &&
            boundaryAtPositionRelativeToTargetParagraph.boundaryEnd.offset >
                targetParagraphPlaceholderRange.end) {
          _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
          return SelectionResult.next;
        }
        if (backwardSelection) {
          if (boundaryAtPositionRelativeToTargetParagraph.boundaryStart.offset >=
              targetParagraphPlaceholderRange.start) {
            _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
            return SelectionResult.end;
          }
          if (boundaryAtPositionRelativeToTargetParagraph.boundaryStart.offset <
              targetParagraphPlaceholderRange.start) {
            _setSelectionPosition(TextPosition(offset: range.start), isEnd: isEnd);
            return SelectionResult.previous;
          }
        } else {
          if (boundaryAtPositionRelativeToTargetParagraph.boundaryEnd.offset <=
              targetParagraphPlaceholderRange.end) {
            _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
            return SelectionResult.end;
          }
          if (boundaryAtPositionRelativeToTargetParagraph.boundaryEnd.offset >
              targetParagraphPlaceholderRange.end) {
            _setSelectionPosition(TextPosition(offset: range.end), isEnd: isEnd);
            return SelectionResult.next;
          }
        }
      }
    }
    return null;
  }

  SelectionResult _updateSelectionEdgeByMultiSelectableTextBoundary(
    Offset globalPosition, {
    required bool isEnd,
    required _TextBoundaryAtPositionInText getTextBoundary,
    required _TextBoundaryAtPosition getClampedTextBoundary,
  }) {
    // When the start/end edges are swapped, i.e. the start is after the end, and
    // the scrollable synthesizes an event for the opposite edge, this will potentially
    // move the opposite edge outside of the origin text boundary and we are unable to recover.
    final TextPosition? existingSelectionStart = _textSelectionStart;
    final TextPosition? existingSelectionEnd = _textSelectionEnd;

    _setSelectionPosition(null, isEnd: isEnd);
    final Matrix4 transform = paragraph.getTransformTo(null);
    transform.invert();
    final Offset localPosition = MatrixUtils.transformPoint(transform, globalPosition);
    if (_rect.isEmpty) {
      final SelectionResult result = SelectionUtils.getResultBasedOnRect(_rect, localPosition);
      _setSelectionPosition(
        result == SelectionResult.next
            ? TextPosition(offset: range.end)
            : TextPosition(offset: range.start, affinity: TextAffinity.upstream),
        isEnd: isEnd,
      );
      return result;
    }
    final Offset adjustedOffset = SelectionUtils.adjustDragOffset(
      _rect,
      localPosition,
      direction: paragraph.textDirection,
    );
    final Offset adjustedOffsetRelativeToParagraph = SelectionUtils.adjustDragOffset(
      paragraph.paintBounds,
      localPosition,
      direction: paragraph.textDirection,
    );

    final TextPosition position = paragraph.getPositionForOffset(adjustedOffset);
    final TextPosition positionInFullText = paragraph.getPositionForOffset(
      adjustedOffsetRelativeToParagraph,
    );

    final SelectionResult? result;
    if (_isPlaceholder()) {
      result = isEnd
          ? _updateSelectionEndEdgeAtPlaceholderByMultiSelectableTextBoundary(
              getTextBoundary,
              globalPosition,
              paragraph.paintBounds.contains(localPosition),
              positionInFullText,
              existingSelectionStart,
              existingSelectionEnd,
            )
          : _updateSelectionStartEdgeAtPlaceholderByMultiSelectableTextBoundary(
              getTextBoundary,
              globalPosition,
              paragraph.paintBounds.contains(localPosition),
              positionInFullText,
              existingSelectionStart,
              existingSelectionEnd,
            );
    } else {
      result = isEnd
          ? _updateSelectionEndEdgeByMultiSelectableTextBoundary(
              getTextBoundary,
              paragraph.paintBounds.contains(localPosition),
              positionInFullText,
              existingSelectionStart,
              existingSelectionEnd,
            )
          : _updateSelectionStartEdgeByMultiSelectableTextBoundary(
              getTextBoundary,
              paragraph.paintBounds.contains(localPosition),
              positionInFullText,
              existingSelectionStart,
              existingSelectionEnd,
            );
    }
    if (result != null) {
      return result;
    }

    // Check if the original local position is within the rect, if it is not then
    // we do not need to look up the text boundary for that position. This is to
    // maintain a selectables selection collapsed at 0 when the local position is
    // not located inside its rect.
    _TextBoundaryRecord? textBoundary = _boundingBoxesContains(localPosition)
        ? getClampedTextBoundary(position)
        : null;
    if (textBoundary != null &&
        (textBoundary.boundaryStart.offset < range.start &&
                textBoundary.boundaryEnd.offset <= range.start ||
            textBoundary.boundaryStart.offset >= range.end &&
                textBoundary.boundaryEnd.offset > range.end)) {
      // When the position is located at a placeholder inside of the text, then we may compute
      // a text boundary that does not belong to the current selectable fragment. In this case
      // we should invalidate the text boundary so that it is not taken into account when
      // computing the target position.
      textBoundary = null;
    }
    final TextPosition targetPosition = _clampTextPosition(
      isEnd
          ? _updateSelectionEndEdgeByTextBoundary(
              textBoundary,
              getClampedTextBoundary,
              position,
              existingSelectionStart,
              existingSelectionEnd,
            )
          : _updateSelectionStartEdgeByTextBoundary(
              textBoundary,
              getClampedTextBoundary,
              position,
              existingSelectionStart,
              existingSelectionEnd,
            ),
    );

    _setSelectionPosition(targetPosition, isEnd: isEnd);
    if (targetPosition.offset == range.end) {
      return SelectionResult.next;
    }

    if (targetPosition.offset == range.start) {
      return SelectionResult.previous;
    }
    // TODO(chunhtai): The geometry information should not be used to determine
    // selection result. This is a workaround to RenderParagraph, where it does
    // not have a way to get accurate text length if its text is truncated due to
    // layout constraint.
    return SelectionUtils.getResultBasedOnRect(_rect, localPosition);
  }

  TextPosition _closestTextBoundary(_TextBoundaryRecord textBoundary, TextPosition position) {
    final int differenceA = (position.offset - textBoundary.boundaryStart.offset).abs();
    final int differenceB = (position.offset - textBoundary.boundaryEnd.offset).abs();
    return differenceA < differenceB ? textBoundary.boundaryStart : textBoundary.boundaryEnd;
  }

  bool _isPlaceholder() {
    // Determine whether this selectable fragment is a placeholder.
    RenderObject? current = paragraph.parent;
    while (current != null) {
      if (current is RenderParagraph) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  RenderParagraph _getOriginParagraph() {
    // This method should only be called from a fragment that contains
    // the origin boundary. By traversing up the RenderTree, determine the
    // highest RenderParagraph that contains the origin text boundary.
    assert(_selectableContainsOriginTextBoundary);
    // Begin at the parent because it is guaranteed the paragraph containing
    // this selectable fragment contains the origin boundary.
    RenderObject? current = paragraph.parent;
    RenderParagraph? originParagraph;
    while (current != null) {
      if (current is RenderParagraph) {
        if (current._lastSelectableFragments != null) {
          var paragraphContainsOriginTextBoundary = false;
          for (final _SelectableFragment fragment in current._lastSelectableFragments!) {
            if (fragment._selectableContainsOriginTextBoundary) {
              paragraphContainsOriginTextBoundary = true;
              originParagraph = current;
              break;
            }
          }
          if (!paragraphContainsOriginTextBoundary) {
            return originParagraph ?? paragraph;
          }
        }
      }
      current = current.parent;
    }
    return originParagraph ?? paragraph;
  }

  ({RenderParagraph paragraph, Offset localPosition})? _getParagraphContainingPosition(
    Offset globalPosition,
  ) {
    // This method will return the closest [RenderParagraph] whose rect
    // contains the given `globalPosition` and the given `globalPosition`
    // relative to that [RenderParagraph]. If no ancestor [RenderParagraph]
    // contains the given `globalPosition` then this method will return null.
    RenderObject? current = paragraph;
    while (current != null) {
      if (current is RenderParagraph) {
        final Matrix4 currentTransform = current.getTransformTo(null);
        currentTransform.invert();
        final Offset currentParagraphLocalPosition = MatrixUtils.transformPoint(
          currentTransform,
          globalPosition,
        );
        final bool positionWithinCurrentParagraph = current.paintBounds.contains(
          currentParagraphLocalPosition,
        );
        if (positionWithinCurrentParagraph) {
          return (paragraph: current, localPosition: currentParagraphLocalPosition);
        }
      }
      current = current.parent;
    }
    return null;
  }

  bool _boundingBoxesContains(Offset position) {
    for (final Rect rect in boundingBoxes) {
      if (rect.contains(position)) {
        return true;
      }
    }
    return false;
  }

  TextPosition _clampTextPosition(TextPosition position) {
    // Affinity of range.end is upstream.
    if (position.offset > range.end ||
        (position.offset == range.end && position.affinity == TextAffinity.downstream)) {
      return TextPosition(offset: range.end, affinity: TextAffinity.upstream);
    }
    if (position.offset < range.start) {
      return TextPosition(offset: range.start);
    }
    return position;
  }

  void _setSelectionPosition(TextPosition? position, {required bool isEnd}) {
    if (isEnd) {
      _textSelectionEnd = position;
    } else {
      _textSelectionStart = position;
    }
  }

  SelectionResult _handleClearSelection() {
    _textSelectionStart = null;
    _textSelectionEnd = null;
    _selectableContainsOriginTextBoundary = false;
    return SelectionResult.none;
  }

  SelectionResult _handleSelectAll() {
    _textSelectionStart = TextPosition(offset: range.start);
    _textSelectionEnd = TextPosition(offset: range.end, affinity: TextAffinity.upstream);
    return SelectionResult.none;
  }

  SelectionResult _handleSelectTextBoundary(_TextBoundaryRecord textBoundary) {
    // This fragment may not contain the boundary, decide what direction the target
    // fragment is located in. Because fragments are separated by placeholder
    // spans, we also check if the beginning or end of the boundary is touching
    // either edge of this fragment.
    if (textBoundary.boundaryStart.offset < range.start &&
        textBoundary.boundaryEnd.offset <= range.start) {
      return SelectionResult.previous;
    } else if (textBoundary.boundaryStart.offset >= range.end &&
        textBoundary.boundaryEnd.offset > range.end) {
      return SelectionResult.next;
    }
    // Fragments are separated by placeholder span, the text boundary shouldn't
    // expand across fragments.
    assert(
      textBoundary.boundaryStart.offset >= range.start &&
          textBoundary.boundaryEnd.offset <= range.end,
    );
    _textSelectionStart = textBoundary.boundaryStart;
    _textSelectionEnd = textBoundary.boundaryEnd;
    _selectableContainsOriginTextBoundary = true;
    return SelectionResult.end;
  }

  TextRange? _intersect(TextRange a, TextRange b) {
    assert(a.isNormalized);
    assert(b.isNormalized);
    final int startMax = math.max(a.start, b.start);
    final int endMin = math.min(a.end, b.end);
    if (startMax <= endMin) {
      // Intersection.
      return TextRange(start: startMax, end: endMin);
    }
    return null;
  }

  SelectionResult _handleSelectMultiFragmentTextBoundary(_TextBoundaryRecord textBoundary) {
    // This fragment may not contain the boundary, decide what direction the target
    // fragment is located in. Because fragments are separated by placeholder
    // spans, we also check if the beginning or end of the boundary is touching
    // either edge of this fragment.
    if (textBoundary.boundaryStart.offset < range.start &&
        textBoundary.boundaryEnd.offset <= range.start) {
      return SelectionResult.previous;
    } else if (textBoundary.boundaryStart.offset >= range.end &&
        textBoundary.boundaryEnd.offset > range.end) {
      return SelectionResult.next;
    }
    final boundaryAsRange = TextRange(
      start: textBoundary.boundaryStart.offset,
      end: textBoundary.boundaryEnd.offset,
    );
    final TextRange? intersectRange = _intersect(range, boundaryAsRange);
    if (intersectRange != null) {
      _textSelectionStart = TextPosition(offset: intersectRange.start);
      _textSelectionEnd = TextPosition(offset: intersectRange.end);
      _selectableContainsOriginTextBoundary = true;
      if (range.end < textBoundary.boundaryEnd.offset) {
        return SelectionResult.next;
      }
      return SelectionResult.end;
    }
    return SelectionResult.none;
  }

  _TextBoundaryRecord _adjustTextBoundaryAtPosition(TextRange textBoundary, TextPosition position) {
    late final TextPosition start;
    late final TextPosition end;
    if (position.offset > textBoundary.end) {
      start = end = TextPosition(offset: position.offset);
    } else {
      start = TextPosition(offset: textBoundary.start);
      end = TextPosition(offset: textBoundary.end, affinity: TextAffinity.upstream);
    }
    return (boundaryStart: start, boundaryEnd: end);
  }

  SelectionResult _handleSelectWord(Offset globalPosition) {
    final TextPosition position = paragraph.getPositionForOffset(
      paragraph.globalToLocal(globalPosition),
    );
    if (_positionIsWithinCurrentSelection(position) && _textSelectionStart != _textSelectionEnd) {
      return SelectionResult.end;
    }
    final _TextBoundaryRecord wordBoundary = _getWordBoundaryAtPosition(position);
    return _handleSelectTextBoundary(wordBoundary);
  }

  _TextBoundaryRecord _getWordBoundaryAtPosition(TextPosition position) {
    final TextRange word = paragraph.getWordBoundary(position);
    assert(word.isNormalized);
    return _adjustTextBoundaryAtPosition(word, position);
  }

  SelectionResult _handleSelectParagraph(Offset globalPosition) {
    final Offset localPosition = paragraph.globalToLocal(globalPosition);
    final TextPosition position = paragraph.getPositionForOffset(localPosition);
    final _TextBoundaryRecord paragraphBoundary = _getParagraphBoundaryAtPosition(
      position,
      fullText,
    );
    return _handleSelectMultiFragmentTextBoundary(paragraphBoundary);
  }

  TextPosition _getPositionInParagraph(RenderParagraph targetParagraph) {
    final Matrix4 transform = paragraph.getTransformTo(targetParagraph);
    final Offset localCenter = paragraph.paintBounds.centerLeft;
    final Offset localPos = MatrixUtils.transformPoint(transform, localCenter);
    final TextPosition position = targetParagraph.getPositionForOffset(localPos);
    return position;
  }

  _TextBoundaryRecord _getParagraphBoundaryAtPosition(TextPosition position, String text) {
    final paragraphBoundary = ParagraphBoundary(text);
    // Use position.offset - 1 when `position` is at the end of the selectable to retrieve
    // the previous text boundary's location.
    final int paragraphStart =
        paragraphBoundary.getLeadingTextBoundaryAt(
          position.offset == text.length || position.affinity == TextAffinity.upstream
              ? position.offset - 1
              : position.offset,
        ) ??
        0;
    final int paragraphEnd =
        paragraphBoundary.getTrailingTextBoundaryAt(position.offset) ?? text.length;
    final paragraphRange = TextRange(start: paragraphStart, end: paragraphEnd);
    assert(paragraphRange.isNormalized);
    return _adjustTextBoundaryAtPosition(paragraphRange, position);
  }

  _TextBoundaryRecord _getClampedParagraphBoundaryAtPosition(TextPosition position) {
    final paragraphBoundary = ParagraphBoundary(fullText);
    // Use position.offset - 1 when `position` is at the end of the selectable to retrieve
    // the previous text boundary's location.
    int paragraphStart =
        paragraphBoundary.getLeadingTextBoundaryAt(
          position.offset == fullText.length || position.affinity == TextAffinity.upstream
              ? position.offset - 1
              : position.offset,
        ) ??
        0;
    int paragraphEnd =
        paragraphBoundary.getTrailingTextBoundaryAt(position.offset) ?? fullText.length;
    paragraphStart = paragraphStart < range.start
        ? range.start
        : paragraphStart > range.end
        ? range.end
        : paragraphStart;
    paragraphEnd = paragraphEnd > range.end
        ? range.end
        : paragraphEnd < range.start
        ? range.start
        : paragraphEnd;
    final paragraphRange = TextRange(start: paragraphStart, end: paragraphEnd);
    assert(paragraphRange.isNormalized);
    return _adjustTextBoundaryAtPosition(paragraphRange, position);
  }

  SelectionResult _handleDirectionallyExtendSelection(
    double horizontalBaseline,
    bool isExtent,
    SelectionExtendDirection movement,
  ) {
    final Matrix4 transform = paragraph.getTransformTo(null);
    if (transform.invert() == 0.0) {
      switch (movement) {
        case SelectionExtendDirection.previousLine:
        case SelectionExtendDirection.backward:
          return SelectionResult.previous;
        case SelectionExtendDirection.nextLine:
        case SelectionExtendDirection.forward:
          return SelectionResult.next;
      }
    }
    final double baselineInParagraphCoordinates = MatrixUtils.transformPoint(
      transform,
      Offset(horizontalBaseline, 0),
    ).dx;
    assert(!baselineInParagraphCoordinates.isNaN);
    final TextPosition newPosition;
    final SelectionResult result;
    switch (movement) {
      case SelectionExtendDirection.previousLine:
      case SelectionExtendDirection.nextLine:
        assert(_textSelectionEnd != null && _textSelectionStart != null);
        final TextPosition targetedEdge = isExtent ? _textSelectionEnd! : _textSelectionStart!;
        final MapEntry<TextPosition, SelectionResult> moveResult = _handleVerticalMovement(
          targetedEdge,
          horizontalBaselineInParagraphCoordinates: baselineInParagraphCoordinates,
          below: movement == SelectionExtendDirection.nextLine,
        );
        newPosition = moveResult.key;
        result = moveResult.value;
      case SelectionExtendDirection.forward:
      case SelectionExtendDirection.backward:
        _textSelectionEnd ??= movement == SelectionExtendDirection.forward
            ? TextPosition(offset: range.start)
            : TextPosition(offset: range.end, affinity: TextAffinity.upstream);
        _textSelectionStart ??= _textSelectionEnd;
        final TextPosition targetedEdge = isExtent ? _textSelectionEnd! : _textSelectionStart!;
        final Offset edgeOffsetInParagraphCoordinates = paragraph._getOffsetForPosition(
          targetedEdge,
        );
        final baselineOffsetInParagraphCoordinates = Offset(
          baselineInParagraphCoordinates,
          // Use half of line height to point to the middle of the line.
          edgeOffsetInParagraphCoordinates.dy - paragraph._textPainter.preferredLineHeight / 2,
        );
        newPosition = paragraph.getPositionForOffset(baselineOffsetInParagraphCoordinates);
        result = SelectionResult.end;
    }
    if (isExtent) {
      _textSelectionEnd = newPosition;
    } else {
      _textSelectionStart = newPosition;
    }
    return result;
  }

  SelectionResult _handleGranularlyExtendSelection(
    bool forward,
    bool isExtent,
    TextGranularity granularity,
  ) {
    _textSelectionEnd ??= forward
        ? TextPosition(offset: range.start)
        : TextPosition(offset: range.end, affinity: TextAffinity.upstream);
    _textSelectionStart ??= _textSelectionEnd;
    final TextPosition targetedEdge = isExtent ? _textSelectionEnd! : _textSelectionStart!;
    if (forward && (targetedEdge.offset == range.end)) {
      return SelectionResult.next;
    }
    if (!forward && (targetedEdge.offset == range.start)) {
      return SelectionResult.previous;
    }
    final SelectionResult result;
    final TextPosition newPosition;
    switch (granularity) {
      case TextGranularity.character:
        final String text = range.textInside(fullText);
        newPosition = _moveBeyondTextBoundaryAtDirection(
          targetedEdge,
          forward,
          CharacterBoundary(text),
        );
        result = SelectionResult.end;
      case TextGranularity.word:
        final TextBoundary textBoundary = paragraph._textPainter.wordBoundaries.moveByWordBoundary;
        newPosition = _moveBeyondTextBoundaryAtDirection(targetedEdge, forward, textBoundary);
        result = SelectionResult.end;
      case TextGranularity.paragraph:
        final String text = range.textInside(fullText);
        newPosition = _moveBeyondTextBoundaryAtDirection(
          targetedEdge,
          forward,
          ParagraphBoundary(text),
        );
        result = SelectionResult.end;
      case TextGranularity.line:
        newPosition = _moveToTextBoundaryAtDirection(targetedEdge, forward, LineBoundary(this));
        result = SelectionResult.end;
      case TextGranularity.document:
        final String text = range.textInside(fullText);
        newPosition = _moveBeyondTextBoundaryAtDirection(
          targetedEdge,
          forward,
          DocumentBoundary(text),
        );
        if (forward && newPosition.offset == range.end) {
          result = SelectionResult.next;
        } else if (!forward && newPosition.offset == range.start) {
          result = SelectionResult.previous;
        } else {
          result = SelectionResult.end;
        }
    }

    if (isExtent) {
      _textSelectionEnd = newPosition;
    } else {
      _textSelectionStart = newPosition;
    }
    return result;
  }

  // Move **beyond** the local boundary of the given type (unless range.start or
  // range.end is reached). Used for most TextGranularity types except for
  // TextGranularity.line, to ensure the selection movement doesn't get stuck at
  // a local fixed point.
  TextPosition _moveBeyondTextBoundaryAtDirection(
    TextPosition end,
    bool forward,
    TextBoundary textBoundary,
  ) {
    final int newOffset = forward
        ? textBoundary.getTrailingTextBoundaryAt(end.offset) ?? range.end
        : textBoundary.getLeadingTextBoundaryAt(end.offset - 1) ?? range.start;
    return TextPosition(offset: newOffset);
  }

  // Move **to** the local boundary of the given type. Typically used for line
  // boundaries, such that performing "move to line start" more than once never
  // moves the selection to the previous line.
  TextPosition _moveToTextBoundaryAtDirection(
    TextPosition end,
    bool forward,
    TextBoundary textBoundary,
  ) {
    assert(end.offset >= 0);
    final int caretOffset;
    switch (end.affinity) {
      case TextAffinity.upstream:
        if (end.offset < 1 && !forward) {
          assert(end.offset == 0);
          return const TextPosition(offset: 0);
        }
        final characterBoundary = CharacterBoundary(fullText);
        caretOffset =
            math.max(
              0,
              characterBoundary.getLeadingTextBoundaryAt(range.start + end.offset) ?? range.start,
            ) -
            1;
      case TextAffinity.downstream:
        caretOffset = end.offset;
    }
    final int offset = forward
        ? textBoundary.getTrailingTextBoundaryAt(caretOffset) ?? range.end
        : textBoundary.getLeadingTextBoundaryAt(caretOffset) ?? range.start;
    return TextPosition(offset: offset);
  }

  MapEntry<TextPosition, SelectionResult> _handleVerticalMovement(
    TextPosition position, {
    required double horizontalBaselineInParagraphCoordinates,
    required bool below,
  }) {
    final List<ui.LineMetrics> lines = paragraph._textPainter.computeLineMetrics();
    final Offset offset = paragraph.getOffsetForCaret(position, Rect.zero);
    int currentLine = lines.length - 1;
    for (final lineMetrics in lines) {
      if (lineMetrics.baseline > offset.dy) {
        currentLine = lineMetrics.lineNumber;
        break;
      }
    }
    final TextPosition newPosition;
    if (below && currentLine == lines.length - 1) {
      newPosition = TextPosition(offset: range.end, affinity: TextAffinity.upstream);
    } else if (!below && currentLine == 0) {
      newPosition = TextPosition(offset: range.start);
    } else {
      final int newLine = below ? currentLine + 1 : currentLine - 1;
      newPosition = _clampTextPosition(
        paragraph.getPositionForOffset(
          Offset(horizontalBaselineInParagraphCoordinates, lines[newLine].baseline),
        ),
      );
    }
    final SelectionResult result;
    if (newPosition.offset == range.start) {
      result = SelectionResult.previous;
    } else if (newPosition.offset == range.end) {
      result = SelectionResult.next;
    } else {
      result = SelectionResult.end;
    }
    assert(result != SelectionResult.next || below);
    assert(result != SelectionResult.previous || !below);
    return MapEntry<TextPosition, SelectionResult>(newPosition, result);
  }

  /// Whether the given text position is contained in current selection
  /// range.
  ///
  /// The parameter `start` must be smaller than `end`.
  bool _positionIsWithinCurrentSelection(TextPosition position) {
    if (_textSelectionStart == null || _textSelectionEnd == null) {
      return false;
    }
    // Normalize current selection.
    late TextPosition currentStart;
    late TextPosition currentEnd;
    if (_compareTextPositions(_textSelectionStart!, _textSelectionEnd!) > 0) {
      currentStart = _textSelectionStart!;
      currentEnd = _textSelectionEnd!;
    } else {
      currentStart = _textSelectionEnd!;
      currentEnd = _textSelectionStart!;
    }
    return _compareTextPositions(currentStart, position) >= 0 &&
        _compareTextPositions(currentEnd, position) <= 0;
  }

  /// Compares two text positions.
  ///
  /// Returns 1 if `position` < `otherPosition`, -1 if `position` > `otherPosition`,
  /// or 0 if they are equal.
  static int _compareTextPositions(TextPosition position, TextPosition otherPosition) {
    if (position.offset < otherPosition.offset) {
      return 1;
    } else if (position.offset > otherPosition.offset) {
      return -1;
    } else if (position.affinity == otherPosition.affinity) {
      return 0;
    } else {
      return position.affinity == TextAffinity.upstream ? 1 : -1;
    }
  }

  @override
  Matrix4 getTransformTo(RenderObject? ancestor) {
    return paragraph.getTransformTo(ancestor);
  }

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    if (!paragraph.attached) {
      assert(startHandle == null && endHandle == null, 'Only clean up can be called.');
      return;
    }
    if (_startHandleLayerLink != startHandle) {
      _startHandleLayerLink = startHandle;
      paragraph.markNeedsPaint();
    }
    if (_endHandleLayerLink != endHandle) {
      _endHandleLayerLink = endHandle;
      paragraph.markNeedsPaint();
    }
  }

  List<Rect>? _cachedBoundingBoxes;

  @override
  List<Rect> get boundingBoxes {
    if (_cachedBoundingBoxes == null) {
      final List<TextBox> boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
        boxHeightStyle: .max,
      );
      if (boxes.isNotEmpty) {
        _cachedBoundingBoxes = <Rect>[];
        for (final textBox in boxes) {
          _cachedBoundingBoxes!.add(textBox.toRect());
        }
      } else {
        final Offset offset = paragraph._getOffsetForPosition(TextPosition(offset: range.start));
        final rect = Rect.fromPoints(
          offset,
          offset.translate(0, -paragraph._textPainter.preferredLineHeight),
        );
        _cachedBoundingBoxes = <Rect>[rect];
      }
    }
    return _cachedBoundingBoxes!;
  }

  Rect? _cachedRect;

  Rect get _rect {
    if (_cachedRect == null) {
      final List<TextBox> boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
        boxHeightStyle: .max,
      );
      if (boxes.isNotEmpty) {
        Rect result = boxes.first.toRect();
        for (var index = 1; index < boxes.length; index += 1) {
          result = result.expandToInclude(boxes[index].toRect());
        }
        _cachedRect = result;
      } else {
        final Offset offset = paragraph._getOffsetForPosition(TextPosition(offset: range.start));
        _cachedRect = Rect.fromPoints(
          offset,
          offset.translate(0, -paragraph._textPainter.preferredLineHeight),
        );
      }
    }
    return _cachedRect!;
  }

  void didChangeParagraphLayout() {
    _cachedRect = null;
    _cachedBoundingBoxes = null;
  }

  @override
  int get contentLength => range.end - range.start;

  @override
  Size get size {
    return _rect.size;
  }

  void paintSelection(PaintingContext context, Offset offset) {
    if (_textSelectionStart == null || _textSelectionEnd == null) {
      return;
    }
    if (paragraph.selectionColor != null) {
      final selection = TextSelection(
        baseOffset: _textSelectionStart!.offset,
        extentOffset: _textSelectionEnd!.offset,
      );
      final selectionPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = paragraph.selectionColor!;
      for (final TextBox textBox in paragraph.getBoxesForSelection(selection)) {
        context.canvas.drawRect(textBox.toRect().shift(offset), selectionPaint);
      }
    }
  }

  void paintHandles(PaintingContext context, Offset offset) {
    if (_textSelectionStart == null || _textSelectionEnd == null) {
      return;
    }
    if (_startHandleLayerLink != null && value.startSelectionPoint != null) {
      context.pushLayer(
        LeaderLayer(
          link: _startHandleLayerLink!,
          offset: offset + value.startSelectionPoint!.localPosition,
        ),
        (PaintingContext context, Offset offset) {},
        Offset.zero,
      );
    }
    if (_endHandleLayerLink != null && value.endSelectionPoint != null) {
      context.pushLayer(
        LeaderLayer(
          link: _endHandleLayerLink!,
          offset: offset + value.endSelectionPoint!.localPosition,
        ),
        (PaintingContext context, Offset offset) {},
        Offset.zero,
      );
    }
  }

  @override
  TextSelection getLineAtOffset(TextPosition position) {
    final TextRange line = paragraph._getLineAtOffset(position);
    final int start = line.start.clamp(range.start, range.end);
    final int end = line.end.clamp(range.start, range.end);
    return TextSelection(baseOffset: start, extentOffset: end);
  }

  @override
  TextPosition getTextPositionAbove(TextPosition position) {
    return _clampTextPosition(paragraph._getTextPositionAbove(position));
  }

  @override
  TextPosition getTextPositionBelow(TextPosition position) {
    return _clampTextPosition(paragraph._getTextPositionBelow(position));
  }

  @override
  TextRange getWordBoundary(TextPosition position) => paragraph.getWordBoundary(position);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('textInsideRange', range.textInside(fullText)));
    properties.add(DiagnosticsProperty<TextRange>('range', range));
    properties.add(DiagnosticsProperty<String>('fullText', fullText));
  }
}
