// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show ParagraphBuilder, PlaceholderAlignment;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'text_style.dart';
import 'text_painter.dart';
import 'text_span.dart';

/// An immutable placeholder that is embedded inline within text.
///
/// [PlaceholderSpan] represents an abstract generic placeholder. [WidgetSpan] should be
/// used instead to specify the contents of the placeholder. A [PlaceholderSpan]
/// by itself does not contain useful information to change a TextSpan.
///
/// [PlaceholderSpan]s must be leaf nodes in the [TextSpan] tree. [PlaceholderSpan]s
/// cannot have any [TextSpan] children.
///
/// [PlaceholderSpan]s will be ignored when passed into a [TextPainter] directly.
/// A [WidgetSpan] should be passed into a [RichText] widget instead.
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
/// See also:
///
///  * [WidgetSpan], a leaf node that represents an embedded inline widget.
///  * [TextSpan], a node that represents text in a [TextSpan] tree.
///  * [Text], a widget for showing uniformly-styled text.
///  * [RichText], a widget for finer control of text rendering.
///  * [TextPainter], a class for painting [TextSpan] objects on a [Canvas].
@immutable
abstract class PlaceholderSpan extends TextSpan {
  /// Creates a [PlaceholderSpan] with the given values.
  ///
  /// The [widget] property should be non-null. [PlaceholderSpan] cannot contain any
  /// [TextSpan] or [PlaceholderSpan] children.
  ///
  /// A [TextStyle] may be provided with the [style] property, but only the
  /// decoration, foreground, background, and spacing options will be used.
  const PlaceholderSpan({
    InlineWidgetAlignment alignment = InlineWidgetAlignment.bottom,
    TextBaseline baseline,
    TextStyle style,
    GestureRecognizer recognizer,
  }) : alignment = alignment,
       baseline = baseline,
       super(style: style, recognizer: recognizer);

  final InlineWidgetAlignment alignment;

  final TextBaseline baseline;

  // /// Adds a placeholder box to the paragraph builder if a size has been
  // /// calculated for the widget.
  // ///
  // /// Sizes are provided through [dimensions], which should contain a 1:1
  // /// in-order mapping of widget to laid out dimensions. If no such dimension
  // /// is provided, the widget will be skipped.
  // ///
  // /// Since widget sizes are calculated independently from the rest of the
  // /// paragraph, the [textScaleFactor] is ignored.
  // @override
  // void build(ui.ParagraphBuilder builder, { double textScaleFactor = 1.0, List<PlaceholderDimensions> dimensions });

  // static ui.PlaceholderAlignment _inlineWidgetAlignmentToPlaceholderAlignment(InlineWidgetAlignment alignment) {
  //   switch (alignment) {
  //     case InlineWidgetAlignment.baseline: return ui.PlaceholderAlignment.baseline;
  //     case InlineWidgetAlignment.aboveBaseline: return ui.PlaceholderAlignment.aboveBaseline;
  //     case InlineWidgetAlignment.belowBaseline: return ui.PlaceholderAlignment.belowBaseline;
  //     case InlineWidgetAlignment.top: return ui.PlaceholderAlignment.top;
  //     case InlineWidgetAlignment.bottom: return ui.PlaceholderAlignment.bottom;
  //     case InlineWidgetAlignment.middle: return ui.PlaceholderAlignment.middle;
  //   }
  //   return null;
  // }

  /// Describe the difference between this widget span and another [TextSpan],
  /// in terms of how much damage it will make to the rendering. The comparison
  /// is deep.
  ///
  /// Comparing a [PlaceholderSpan] with a [TextSpan] will result in [RenderComparison.layout].
  ///
  /// See also:
  ///
  ///  * [TextStyle.compareTo], which does the same thing for [TextStyle]s.
  // RenderComparison compareTo(TextSpan other) {
  //   if (identical(this, other))
  //     return RenderComparison.identical;
  //   if (!(other.runtimeType is PlaceholderSpan))
  //     return RenderComparison.layout;
  //   final PlaceholderSpan typedOther = other;
  //   if ((style == null) != (other.style == null))
  //     return RenderComparison.layout;
  //   RenderComparison result = recognizer == other.recognizer ? RenderComparison.identical : RenderComparison.metadata;
  //   if (style != null) {
  //     final RenderComparison candidate = style.compareTo(other.style);
  //     if (candidate.index > result.index)
  //       result = candidate;
  //     if (result == RenderComparison.layout)
  //       return result;
  //   }
  //   // PlaceholderSpans are always a leaf node in the TextSpan tree, and have
  //   // no children.
  //   return result;
  // }

  // @override
  // bool operator ==(dynamic other) {
  //   if (identical(this, other))
  //     return true;
  //   if (!(other is PlaceholderSpan))
  //     return false;
  //   final PlaceholderSpan typedOther = other;
  //   return typedOther.style == style
  //       && typedOther.recognizer == recognizer;
  // }
}
