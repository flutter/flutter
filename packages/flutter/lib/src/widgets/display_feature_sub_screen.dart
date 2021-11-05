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
import 'overlay.dart';

/// Positions [child] such that it avoids overlapping any [DisplayFeature] that
/// splits the screen into sub-screens.
///
/// A [DisplayFeature] splits the screen into sub-screens if it is at least as
/// tall, producing a left and right sub-screen, or at least as wide, producing
/// a top and bottom sub-screen. This applies to sub-screens as well.
///
/// After determining the sub-screens, the closest one to [anchorPoint] is used
/// to render the [child].
///
/// If no [anchorPoint] is provided, then [Directionality] is used:
///  * for [TextDirection.ltr], [anchorPoint] is `Offset.zero`, leading the
///  sub-screen in the top-left to be used.
///  * for [TextDirection.rtl], [anchorPoint] is `Offset(double.maxFinite, 0)`,
///  leading the subscreen in the top-right to be used.
///
/// If no [anchorPoint] is provided, and there is no [Directionality] ancestor
/// widget is in the tree, then the widget throws during build.
///
/// In order to determine how the child intersects with
/// [MediaQueryData.displayFeatures] this widget also needs to know its own
/// size and position relative to the screen edge. The [padding] can be used to
/// directly specify this information. If it is not provided, the first
/// [Overlay] is used to determine this information. If no [Overlay] parent
/// exists, [DisplayFeatureSubScreen] assumes it is positioned at [Offset.zero]
/// with the size [MediaQueryData.size].
///
/// See also:
///
///  * [showDialog], which is a way to display a DialogRoute.
///  * [showCupertinoDialog], which displays an iOS-style dialog.
class DisplayFeatureSubScreen extends StatelessWidget {
  /// Creates a widget that positions its child so that it avoids display
  /// features.
  const DisplayFeatureSubScreen({
    Key? key,
    required this.child,
    this.anchorPoint,
    this.padding,
  }) : super(key: key);

  /// The child that will avoid the display features.
  final Widget child;

  /// The anchor point used to pick the closest area that has no display
  /// features.
  ///
  /// If the anchor point sits inside one of these areas, then that area is
  /// picked. If not, then the area with the closest edge to the point is used.
  ///
  /// `Offset(0,0)` is the top-left corner of the available screen space. For
  /// a dual-screen device, this is the top-left corner of the left screen.
  final Offset? anchorPoint;

  /// The distance from the edge of the screen, used to determine how
  /// [DisplayFeatureSubScreen] intersects [MediaQueryData.displayFeatures].
  ///
  /// When [DisplayFeatureSubScreen] is not the root layout and the distance
  /// from the screen edge increases due to padding added by parent layout, the
  /// [padding] needs to be updated.
  ///
  /// When [padding] is not provided, [DisplayFeatureSubScreen] assumes it is
  /// a direct child inside [Overlay] and uses the position and size of the
  /// [Overlay] as the distance to the edge of the screen.
  ///
  /// If no [padding] is provided and no [Overlay] parent exists in the tree,
  /// [DisplayFeatureSubScreen] assumes there is no distance to the edge of the
  /// screen and that the available space for layout is [MediaQueryData.size].
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final Rect availableSpace = _availableSpace(context);
    final Iterable<Rect> safeAreas = _safeAreasInBounds(context, availableSpace);
    final Rect safeArea = anchorPoint == null
        ? _firstSafeArea(safeAreas, context)
        : _closestToAnchorPoint(safeAreas, _finiteOffset(anchorPoint!));

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(left: safeArea.left, top: safeArea.top),
        child: SizedBox(
          width: safeArea.width,
          height: safeArea.height,
          child: child,
        ),
      ),
    );
  }

  static Rect _firstSafeArea(Iterable<Rect> safeAreas, BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);
    switch (textDirection) {
      case TextDirection.rtl:
        return _closestToAnchorPoint(safeAreas, const Offset(double.maxFinite, 0));
      case TextDirection.ltr:
        return _closestToAnchorPoint(safeAreas, Offset.zero);
    }
  }

  static Rect _closestToAnchorPoint(Iterable<Rect> safeAreas, Offset anchorPoint) {
    return safeAreas.fold(safeAreas.first, (Rect previousValue, Rect element) {
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

  Rect _availableSpace(BuildContext context){
    if (padding != null) {
      return padding!.deflateRect(Offset.zero & MediaQuery.of(context).size);
    } else {
      final RenderObject? renderObject = Overlay.of(context)?.context.findRenderObject();
      if (renderObject != null) {
        final RenderBox box = renderObject as RenderBox;
        if (box.hasSize && box.size.isFinite) {
          return MatrixUtils.transformRect(
            box.getTransformTo(null),
            Offset.zero & box.size,
          );
        }
      }
    }
    return Offset.zero & MediaQuery.of(context).size;
  }

  static Iterable<Rect> _safeAreasInBounds(BuildContext context, Rect bounds) {
    final Iterable<Rect> avoidBounds = MediaQuery.of(context).displayFeatures
        .where((DisplayFeature displayFeature) => displayFeature.bounds.overlaps(bounds))
        .map((DisplayFeature displayFeature) => displayFeature.bounds.shift(-bounds.topLeft));
    return _safeAreas(Rect.fromLTWH(0, 0, bounds.width, bounds.height), avoidBounds);
  }

  static Iterable<Rect> _safeAreas(Rect screen, Iterable<Rect> avoidBounds) {
    Iterable<Rect> areas = <Rect>[screen];
    for (final Rect bounds in avoidBounds) {
      areas = areas.expand((Rect area) sync* {
        if (area.top >= bounds.top && area.bottom <= bounds.bottom) {
          // Display feature splits the area vertically
          if (area.left < bounds.left) {
            // There is a smaller area, left of the display feature
            yield Rect.fromLTWH(area.left, area.top, bounds.left - area.left, area.height);
          }
          if (area.right > bounds.right) {
            // There is a smaller area, right of the display feature
            yield Rect.fromLTWH(bounds.right, area.top, area.right - bounds.right, area.height);
          }
        } else if (area.left >= bounds.left && area.right <= bounds.right) {
          // Display feature splits the area horizontally
          if (area.top < bounds.top) {
            // There is a smaller area, above the display feature
            yield Rect.fromLTWH(area.left, area.top, area.width, bounds.top - area.top);
          }
          if (area.bottom > bounds.bottom) {
            // There is a smaller area, below the display feature
            yield Rect.fromLTWH(area.left, bounds.bottom, area.width, area.bottom - bounds.bottom);
          }
        } else {
          yield area;
        }
      });
    }
    return areas;
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
}
