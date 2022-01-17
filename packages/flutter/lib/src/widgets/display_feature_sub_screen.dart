// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show DisplayFeature;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';

/// Positions [child] such that it avoids overlapping any [DisplayFeature] that
/// splits the screen into sub-screens.
///
/// A [DisplayFeature] splits the screen into sub-screens if
///  - it obstructs the screen, meaning the area it occupies is not 0. Display
///  features of type [DisplayFeatureType.fold] can have height 0 or width 0 and
///  not be obstructing the screen.
///  - it is at least as tall as the screen, producing a left and right
///  sub-screen or
///  - it is at least as wide as the screen, producing a top and bottom
///  sub-screen
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
/// Similarly to [SafeArea], this widget assumes there is no added padding
/// between it and the first [MediaQuery] ancestor. The [child] is wrapped in a
/// new [MediaQuery] instance containing the [DisplayFeature]s that exist in the
/// selected sub-screen, with coordinates relative to the sub-screen. Padding is
/// also adjusted to zero out any sides that were avoided by this widget.
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
    this.anchorPoint,
    required this.child,
  }) : super(key: key);

  /// The anchor point used to pick the closest sub-screen.
  ///
  /// If the anchor point sits inside one of these sub-screens, then that
  /// sub-screen is picked. If not, then the sub-screen with the closest edge to
  /// the point is used.
  ///
  /// `Offset(0,0)` is the top-left corner of the available screen space. For
  /// a dual-screen device, this is the top-left corner of the left screen.
  final Offset? anchorPoint;

  /// The widget below this widget in the tree.
  ///
  /// The padding on the [MediaQuery] for the [child] will be suitably adjusted
  /// to zero out any sides that were avoided by this widget. The [MediaQuery]
  /// for the [child] will no longer contain any display features that split the
  /// screen into sub-screens.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final Size parentSize = mediaQuery.size;
    final Rect wantedBounds = Offset.zero & parentSize;
    final Offset _anchorPoint =
        _finiteOffset(anchorPoint ?? _fallbackAnchorPoint(context));
    final Iterable<Rect> subScreens =
        _subScreensInBounds(wantedBounds, _avoidBounds(mediaQuery));
    final Rect closestSubScreen =
        _closestToAnchorPoint(subScreens, _anchorPoint);

    return Padding(
      padding: EdgeInsets.only(
        left: closestSubScreen.left,
        top: closestSubScreen.top,
        right: parentSize.width - closestSubScreen.right,
        bottom: parentSize.height - closestSubScreen.bottom,
      ),
      child: MediaQuery(
        data: mediaQuery.removeDisplayFeatures(closestSubScreen),
        child: child,
      ),
    );
  }

  static Offset _fallbackAnchorPoint(BuildContext context) {
    final TextDirection textDirection = Directionality.of(context);
    switch (textDirection) {
      case TextDirection.rtl:
        return const Offset(double.maxFinite, 0);
      case TextDirection.ltr:
        return Offset.zero;
    }
  }

  static Iterable<Rect> _avoidBounds(MediaQueryData mediaQuery) {
    return mediaQuery.displayFeatures.map((DisplayFeature d) => d.bounds)
        .where((Rect r) => r.shortestSide > 0);
  }

  /// Returns the closest sub-screen to the [anchorPoint]
  static Rect _closestToAnchorPoint(
      Iterable<Rect> subScreens, Offset anchorPoint) {
    return subScreens.fold(subScreens.first,
        (Rect previousValue, Rect element) {
      final double previousDistance =
          _distanceFromPointToRect(anchorPoint, previousValue);
      final double elementDistance =
          _distanceFromPointToRect(anchorPoint, element);
      if (previousDistance < elementDistance)
        return previousValue;
      else
        return element;
    });
  }

  static double _distanceFromPointToRect(Offset point, Rect rect) {
    // Cases for point position relative to rect:
    // 1  2  3
    // 4 [R] 5
    // 6  7  8
    if (point.dx < rect.left) {
      if (point.dy < rect.top) {
        // Case 1
        return (point - rect.topLeft).distance;
      } else if (point.dy > rect.bottom) {
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
      } else if (point.dy > rect.bottom) {
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
      } else if (point.dy > rect.bottom) {
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
  static Iterable<Rect> _subScreensInBounds(
      Rect wantedBounds, Iterable<Rect> avoidBounds) {
    Iterable<Rect> subScreens = <Rect>[wantedBounds];
    for (final Rect bounds in avoidBounds) {
      subScreens = subScreens.expand((Rect screen) {
        final List<Rect> results = <Rect>[];
        if (screen.top >= bounds.top && screen.bottom <= bounds.bottom) {
          // Display feature splits the screen vertically
          if (screen.left < bounds.left) {
            // There is a smaller sub-screen, left of the display feature
            results.add(Rect.fromLTWH(screen.left, screen.top,
                bounds.left - screen.left, screen.height));
          }
          if (screen.right > bounds.right) {
            // There is a smaller sub-screen, right of the display feature
            results.add(Rect.fromLTWH(bounds.right, screen.top,
                screen.right - bounds.right, screen.height));
          }
        } else if (screen.left >= bounds.left && screen.right <= bounds.right) {
          // Display feature splits the sub-screen horizontally
          if (screen.top < bounds.top) {
            // There is a smaller sub-screen, above the display feature
            results.add(Rect.fromLTWH(
                screen.left, screen.top, screen.width, bounds.top - screen.top));
          }
          if (screen.bottom > bounds.bottom) {
            // There is a smaller sub-screen, below the display feature
            results.add(Rect.fromLTWH(screen.left, bounds.bottom, screen.width,
                screen.bottom - bounds.bottom));
          }
        } else {
          results.add(screen);
        }
        return results;
      });
    }
    return subScreens;
  }

  static Offset _finiteOffset(Offset offset) {
    if (offset.isFinite) {
      return offset;
    } else {
      return Offset(_finiteNumber(offset.dx), _finiteNumber(offset.dy));
    }
  }

  static double _finiteNumber(double nr) {
    if (!nr.isInfinite) {
      return nr;
    }
    return nr.isNegative ? -double.maxFinite : double.maxFinite;
  }
}
