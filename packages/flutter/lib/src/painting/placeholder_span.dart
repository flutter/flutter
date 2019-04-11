// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show ParagraphBuilder, PlaceholderAlignment;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'basic_types.dart';
import 'inline_span.dart';
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
/// See also:
///
///  * [WidgetSpan], a leaf node that represents an embedded inline widget.
///  * [TextSpan], a node that represents text in a [TextSpan] tree.
///  * [Text], a widget for showing uniformly-styled text.
///  * [RichText], a widget for finer control of text rendering.
///  * [TextPainter], a class for painting [TextSpan] objects on a [Canvas].
@immutable
abstract class PlaceholderSpan extends InlineSpan {
  /// Creates a [PlaceholderSpan] with the given values.
  ///
  /// The [widget] property should be non-null. [PlaceholderSpan] cannot contain any
  /// [TextSpan] or [PlaceholderSpan] children.
  ///
  /// A [TextStyle] may be provided with the [style] property, but only the
  /// decoration, foreground, background, and spacing options will be used.
  const PlaceholderSpan({
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.bottom,
    TextBaseline baseline,
    TextStyle style,
    GestureRecognizer recognizer,
  }) : alignment = alignment,
       baseline = baseline,
       super(style: style, recognizer: recognizer);

  /// How the placeholder aligns vertically with the text.
  ///
  /// See [ui.PlaceholderAlignment] for details on each mode.
  final ui.PlaceholderAlignment alignment;

  /// The [TextBaseline] to align against when using [ui.PlaceholderAlignment.baseline],
  /// [ui.PlaceholderAlignment.aboveBaseline], and [ui.PlaceholderAlignment.belowBaseline].
  ///
  /// This is ignored when using other alignment modes.
  final TextBaseline baseline;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.whitespace;
    // Properties on style are added as if they were properties directly on
    // this InlineSpan.
    properties.add(EnumProperty<ui.PlaceholderAlignment>('alignment', alignment, defaultValue: null));
    properties.add(EnumProperty<TextBaseline>('baseline', baseline, defaultValue: null));
  }
}
