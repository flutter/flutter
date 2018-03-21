// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'object.dart';
import 'stack.dart';

// Describes which side the region data overflows on.
enum _OverflowSide {
  left,
  top,
  bottom,
  right,
}

// Data used by the DebugOverflowIndicator to manage the regions and labels for
// the indicators.
class _OverflowRegionData {
  const _OverflowRegionData({
    this.rect,
    this.label: '',
    this.labelOffset: Offset.zero,
    this.rotation: 0.0,
    this.side,
  });

  final Rect rect;
  final String label;
  final Offset labelOffset;
  final double rotation;
  final _OverflowSide side;
}

/// An mixin indicator that is drawn when a [RenderObject] overflows its
/// container.
///
/// This is used by some RenderObjects that are containers to show where, and by
/// how much, their children overflow their containers. These indicators are
/// typically only shown in a debug build (where the call to
/// [paintOverflowIndicator] is surrounded by an assert).
///
/// This class will also print a debug message to the console when the container
/// overflows. It will print on the first occurrence, and once after each time that
/// [reassemble] is called.
///
/// ## Sample code
///
/// ```dart
/// class MyRenderObject extends RenderAligningShiftedBox with DebugOverflowIndicatorMixin {
///   MyRenderObject({
///     AlignmentGeometry alignment,
///     TextDirection textDirection,
///     RenderBox child,
///   }) : super.mixin(alignment, textDirection, child);
///
///   Rect _containerRect;
///   Rect _childRect;
///
///   @override
///   void performLayout() {
///     // ...
///     final BoxParentData childParentData = child.parentData;
///     _containerRect = Offset.zero & size;
///     _childRect = childParentData.offset & child.size;
///   }
///
///   @override
///   void paint(PaintingContext context, Offset offset) {
///     // Do normal painting here...
///     // ...
///
///     assert(() {
///       paintOverflowIndicator(context, offset, _containerRect, _childRect);
///       return true;
///     }());
///   }
/// }
/// ```
///
/// See also:
///
///   * The code for [RenderUnconstrainedBox] and [RenderFlex] for examples of
///     classes that use this indicator mixin.
abstract class DebugOverflowIndicatorMixin extends RenderObject {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory DebugOverflowIndicatorMixin._() => null;

  static const Color _black = const Color(0xBF000000);
  static const Color _yellow = const Color(0xBFFFFF00);
  // The fraction of the container that the indicator covers.
  static const double _indicatorFraction = 0.1;
  static const double _indicatorFontSizePixels = 7.5;
  static const double _indicatorLabelPaddingPixels = 1.0;
  static const TextStyle _indicatorTextStyle = const TextStyle(
    color: const Color(0xFF900000),
    fontSize: _indicatorFontSizePixels,
    fontWeight: FontWeight.w800,
  );
  static final Paint _indicatorPaint = new Paint()
    ..shader = new ui.Gradient.linear(
      const Offset(0.0, 0.0),
      const Offset(10.0, 10.0),
      <Color>[_black, _yellow, _yellow, _black],
      <double>[0.25, 0.25, 0.75, 0.75],
      TileMode.repeated,
    );
  static final Paint _labelBackgroundPaint = new Paint()..color = const Color(0xFFFFFFFF);

  final List<TextPainter> _indicatorLabel = new List<TextPainter>.filled(
    _OverflowSide.values.length,
    new TextPainter(textDirection: TextDirection.ltr), // This label is in English.
  );

  // Set to true to trigger a debug message in the console upon
  // the next paint call. Will be reset after each paint.
  bool _overflowReportNeeded = true;

  String _formatPixels(double value) {
    assert(value > 0.0);
    String pixels;
    if (value > 10.0) {
      pixels = value.toStringAsFixed(0);
    } else if (value > 1.0) {
      pixels = value.toStringAsFixed(1);
    } else {
      pixels = value.toStringAsPrecision(3);
    }
    return pixels;
  }

  List<_OverflowRegionData> _calculateOverflowRegions(RelativeRect overflow, Rect containerRect) {
    final List<_OverflowRegionData> regions = <_OverflowRegionData>[];
    if (overflow.left > 0.0) {
      final Rect markerRect = new Rect.fromLTWH(
        0.0,
        0.0,
        containerRect.width * _indicatorFraction,
        containerRect.height,
      );
      regions.add(new _OverflowRegionData(
        rect: markerRect,
        label: 'LEFT OVERFLOWED BY ${_formatPixels(overflow.left)} PIXELS',
        labelOffset: markerRect.centerLeft +
            const Offset(_indicatorFontSizePixels + _indicatorLabelPaddingPixels, 0.0),
        rotation: math.pi / 2.0,
        side: _OverflowSide.left,
      ));
    }
    if (overflow.right > 0.0) {
      final Rect markerRect = new Rect.fromLTWH(
        containerRect.width * (1.0 - _indicatorFraction),
        0.0,
        containerRect.width * _indicatorFraction,
        containerRect.height,
      );
      regions.add(new _OverflowRegionData(
        rect: markerRect,
        label: 'RIGHT OVERFLOWED BY ${_formatPixels(overflow.right)} PIXELS',
        labelOffset: markerRect.centerRight -
            const Offset(_indicatorFontSizePixels + _indicatorLabelPaddingPixels, 0.0),
        rotation: -math.pi / 2.0,
        side: _OverflowSide.right,
      ));
    }
    if (overflow.top > 0.0) {
      final Rect markerRect = new Rect.fromLTWH(
        0.0,
        0.0,
        containerRect.width,
        containerRect.height * _indicatorFraction,
      );
      regions.add(new _OverflowRegionData(
        rect: markerRect,
        label: 'TOP OVERFLOWED BY ${_formatPixels(overflow.top)} PIXELS',
        labelOffset: markerRect.topCenter + const Offset(0.0, _indicatorLabelPaddingPixels),
        rotation: 0.0,
        side: _OverflowSide.top,
      ));
    }
    if (overflow.bottom > 0.0) {
      final Rect markerRect = new Rect.fromLTWH(
        0.0,
        containerRect.height * (1.0 - _indicatorFraction),
        containerRect.width,
        containerRect.height * _indicatorFraction,
      );
      regions.add(new _OverflowRegionData(
        rect: markerRect,
        label: 'BOTTOM OVERFLOWED BY ${_formatPixels(overflow.bottom)} PIXELS',
        labelOffset: markerRect.bottomCenter -
            const Offset(0.0, _indicatorFontSizePixels + _indicatorLabelPaddingPixels),
        rotation: 0.0,
        side: _OverflowSide.bottom,
      ));
    }
    return regions;
  }

  void _reportOverflow(RelativeRect overflow, String overflowHints) {
    overflowHints ??= 'The edge of the $runtimeType that is '
      'overflowing has been marked in the rendering with a yellow and black '
      'striped pattern. This is usually caused by the contents being too big '
      'for the $runtimeType.\n'
      'This is considered an error condition because it indicates that there '
      'is content that cannot be seen. If the content is legitimately bigger '
      'than the available space, consider clipping it with a ClipRect widget '
      'before putting it in the $runtimeType, or using a scrollable '
      'container, like a ListView.';

    final List<String> overflows = <String>[];
    if (overflow.left > 0.0)
      overflows.add('${_formatPixels(overflow.left)} pixels on the left');
    if (overflow.top > 0.0)
      overflows.add('${_formatPixels(overflow.top)} pixels on the top');
    if (overflow.bottom > 0.0)
      overflows.add('${_formatPixels(overflow.bottom)} pixels on the bottom');
    if (overflow.right > 0.0)
      overflows.add('${_formatPixels(overflow.right)} pixels on the right');
    String overflowText = '';
    assert(overflows.isNotEmpty,
        "Somehow $runtimeType didn't actually overflow like it thought it did.");
    switch (overflows.length) {
      case 1:
        overflowText = overflows.first;
        break;
      case 2:
        overflowText = '${overflows.first} and ${overflows.last}';
        break;
      default:
        overflows[overflows.length - 1] = 'and ${overflows[overflows.length - 1]}';
        overflowText = overflows.join(', ');
    }
    FlutterError.reportError(
      new FlutterErrorDetailsForRendering(
        exception: 'A $runtimeType overflowed by $overflowText.',
        library: 'rendering library',
        context: 'during layout',
        renderObject: this,
        informationCollector: (StringBuffer information) {
          information.writeln(overflowHints);
          information.writeln('The specific $runtimeType in question is:');
          information.writeln('  ${toStringShallow(joiner: '\n  ')}');
          information.writeln('◢◤' * (FlutterError.wrapWidth ~/ 2));
        },
      ),
    );
  }

  /// To be called when the overflow indicators should be painted.
  ///
  /// Typically only called if there is an overflow, and only from within a
  /// debug build.
  ///
  /// See example code in [DebugOverflowIndicatorMixin] documentation.
  void paintOverflowIndicator(
    PaintingContext context,
    Offset offset,
    Rect containerRect,
    Rect childRect, {
    String overflowHints,
  }) {
    final RelativeRect overflow = new RelativeRect.fromRect(containerRect, childRect);

    if (overflow.left <= 0.0 &&
        overflow.right <= 0.0 &&
        overflow.top <= 0.0 &&
        overflow.bottom <= 0.0) {
      return;
    }

    final List<_OverflowRegionData> overflowRegions = _calculateOverflowRegions(overflow, containerRect);
    for (_OverflowRegionData region in overflowRegions) {
      context.canvas.drawRect(region.rect.shift(offset), _indicatorPaint);

      if (_indicatorLabel[region.side.index].text?.text != region.label) {
        _indicatorLabel[region.side.index].text = new TextSpan(
          text: region.label,
          style: _indicatorTextStyle,
        );
        _indicatorLabel[region.side.index].layout();
      }

      final Offset labelOffset = region.labelOffset + offset;
      final Offset centerOffset = new Offset(-_indicatorLabel[region.side.index].width / 2.0, 0.0);
      final Rect textBackgroundRect = centerOffset & _indicatorLabel[region.side.index].size;
      context.canvas.save();
      context.canvas.translate(labelOffset.dx, labelOffset.dy);
      context.canvas.rotate(region.rotation);
      context.canvas.drawRect(textBackgroundRect, _labelBackgroundPaint);
      _indicatorLabel[region.side.index].paint(context.canvas, centerOffset);
      context.canvas.restore();
    }

    if (_overflowReportNeeded) {
      _overflowReportNeeded = false;
      _reportOverflow(overflow, overflowHints);
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Users expect error messages to be shown again after hot reload.
    assert(() {
      _overflowReportNeeded = true;
      return true;
    }());
  }
}
