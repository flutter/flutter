import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/rendering/object.dart';
import 'package:flutter/widgets.dart';

/// Material or Android?
class MaterialTextEditingLoupe extends StatefulWidget {
  const MaterialTextEditingLoupe(
      {super.key,
      required this.controller,
      required this.loupeSelectionOverlayInfoBearer});
  final LoupeController controller;
  final ValueNotifier<LoupeSelectionOverlayInfoBearer>
      loupeSelectionOverlayInfoBearer;

  @override
  State<MaterialTextEditingLoupe> createState() =>
      _MaterialTextEditingLoupeState();
}

class _MaterialTextEditingLoupeState extends State<MaterialTextEditingLoupe> {
  late Offset loupePosition;
  Offset extraFocalPointOffset = Offset.zero;

  @override
  void initState() {
    widget.loupeSelectionOverlayInfoBearer
        .addListener(_determineLoupePositionAndFocalPoint);
    super.initState();
  }

  @override
  void dispose() {
    widget.loupeSelectionOverlayInfoBearer
        .removeListener(_determineLoupePositionAndFocalPoint);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _determineLoupePositionAndFocalPoint();
    super.didChangeDependencies();
  }

  void _determineLoupePositionAndFocalPoint() {
    final LoupeSelectionOverlayInfoBearer selectionInfo =
        widget.loupeSelectionOverlayInfoBearer.value;
    final Rect screenRect = Offset.zero & MediaQuery.of(context).size;

    // Since by default, we draw at the top left corner, this offset
    // shifts the loupe so we draw at the center, and then also include
    // the "above touch point" shift.
    final Offset basicLoupeOffset = Offset(
        MaterialLoupe._size.width / 2,
        MaterialLoupe._size.height -
            MaterialLoupe._kStandardVerticalFocalPointShift);

    // Since the loupe should not go past the end of the line,
    // but must track the gesture otherwise, bound the X of the loupe to be at most
    // the end of the line. Since the center of the loupe may line up directly with
    // the end of the line, add half the width to the globalXLineEnd, so that half
    // the loupe may overhang the end of the text.
    final double loupeX = selectionInfo.globalXLineEnd != null
        ? math.min(selectionInfo.globalGesturePosition.dx,
            selectionInfo.globalXLineEnd! + (MaterialLoupe._size.width / 2))
        : selectionInfo.globalGesturePosition.dx;

    //place the loupe at the previously calculated X, and the Y should be
    // exactly at the center of the handle.
    final Rect unadjustedLoupeRect =
        Offset(loupeX, selectionInfo.handleRect.center.dy) - basicLoupeOffset &
            MaterialLoupe._size;

    // Shift the loupe so that, if we are ever out of the screen, we become in bounds.
    final Rect screenBoundsAdjustedLoupeRect =
        LoupeController.shiftWithinBounds(
            bounds: screenRect, rect: unadjustedLoupeRect);

    // The insets, from either edge, that the focal point should not point
    // past lest the loupe displays something out of bounds.
    final double horizontalMaxFocalPointEdgeInsets =
        (MaterialLoupe._size.width / 2) / MaterialLoupe._magnification;

    // Adjust the focal point horizontally such that none of the loupe
    // ever points to anything out of bounds.
    final double newGlobalFocalPointX = screenBoundsAdjustedLoupeRect.center.dx
        .clamp(
            selectionInfo.fieldBounds.left + horizontalMaxFocalPointEdgeInsets,
            selectionInfo.fieldBounds.right -
                horizontalMaxFocalPointEdgeInsets);

    // Since the previous value is now a global offset (i.e. globalFocalPoint
    // now points directly to a part of the screen), we must subtract our global offset
    // so that we now have the shift in the focal point required.
    final double newRelativeFocalPointX =
        screenBoundsAdjustedLoupeRect.center.dx - newGlobalFocalPointX;

    // The Y component means that if we are pressed up against the top of the screen,
    // then we should adjust the focal point such that it now points to how far we moved
    // the loupe. screenBoundsAdjustedLoupeRect.top == unadjustedLoupeRect.top for most cases,
    // but when pressed up agains tthe top of the screen, we adjust the focal point by 
    // the amount that we shifted from our "natural" position.
    final Offset focalPointAdjustmentForScreenBoundsAdjustment = Offset(
        newRelativeFocalPointX,
        screenBoundsAdjustedLoupeRect.top - unadjustedLoupeRect.top);

    setState(() {
      loupePosition = screenBoundsAdjustedLoupeRect.topLeft;
      extraFocalPointOffset = focalPointAdjustmentForScreenBoundsAdjustment;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialLoupe(
      controller: widget.controller,
      additionalFocalPointOffset: extraFocalPointOffset,
      position: loupePosition,
    );
  }
}

/// A Material styled loupe.
///
/// This widget focuses on mimicing the _style_ of the loupe on material. For a
/// widget that is focused on mimicing the behavior of a material loupe, see [MaterialTextEditingLoupe].
class MaterialLoupe extends StatelessWidget {
  /// Creates a [Loupe] in the Material style.
  const MaterialLoupe({
    super.key,
    this.position = Offset.zero,
    this.additionalFocalPointOffset = Offset.zero,
    required this.controller,
  });

  static const Size _size = Size(77.37, 37.9);
  static const double _kStandardVerticalFocalPointShift = -18;
  static const Color _filmColor = Color.fromARGB(8, 158, 158, 158);
  static const List<BoxShadow> _shadows = <BoxShadow>[
    BoxShadow(
        blurRadius: 1.5,
        offset: Offset(0, 2),
        spreadRadius: 0.75,
        color: Color.fromARGB(25, 0, 0, 0))
  ];
  static const double _borderRadius = 40;
  static const double _magnification = 1.25;

  final LoupeController controller;

  final Offset position;
  final Offset additionalFocalPointOffset;

  static const Duration _verticalAnimationDuration = Duration(milliseconds: 70);

  @override
  Widget build(BuildContext context) {
    return _VerticallyAnimatedPositioned(
      left: position.dx,
      top: position.dy,
      duration: _verticalAnimationDuration,
      child: Loupe(
        controller: controller,
        decoration: const LoupeDecoration(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(_borderRadius))),
            shadows: _shadows),
        magnificationScale: _magnification,
        focalPoint: additionalFocalPointOffset +
            Offset(
                0,
                _kStandardVerticalFocalPointShift -
                    MaterialLoupe._size.height / 2),
        size: _size,
        child: Container(
          color: _filmColor,
          child: Center(
              child: Container(
            width: 2.5,
            height: 2.5,
            decoration:
                BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          )),
        ),
      ),
    );
  }
}

class _VerticallyAnimatedPositioned extends ImplicitlyAnimatedWidget {
  const _VerticallyAnimatedPositioned({
    required this.child,
    this.left,
    this.top,
    required super.duration,
  }) : super(curve: Curves.linear);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The offset of the child's left edge from the left of the stack.
  final double? left;

  /// The offset of the child's top edge from the top of the stack.
  final double? top;

  @override
  AnimatedWidgetBaseState<_VerticallyAnimatedPositioned> createState() =>
      _VerticallyAnimatedPositionedState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('left', left, defaultValue: null));
    properties.add(DoubleProperty('top', top, defaultValue: null));
  }
}

class _VerticallyAnimatedPositionedState
    extends AnimatedWidgetBaseState<_VerticallyAnimatedPositioned> {
  Tween<double>? _top;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _top = visitor(_top, widget.top,
            (dynamic value) => Tween<double>(begin: value as double))
        as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left,
      top: _top?.evaluate(animation),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(ObjectFlagProperty<Tween<double>>.has('top', _top));
  }
}
