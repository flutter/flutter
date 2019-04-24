// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show ParagraphBuilder, PlaceholderAlignment;

import 'package:flutter/painting.dart';
import 'package:flutter/gestures.dart';

import 'framework.dart';

/// Where to vertically align the widget relative to the surrounding text.
///
/// This is parallel to [ui.PlaceholderAignment], but refers to widgets.
enum InlineWidgetAlignment {
  /// Match the baseline of the widget with the baseline specified in
  /// [WidgetSpan.baseline]. Using widget-baseline alignment results in
  /// the inability to use min/max intrinsic width/height on the entire
  /// [RenderParagraph] due to the requirement that layout be called before
  /// getting the baseline.
  ///
  /// This is useful when aligning text-based inline widgets such as
  /// [TextField]s and will ensure the text will line up correctly.
  baseline,

  /// Align the bottom edge of the widget with the baseline specified in
  /// [WidgetSpan.baseline] such that the widget sits on top of the baseline.
  aboveBaseline,

  /// Align the top edge of the widget with the baseline specified in
  /// [WidgetSpan.baseline] such that the widget hangs below the baseline.
  belowBaseline,

  /// Align the top edge of the widget with the top edge of the font specified
  /// in [WidgetSpan.style]. When the widget is very tall, the extra space
  /// will hang from the top and extend through the bottom of the line.
  top,

  /// Align the bottom edge of the widget with the top edge of the font specified
  /// in [WidgetSpan.style]. When the widget is very tall, the extra space
  /// will rise from the bottom and extend through the top of the line.
  bottom,

  /// Align the middle of the placeholder with the middle of the text. When the
  /// widget is very tall, the extra space will grow equally from the top and
  /// bottom of the line.
  middle,
}

/// An immutable widget that is embedded inline within text.
///
/// The [widget] property is the widget that will be embedded. It is the
/// widget's responsibility to size itself appropriately, the text will
/// not enforce any constraints.
///
/// The [widget] property may contain its own children, including
/// [RichText] widgets which may include additional [WidgetSpan]s. Child
/// [RichText] widgets will be laid out independently and occupy a
/// rectangular space in the parent text layout.
///
/// [WidgetSpan]s will be ignored when passed into a [TextPainter] directly.
/// To properly layout and paint the [widget], [WidgetSpan] should be passed
/// into a [RichText] widget.
///
/// {@tool sample}
///
/// A card with `Hello World!` embedded inline within a TextSpan tree.
///
/// ```dart
/// <TextSpan>[
///   TextSpan(text: 'Flutter is'),
///   WidgetSpan(
///     widget: SizedBox(
///       width: 120,
///       height: 50,
///       child: Card(
///         child: Center(
///           child: Text('Hello World!')
///         )
///       ),
///     )
///   ),
///   TextSpan(text: 'the best!'),
/// ]
/// ```
/// {@end-tool}
///
/// The [semanticsLabel] argument may be provided to supply a description of
/// this [WidgetSpan] within the [toPlainText]. The semantics label of the
/// overall [InlineSpan] tree will not mention [WidgetSpan]s unless
/// [semanticsLabel] is provided. Semantics for the widget itself will still
/// function independently from the [InlineSpan] semantics label.
///
/// See also:
///
///  * [TextSpan], a node that represents text in a [TextSpan] tree.
///  * [Text], a widget for showing uniformly-styled text.
///  * [RichText], a widget for finer control of text rendering.
///  * [TextPainter], a class for painting [TextSpan] objects on a [Canvas].
@immutable
class WidgetSpan extends PlaceholderSpan {
  /// Creates a [WidgetSpan] with the given values.
  ///
  /// The [widget] property should be non-null. [WidgetSpan] cannot contain any
  /// [TextSpan] or [WidgetSpan] children.
  ///
  /// A [TextStyle] may be provided with the [style] property, but only the
  /// decoration, foreground, background, and spacing options will be used.
  const WidgetSpan({
    Widget child,
    InlineWidgetAlignment alignment = InlineWidgetAlignment.bottom,
    TextBaseline baseline,
    TextStyle style,
  }) : assert(child != null),
       assert((alignment == InlineWidgetAlignment.aboveBaseline ||
               alignment == InlineWidgetAlignment.belowBaseline ||
               alignment == InlineWidgetAlignment.baseline) ? baseline != null : true),
       child = child,
       super(alignment:
           // Convert InlineWidgetAlignment to PlaceholderAlignment in a const fashion.
           alignment == InlineWidgetAlignment.baseline ? ui.PlaceholderAlignment.baseline :
           alignment == InlineWidgetAlignment.aboveBaseline ? ui.PlaceholderAlignment.aboveBaseline :
           alignment == InlineWidgetAlignment.belowBaseline ? ui.PlaceholderAlignment.belowBaseline :
           alignment == InlineWidgetAlignment.top ? ui.PlaceholderAlignment.top :
           alignment == InlineWidgetAlignment.bottom ? ui.PlaceholderAlignment.bottom :
           alignment == InlineWidgetAlignment.middle ? ui.PlaceholderAlignment.middle : null,
         baseline: baseline, style: style, children: null,
       );

  /// The widget to embed inline with text.
  final Widget child;

  /// Adds a placeholder box to the paragraph builder if a size has been
  /// calculated for the widget.
  ///
  /// Sizes are provided through [dimensions], which should contain a 1:1
  /// in-order mapping of widget to laid out dimensions. If no such dimension
  /// is provided, the widget will be skipped.
  ///
  /// Since widget sizes are calculated independently from the rest of the
  /// paragraph, the [textScaleFactor] is ignored.
  @override
  void build(ui.ParagraphBuilder builder, { double textScaleFactor = 1.0, List<PlaceholderDimensions> dimensions }) {
    assert(debugAssertIsValid());

    final bool hasStyle = style != null;
    if (hasStyle)
      builder.pushStyle(style.getTextStyle(textScaleFactor: textScaleFactor));
    if (dimensions != null) {
      assert(builder.placeholderCount < dimensions.length);
      PlaceholderDimensions currentDimensions = dimensions[builder.placeholderCount];
      builder.addPlaceholder(
        currentDimensions.size.width,
        currentDimensions.size.height,
        alignment,
        baseline: currentDimensions.baseline,
        baselineOffset: currentDimensions.baselineOffset,
      );
    }
    if (hasStyle)
      builder.pop();
  }

  /// Calls visitor on this [WidgetSpan]. There are no children spans to walk.
  bool visitChildren(InlineSpanVisitor visitor) {
    if (!visitor(this))
      return false;
    assert(children == null);
    return true;
  }

  /// [WidgetSpan]s are flattened to a `0xFFFC` object replacement character in the
  /// plain text representation.
  String toPlainText({bool includeSemanticsLabels = true}) {
    return '\u{FFFC}';
  }

  int codeUnitAt(int index) {
    return null;
  }

  /// Describe the difference between this widget span and another [TextSpan],
  /// in terms of how much damage it will make to the rendering. The comparison
  /// is deep.
  ///
  /// Comparing a [WidgetSpan] with a [TextSpan] will result in [RenderComparison.layout].
  ///
  /// See also:
  ///
  ///  * [TextStyle.compareTo], which does the same thing for [TextStyle]s.
  RenderComparison compareTo(InlineSpan other) {
    if (identical(this, other))
      return RenderComparison.identical;
    if (other.runtimeType != runtimeType)
      return RenderComparison.layout;
    final WidgetSpan typedOther = other;
    if ((style == null) != (other.style == null))
      return RenderComparison.layout;
    RenderComparison result = RenderComparison.identical;
    if (style != null) {
      final RenderComparison candidate = style.compareTo(other.style);
      if (candidate.index > result.index)
        result = candidate;
      if (result == RenderComparison.layout)
        return result;
    }
    return result;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final WidgetSpan typedOther = other;
    return typedOther.child == child
        && typedOther.style == style;
  }

  /// Returns the text span that contains the given position in the text.
  InlineSpan getSpanForPosition(TextPosition position) {
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
  bool debugAssertIsValid() {
    // WidgetSpans are always valid as asserts prevent invalid WidgetSpans
    // from being constructed.
    return true;
  }
}
