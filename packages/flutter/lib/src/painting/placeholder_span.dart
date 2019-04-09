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
}
