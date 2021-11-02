// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show DisplayFeature;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';
import 'overlay.dart';

/// Positions [child] such that it avoids overlapping any [DisplayFeature] that
/// splits the screen into sub-screens.
///
/// After determining the sub-screens, the closest one to [anchorPoint] is used
/// render the [child].
///
/// If no [anchorPoint] is provided, then [Directionality] is used. If no
/// [Directionality] and no [anchorPoint] are provided, then the top-left screen
/// is used.
///
/// See also:
///
///  * [showDialog], which is a way to display a DialogRoute.
///  * [showCupertinoDialog], which displays an iOS-style dialog.
class DisplayFeatureSubScreen extends StatelessWidget {
  /// Creates a widget that positions its child so that it avoids display features.
  const DisplayFeatureSubScreen({
    Key? key,
    required this.child,
    this.anchorPoint,
  }) : super(key: key);

  /// The child that will avoid the display features.
  final Widget child;

  /// The anchor point used to pick the closest area that has no display features.
  /// `Offset(0,0)` is the top-left corner of the available screen space. For
  /// a dual-screen device, this is the top-left corner of the left screen.
  final Offset? anchorPoint;

  @override
  Widget build(BuildContext context) {
    final List<Rect> safeAreas = _safeAreasInNavigator(context);
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

  static Rect _firstSafeArea(List<Rect> safeAreas, BuildContext context) {
    final TextDirection? textDirection = Directionality.maybeOf(context);
    if (textDirection == TextDirection.rtl)
      return _closestToAnchorPoint(safeAreas, const Offset(double.maxFinite, 0));
    else
      return _closestToAnchorPoint(safeAreas, Offset.zero);
  }

  static Rect _closestToAnchorPoint(List<Rect> safeAreas, Offset anchorPoint) {
    return safeAreas.fold(safeAreas.first, (Rect previousValue, Rect element) {
      final double previousDistance = (previousValue.center - anchorPoint).distanceSquared;
      final double elementDistance = (element.center - anchorPoint).distanceSquared;
      if (previousDistance < elementDistance)
        return previousValue;
      else
        return element;
    });
  }

  static List<Rect> _safeAreasInNavigator(BuildContext context) {
    final RenderObject? renderObject = Overlay.of(context)?.context.findRenderObject();
    Rect? navigatorBounds;
    final Vector3? translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null) {
      navigatorBounds = renderObject?.paintBounds.shift(Offset(translation.x, translation.y));
    }
    List<Rect> avoidBounds;
    if (navigatorBounds == null) {
      final Size screenSize = MediaQuery.of(context).size;
      navigatorBounds = Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
      avoidBounds = MediaQuery.of(context).displayFeatures
          .map((DisplayFeature displayFeature) => displayFeature.bounds)
          .toList();
    } else {
      avoidBounds = MediaQuery.of(context).displayFeatures
          .where((DisplayFeature displayFeature) => displayFeature.bounds.overlaps(navigatorBounds!))
          .map((DisplayFeature displayFeature) => displayFeature.bounds.shift(-navigatorBounds!.topLeft))
          .toList();
    }
    return _safeAreas(Rect.fromLTWH(0, 0, navigatorBounds.width, navigatorBounds.height), avoidBounds);
  }

  static List<Rect> _safeAreas(Rect screen, List<Rect> avoidBounds) {
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
    return areas.toList();
  }

  static Offset _finiteOffset(Offset offset){
    if (offset.isFinite) {
      return offset;
    } else {
      return Offset(_finiteNumber(offset.dx), _finiteNumber(offset.dy));
    }
  }

  static double _finiteNumber(double nr){
    if (nr.isInfinite && nr.isNegative) {
      return -double.maxFinite;
    } else if (nr.isInfinite && !nr.isNegative) {
      return double.maxFinite;
    } else {
      return nr;
    }
  }
}
