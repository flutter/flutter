// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show DisplayFeature;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';

/// Positions [child] such that it avoids overlapping any [DisplayFeature] that
/// splits the screen into sub-screens.
///
/// A [DisplayFeature] splits the screen into sub-screens if it is at least as
/// tall as the screen, producing a left and right sub-screen, or at least as
/// wide as the screen, producing a top and bottom sub-screen.
///
/// After determining the sub-screens, the closest one to [anchorPoint] is used
/// to render the [child].
///
/// If no [anchorPoint] is provided, then [Directionality] is used:
///  * for [TextDirection.ltr], [anchorPoint] is `Offset.zero`, which will cause
///  the [child] to appear in the top-left sub-screen.
///  * for [TextDirection.rtl], [anchorPoint] is `Offset(double.maxFinite, 0)`,
///  which will cause the [child] to appear in the top-right sub-screen.
///
/// If no [anchorPoint] is provided, and there is no [Directionality] ancestor
/// widget in the tree, then the widget throws during build.
///
/// See also:
///
///  * [showDialog], which is a way to display a DialogRoute.
///  * [showCupertinoDialog], which displays an iOS-style dialog.
class DisplayFeatureSubScreen extends SingleChildRenderObjectWidget {
  /// Creates a widget that positions its child so that it avoids display
  /// features.
  const DisplayFeatureSubScreen({
    Key? key,
    this.anchorPoint,
    Widget? child,
  }) : super(key: key, child: child);

  /// The anchor point used to pick the closest sub-screen.
  ///
  /// If the anchor point sits inside one of these sub-screens, then that
  /// sub-screen is picked. If not, then the sub-screen with the closest edge to
  /// the point is used.
  ///
  /// `Offset(0,0)` is the top-left corner of the available screen space. For
  /// a dual-screen device, this is the top-left corner of the left screen.
  final Offset? anchorPoint;

  static Offset _fallbackAnchorPoint(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);
    switch (textDirection) {
      case TextDirection.rtl:
        return const Offset(double.maxFinite, 0);
      case TextDirection.ltr:
        return Offset.zero;
    }
  }

  @override
  RenderDisplayFeatureSubScreen createRenderObject(BuildContext context) {
    return RenderDisplayFeatureSubScreen(
      anchorPoint: anchorPoint ?? _fallbackAnchorPoint(context),
      avoidBounds: MediaQuery.of(context).displayFeatures
          .map((DisplayFeature e) => e.bounds)
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderDisplayFeatureSubScreen renderObject) {
    renderObject.anchorPoint = anchorPoint ?? _fallbackAnchorPoint(context);
    renderObject.avoidBounds = MediaQuery.of(context).displayFeatures
        .map((DisplayFeature e) => e.bounds);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('anchorPoint', anchorPoint));
    //TODO: Add other relevant properties
  }
}

/// Positions and sizes its child to fill a sub-screen.
///
/// This occupies the maximum space it is allowed and then positions its child
/// using global information. Both [anchorPoint] and [avoidBounds] are expressed
/// in global coordinates. An [anchorPoint] with value `Offset.zero` means the
/// top-left corner of the available screen space. [avoidBouds] are all the
/// bounds of the [MediaQueryData.displayFeatures].
///
/// See also:
///
///  * [DisplayFeatureSubScreen] to understand how sub-screens are defined
class RenderDisplayFeatureSubScreen extends RenderShiftedBox {
  /// Creates a render object that positions and sizes its child.
  RenderDisplayFeatureSubScreen({
    required Iterable<Rect> avoidBounds,
    required Offset anchorPoint,
    RenderBox? child,
  }) : assert(anchorPoint != null),
        assert(avoidBounds != null),
        _anchorPoint = anchorPoint,
        _avoidBounds = avoidBounds,
        super(child);

  /// The anchor point used to pick the closest sub-screen.
  Offset get anchorPoint => _anchorPoint;
  Offset _anchorPoint;
  set anchorPoint(Offset value) {
    assert(value != null);
    if (_anchorPoint == value)
      return;
    _anchorPoint = value;
    markNeedsLayout();
  }

  /// Areas of the screen that this render object uses to determine where the
  /// sub-screens are positioned.
  Iterable<Rect> get avoidBounds => _avoidBounds;
  Iterable<Rect> _avoidBounds;
  set avoidBounds(Iterable<Rect> value) {
    assert(value != null);
    if (_iterableEquals<Rect>(_avoidBounds, value))
      return;
    _avoidBounds = value;
    markNeedsLayout();
  }

  /// This render object needs to know its own size and position on the screen
  /// in order to properly position its child. The global offset is not
  /// available during layout, since ancestors of this render object are not yet
  /// done positioning their children. This is why we cache the position
  /// obtained during the paint phase. When the global offset changes during
  /// paint, this render object marks itself as needing layout.
  Offset _lastOffset = Offset.zero;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    if (child == null)
      return;
    if (avoidBounds.isEmpty) {
      child!.layout(BoxConstraints.tight(size));
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      childParentData.offset = Offset.zero;
    } else {
      final Rect wantedBounds = _lastOffset & size;
      final Iterable<Rect> subScreens = _subScreensInBounds(wantedBounds, avoidBounds);
      final Rect closestSubScreen = _closestToAnchorPoint(subScreens, _finiteOffset(anchorPoint));

      child!.layout(BoxConstraints.tight(closestSubScreen.size));
      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      childParentData.offset = closestSubScreen.topLeft - _lastOffset;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (offset != _lastOffset) {
      _lastOffset = offset;
      RendererBinding.instance!.addPostFrameCallback((Duration value) {
        markNeedsLayout();
      });
    }
    super.paint(context, offset);
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      //TODO: Show the display features and the anchorPoint
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('anchorPoint', anchorPoint));
    properties.add(IterableProperty<Rect>('avoidBounds', avoidBounds));
  }

  /// Returns the closest sub-screen to the [anchorPoint]
  static Rect _closestToAnchorPoint(Iterable<Rect> subScreens, Offset anchorPoint) {
    return subScreens.fold(subScreens.first, (Rect previousValue, Rect element) {
      final double previousDistance = _distanceFromPointToRect(anchorPoint, previousValue);
      final double elementDistance = _distanceFromPointToRect(anchorPoint, element);
      if (previousDistance < elementDistance)
        return previousValue;
      else
        return element;
    });
  }

  static double _distanceFromPointToRect(Offset point, Rect rect){
    // Cases for point position relative to rect:
    // 1  2  3
    // 4 [R] 5
    // 6  7  8
    if (point.dx < rect.left) {
      if (point.dy < rect.top) {
        // Case 1
        return (point - rect.topLeft).distance;
      } else if (point.dy > rect.bottom){
        // Case 6
        return (point - rect.bottomLeft).distance;
      } else {
        // Case 4
        return rect.left - point.dx;
      }
    } else if (point.dx > rect.right) {
      if (point.dy < rect.top) {
        // Case 3
        return (point - rect.topRight).distance;
      } else if (point.dy > rect.bottom){
        // Case 8
        return (point - rect.bottomRight).distance;
      } else {
        // Case 5
        return point.dx - rect.right;
      }
    } else {
      if (point.dy < rect.top) {
        // Case 2
        return rect.top - point.dy;
      } else if (point.dy > rect.bottom){
        // Case 7
        return point.dy - rect.bottom;
      } else {
        // Case R
        return 0;
      }
    }
  }

  /// Returns sub-screens resulted by dividing [wantedBounds] along items of
  /// [avoidBounds] that are at least as high or as wide.
  static Iterable<Rect> _subScreensInBounds(Rect wantedBounds, Iterable<Rect> avoidBounds) {
    Iterable<Rect> subScreens = <Rect>[wantedBounds];
    for (final Rect bounds in avoidBounds) {
      subScreens = subScreens.expand((Rect screen) sync* {
        if (screen.top >= bounds.top && screen.bottom <= bounds.bottom) {
          // Display feature splits the screen vertically
          if (screen.left < bounds.left) {
            // There is a smaller sub-screen, left of the display feature
            yield Rect.fromLTWH(screen.left, screen.top, bounds.left - screen.left, screen.height);
          }
          if (screen.right > bounds.right) {
            // There is a smaller sub-screen, right of the display feature
            yield Rect.fromLTWH(bounds.right, screen.top, screen.right - bounds.right, screen.height);
          }
        } else if (screen.left >= bounds.left && screen.right <= bounds.right) {
          // Display feature splits the sub-screen horizontally
          if (screen.top < bounds.top) {
            // There is a smaller sub-screen, above the display feature
            yield Rect.fromLTWH(screen.left, screen.top, screen.width, bounds.top - screen.top);
          }
          if (screen.bottom > bounds.bottom) {
            // There is a smaller sub-screen, below the display feature
            yield Rect.fromLTWH(screen.left, bounds.bottom, screen.width, screen.bottom - bounds.bottom);
          }
        } else {
          yield screen;
        }
      });
    }
    return subScreens;
  }

  static Offset _finiteOffset(Offset offset){
    if (offset.isFinite) {
      return offset;
    } else {
      return Offset(_finiteNumber(offset.dx), _finiteNumber(offset.dy));
    }
  }

  static double _finiteNumber(double nr){
    if (!nr.isInfinite) {
      return nr;
    }
    return nr.isNegative ? -double.maxFinite : double.maxFinite;
  }

  static bool _iterableEquals<T>(Iterable<T> a, Iterable<T> b){
    if (identical(a,b)) {
      return true;
    }
    final Iterator<T> aIterator = a.iterator;
    final Iterator<T> bIterator = b.iterator;
    while (true) {
      final bool hasNext = aIterator.moveNext();
      if (hasNext != bIterator.moveNext()) {
        return false;
      }
      if (!hasNext) {
        return true;
      }
      if (aIterator.current != bIterator.current) {
        return false;
      }
    }
  }
}
