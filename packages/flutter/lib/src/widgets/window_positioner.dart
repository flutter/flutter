import 'dart:ui';

/// Defines the anchor point for the anchor rectangle or child [Window] when
/// positioning a [Window]. The specified anchor is used to derive an anchor
/// point on the anchor rectangle that the anchor point for the child [Window]
/// will be positioned relative to. If a corner anchor is set (e.g. [topLeft]
/// or [bottomRight]), the anchor point will be at the specified corner;
/// otherwise, the derived anchor point will be centered on the specified edge,
/// or in the center of the anchor rectangle if no edge is specified.
enum WindowPositionerAnchor {
  /// If the [WindowPositioner.parentAnchor] is set to [center], then the
  /// child [Window] will be positioned relative to the center
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [center], then the middle
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  center,

  /// If the [WindowPositioner.parentAnchor] is set to [top], then the
  /// child [Window] will be positioned relative to the top
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [top], then the top
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  top,

  /// If the [WindowPositioner.parentAnchor] is set to [bottom], then the
  /// child [Window] will be positioned relative to the bottom
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [bottom], then the bottom
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  bottom,

  /// If the [WindowPositioner.parentAnchor] is set to [left], then the
  /// child [Window] will be positioned relative to the left
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [left], then the left
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  left,

  /// If the [WindowPositioner.parentAnchor] is set to [right], then the
  /// child [Window] will be positioned relative to the right
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [right], then the right
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  right,

  /// If the [WindowPositioner.parentAnchor] is set to [topLeft], then the
  /// child [Window] will be positioned relative to the top left
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [topLeft], then the top left
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  topLeft,

  /// If the [WindowPositioner.parentAnchor] is set to [bottomLeft], then the
  /// child [Window] will be positioned relative to the bottom left
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [bottomLeft], then the bottom left
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  bottomLeft,

  /// If the [WindowPositioner.parentAnchor] is set to [topRight], then the
  /// child [Window] will be positioned relative to the top right
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [topRight], then the top right
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  topRight,

  /// If the [WindowPositioner.parentAnchor] is set to [bottomRight], then the
  /// child [Window] will be positioned relative to the bottom right
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [bottomRight], then the bottom right
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  bottomRight,
}

/// The [WindowPositionerConstraintAdjustment] value defines the ways in which
/// Flutter will adjust the position of the [Window], if the unadjusted position would result
/// in the surface being partly constrained.
///
/// Whether a [Window] is considered 'constrained' is left to the platform
/// to determine. For example, the surface may be partly outside the
/// compositor's defined 'work area', thus necessitating the child [Window]'s
/// position be adjusted until it is entirely inside the work area.
///
/// 'Flip' means reverse the anchor points and offset along an axis.
/// 'Slide' means adjust the offset along an axis.
/// 'Resize' means adjust the client [Window] size along an axis.
///
/// The adjustments can be combined, according to a defined precedence: 1)
/// Flip, 2) Slide, 3) Resize.
enum WindowPositionerConstraintAdjustment {
  /// If [slideX] is specified in [WindowPositioner.constraintAdjustment]
  /// and the [Window] would be displayed off the screen in the X-axis, then it will be
  /// translated in the X-direction (either negative or positive) in order
  /// to best display the window on screen.
  slideX,

  /// If [slideY] is specified in [WindowPositioner.constraintAdjustment]
  /// and the [Window] would be displayed off the screen in the Y-axis, then it will be
  /// translated in the Y-direction (either negative or positive) in order
  /// to best display the window on screen.
  slideY,

  /// If [flipX] is specified in [WindowPositioner.constraintAdjustment]
  /// and the [Window] would be displayed off the screen in the X-axis in one direction, then
  /// it will be flipped to the opposite side of its parent in order to show
  /// to best display the window on screen.
  flipX,

  /// If [flipY] is specified in [WindowPositioner.constraintAdjustment]
  /// and then [Window] would be displayed off the screen in the Y-axis in one direction, then
  /// it will be flipped to the opposite side of its parent in order to show
  /// it on screen.
  flipY,

  /// If [resizeX] is specified in [WindowPositioner.constraintAdjustment]
  /// and the [Window] would be displayed off the screen in the X-axis, then
  /// its width will be reduced such that it fits on screen.
  resizeX,

  /// If [resizeY] is specified in [WindowPositioner.constraintAdjustment]
  /// and the [Window] would be displayed off the screen in the Y-axis, then
  /// its height will be reduced such that it fits on screen.
  resizeY,
}

/// The [WindowPositioner] provides a collection of rules for the placement
/// of a child [Window] relative to a parent [Window]. Rules can be defined to ensure
/// the child [Window] remains within the visible area's borders, and to
/// specify how the child [Window] changes its position, such as sliding along
/// an axis, or flipping around a rectangle.
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

  /// Defines the anchor point for the anchor rectangle. The specified anchor
  /// is used to derive an anchor point that the child [Window] will be
  /// positioned relative to. If a corner anchor is set (e.g. [topLeft] or
  /// [bottomRight]), the anchor point will be at the specified corner;
  /// otherwise, the derived anchor point will be centered on the specified
  /// edge, or in the center of the anchor rectangle if no edge is specified.
  final WindowPositionerAnchor parentAnchor;

  /// Defines the anchor point for the child [Window]. The specified anchor
  /// is used to derive an anchor point that will be positioned relative to the
  /// parentAnchor. If a corner anchor is set (e.g. [topLeft] or
  /// [bottomRight]), the anchor point will be at the specified corner;
  /// otherwise, the derived anchor point will be centered on the specified
  /// edge, or in the center of the anchor rectangle if no edge is specified.
  final WindowPositionerAnchor childAnchor;

  /// Specify the [Window] position offset relative to the position of the
  /// anchor on the anchor rectangle and the anchor on the child. For
  /// example if the anchor of the anchor rectangle is at (x, y), the [Window]
  /// has the child_anchor [topLeft], and the offset is (ox, oy), the calculated
  /// [Window] position will be (x + ox, y + oy). The offset position of the
  /// [Window] is the one used for constraint testing. See constraintAdjustment.
  ///
  /// An example use case is placing a popup menu on top of a user interface
  /// element, while aligning the user interface element of the parent [Window]
  /// with some user interface element placed somewhere in the popup [Window].
  final Offset offset;

  /// The constraintAdjustment value define ways Flutter will adjust
  /// the position of the [Window], if the unadjusted position would result
  /// in the surface being partly constrained.
  ///
  /// Whether a [Window] is considered 'constrained' is left to the platform
  /// to determine. For example, the surface may be partly outside the
  /// output's 'work area', thus necessitating the child [Window]'s
  /// position be adjusted until it is entirely inside the work area.
  ///
  /// The adjustments can be combined, according to a defined precedence: 1)
  /// Flip, 2) Slide, 3) Resize.
  final Set<WindowPositionerConstraintAdjustment> constraintAdjustment;

  /// Computes the screen-space rectangle for a child window placed according to
  /// this [WindowPositioner]. [childSize] is the frame size of the child window.
  /// [anchorRect] is the rectangle relative to which the child window is placed.
  /// [parentRect] is the parent window's rectangle. [outputRect] is the output
  /// display area where the child window will be placed. All sizes and rectangles
  /// are in physical coordinates.
  Rect placeWindow({
    required Size childSize,
    required Rect anchorRect,
    required Rect parentRect,
    required Rect outputRect,
  }) {
    Rect defaultResult;
    {
      final Offset result =
          _constraintTo(parentRect, parentAnchor.anchorPositionFor(anchorRect) + offset) +
          childAnchor.offsetFor(childSize);
      defaultResult = result & childSize;
      if (_rectContains(outputRect, defaultResult)) {
        return defaultResult;
      }
    }

    if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.flipX)) {
      final Offset result =
          _constraintTo(
            parentRect,
            parentAnchor.flipX().anchorPositionFor(anchorRect) + _flipX(offset),
          ) +
          childAnchor.flipX().offsetFor(childSize);
      if (_rectContains(outputRect, result & childSize)) {
        return result & childSize;
      }
    }

    if (constraintAdjustment.contains(WindowPositionerConstraintAdjustment.flipY)) {
      final Offset result =
          _constraintTo(
            parentRect,
            parentAnchor.flipY().anchorPositionFor(anchorRect) + _flipY(offset),
          ) +
          childAnchor.flipY().offsetFor(childSize);
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
            parentAnchor.flipY().flipX().anchorPositionFor(anchorRect) + _flipX(_flipY(offset)),
          ) +
          childAnchor.flipY().flipX().offsetFor(childSize);
      if (_rectContains(outputRect, result & childSize)) {
        return result & childSize;
      }
    }

    {
      Offset result =
          _constraintTo(parentRect, parentAnchor.anchorPositionFor(anchorRect) + offset) +
          childAnchor.offsetFor(childSize);

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
          _constraintTo(parentRect, parentAnchor.anchorPositionFor(anchorRect) + offset) +
          childAnchor.offsetFor(childSize);

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
  WindowPositionerAnchor flipX() {
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

  WindowPositionerAnchor flipY() {
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

  Offset offsetFor(Size size) {
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

  Offset anchorPositionFor(Rect rect) {
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
