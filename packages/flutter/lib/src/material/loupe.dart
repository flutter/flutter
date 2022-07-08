import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

    final Rect unadjustedLoupeRect = selectionInfo.handleCenter -
            Offset(
                MaterialLoupe._size.width / 2,
                MaterialLoupe._size.height -
                    MaterialLoupe._kStandardVerticalFocalPointShift) &
        MaterialLoupe._size;

    final Rect screenBoundsAdjustedLoupeRect =
        LoupeController.shiftWithinBounds(
            bounds: screenRect, rect: unadjustedLoupeRect);

    // The insets, from either edge, that the focal point should not point
    // past lest the loupe displays something out of bounds.
    final double horizontalMaxFocalPointEdgeInsets =
        (MaterialLoupe._size.width * MaterialLoupe._magnification) / 2;

    // Adjust the focal point horizontally such that none of the loupe
    // ever points to anything out of bounds.
    final double newGlobalFocalPointX = screenBoundsAdjustedLoupeRect.center.dx
        .clamp(
            selectionInfo.fieldBounds.left + horizontalMaxFocalPointEdgeInsets,
            selectionInfo.fieldBounds.right -
                horizontalMaxFocalPointEdgeInsets);

    final double newRelativeFocalPointX =
        screenBoundsAdjustedLoupeRect.center.dx - newGlobalFocalPointX;

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
  static const BorderRadius _borderRadius =
      BorderRadius.all(Radius.circular(40));
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
            shape: RoundedRectangleBorder(borderRadius: _borderRadius),
            shadows: _shadows),
        magnificationScale: _magnification,
        focalPoint: additionalFocalPointOffset +
            Offset(
                0,
                _kStandardVerticalFocalPointShift -
                    MaterialLoupe._size.height / 2),
        size: _size,
        child: Container(color: _filmColor),
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
