// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

export 'package:flutter/foundation.dart' show debugPrint;

// Any changes to this file should be reflected in the debugAssertAllRenderVarsUnset()
// function below.

const Color _kDebugPaintSizeColor = const Color(0xFF00FFFF);
const Color _kDebugPaintSpacingColor = const Color(0x90909090);
const Color _kDebugPaintPaddingColor = const Color(0x900090FF);
const Color _kDebugPaintPaddingInnerEdgeColor = const Color(0xFF0090FF);
const Color _kDebugPaintBoxArrowColor = const Color(0xFFFFFF00);
const Color _kDebugPaintSliverArrowColor = const Color(0xFF33CC33);
const Color _kDebugPaintAlphabeticBaselineColor = const Color(0xFF00FF00);
const Color _kDebugPaintIdeographicBaselineColor = const Color(0xFFFFD000);
const Color _kDebugPaintLayerBordersColor = const Color(0xFFFF9800);
const int _kDebugPaintPointersColorValue = 0x00BBBB;
const HSVColor _kDebugCurrentRepaintColor = const HSVColor.fromAHSV(0.4, 60.0, 1.0, 1.0);
const double _kDebugRepaintRainbowHueIncrement = 2.0;

/// Causes each RenderBox to paint a box around its bounds, and some extra
/// boxes, such as [RenderPadding], to draw construction lines.
bool debugPaintSizeEnabled = false;

/// The color to use when painting RenderObject bounds.
Color debugPaintSizeColor = _kDebugPaintSizeColor;

/// The color to use when painting some boxes that just add space (e.g. an empty
/// RenderConstrainedBox or [RenderPadding]).
///
/// Used by, among other methods, [debugPaintPadding], which is called by
/// [RenderPadding.debugPaintSize] when [debugPaintSizeEnabled] is true.
Color debugPaintSpacingColor = _kDebugPaintSpacingColor;

/// The color to use when painting [RenderPadding] edges.
///
/// Used by, among other methods, [debugPaintPadding], which is called by
/// [RenderPadding.debugPaintSize] when [debugPaintSizeEnabled] is true.
Color debugPaintPaddingColor = _kDebugPaintPaddingColor;

/// The color to use when painting [RenderPadding] edges. This color is painted on
/// top of [debugPaintPaddingColor].
///
/// Used by, among other methods, [debugPaintPadding], which is called by
/// [RenderPadding.debugPaintSize] when [debugPaintSizeEnabled] is true.
Color debugPaintPaddingInnerEdgeColor = _kDebugPaintPaddingInnerEdgeColor;

/// The color to use when painting the arrows used to show [RenderPositionedBox] alignment.
Color debugPaintBoxArrowColor = _kDebugPaintBoxArrowColor;

/// The color to use when painting the arrows used to show [RenderSliver] alignment.
Color debugPaintSliverArrowColor = _kDebugPaintSliverArrowColor;

/// Causes each RenderBox to paint a line at each of its baselines.
bool debugPaintBaselinesEnabled = false;

/// The color to use when painting alphabetic baselines.
Color debugPaintAlphabeticBaselineColor = _kDebugPaintAlphabeticBaselineColor;

/// The color to use when painting ideographic baselines.
Color debugPaintIdeographicBaselineColor = _kDebugPaintIdeographicBaselineColor;

/// Causes each Layer to paint a box around its bounds.
bool debugPaintLayerBordersEnabled = false;

/// The color to use when painting Layer borders.
Color debugPaintLayerBordersColor = _kDebugPaintLayerBordersColor;

/// Causes objects like [RenderPointerListener] to flash while they are being
/// tapped. This can be useful to see how large the hit box is, e.g. when
/// debugging buttons that are harder to hit than expected.
///
/// For details on how to support this in your [RenderBox] subclass, see
/// [RenderBox.debugHandleEvent].
bool debugPaintPointersEnabled = false;

/// The color to use when reporting pointers for [debugPaintPointersEnabled].
int debugPaintPointersColorValue = _kDebugPaintPointersColorValue;

/// Overlay a rotating set of colors when repainting layers in checked mode.
bool debugRepaintRainbowEnabled = false;

/// Overlay a rotating set of colors when repainting text in checked mode.
bool debugRepaintTextRainbowEnabled = false;

/// The current color to overlay when repainting a layer.
HSVColor debugCurrentRepaintColor = _kDebugCurrentRepaintColor;

/// The amount to increment the hue of the current repaint color.
double debugRepaintRainbowHueIncrement = _kDebugRepaintRainbowHueIncrement;

/// Log the call stacks that mark render objects as needing paint.
bool debugPrintMarkNeedsPaintStacks = false;

/// Log the call stacks that mark render objects as needing layout.
///
/// For sanity, this only logs the stack traces of cases where an object is
/// added to the list of nodes needing layout. This avoids printing multiple
/// redundant stack traces as a single [RenderObject.markNeedsLayout] call walks
/// up the tree.
bool debugPrintMarkNeedsLayoutStacks = false;

/// Check the intrinsic sizes of each [RenderBox] during layout.
bool debugCheckIntrinsicSizes = false;

/// Adds [dart:developer.Timeline] events for every RenderObject painted.
///
/// For details on how to use [dart:developer.Timeline] events in the Dart
/// Observatory to optimize your app, see:
/// <https://fuchsia.googlesource.com/sysui/+/master/docs/performance.md>
bool debugProfilePaintsEnabled = false;


/// Returns a list of strings representing the given transform in a format useful for [RenderObject.debugFillDescription].
List<String> debugDescribeTransform(Matrix4 transform) {
  final List<String> matrix = transform.toString().split('\n').map((String s) => '  $s').toList();
  matrix.removeLast();
  return matrix;
}

void _debugDrawDoubleRect(Canvas canvas, Rect outerRect, Rect innerRect, Color color) {
  final Path path = new Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(outerRect)
    ..addRect(innerRect);
  final Paint paint = new Paint()
    ..color = color;
  canvas.drawPath(path, paint);
}

/// Paint padding using the [debugPaintPaddingColor],
/// [debugPaintPaddingInnerEdgeColor], and [debugPaintSpacingColor] colors.
///
/// Called by [RenderPadding.debugPaintSize] when [debugPaintSizeEnabled] is
/// true.
void debugPaintPadding(Canvas canvas, Rect outerRect, Rect innerRect, { double outlineWidth: 2.0 }) {
  assert(() {
    if (innerRect != null && !innerRect.isEmpty) {
      _debugDrawDoubleRect(canvas, outerRect, innerRect, debugPaintPaddingColor);
      _debugDrawDoubleRect(canvas, innerRect.inflate(outlineWidth).intersect(outerRect), innerRect, debugPaintPaddingInnerEdgeColor);
    } else {
      final Paint paint = new Paint()
        ..color = debugPaintSpacingColor;
      canvas.drawRect(outerRect, paint);
    }
    return true;
  });
}

/// Returns true if none of the rendering library debug variables have been changed.
///
/// This function is used by the test framework to ensure that debug variables
/// haven't been inadvertently changed.
///
/// See [https://docs.flutter.io/flutter/rendering/rendering-library.html] for
/// a complete list.
bool debugAssertAllRenderVarsUnset(String reason) {
  assert(() {
    if (debugPaintSizeEnabled ||
        debugPaintBaselinesEnabled ||
        debugPaintLayerBordersEnabled ||
        debugPaintPointersEnabled ||
        debugRepaintRainbowEnabled ||
        debugRepaintTextRainbowEnabled ||
        debugPrintMarkNeedsPaintStacks ||
        debugPrintMarkNeedsLayoutStacks ||
        debugCheckIntrinsicSizes ||
        debugProfilePaintsEnabled ||
        debugPaintSizeColor != _kDebugPaintSizeColor ||
        debugPaintSpacingColor != _kDebugPaintSpacingColor ||
        debugPaintPaddingColor != _kDebugPaintPaddingColor ||
        debugPaintPaddingInnerEdgeColor != _kDebugPaintPaddingInnerEdgeColor ||
        debugPaintBoxArrowColor != _kDebugPaintBoxArrowColor ||
        debugPaintSliverArrowColor != _kDebugPaintSliverArrowColor ||
        debugPaintAlphabeticBaselineColor != _kDebugPaintAlphabeticBaselineColor ||
        debugPaintIdeographicBaselineColor != _kDebugPaintIdeographicBaselineColor ||
        debugPaintLayerBordersColor != _kDebugPaintLayerBordersColor ||
        debugPaintPointersColorValue != _kDebugPaintPointersColorValue ||
        debugCurrentRepaintColor != _kDebugCurrentRepaintColor ||
        debugRepaintRainbowHueIncrement != _kDebugRepaintRainbowHueIncrement) {
      throw new FlutterError(reason);
    }
    return true;
  });
  return true;
}
