// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:ui' as ui show ParagraphBuilder, PlaceholderAlignment;

import 'package:flutter/foundation.dart';

import 'basic_types.dart';
import 'inline_span.dart';
import 'text_painter.dart';
import 'text_span.dart';
import 'text_style.dart';

/// An immutable placeholder that is embedded inline within text.
///
/// [PlaceholderSpan] represents a placeholder that acts as a stand-in for other
/// content.
///
/// A [PlaceholderSpan] by itself does not change the text layout visually
/// but can be used to insert invisible codepoint indexes into the text to
/// account for rich or dynamic content that requires plaintext metadata to
/// properly represent in a [TextEditingValue]. For example, a raw placeholder
/// can be inserted to account for a `<b>` bold tag. The caret would properly
/// skip over 3 indexes to account for the non-rendered bold tag string.
///
/// [WidgetSpan] from the widgets library extends [PlaceholderSpan] and may be
/// used instead to specify a widget as the contents of the placeholder.
///
/// See also:
///
///  * [WidgetSpan], a leaf node that represents an embedded inline widget.
///  * [TextSpan], a node that represents text in a [TextSpan] tree.
///  * [Text], a widget for showing uniformly-styled text.
///  * [RichText], a widget for finer control of text rendering.
///  * [TextPainter], a class for painting [TextSpan] objects on a [Canvas].
class PlaceholderSpan extends InlineSpan {
  /// Creates a [PlaceholderSpan] with the given values.
  ///
  /// A [TextStyle] may be provided with the [style] property, but only the
  /// decoration, foreground, background, and spacing options will be used.
  const PlaceholderSpan({
    this.alignment = ui.PlaceholderAlignment.bottom,
    this.baseline,
    TextStyle? style,
    this.plainText = '\uFFFC',
  }) : super(style: style);

  /// How the placeholder aligns vertically with the text.
  ///
  /// See [ui.PlaceholderAlignment] for details on each mode.
  final ui.PlaceholderAlignment alignment;

  /// The [TextBaseline] to align against when using [ui.PlaceholderAlignment.baseline],
  /// [ui.PlaceholderAlignment.aboveBaseline], and [ui.PlaceholderAlignment.belowBaseline].
  ///
  /// This is ignored when using other alignment modes.
  final TextBaseline? baseline;

  /// The plaintext respresentation of the placeholder.
  ///
  /// The placeholder will occupy the same number of codepoint indexes in the
  /// laid out text as the length of this String.
  ///
  /// This is typically the String content this placeholder is replacing.
  final String plainText;

  /// Adds an empty placeholder to the paragraph builder.
  @override
  void build(ui.ParagraphBuilder builder, { double textScaleFactor = 1.0, List<PlaceholderDimensions>? dimensions }) {
    assert(debugAssertIsValid());
    final bool hasStyle = style != null;
    if (hasStyle) {
      builder.pushStyle(style!.getTextStyle(textScaleFactor: textScaleFactor));
    }
    builder.addPlaceholder(
      0, // width
      0, // height
      alignment,
      scale: 1.0,
      baseline: TextBaseline.alphabetic,
      baselineOffset: 0,
      codepointLength: plainText.length,
    );
    if (hasStyle) {
      builder.pop();
    }
  }

  /// Returns the plaintext representation of the placeholder.
  ///
  /// By default, [PlaceholderSpan]s are flattened to a `0xFFFC` object replacement character in the
  /// plain text representation when `includePlaceholders` is true. This can be customized with the
  /// `plainText` parameter in the contructor.
  @override
  void computeToPlainText(StringBuffer buffer, {bool includeSemanticsLabels = true, bool includePlaceholders = true}) {
    if (includePlaceholders) {
      buffer.write(plainText);
    }
  }

  /// Calls `visitor` on this [PlaceholderSpan]. There are no children spans to walk.
  @override
  bool visitChildren(InlineSpanVisitor visitor) {
    return visitor(this);
  }

  @override
  int? codeUnitAtVisitor(int index, Accumulator offset) {
    return null;
  }

  @override
  RenderComparison compareTo(InlineSpan other) {
    if (identical(this, other))
      return RenderComparison.identical;
    if (other.runtimeType != runtimeType)
      return RenderComparison.layout;
    final WidgetSpan typedOther = other as PlaceholderSpan;
    if (child != typedOther.child ||
        alignment != typedOther.alignment ||
        plainText != typedOther.plainText) {
      return RenderComparison.layout;
    }
    RenderComparison result = RenderComparison.identical;
    if (style != null) {
      final RenderComparison candidate = style!.compareTo(other.style!);
      if (candidate.index > result.index)
        result = candidate;
      if (result == RenderComparison.layout)
        return result;
    }
    return result;
  }

  @override
  InlineSpan? getSpanForPositionVisitor(TextPosition position, Accumulator offset) {
    final TextAffinity affinity = position.affinity;
    final int targetOffset = position.offset;
    final int endOffset = offset.value + plainText.length;
    if (offset.value == targetOffset && affinity == TextAffinity.downstream ||
        offset.value < targetOffset && targetOffset < endOffset ||
        endOffset == targetOffset && affinity == TextAffinity.upstream) {
      return this;
    }
    offset.increment(plainText.length);
    return null;
  }

  @override
  void computeSemanticsInformation(List<InlineSpanSemanticsInformation> collector) {
    collector.add(InlineSpanSemanticsInformation.placeholder);
  }

  /// Populates the `semanticsOffsets` and `semanticsElements` with the appropriate data
  /// to be able to construct a [SemanticsNode].
  ///
  /// [PlaceholderSpan]s have a text length of 1, which corresponds to the object
  /// replacement character (0xFFFC) that is inserted to represent it.
  ///
  /// Null is added to `semanticsElements` for [PlaceholderSpan]s.
  void describeSemantics(Accumulator offset, List<int> semanticsOffsets, List<dynamic> semanticsElements) {
    semanticsOffsets.add(offset.value);
    semanticsOffsets.add(offset.value + 1);
    semanticsElements.add(null); // null indicates this is a placeholder.
    offset.increment(1);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(EnumProperty<ui.PlaceholderAlignment>('alignment', alignment, defaultValue: null));
    properties.add(EnumProperty<TextBaseline>('baseline', baseline, defaultValue: null));
  }

  @override
  bool debugAssertIsValid() {
    // PlaceholderSpans are always valid
    return true;
  }
}
