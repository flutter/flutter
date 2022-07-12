import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// A CupertinoLoupe, specifically for text editing.
///
/// Delegates styling to [CupertinoLoupe], but is positioned depending on
/// [loupeSelectionOverlayInfoBearer].
///
/// Specifically, the text editing loupe positions itself at the vertical center of the
/// line the text editing handle is on, with some vertical tolerance. There are only global
/// constraints on the X axis based on the screen width, minus some threshold. This means
/// that the loupe positions itself exactly at the X of the touchpoint, but not off the screen.
class CupertinoTextEditingLoupe extends StatefulWidget {
  /// A drag resistance on the Y of the lens, before it snaps to the next line.
  static const double _kDragResistance = 10;

  /// On iOS, the loupe hides itself if you drag too far below the actual text.
  static const double _kHideIfBelowThreshold = -48;

  static const double _kHorizontalScreenEdgePadding = 10;

  final LoupeController controller;
  final ValueNotifier<LoupeSelectionOverlayInfoBearer>
      loupeSelectionOverlayInfoBearer;

  const CupertinoTextEditingLoupe(
      {super.key,
      required this.controller,
      required this.loupeSelectionOverlayInfoBearer});

  @override
  State<CupertinoTextEditingLoupe> createState() =>
      _CupertinoTextEditingLoupeState();
}

class _CupertinoTextEditingLoupeState extends State<CupertinoTextEditingLoupe> {
  late Offset _currentAdjustedLoupePosition;

  double _verticalFocalPointAdjustment = 0;

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
    final LoupeSelectionOverlayInfoBearer textEditingContext =
        widget.loupeSelectionOverlayInfoBearer.value;
            

    // The exact Y of the center of the current line.
    final double verticalCenterOfCurrentLine = textEditingContext.handleRect.center.dy;

    // If the loupe is currently showing, but we have dragged out of threshold,
    // we should hide it.
    if (verticalCenterOfCurrentLine -
            textEditingContext.globalGesturePosition.dy <
        CupertinoTextEditingLoupe._kHideIfBelowThreshold) {
      // only signal a hide if we are currently showing.
      if (widget.controller.status.value == AnimationStatus.completed) {
        widget.controller.hide(removeFromOverlay: false);
      }
      return;
    }

    // If we are gone, but got to this point, we shouldn't be: show.
    if (widget.controller.status.value == AnimationStatus.dismissed) {
      widget.controller.signalShow();
    }

    // Never go above the center of the line, but have some resistance
    // going downward if the drag goes too far.
    final double verticalPositionOfLens = math.max(
        verticalCenterOfCurrentLine,
        verticalCenterOfCurrentLine -
            (verticalCenterOfCurrentLine -
                    textEditingContext.globalGesturePosition.dy) /
                CupertinoTextEditingLoupe._kDragResistance);

    final Offset rawLoupePosition = Offset(
        // The X is exactly where the gesture is.
        textEditingContext.globalGesturePosition.dx -
            CupertinoLoupe._kLoupeSize.width / 2,
        verticalPositionOfLens -
            (CupertinoLoupe._kLoupeSize.height -
                CupertinoLoupe._kVerticalFocalPointOffset));

    final Rect screenRect = Offset.zero & MediaQuery.of(context).size;

    final Offset adjustedLoupePosition = LoupeController.shiftWithinBounds(
      bounds: Rect.fromLTRB(
          screenRect.left +
              CupertinoTextEditingLoupe._kHorizontalScreenEdgePadding,
          // iOS doesn't reposition for Y, so we should expand the threshold
          // so we can send the whole loupe out of bounds if need be.
          screenRect.top -
              (CupertinoLoupe._kLoupeSize.height +
                  CupertinoLoupe._kVerticalFocalPointOffset),
          screenRect.right -
              CupertinoTextEditingLoupe._kHorizontalScreenEdgePadding,
          screenRect.bottom +
              (CupertinoLoupe._kLoupeSize.height +
                  CupertinoLoupe._kVerticalFocalPointOffset)),
      rect: rawLoupePosition & CupertinoLoupe._kLoupeSize,
    ).topLeft;

    setState(() {
      _currentAdjustedLoupePosition = adjustedLoupePosition;
      // the lens should always point to the center of the line.
      _verticalFocalPointAdjustment =
          verticalPositionOfLens - verticalCenterOfCurrentLine;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoLoupe(
      controller: widget.controller,
      position: _currentAdjustedLoupePosition,
      additionalFocalPointOffset: Offset(0, _verticalFocalPointAdjustment),
    );
  }
}

/// A [Loupe] in the Cupertino style.
///
/// Control the position and display status of [CupertinoLoupe]
/// through a given [LoupeController].
///
/// [CupertinoLoupe] is a wrapper around [Loupe] that handles styling
/// and trasitions.
///
/// See also:
/// * [Loupe], the backing implementation.
/// * [CupertinoTextEditingLoupe], a widget that positions [CupertinoLoupe] based on
/// [LoupeSelectionOverlayInfoBearer].
/// * [LoupeController], the controller for this loupe.
class CupertinoLoupe extends StatefulWidget {
  /// Creates a [Loupe] in the Cupertino style.
  ///
  /// This loupe has a small drag delay and remains within the bounds of
  /// [MediaQuery]'s size. This means that when this loupe is repositioned through
  /// [controller.requestedPosition], [CupertinoLoupe] may not position itself exactly
  /// at the requestedPosition immediately, or at all if any part of the loupe is determined
  /// to be out of bounds.
  ///
  /// The bounds shift is determined by [LoupeController.shiftWithinBounds], where the loupe
  /// is shifted within the bounds of the screen size.
  const CupertinoLoupe({
    super.key,
    required this.controller,
    required this.position,
    this.additionalFocalPointOffset = Offset.zero,
  });
  // These constants were eyeballed on an iPhone XR iOS v15.5.
  static const double _kVerticalFocalPointOffset = -25;
  static const Size _kLoupeSize = Size(82.5, 45);
  static const Duration _kDragAnimationDuration = Duration(milliseconds: 45);
  static const Duration _kIoAnimationDuration = Duration(milliseconds: 150);
  static const BorderRadius _kBorderRadius =
      BorderRadius.all(Radius.elliptical(60, 50));

  /// This [Loupe]'s controller.
  final LoupeController controller;

  /// The position of this [Loupe].
  ///
  /// This position may not be precise, due to [CupertinoLoupe] having
  /// a small drag delay (of [Duration] [_kDragAnimationDuration]).
  final Offset position;

  /// Any additional focal point offset, applied over the regular focal
  /// point offset defined in [CupertinoLoupe._kVerticalFocalPointOffset].
  final Offset additionalFocalPointOffset;

  @override
  State<CupertinoLoupe> createState() => _CupertinoLoupeState();
}

class _CupertinoLoupeState extends State<CupertinoLoupe>
    with SingleTickerProviderStateMixin {
  late AnimationController _ioAnimationController;
  late Animation<double> _ioAnimation;

  @override
  void initState() {
    _ioAnimationController = AnimationController(
      value: 0,
      vsync: this,
      duration: CupertinoLoupe._kIoAnimationDuration,
    )..addListener(() => setState(() {}));

    _ioAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
        CurvedAnimation(parent: _ioAnimationController, curve: Curves.easeOut));

    super.initState();
  }

  @override
  void dispose() {
    _ioAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
        duration: CupertinoLoupe._kDragAnimationDuration,
        curve: Curves.easeOut,
        left: widget.position.dx,
        top: widget.position.dy,
        child: Transform.translate(
            offset: Offset.lerp(
              const Offset(0, -CupertinoLoupe._kVerticalFocalPointOffset),
              Offset.zero,
              _ioAnimation.value,
            )!,
            child: Loupe(
              transitionAnimationController: _ioAnimationController,
              controller: widget.controller,
              focalPoint: Offset(
                      0,
                      (CupertinoLoupe._kVerticalFocalPointOffset -
                              CupertinoLoupe._kLoupeSize.height / 2) *
                          _ioAnimation.value) +
                  widget.additionalFocalPointOffset,
              decoration: LoupeDecoration(
                opacity: _ioAnimation.value,
                shape: const RoundedRectangleBorder(
                    borderRadius: CupertinoLoupe._kBorderRadius,
                    side:
                        BorderSide(color: Color.fromARGB(255, 235, 235, 235))),
                shadows: const <BoxShadow>[
                  BoxShadow(
                      color: Color.fromARGB(34, 0, 0, 0),
                      blurRadius: 5,
                      spreadRadius: 0.2,
                      offset: Offset(0, 3))
                ],
              ),
              size: CupertinoLoupe._kLoupeSize,
            )));
  }
}
