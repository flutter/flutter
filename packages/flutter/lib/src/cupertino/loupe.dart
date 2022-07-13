import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// A CupertinoLoupe, specifically for text editing.
///
/// Delegates styling to [CupertinoLoupe] with is positioned depending on
/// [loupeSelectionOverlayInfoBearer].
///
/// Specifically, the [CupertinoTextEditingLoupe] follows the following rules:
/// - Never position itself horizontally outside the screen width, with [_kHorizontalScreenEdgePadding] padding.
/// - Hidden if a gesture is detected [_kHideIfBelowThreshold] units below the line, shown otherwise.
/// - Follow the X of the gesture directly (with respect to rule 1).
/// - Have some vertical drag resistance; i.e. if a gesture is detected k units below the field,
/// then have vertical offset [_kDragResistance] * k.
class CupertinoTextEditingLoupe extends StatefulWidget {
  /// Construct a [RawLoupe] in the Cupertino style, positioning with respect to
  /// [loupeSelectionOverlayInfoBearer].
  const CupertinoTextEditingLoupe(
      {super.key,
      required this.controller,
      required this.loupeSelectionOverlayInfoBearer});

  /// A drag resistance on the Y of the lens, before it snaps to the next line.
  static const double _kDragResistance = 10;

  /// The loupe hides itself if you drag too far below the text line that
  /// you are hovering over.
  static const double _kHideIfBelowThreshold = -48;

  /// The padding on either edge of the screen that any part of the loupe
  /// cannot exist past.
  ///
  /// This includes the entire loupe, not just the center.
  ///
  /// If the screen has width w, then the loupe is bound to
  /// [_kHorizontalScreenEdgePadding, w - _kHorizontalScreenEdgePadding].
  static const double _kHorizontalScreenEdgePadding = 10;

  /// The duration that the loupe drags behind it's final position.
  static const Duration _kDragAnimationDuration = Duration(milliseconds: 45);

  /// This loupe's controller.
  final LoupeController controller;

  /// [CupertinoTextEditingLoupe] will determine it's own positioning
  /// based on the [LoupeSelectionOverlayInfoBearer] of this notifier.
  final ValueNotifier<LoupeSelectionOverlayInfoBearer>
      loupeSelectionOverlayInfoBearer;

  @override
  State<CupertinoTextEditingLoupe> createState() =>
      _CupertinoTextEditingLoupeState();
}

class _CupertinoTextEditingLoupeState extends State<CupertinoTextEditingLoupe> {
  // Initalize to dummy values just incase the inital call to 
  // _determineLoupePositionAndFocalPoint hides, and thus does not 
  // set these values.
  Offset _currentAdjustedLoupePosition = Offset.zero;
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
    final double verticalCenterOfCurrentLine =
        textEditingContext.handleRect.center.dy;

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


    // The raw position, tracking the gesture directly.
    final Offset rawLoupePosition = Offset(
        textEditingContext.globalGesturePosition.dx -
            CupertinoLoupe.kLoupeSize.width / 2,
        verticalPositionOfLens -
            (CupertinoLoupe.kLoupeSize.height -
                CupertinoLoupe.kVerticalFocalPointOffset));

    final Rect screenRect = Offset.zero & MediaQuery.of(context).size;

    // Adjust the loupe position so that it never exists outside the horizontal
    // padding.
    final Offset adjustedLoupePosition = LoupeController.shiftWithinBounds(
      bounds: Rect.fromLTRB(
          screenRect.left +
              CupertinoTextEditingLoupe._kHorizontalScreenEdgePadding,
          // iOS doesn't reposition for Y, so we should expand the threshold
          // so we can send the whole loupe out of bounds if need be.
          screenRect.top -
              (CupertinoLoupe.kLoupeSize.height +
                  CupertinoLoupe.kVerticalFocalPointOffset),
          screenRect.right -
              CupertinoTextEditingLoupe._kHorizontalScreenEdgePadding,
          screenRect.bottom +
              (CupertinoLoupe.kLoupeSize.height +
                  CupertinoLoupe.kVerticalFocalPointOffset)),
      rect: rawLoupePosition & CupertinoLoupe.kLoupeSize,
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
    return AnimatedPositioned(
      duration: CupertinoTextEditingLoupe._kDragAnimationDuration,
      curve: Curves.easeOut,
      left: _currentAdjustedLoupePosition.dx,
      top: _currentAdjustedLoupePosition.dy,
      child: CupertinoLoupe(
        controller: widget.controller,
        additionalFocalPointOffset: Offset(0, _verticalFocalPointAdjustment),
      ),
    );
  }
}

/// A [RawLoupe] in the Cupertino style.
///
/// Control the position and display status of [CupertinoLoupe]
/// through a given [LoupeController].
///
/// [CupertinoLoupe] is a wrapper around [RawLoupe] that handles styling
/// and trasitions.
///
/// See also:
/// * [RawLoupe], the backing implementation.
/// * [CupertinoTextEditingLoupe], a widget that positions [CupertinoLoupe] based on
/// [LoupeSelectionOverlayInfoBearer].
/// * [LoupeController], the controller for this loupe.
class CupertinoLoupe extends StatefulWidget {
  /// Creates a [RawLoupe] in the Cupertino style.
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
    this.additionalFocalPointOffset = Offset.zero,
  });
  // These constants were eyeballed on an iPhone XR iOS v15.5.

  @visibleForTesting
  /// The vertical offset, from the center of the loupe,
  /// that the focal point should point to.
  static const double kVerticalFocalPointOffset = -25;

  @visibleForTesting
  /// The size of the loupe.
  static const Size kLoupeSize = Size(82.5, 45);
  
  static const Duration _kIoAnimationDuration = Duration(milliseconds: 150);
  static const BorderRadius _kBorderRadius =
      BorderRadius.all(Radius.elliptical(60, 50));

  /// This [RawLoupe]'s controller.
  final LoupeController controller;

  /// Any additional focal point offset, applied over the regular focal
  /// point offset defined in [CupertinoLoupe.kVerticalFocalPointOffset].
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
    return Transform.translate(
        offset: Offset.lerp(
          const Offset(0, -CupertinoLoupe.kVerticalFocalPointOffset),
          Offset.zero,
          _ioAnimation.value,
        )!,
        child: RawLoupe(
          transitionAnimationController: _ioAnimationController,
          controller: widget.controller,
          focalPoint: Offset(
                  0,
                  (CupertinoLoupe.kVerticalFocalPointOffset -
                          CupertinoLoupe.kLoupeSize.height / 2) *
                      _ioAnimation.value) +
              widget.additionalFocalPointOffset,
          decoration: LoupeDecoration(
            opacity: _ioAnimation.value,
            shape: const RoundedRectangleBorder(
                borderRadius: CupertinoLoupe._kBorderRadius,
                side: BorderSide(color: Color.fromARGB(255, 235, 235, 235))),
            shadows: const <BoxShadow>[
              BoxShadow(
                  color: Color.fromARGB(34, 0, 0, 0),
                  blurRadius: 5,
                  spreadRadius: 0.2,
                  offset: Offset(0, 3))
            ],
          ),
          size: CupertinoLoupe.kLoupeSize,
        ));
  }
}
