import 'dart:ui';
import 'package:flutter/foundation.dart';
import '_window.dart';

/// Defines how a child window will be placed relative to the anchor rectangle
/// of its parent.
///
/// The specified anchor is used to derive an anchor point on the anchor rectangle that
/// the child [BaseWindowController] will be positioned relative to.
/// If a corner anchor is set (e.g. [topLeft] or [bottomRight]),
/// the anchor point will be at the specified corner; otherwise, the derived anchor point
/// will be centered on the specified edge, or in the center of the anchor rectangle
/// if no edge is specified.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
enum WindowPositionerAnchor {
  /// If the [WindowPositioner.parentAnchor] is set to [center], then the
  /// child window will be positioned relative to the center
  /// of the parent window.
  ///
  /// If [WindowPositioner.childAnchor] is set to [center], then the middle
  /// of the child window will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  center,

  /// If the [WindowPositioner.parentAnchor] is set to [top], then the
  /// child window will be positioned relative to the top
  /// of the parent window.
  ///
  /// If [WindowPositioner.childAnchor] is set to [top], then the top
  /// of the child window will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  top,

  /// If the [WindowPositioner.parentAnchor] is set to [bottom], then the
  /// child window will be positioned relative to the bottom
  /// of the parent window.
  ///
  /// If [WindowPositioner.childAnchor] is set to [bottom], then the bottom
  /// of the child window will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bottom,

  /// If the [WindowPositioner.parentAnchor] is set to [left], then the
  /// child window will be positioned relative to the left
  /// of the parent window.
  ///
  /// If [WindowPositioner.childAnchor] is set to [left], then the left
  /// of the child window will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  left,

  /// If the [WindowPositioner.parentAnchor] is set to [right], then the
  /// child window will be positioned relative to the right
  /// of the parent window.
  ///
  /// If [WindowPositioner.childAnchor] is set to [right], then the right
  /// of the child window will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  right,

  /// If the [WindowPositioner.parentAnchor] is set to [topLeft], then the
  /// child window will be positioned relative to the top left
  /// of the parent window.
  ///
  /// If [WindowPositioner.childAnchor] is set to [topLeft], then the top left
  /// of the child window will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  topLeft,

  /// If the [WindowPositioner.parentAnchor] is set to [bottomLeft], then the
  /// child window will be positioned relative to the bottom left
  /// of the parent window.
  ///
  /// If [WindowPositioner.childAnchor] is set to [bottomLeft], then the bottom left
  /// of the child window will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bottomLeft,

  /// If the [WindowPositioner.parentAnchor] is set to [topRight], then the
  /// child window will be positioned relative to the top right
  /// of the parent window.
  ///
  /// If [WindowPositioner.childAnchor] is set to [topRight], then the top right
  /// of the child window will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  topRight,

  /// If the [WindowPositioner.parentAnchor] is set to [bottomRight], then the
  /// child window will be positioned relative to the bottom right
  /// of the parent window.
  ///
  /// If [WindowPositioner.childAnchor] is set to [bottomRight], then the bottom right
  /// of the child window will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  bottomRight;

  WindowPositionerAnchor _flipX() {
    return switch (this) {
      WindowPositionerAnchor.center => WindowPositionerAnchor.center,
      WindowPositionerAnchor.top => WindowPositionerAnchor.top,
      WindowPositionerAnchor.bottom => WindowPositionerAnchor.bottom,
      WindowPositionerAnchor.left => WindowPositionerAnchor.right,
      WindowPositionerAnchor.right => WindowPositionerAnchor.left,
      WindowPositionerAnchor.topLeft => WindowPositionerAnchor.topRight,
      WindowPositionerAnchor.bottomLeft => WindowPositionerAnchor.bottomRight,
      WindowPositionerAnchor.topRight => WindowPositionerAnchor.topLeft,
      WindowPositionerAnchor.bottomRight => WindowPositionerAnchor.bottomLeft,
    };
  }

  WindowPositionerAnchor _flipY() {
    return switch (this) {
      WindowPositionerAnchor.center => WindowPositionerAnchor.center,
      WindowPositionerAnchor.top => WindowPositionerAnchor.bottom,
      WindowPositionerAnchor.bottom => WindowPositionerAnchor.top,
      WindowPositionerAnchor.left => WindowPositionerAnchor.left,
      WindowPositionerAnchor.right => WindowPositionerAnchor.right,
      WindowPositionerAnchor.topLeft => WindowPositionerAnchor.bottomLeft,
      WindowPositionerAnchor.bottomLeft => WindowPositionerAnchor.topLeft,
      WindowPositionerAnchor.topRight => WindowPositionerAnchor.bottomRight,
      WindowPositionerAnchor.bottomRight => WindowPositionerAnchor.topRight,
    };
  }

  Offset _offsetFor(Size size) {
    return switch (this) {
      WindowPositionerAnchor.center => Offset(-size.width / 2.0, -size.height / 2.0),
      WindowPositionerAnchor.top => Offset(-size.width / 2.0, 0.0),
      WindowPositionerAnchor.bottom => Offset(-size.width / 2.0, -size.height),
      WindowPositionerAnchor.left => Offset(0.0, -size.height / 2.0),
      WindowPositionerAnchor.right => Offset(-size.width, -size.height / 2.0),
      WindowPositionerAnchor.topLeft => Offset.zero,
      WindowPositionerAnchor.bottomLeft => Offset(0.0, -size.height),
      WindowPositionerAnchor.topRight => Offset(-size.width, 0.0),
      WindowPositionerAnchor.bottomRight => Offset(-size.width, -size.height),
    };
  }

  Offset _anchorPositionFor(Rect rect) {
    return switch (this) {
      WindowPositionerAnchor.center => rect.center,
      WindowPositionerAnchor.top => rect.topCenter,
      WindowPositionerAnchor.bottom => rect.bottomCenter,
      WindowPositionerAnchor.left => rect.centerLeft,
      WindowPositionerAnchor.right => rect.centerRight,
      WindowPositionerAnchor.topLeft => rect.topLeft,
      WindowPositionerAnchor.bottomLeft => rect.bottomLeft,
      WindowPositionerAnchor.topRight => rect.topRight,
      WindowPositionerAnchor.bottomRight => rect.bottomRight,
    };
  }
}

/// The [WindowPositionerConstraintAdjustment] how a window will adjust
/// its position when it would be partly constrained by the platform.
///
/// Whether a window is considered "constrained" is left to the platform
/// to determine. For example, the surface may be partly outside of the
/// area of the monitor, thus necessitating that the position of the
/// child be adjusted until it is entirely inside the work area.
///
/// [flipX] and [flipY] mean reverse the anchor points and offset along an axis.
/// [slideX] and [slideY] mean adjust the offset along an axis.
/// [resizeX] and [resizeY] mean adjust the client window size along an axis.
///
/// The adjustments can be combined, according to a defined precedence:
///
///  1. [flipX] and [flipY]
///  2. [slideX] and [slideY]
///  3. [resizeX] and [resizeY]
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
enum WindowPositionerConstraintAdjustment {
  /// If [slideX] is specified in [WindowPositioner.constraintAdjustment]
  /// and the window would be displayed off the screen in the X-axis, then it will be
  /// translated in the X-direction (either negative or positive) in order
  /// to best display the window on screen.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  slideX,

  /// If [slideY] is specified in [WindowPositioner.constraintAdjustment]
  /// and the window would be displayed off the screen in the Y-axis, then it will be
  /// translated in the Y-direction (either negative or positive) in order
  /// to best display the window on screen.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  slideY,

  /// If [flipX] is specified in [WindowPositioner.constraintAdjustment]
  /// and the window would be displayed off the screen in the X-axis in one direction, then
  /// it will be flipped to the opposite side of its parent in order to show
  /// to best display the window on screen.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  flipX,

  /// If [flipY] is specified in [WindowPositioner.constraintAdjustment]
  /// and then window would be displayed off the screen in the Y-axis in one direction, then
  /// it will be flipped to the opposite side of its parent in order to show
  /// it on screen.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  flipY,

  /// If [resizeX] is specified in [WindowPositioner.constraintAdjustment]
  /// and the window would be displayed off the screen in the X-axis, then
  /// its width will be reduced such that it fits on screen.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  resizeX,

  /// If [resizeY] is specified in [WindowPositioner.constraintAdjustment]
  /// and the window would be displayed off the screen in the Y-axis, then
  /// its height will be reduced such that it fits on screen.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  resizeY,
}

/// The [WindowPositioner] defines how child windows are placed relative to
/// their parents.
///
/// For example, the rules may be defined such that the child window remains
/// within the visible area's borders, and to specify how the child window
/// changes its position, such as sliding along an axis, or flipping around a
/// rectangle.
///
/// See also:
///
///  * [TooltipWindowController], a subclass of [BaseWindowController] that
///    uses [WindowPositioner] to position tooltip windows.
///  * [WindowPositionerAnchor], which defines anchor points for positioning
///    windows.
///  * [WindowPositionerConstraintAdjustment], which defines how windows adjust
///    their position when they would be partly constrained by the platform.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
class WindowPositioner {
  /// Const constructor for [WindowPositioner].
  const WindowPositioner({
    this.parentAnchor = WindowPositionerAnchor.center,
    this.childAnchor = WindowPositionerAnchor.center,
    this.offset = Offset.zero,
    this.constraintAdjustment = const <WindowPositionerConstraintAdjustment>{},
  });

  /// Copy a [WindowPositioner] with some fields replaced.
  WindowPositioner copyWith({
    WindowPositionerAnchor? parentAnchor,
    WindowPositionerAnchor? childAnchor,
    Offset? offset,
    Set<WindowPositionerConstraintAdjustment>? constraintAdjustment,
  }) {
    return WindowPositioner(
      parentAnchor: parentAnchor ?? this.parentAnchor,
      childAnchor: childAnchor ?? this.childAnchor,
      offset: offset ?? this.offset,
      constraintAdjustment: constraintAdjustment ?? this.constraintAdjustment,
    );
  }

  /// Defines the anchor point for the anchor rectangle.
  ///
  /// The specified anchor is used to derive an anchor point that the child
  /// window will be positioned relative to. If a corner anchor is set
  /// (e.g. [WindowPositionerAnchor.topLeft] or [WindowPositionerAnchor.bottomRight]),
  /// the anchor point will be at the specified corner;
  /// otherwise, the derived anchor point will be centered on the specified
  /// edge, or in the center of the anchor rectangle if no edge is specified.
  ///
  /// This is used in conjunction with [childAnchor] to determine the final position
  /// of the child window.
  final WindowPositionerAnchor parentAnchor;

  /// Defines the anchor point for the child window.
  ///
  /// The specified anchor is used to derive an anchor point that will be positioned
  /// relative to the [parentAnchor]. If a corner anchor is set (e.g. [WindowPositionerAnchor.topLeft] or
  /// [WindowPositionerAnchor.bottomRight]), the anchor point will be at the specified corner;
  /// otherwise, the derived anchor point will be centered on the specified
  /// edge, or in the center of the anchor rectangle if no edge is specified.
  ///
  /// This is used in conjunction with [parentAnchor] to determine the final position
  /// of the child window.
  final WindowPositionerAnchor childAnchor;

  /// Specify the window position offset relative to the position of the
  /// anchor on the anchor rectangle and the anchor on the child.
  ///
  /// For example if the anchor of the anchor rectangle is at (x, y), the window
  /// has a [childAnchor] of [WindowPositionerAnchor.topLeft], and the [offset]
  /// is (ox, oy), the calculated window position will be (x + ox, y + oy).
  /// The offset position of the window is the one used for constraint testing.
  /// See [constraintAdjustment].
  ///
  /// An example use case is placing a popup menu on top of a user interface
  /// element, while aligning the user interface element of the parent window
  /// with some user interface element placed somewhere in the popup window.
  final Offset offset;

  /// Defines how Flutter will adjust the position of the window if the unadjusted
  /// position would result in the window being partly constrained by the platform.
  ///
  /// Whether a window is considered "constrained" is left to the platform
  /// to determine. For example, the window may be partly outside the
  /// output's 'work area', thus necessitating the child window's
  /// position be adjusted until it is entirely inside the work area.
  ///
  /// The adjustments can be combined, according to a defined precedence:
  ///
  /// 1. [WindowPositionerConstraintAdjustment.flipX] and [WindowPositionerConstraintAdjustment.flipY]
  /// 2. [WindowPositionerConstraintAdjustment.slideX] and [WindowPositionerConstraintAdjustment.slideY]
  /// 3. [WindowPositionerConstraintAdjustment.resizeX] and [WindowPositionerConstraintAdjustment.resizeY]
  ///
  /// The first adjustment that results in the child window being entirely inside the work area will be picked.
  ///
  /// See also:
  ///
  ///  * [WindowPositionerConstraintAdjustment] for details on each adjustment type.
  final Set<WindowPositionerConstraintAdjustment> constraintAdjustment;

  /// Computes the screen-space rectangle for a child window placed according to
  /// this [WindowPositioner].
  ///
  /// [childSize] is the frame size of the child window.
  ///
  /// [anchorRect] is the rectangle relative to which the child window is placed.
  ///
  /// [parentRect] is the parent window's rectangle.
  ///
  /// [displayRect] is the output display area where the child window will be placed.
  ///
  /// All sizes and rectangles are in physical coordinates.
  Rect placeWindow({
    required Size childSize,
    required Rect anchorRect,
    required Rect parentRect,
    required Rect displayRect,
  }) {
    Rect defaultResult;
    {
      final Offset result =
          _constrainTo(parentRect, parentAnchor._anchorPositionFor(anchorRect) + offset) +
          childAnchor._offsetFor(childSize);
      defaultResult = result & childSize;
      if (_rectContains(displayRect, defaultResult)) {
        return defaultResult;
      }
    }

    if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.flipX)) {
      final Offset result =
          _constrainTo(
            parentRect,
            parentAnchor._flipX()._anchorPositionFor(anchorRect) + _flipX(offset),
          ) +
          childAnchor._flipX()._offsetFor(childSize);
      if (_rectContains(displayRect, result & childSize)) {
        return result & childSize;
      }
    }

    if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.flipY)) {
      final Offset result =
          _constrainTo(
            parentRect,
            parentAnchor._flipY()._anchorPositionFor(anchorRect) + _flipY(offset),
          ) +
          childAnchor._flipY()._offsetFor(childSize);
      if (_rectContains(displayRect, result & childSize)) {
        return result & childSize;
      }
    }

    if (constraintAdjustment.containsAll(<WindowPositionerConstraintAdjustment>{
      WindowPositionerConstraintAdjustment.flipX,
      WindowPositionerConstraintAdjustment.flipY,
    })) {
      final Offset result =
          _constrainTo(
            parentRect,
            parentAnchor._flipY()._flipX()._anchorPositionFor(anchorRect) + _flipX(_flipY(offset)),
          ) +
          childAnchor._flipY()._flipX()._offsetFor(childSize);
      if (_rectContains(displayRect, result & childSize)) {
        return result & childSize;
      }
    }

    {
      Offset result =
          _constrainTo(parentRect, parentAnchor._anchorPositionFor(anchorRect) + offset) +
          childAnchor._offsetFor(childSize);

      if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.slideX)) {
        final double leftOverhang = result.dx - displayRect.left;
        final double rightOverhang = result.dx + childSize.width - displayRect.right;
        if (leftOverhang < 0.0) {
          result = result.translate(-leftOverhang, 0.0);
        } else if (rightOverhang > 0.0) {
          result = result.translate(-rightOverhang, 0.0);
        }
      }

      if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.slideY)) {
        final double topOverhang = result.dy - displayRect.top;
        final double bottomOverhang = result.dy + childSize.height - displayRect.bottom;
        if (topOverhang < 0.0) {
          result = result.translate(0.0, -topOverhang);
        } else if (bottomOverhang > 0.0) {
          result = result.translate(0.0, -bottomOverhang);
        }
      }

      if (_rectContains(displayRect, result & childSize)) {
        return result & childSize;
      }
    }

    {
      Offset result =
          _constrainTo(parentRect, parentAnchor._anchorPositionFor(anchorRect) + offset) +
          childAnchor._offsetFor(childSize);

      if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.resizeX)) {
        final double leftOverhang = result.dx - displayRect.left;
        final double rightOverhang = result.dx + childSize.width - displayRect.right;
        if (leftOverhang < 0.0) {
          result = result.translate(-leftOverhang, 0.0);
          childSize = Size(childSize.width + leftOverhang, childSize.height);
        }
        if (rightOverhang > 0.0) {
          childSize = Size(childSize.width - rightOverhang, childSize.height);
        }
      }

      if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.resizeY)) {
        final double topOverhang = result.dy - displayRect.top;
        final double bottomOverhang = result.dy + childSize.height - displayRect.bottom;
        if (topOverhang < 0.0) {
          result = result.translate(0.0, -topOverhang);
          childSize = Size(childSize.width, childSize.height + topOverhang);
        }
        if (bottomOverhang > 0.0) {
          childSize = Size(childSize.width, childSize.height - bottomOverhang);
        }
      }

      if (_rectContains(displayRect, result & childSize)) {
        return result & childSize;
      }
    }

    return defaultResult;
  }
}

bool _rectContains(Rect r1, Rect r2) {
  return r1.left <= r2.left && r1.right >= r2.right && r1.top <= r2.top && r1.bottom >= r2.bottom;
}

Offset _constrainTo(Rect r, Offset p) {
  return Offset(p.dx.clamp(r.left, r.right), p.dy.clamp(r.top, r.bottom));
}

Offset _flipX(Offset offset) {
  return Offset(-offset.dx, offset.dy);
}

Offset _flipY(Offset offset) {
  return Offset(offset.dx, -offset.dy);
}
