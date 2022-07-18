// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show ParagraphBuilder, PlaceholderAlignment;

import 'package:flutter/painting.dart';

import 'framework.dart';

/// An immutable widget that is embedded inline within text.
///
/// The [child] property is the widget that will be embedded. Children are
/// constrained by the width of the paragraph.
///
/// The [child] property may contain its own [Widget] children (if applicable),
/// including [Text] and [RichText] widgets which may include additional
/// [WidgetSpan]s. Child [Text] and [RichText] widgets will be laid out
/// independently and occupy a rectangular space in the parent text layout.
///
/// [WidgetSpan]s will be ignored when passed into a [TextPainter] directly.
/// To properly layout and paint the [child] widget, [WidgetSpan] should be
/// passed into a [Text.rich] widget.
///
/// {@tool snippet}
///
/// A card with `Hello World!` embedded inline within a TextSpan tree.
///
/// ```dart
/// const Text.rich(
///   TextSpan(
///     children: <InlineSpan>[
///       TextSpan(text: 'Flutter is'),
///       WidgetSpan(
///         child: SizedBox(
///           width: 120,
///           height: 50,
///           child: Card(
///             child: Center(
///               child: Text('Hello World!')
///             )
///           ),
///         )
///       ),
///       TextSpan(text: 'the best!'),
///     ],
///   )
/// )
/// ```
/// {@end-tool}
///
/// [WidgetSpan] contributes the semantics of the [WidgetSpan.child] to the
/// semantics tree.
///
/// See also:
///
///  * [TextSpan], a node that represents text in an [InlineSpan] tree.
///  * [Text], a widget for showing uniformly-styled text.
///  * [RichText], a widget for finer control of text rendering.
///  * [TextPainter], a class for painting [InlineSpan] objects on a [Canvas].
@immutable
class WidgetSpan extends PlaceholderSpan {
  /// Creates a [WidgetSpan] with the given values.
  ///
  /// The [child] property must be non-null. [WidgetSpan] is a leaf node in
  /// the [InlineSpan] tree. Child widgets are constrained by the width of the
  /// paragraph they occupy. Child widget heights are unconstrained, and may
  /// cause the text to overflow and be ellipsized/truncated.
  ///
  /// A [TextStyle] may be provided with the [style] property, but only the
  /// decoration, foreground, background, and spacing options will be used.
  const WidgetSpan({
    required this.child,
    super.alignment,
    super.baseline,
    super.style,
  }) : assert(child != null),
       assert(
         baseline != null || !(
          identical(alignment, ui.PlaceholderAlignment.aboveBaseline) ||
          identical(alignment, ui.PlaceholderAlignment.belowBaseline) ||
          identical(alignment, ui.PlaceholderAlignment.baseline)
        ),
      );

  /// The widget to embed inline within text.
  final Widget child;

  /// Adds a placeholder box to the paragraph builder if a size has been
  /// calculated for the widget.
  ///
  /// Sizes are provided through `dimensions`, which should contain a 1:1
  /// in-order mapping of widget to laid-out dimensions. If no such dimension
  /// is provided, the widget will be skipped.
  ///
  /// The `textScaleFactor` will be applied to the laid-out size of the widget.
  @override
  void build(ui.ParagraphBuilder builder, { double textScaleFactor = 1.0, List<PlaceholderDimensions>? dimensions }) {
    assert(debugAssertIsValid());
    assert(dimensions != null);
    final bool hasStyle = style != null;
    if (hasStyle) {
      builder.pushStyle(style!.getTextStyle(textScaleFactor: textScaleFactor));
    }
    assert(builder.placeholderCount < dimensions!.length);
    final PlaceholderDimensions currentDimensions = dimensions![builder.placeholderCount];
    builder.addPlaceholder(
      currentDimensions.size.width,
      currentDimensions.size.height,
      alignment,
      scale: textScaleFactor,
      baseline: currentDimensions.baseline,
      baselineOffset: currentDimensions.baselineOffset,
    );
    if (hasStyle) {
      builder.pop();
    }
  }

  /// Calls `visitor` on this [WidgetSpan]. There are no children spans to walk.
  @override
  bool visitChildren(InlineSpanVisitor visitor) {
    return visitor(this);
  }

  @override
  InlineSpan? getSpanForPositionVisitor(TextPosition position, Accumulator offset) {
    if (position.offset == offset.value) {
      return this;
    }
    offset.increment(1);
    return null;
  }

  @override
  int? codeUnitAtVisitor(int index, Accumulator offset) {
    offset.increment(1);
    return PlaceholderSpan.placeholderCodeUnit;
  }

  @override
  RenderComparison compareTo(InlineSpan other) {
    if (identical(this, other)) {
      return RenderComparison.identical;
    }
    if (other.runtimeType != runtimeType) {
      return RenderComparison.layout;
    }
    if ((style == null) != (other.style == null)) {
      return RenderComparison.layout;
    }
    final WidgetSpan typedOther = other as WidgetSpan;
    if (child != typedOther.child || alignment != typedOther.alignment) {
      return RenderComparison.layout;
    }
    RenderComparison result = RenderComparison.identical;
    if (style != null) {
      final RenderComparison candidate = style!.compareTo(other.style!);
      if (candidate.index > result.index) {
        result = candidate;
      }
      if (result == RenderComparison.layout) {
        return result;
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    if (super != other) {
      return false;
    }
    return other is WidgetSpan
        && other.child == child
        && other.alignment == alignment
        && other.baseline == baseline;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, child, alignment, baseline);

  /// Returns the text span that contains the given position in the text.
  @override
  InlineSpan? getSpanForPosition(TextPosition position) {
    assert(debugAssertIsValid());
    return null;
  }

  /// In debug mode, throws an exception if the object is not in a
  /// valid configuration. Otherwise, returns true.
  ///
  /// This is intended to be used as follows:
  ///
  /// ```dart
  /// assert(myWidgetSpan.debugAssertIsValid());
  /// ```
  @override
  bool debugAssertIsValid() {
    // WidgetSpans are always valid as asserts prevent invalid WidgetSpans
    // from being constructed.
    return true;
  }
}
