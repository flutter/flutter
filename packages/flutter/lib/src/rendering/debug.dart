// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart';

export 'package:flutter/foundation.dart' show debugPrint;

// Any changes to this file should be reflected in the debugAssertAllRenderVarsUnset()
// function below.

/// Used by [debugDumpSemanticsTree] to specify the order in which child nodes
/// are printed.
enum DebugSemanticsDumpOrder {
  /// Print nodes in inverse hit test order.
  ///
  /// In inverse hit test order, the last child of a [SemanticsNode] will be
  /// asked first if it wants to respond to a user's interaction, followed by
  /// the second last, etc. until a taker is found.
  inverseHitTest,

  /// Print nodes in traversal order.
  ///
  /// Traversal order defines how the user can move the accessibility focus from
  /// one node to another.
  traversal,
}

const HSVColor _kDebugDefaultRepaintColor = const HSVColor.fromAHSV(0.4, 60.0, 1.0, 1.0);

/// Causes each RenderBox to paint a box around its bounds, and some extra
/// boxes, such as [RenderPadding], to draw construction lines.
///
/// The edges of boies are painted as a one-pixel-thick `const Color(0xFF00FFFF)` outline.
///
/// Spacing is painted as a solid `const Color(0x90909090)` area.
///
/// Padding is filled in solid `const Color(0x900090FF)`, with the inner edge
/// outlined in `const Color(0xFF0090FF)`, using [debugPaintPadding].
bool debugPaintSizeEnabled = false;

/// Causes each RenderBox to paint a line at each of its baselines.
bool debugPaintBaselinesEnabled = false;

/// Causes each Layer to paint a box around its bounds.
bool debugPaintLayerBordersEnabled = false;

/// Causes objects like [RenderPointerListener] to flash while they are being
/// tapped. This can be useful to see how large the hit box is, e.g. when
/// debugging buttons that are harder to hit than expected.
///
/// For details on how to support this in your [RenderBox] subclass, see
/// [RenderBox.debugHandleEvent].
bool debugPaintPointersEnabled = false;

/// Overlay a rotating set of colors when repainting layers in checked mode.
bool debugRepaintRainbowEnabled = false;

/// Overlay a rotating set of colors when repainting text in checked mode.
bool debugRepaintTextRainbowEnabled = false;

/// The current color to overlay when repainting a layer.
///
/// This is used by painting debug code that implements
/// [debugRepaintRainbowEnabled] or [debugRepaintTextRainbowEnabled].
///
/// The value is incremented by [RenderView.compositeFrame] if either of those
/// flags is enabled.
HSVColor debugCurrentRepaintColor = _kDebugDefaultRepaintColor;

/// Log the call stacks that mark render objects as needing layout.
///
/// For sanity, this only logs the stack traces of cases where an object is
/// added to the list of nodes needing layout. This avoids printing multiple
/// redundant stack traces as a single [RenderObject.markNeedsLayout] call walks
/// up the tree.
bool debugPrintMarkNeedsLayoutStacks = false;

/// Log the call stacks that mark render objects as needing paint.
bool debugPrintMarkNeedsPaintStacks = false;

/// Log the dirty render objects that are laid out each frame.
///
/// Combined with [debugPrintBeginFrameBanner], this allows you to distinguish
/// layouts triggered by the initial mounting of a render tree (e.g. in a call
/// to [runApp]) from the regular layouts triggered by the pipeline.
///
/// Combined with [debugPrintMarkNeedsLayoutStacks], this lets you watch a
/// render object's dirty/clean lifecycle.
///
/// See also:
///
///  * [debugProfilePaintsEnabled], which does something similar for
///    painting but using the timeline view.
///
///  * [debugPrintRebuildDirtyWidgets], which does something similar for widgets
///    being rebuilt.
///
///  * The discussion at [RendererBinding.drawFrame].
bool debugPrintLayouts = false;

/// Check the intrinsic sizes of each [RenderBox] during layout.
///
/// By default this is turned off since these checks are expensive, but it is
/// enabled by the test framework.
bool debugCheckIntrinsicSizes = false;

/// Adds [dart:developer.Timeline] events for every [RenderObject] painted.
///
/// This is only enabled in debug builds. The timing information this exposes is
/// not representative of actual paints. However, it can expose unexpected
/// painting in the timeline.
///
/// For details on how to use [dart:developer.Timeline] events in the Dart
/// Observatory to optimize your app, see:
/// <https://fuchsia.googlesource.com/sysui/+/master/docs/performance.md>
///
/// See also:
///
///  * [debugPrintLayouts], which does something similar for layout but using
///    console output.
///
///  * [debugProfileBuildsEnabled], which does something similar for widgets
///    being rebuilt, and [debugPrintRebuildDirtyWidgets], its console
///    equivalent.
///
///  * The discussion at [RendererBinding.drawFrame].
bool debugProfilePaintsEnabled = false;


/// Returns a list of strings representing the given transform in a format
/// useful for [TransformProperty].
///
/// If the argument is null, returns a list with the single string "null".
List<String> debugDescribeTransform(Matrix4 transform) {
  if (transform == null)
    return const <String>['null'];
  final List<String> matrix = transform.toString().split('\n').map((String s) => '  $s').toList();
  matrix.removeLast();
  return matrix;
}

/// Property which handles [Matrix4] that represent transforms.
class TransformProperty extends DiagnosticsProperty<Matrix4> {
  /// Create a diagnostics property for [Matrix4] objects.
  ///
  /// The [showName] argument must not be null.
  TransformProperty(String name, Matrix4 value, {
    bool showName: true,
    Object defaultValue: kNoDefaultValue,
  }) : assert(showName != null), super(
    name,
    value,
    showName: showName,
    defaultValue: defaultValue,
  );

  @override
  String valueToString({ TextTreeConfiguration parentConfiguration }) {
    if (parentConfiguration != null && !parentConfiguration.lineBreakProperties) {
      // Format the value on a single line to be compatible with the parent's
      // style.
      final List<Vector4> rows = <Vector4>[
        value.getRow(0),
        value.getRow(1),
        value.getRow(2),
        value.getRow(3),
      ];
      return '[${rows.join("; ")}]';
    }
    return debugDescribeTransform(value).join('\n');
  }
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

/// Paint a diagram showing the given area as padding.
///
/// Called by [RenderPadding.debugPaintSize] when [debugPaintSizeEnabled] is
/// true.
void debugPaintPadding(Canvas canvas, Rect outerRect, Rect innerRect, { double outlineWidth: 2.0 }) {
  assert(() {
    if (innerRect != null && !innerRect.isEmpty) {
      _debugDrawDoubleRect(canvas, outerRect, innerRect, const Color(0x900090FF));
      _debugDrawDoubleRect(canvas, innerRect.inflate(outlineWidth).intersect(outerRect), innerRect, const Color(0xFF0090FF));
    } else {
      final Paint paint = new Paint()
        ..color = const Color(0x90909090);
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
/// See <https://docs.flutter.io/flutter/rendering/rendering-library.html> for
/// a complete list.
///
/// The `debugCheckIntrinsicSizesOverride` argument can be provided to override
/// the expected value for [debugCheckIntrinsicSizes]. (This exists because the
/// test framework itself overrides this value in some cases.)
bool debugAssertAllRenderVarsUnset(String reason, { bool debugCheckIntrinsicSizesOverride: false }) {
  assert(() {
    if (debugPaintSizeEnabled ||
        debugPaintBaselinesEnabled ||
        debugPaintLayerBordersEnabled ||
        debugPaintPointersEnabled ||
        debugRepaintRainbowEnabled ||
        debugRepaintTextRainbowEnabled ||
        debugCurrentRepaintColor != _kDebugDefaultRepaintColor ||
        debugPrintMarkNeedsLayoutStacks ||
        debugPrintMarkNeedsPaintStacks ||
        debugPrintLayouts ||
        debugCheckIntrinsicSizes != debugCheckIntrinsicSizesOverride ||
        debugProfilePaintsEnabled) {
      throw new FlutterError(reason);
    }
    return true;
  });
  return true;
}
