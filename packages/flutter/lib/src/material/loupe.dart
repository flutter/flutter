import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/cupertino/loupe.dart';

/// {@template widgets.material.loupe.loupe}
/// A [Loupe] positioned by rules dictated by the native Android loupe.
/// {@endtemplate}
///
/// {@template widgets.material.loupe.positionRules}
/// Positions itself based on [loupeSelectionOverlayInfoBearer]. Specifically, follows the
/// following rules:
/// - Tracks the gesture, but clamped to the beginning and end of the currently editing line.
/// - Focal point may never contain anything out of bounds.
/// - Never goes out of bounds vertically; offset until the entire loupe is in the screen. The
/// focal point, regardless of this transformation, always points to the touch Y.
/// - If just jumped between lines (prevY != currentY) then animate for duration
/// [jumpBetweenLinesAnimationDuration].
/// {@endtemplate}
class TextEditingLoupe extends StatefulWidget {
  /// {@macro widgets.material.loupe.loupe}
  /// {@template widgets.material.loupe.positionRules}
  const TextEditingLoupe(
      {super.key,
      required this.controller,
      required this.loupeSelectionOverlayInfoBearer});

  /// A [LoupeControllerWidgetBuilder]<[LoupeSelectionOverlayInfoBearer]>
  /// that returns a [CupertinoTextEditingLoupe] on iOS, [TextEditingLoupe]
  /// on Android, and null on all other platforms.
  static Widget? adaptiveLoupeControllerBuilder(
    BuildContext context,
    LoupeController controller,
    ValueNotifier<LoupeSelectionOverlayInfoBearer>
        loupeSelectionOverlayInfoBearer,
  ) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoTextEditingLoupe(
        controller: controller,
        loupeSelectionOverlayInfoBearer: loupeSelectionOverlayInfoBearer,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return TextEditingLoupe(
          controller: controller,
          loupeSelectionOverlayInfoBearer: loupeSelectionOverlayInfoBearer);
    }

    return null;
  }

  /// The duration that the position is animated if [TextEditingLoupe] just jumped between lines.
  @visibleForTesting
  static const Duration jumpBetweenLinesAnimationDuration =
      Duration(milliseconds: 70);

  /// A [LoupeController] for this loupe.
  final LoupeController controller;

  /// [TextEditingLoupe] positions itself based on [loupeSelectionOverlayInfoBearer].
  ///
  /// {@macro widgets.material.loupe.positionRules}
  final ValueNotifier<LoupeSelectionOverlayInfoBearer>
      loupeSelectionOverlayInfoBearer;

  @override
  State<TextEditingLoupe> createState() => _TextEditingLoupeState();
}

class _TextEditingLoupeState extends State<TextEditingLoupe> {
  // Should _only_ be null on construction. This is because of the animation logic.
  //
  // {@template flutter.material.materialTextEditingLoupe.loupePosition.nullReason}
  // animations are added when last_build_y != current_build_y, but this condition
  // is true on the inital render. Thus, this is null for the first frame and the
  // condition becomes [loupePosition != null && last_build_y != this_build_y].
  // {@endtemplate}
  Offset? _loupePosition;

  // A timer that unsets itself after an animation duration.
  // If the timer exists, then the loupe animates it's position -
  // if this timer does not exist, the loupe tracks the gesture (with respect
  // to the positioning rules) directly.
  Timer? _positionShouldBeAnimatedTimer;
  bool get _positionShouldBeAnimated => _positionShouldBeAnimatedTimer != null;

  Offset _extraFocalPointOffset = Offset.zero;

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

    if (_positionShouldBeAnimatedTimer != null) {
      _positionShouldBeAnimatedTimer!.cancel();
    }

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _determineLoupePositionAndFocalPoint();
    super.didChangeDependencies();
  }

  /// {@macro widgets.material.loupe.positionRules}
  void _determineLoupePositionAndFocalPoint() {
    final LoupeSelectionOverlayInfoBearer selectionInfo =
        widget.loupeSelectionOverlayInfoBearer.value;
    final Rect screenRect = Offset.zero & MediaQuery.of(context).size;

    // Since by default, we draw at the top left corner, this offset
    // shifts the loupe so we draw at the center, and then also include
    // the "above touch point" shift.
    final Offset basicLoupeOffset = Offset(Loupe.kSize.width / 2,
        Loupe.kSize.height - Loupe.kStandardVerticalFocalPointShift);

    // Since the loupe should not go past the edges of the line,
    // but must track the gesture otherwise, bound the X of the loupe
    // to always stay between line start and end.
    final double loupeX = selectionInfo.globalGesturePosition.dx.clamp(
        selectionInfo.currentLineBoundries.left,
        selectionInfo.currentLineBoundries.right);

    //place the loupe at the previously calculated X, and the Y should be
    // exactly at the center of the handle.
    final Rect unadjustedLoupeRect =
        Offset(loupeX, selectionInfo.handleRect.center.dy) - basicLoupeOffset &
            Loupe.kSize;

    // Shift the loupe so that, if we are ever out of the screen, we become in bounds.
    // Note that this probably won't have much an effect on the X, since we already bound
    // to the currentLineBoundries, but will shift vertically if the loupe is out of bounds.
    final Rect screenBoundsAdjustedLoupeRect =
        LoupeController.shiftWithinBounds(
            bounds: screenRect, rect: unadjustedLoupeRect);

    // Done with the loupe position!
    final Offset finalLoupePosition = screenBoundsAdjustedLoupeRect.topLeft;

    // The insets, from either edge, that the focal point should not point
    // past lest the loupe displays something out of bounds.
    final double horizontalMaxFocalPointEdgeInsets =
        (Loupe.kSize.width / 2) / Loupe._magnification;

    // Adjust the focal point horizontally such that none of the loupe
    // ever points to anything out of bounds.
    final double newGlobalFocalPointX;

    // If the text field is so narrow that we can't not show out of bounds,
    // then settle for pointing to the center all the time.
    if (selectionInfo.fieldBounds.width <
        horizontalMaxFocalPointEdgeInsets * 2) {
      newGlobalFocalPointX = selectionInfo.fieldBounds.center.dy;
    } else {
      // Otherwise, we can clamp the focal point to always point not
      // out of bounds.
      newGlobalFocalPointX = screenBoundsAdjustedLoupeRect.center.dx.clamp(
          selectionInfo.fieldBounds.left + horizontalMaxFocalPointEdgeInsets,
          selectionInfo.fieldBounds.right - horizontalMaxFocalPointEdgeInsets);
    }

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


    Timer? positionShouldBeAnimated = _positionShouldBeAnimatedTimer;
    // {@template flutter.material.materialTextEditingLoupe.loupePosition.nullReason}
    if (_loupePosition != null && finalLoupePosition.dy != _loupePosition!.dy) {
      if (_positionShouldBeAnimatedTimer != null &&
          _positionShouldBeAnimatedTimer!.isActive) {
        _positionShouldBeAnimatedTimer!.cancel();
      }

      // Create a timer that deletes itself when the timer is complete.
      // This is [mounted] safe, since the timer is canceled in [dispose].
      positionShouldBeAnimated = Timer(
          TextEditingLoupe.jumpBetweenLinesAnimationDuration,
          () => setState(() {
                _positionShouldBeAnimatedTimer = null;
              }));
    }

    setState(() {
      _loupePosition = finalLoupePosition;
      _positionShouldBeAnimatedTimer = positionShouldBeAnimated;
      _extraFocalPointOffset = focalPointAdjustmentForScreenBoundsAdjustment;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(_loupePosition != null,
        'Loupe position should only be null before the first build.');

    final Widget loupe = Loupe(
      controller: widget.controller,
      additionalFocalPointOffset: _extraFocalPointOffset,
    );

    return AnimatedPositioned(
      top: _loupePosition!.dy,
      left: _loupePosition!.dx,
      // Material Loupe typically does not animate, unless we jump between lines,
      // in whichcase we animate between lines.
      duration: _positionShouldBeAnimated
          ? TextEditingLoupe.jumpBetweenLinesAnimationDuration
          : Duration.zero,
      child: loupe,
    );
  }
}

/// A Material styled loupe.
///
/// This widget focuses on mimicking the _style_ of the loupe on material. For a
/// widget that is focused on mimicking the behavior of a material loupe, see [TextEditingLoupe].
class Loupe extends StatelessWidget {
  /// Creates a [RawLoupe] in the Material style.
  const Loupe({
    super.key,
    this.additionalFocalPointOffset = Offset.zero,
    required this.controller,
  });

  @visibleForTesting

  /// The size of the loupe.
  static const Size kSize = Size(77.37, 37.9);

  @visibleForTesting

  /// The vertical shift that the loupe should be over the focal point.
  static const double kStandardVerticalFocalPointShift = -18;
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

  /// This loupe's controller.
  final LoupeController controller;

  /// Any additional offset the focal point requires to "point"
  /// to the correct place.
  ///
  /// This is useful for instances where the loupe is not pointing to something
  /// directly below it.
  final Offset additionalFocalPointOffset;

  @override
  Widget build(BuildContext context) {
    return RawLoupe(
      controller: controller,
      decoration: const LoupeDecoration(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(_borderRadius))),
          shadows: _shadows),
      magnificationScale: _magnification,
      focalPoint: additionalFocalPointOffset +
          Offset(0, kStandardVerticalFocalPointShift - Loupe.kSize.height / 2),
      size: kSize,
      child: Container(
        color: _filmColor,
      ),
    );
  }
}
