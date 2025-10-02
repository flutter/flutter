// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Do not import this file in production applications or packages published
// to pub.dev. Flutter will make breaking changes to this file, even in patch
// versions.
//
// All APIs in this file must be private or must:
//
// 1. Have the `@internal` attribute.
// 2. Throw an `UnsupportedError` if `isWindowingEnabled`
//    is `false`.
//
// See: https://github.com/flutter/flutter/issues/30701.

import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../foundation/_features.dart';

const String _kWindowingDisabledErrorMessage = '''
Windowing APIs are not enabled.

Windowing APIs are currently experimental. Do not use windowing APIs in
production applications or plugins published to pub.dev.

To try experimental windowing APIs:
1. Switch to Flutter's main release channel.
2. Turn on the windowing feature flag.

See: https://github.com/flutter/flutter/issues/30701.
''';

/// Defines the anchor point for the anchor rectangle or child window when
/// positioning a window.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
enum WindowPositionerAnchor {
  /// Center anchor point.
  center,

  /// Top anchor point.
  top,

  /// Bottom anchor point.
  bottom,

  /// Left anchor point.
  left,

  /// Right anchor point.
  right,

  /// Top-left corner anchor point.
  topLeft,

  /// Bottom-left corner anchor point.
  bottomLeft,

  /// Top-right corner anchor point.
  topRight,

  /// Bottom-right corner anchor point.
  bottomRight,
}

/// Defines ways in which Flutter will adjust the position of a window.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
enum WindowPositionerConstraintAdjustment {
  /// Slide the window in the X direction.
  slideX,

  /// Slide the window in the Y direction.
  slideY,

  /// Flip the window in the X direction.
  flipX,

  /// Flip the window in the Y direction.
  flipY,

  /// Resize the window in the X direction.
  resizeX,

  /// Resize the window in the Y direction.
  resizeY,
}

/// Provides rules for the placement of a child window relative to a parent window.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
class WindowPositioner {
  /// Creates a [WindowPositioner].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  const WindowPositioner({
    this.parentAnchor = WindowPositionerAnchor.center,
    this.childAnchor = WindowPositionerAnchor.center,
    this.offset = Offset.zero,
    this.constraintAdjustment = const <WindowPositionerConstraintAdjustment>{},
  });

  /// Anchor point for the anchor rectangle.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final WindowPositionerAnchor parentAnchor;

  /// Anchor point for the child window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final WindowPositionerAnchor childAnchor;

  /// Position offset relative to the anchor points.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final Offset offset;

  /// Constraint adjustments for window positioning.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final Set<WindowPositionerConstraintAdjustment> constraintAdjustment;

  /// Computes the screen-space rectangle for a child window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  Rect placeWindow({
    required Size childSize,
    required Rect anchorRect,
    required Rect parentRect,
    required Rect outputRect,
  }) {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    Rect defaultResult;
    {
      final Offset result =
          _constraintTo(parentRect, parentAnchor._anchorPositionFor(anchorRect) + offset) +
          childAnchor._offsetFor(childSize);
      defaultResult = result & childSize;
      if (_rectContains(outputRect, defaultResult)) {
        return defaultResult;
      }
    }

    if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.flipX)) {
      final Offset result =
          _constraintTo(
            parentRect,
            parentAnchor._flipX()._anchorPositionFor(anchorRect) + _flipX(offset),
          ) +
          childAnchor._flipX()._offsetFor(childSize);
      if (_rectContains(outputRect, result & childSize)) {
        return result & childSize;
      }
    }

    if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.flipY)) {
      final Offset result =
          _constraintTo(
            parentRect,
            parentAnchor._flipY()._anchorPositionFor(anchorRect) + _flipY(offset),
          ) +
          childAnchor._flipY()._offsetFor(childSize);
      if (_rectContains(outputRect, result & childSize)) {
        return result & childSize;
      }
    }

    if (constraintAdjustment.containsAll(<WindowPositionerConstraintAdjustment>{
      WindowPositionerConstraintAdjustment.flipX,
      WindowPositionerConstraintAdjustment.flipY,
    })) {
      final Offset result =
          _constraintTo(
            parentRect,
            parentAnchor._flipY()._flipX()._anchorPositionFor(anchorRect) + _flipX(_flipY(offset)),
          ) +
          childAnchor._flipY()._flipX()._offsetFor(childSize);
      if (_rectContains(outputRect, result & childSize)) {
        return result & childSize;
      }
    }

    {
      Offset result =
          _constraintTo(parentRect, parentAnchor._anchorPositionFor(anchorRect) + offset) +
          childAnchor._offsetFor(childSize);

      if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.slideX)) {
        final double leftOverhang = result.dx - outputRect.left;
        final double rightOverhang = result.dx + childSize.width - outputRect.right;
        if (leftOverhang < 0.0) {
          result = result.translate(-leftOverhang, 0.0);
        } else if (rightOverhang > 0.0) {
          result = result.translate(-rightOverhang, 0.0);
        }
      }

      if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.slideY)) {
        final double topOverhang = result.dy - outputRect.top;
        final double bottomOverhang = result.dy + childSize.height - outputRect.bottom;
        if (topOverhang < 0.0) {
          result = result.translate(0.0, -topOverhang);
        } else if (bottomOverhang > 0.0) {
          result = result.translate(0.0, -bottomOverhang);
        }
      }

      if (_rectContains(outputRect, result & childSize)) {
        return result & childSize;
      }
    }

    {
      Offset result =
          _constraintTo(parentRect, parentAnchor._anchorPositionFor(anchorRect) + offset) +
          childAnchor._offsetFor(childSize);

      if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.resizeX)) {
        final double leftOverhang = result.dx - outputRect.left;
        final double rightOverhang = result.dx + childSize.width - outputRect.right;
        if (leftOverhang < 0.0) {
          result = result.translate(-leftOverhang, 0.0);
          childSize = Size(childSize.width + leftOverhang, childSize.height);
        }
        if (rightOverhang > 0.0) {
          childSize = Size(childSize.width - rightOverhang, childSize.height);
        }
      }

      if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.resizeY)) {
        final double topOverhang = result.dy - outputRect.top;
        final double bottomOverhang = result.dy + childSize.height - outputRect.bottom;
        if (topOverhang < 0.0) {
          result = result.translate(0.0, -topOverhang);
          childSize = Size(childSize.width, childSize.height + topOverhang);
        }
        if (bottomOverhang > 0.0) {
          childSize = Size(childSize.width, childSize.height - bottomOverhang);
        }
      }

      if (_rectContains(outputRect, result & childSize)) {
        return result & childSize;
      }
    }

    return defaultResult;
  }
}

extension on WindowPositionerAnchor {
  WindowPositionerAnchor _flipX() {
    switch (this) {
      case WindowPositionerAnchor.center:
        return WindowPositionerAnchor.center;
      case WindowPositionerAnchor.top:
        return WindowPositionerAnchor.top;
      case WindowPositionerAnchor.bottom:
        return WindowPositionerAnchor.bottom;
      case WindowPositionerAnchor.left:
        return WindowPositionerAnchor.right;
      case WindowPositionerAnchor.right:
        return WindowPositionerAnchor.left;
      case WindowPositionerAnchor.topLeft:
        return WindowPositionerAnchor.topRight;
      case WindowPositionerAnchor.bottomLeft:
        return WindowPositionerAnchor.bottomRight;
      case WindowPositionerAnchor.topRight:
        return WindowPositionerAnchor.topLeft;
      case WindowPositionerAnchor.bottomRight:
        return WindowPositionerAnchor.bottomLeft;
    }
  }

  WindowPositionerAnchor _flipY() {
    switch (this) {
      case WindowPositionerAnchor.center:
        return WindowPositionerAnchor.center;
      case WindowPositionerAnchor.top:
        return WindowPositionerAnchor.bottom;
      case WindowPositionerAnchor.bottom:
        return WindowPositionerAnchor.top;
      case WindowPositionerAnchor.left:
        return WindowPositionerAnchor.left;
      case WindowPositionerAnchor.right:
        return WindowPositionerAnchor.right;
      case WindowPositionerAnchor.topLeft:
        return WindowPositionerAnchor.bottomLeft;
      case WindowPositionerAnchor.bottomLeft:
        return WindowPositionerAnchor.topLeft;
      case WindowPositionerAnchor.topRight:
        return WindowPositionerAnchor.bottomRight;
      case WindowPositionerAnchor.bottomRight:
        return WindowPositionerAnchor.topRight;
    }
  }

  Offset _offsetFor(Size size) {
    switch (this) {
      case WindowPositionerAnchor.center:
        return Offset(-size.width / 2.0, -size.height / 2.0);
      case WindowPositionerAnchor.top:
        return Offset(-size.width / 2.0, 0.0);
      case WindowPositionerAnchor.bottom:
        return Offset(-size.width / 2.0, -1.0 * size.height);
      case WindowPositionerAnchor.left:
        return Offset(0.0, -size.height / 2.0);
      case WindowPositionerAnchor.right:
        return Offset(-1.0 * size.width, -size.height / 2.0);
      case WindowPositionerAnchor.topLeft:
        return Offset.zero;
      case WindowPositionerAnchor.bottomLeft:
        return Offset(0.0, -1.0 * size.height);
      case WindowPositionerAnchor.topRight:
        return Offset(-size.width, 0.0);
      case WindowPositionerAnchor.bottomRight:
        return Offset(-1.0 * size.width, -1.0 * size.height);
    }
  }

  Offset _anchorPositionFor(Rect rect) {
    switch (this) {
      case WindowPositionerAnchor.center:
        return rect.center;
      case WindowPositionerAnchor.top:
        return rect.topCenter;
      case WindowPositionerAnchor.bottom:
        return rect.bottomCenter;
      case WindowPositionerAnchor.left:
        return rect.centerLeft;
      case WindowPositionerAnchor.right:
        return rect.centerRight;
      case WindowPositionerAnchor.topLeft:
        return rect.topLeft;
      case WindowPositionerAnchor.bottomLeft:
        return rect.bottomLeft;
      case WindowPositionerAnchor.topRight:
        return rect.topRight;
      case WindowPositionerAnchor.bottomRight:
        return rect.bottomRight;
    }
  }
}

bool _rectContains(Rect r1, Rect r2) {
  return r1.left <= r2.left && r1.right >= r2.right && r1.top <= r2.top && r1.bottom >= r2.bottom;
}

Offset _constraintTo(Rect r, Offset p) {
  return Offset(p.dx.clamp(r.left, r.right), p.dy.clamp(r.top, r.bottom));
}

Offset _flipX(Offset offset) {
  return Offset(-offset.dx, offset.dy);
}

Offset _flipY(Offset offset) {
  return Offset(offset.dx, -offset.dy);
}
