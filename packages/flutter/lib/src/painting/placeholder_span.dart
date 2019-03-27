// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show ParagraphBuilder;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'basic_types.dart';
import 'text_style.dart';

/// An placeholder that represents a custom inline [WidgetSpan]
/// 
/// This class does not add any additional properties and should only be
/// used as a placeholder.
/// 
/// See also:
///
///  * [Text], a widget for showing uniformly-styled text.
///  * [RichText], a widget for finer control of text rendering.
///  * [TextPainter], a class for painting [TextSpan] objects on a [Canvas].
@immutable
class PlaceholderSpan extends TextSpan {
  /// Creates a [TextSpan] with the given values.
  ///
  /// For the object to be useful, at least one of [text] or
  /// [children] should be set.
  const PlaceholderSpan({
    TextStyle style,
    GestureRecognizer recognizer,
  }) : super(style: style, recognizer: recognizer);

  // int index;

  /// Apply the [style], [text], and [children] of this object to the
  /// given [ParagraphBuilder], from which a [Paragraph] can be obtained.
  /// [Paragraph] objects can be drawn on [Canvas] objects.
  ///
  /// Rather than using this directly, it's simpler to use the
  /// [TextPainter] class to paint [TextSpan] objects onto [Canvas]
  /// objects.
  /// 
  @override
  void build(ui.ParagraphBuilder builder, { double textScaleFactor = 1.0, List<PlaceholderDimensions> dimensions }) {
    assert(debugAssertIsValid());

    final bool hasStyle = style != null;
    if (hasStyle)
      builder.pushStyle(style.getTextStyle(textScaleFactor: textScaleFactor));
    if (builder.placeholderCount < dimensions.length) {
      PlaceholderDimensions currentDimensions = dimensions[builder.placeholderCount];
      builder.addPlaceholder(
        currentDimensions.size.width,
        currentDimensions.size.height,
        currentDimensions.baseline
      );
    }
    if (hasStyle)
      builder.pop();
  }
}
