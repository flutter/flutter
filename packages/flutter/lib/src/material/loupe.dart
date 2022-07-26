// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// {@template widgets.material.loupe.loupe}
/// A [Loupe] positioned by rules dictated by the native Android loupe.
/// {@endtemplate}
///
/// {@template widgets.material.loupe.positionRules}
/// Positions itself based on [loupeSelectionOverlayInfoBearer]. Specifically, follows the
/// following rules:
/// - Tracks the gesture's X, but clamped to the beginning and end of the currently editing line.
/// - Focal point may never contain anything out of bounds.
/// - Never goes out of bounds vertically; offset until the entire loupe is in the screen. The
///   focal point, regardless of this transformation, always points to the touch Y.
/// - If just jumped between lines (prevY != currentY) then animate for duration
/// [jumpBetweenLinesAnimationDuration].
/// {@endtemplate}
class TextEditingLoupe extends StatefulWidget {
  /// {@macro widgets.material.loupe.loupe}
  ///
  /// {@template widgets.material.loupe.androidDisclaimer}
  /// These constants and default paramaters were taken from the
  /// Android 12 source code where directly transferable, and eyeballed on
  /// a Pixel 6 running Android 12 otherwise.
  /// {@endtemplate}
  ///
  /// {@template widgets.material.loupe.positionRules}
  const TextEditingLoupe(
      {super.key, required this.loupeSelectionOverlayInfoBearer});

  /// A [TextEditingLoupeConfiguration] that returns a [CupertinoTextEditingLoupe] on iOS,
  /// [TextEditingLoupe] on Android, and null on all other platforms, and shows the editing handles
  /// only on iOS.
  static TextEditingLoupeConfiguration adaptiveLoupeConfiguration = TextEditingLoupeConfiguration(
    shouldDisplayHandlesInLoupe: defaultTargetPlatform == TargetPlatform.iOS,
    loupeBuilder: (
      BuildContext context,
      LoupeController controller,
      ValueNotifier<LoupeSelectionOverlayInfoBearer> loupeSelectionOverlayInfoBearer,
    ) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          return CupertinoTextEditingLoupe(
            controller: controller,
            loupeSelectionOverlayInfoBearer: loupeSelectionOverlayInfoBearer,
          );
        case TargetPlatform.android:
          return TextEditingLoupe(
              loupeSelectionOverlayInfoBearer: loupeSelectionOverlayInfoBearer);

        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          return null;
      }
    }
  );

  /// The duration that the position is animated if [TextEditingLoupe] just switched
  /// between lines.
  @visibleForTesting
  static const Duration jumpBetweenLinesAnimationDuration =
      Duration(milliseconds: 70);

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
  // Animations are added when `last_build_y != current_build_y`. This condition
  // is true on the inital render, which would mean that the inital
  // build would be animated - this is undesired. Thus, this is null for the
  // first frame and the condition becomes `loupePosition != null && last_build_y != this_build_y`.
  // {@endtemplate}
  Offset? _loupePosition;

  // A timer that unsets itself after an animation duration.
  // If the timer exists, then the loupe animates its position -
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
    // shifts the loupe so we draw at the center, and then also includes
    // the "above touch point" shift.
    final Offset basicLoupeOffset = Offset(
        Loupe.kDefaultLoupeSize.width / 2,
        Loupe.kDefaultLoupeSize.height -
            Loupe.kStandardVerticalFocalPointShift);

    // Since the loupe should not go past the edges of the line,
    // but must track the gesture otherwise, constrain the X of the loupe
    // to always stay between line start and end.
    final double loupeX = clampDouble(
        selectionInfo.globalGesturePosition.dx,
        selectionInfo.currentLineBoundries.left,
        selectionInfo.currentLineBoundries.right);

    // Place the loupe at the previously calculated X, and the Y should be
    // exactly at the center of the handle.
    final Rect unadjustedLoupeRect =
        Offset(loupeX, selectionInfo.caratRect.center.dy) - basicLoupeOffset &
            Loupe.kDefaultLoupeSize;

    // Shift the loupe so that, if we are ever out of the screen, we become in bounds.
    // This probably won't have much of an effect on the X, since it is already bound
    // to the currentLineBoundries, but will shift vertically if the loupe is out of bounds.
    final Rect screenBoundsAdjustedLoupeRect =
        LoupeController.shiftWithinBounds(
            bounds: screenRect, rect: unadjustedLoupeRect);

    // Done with the loupe position!
    final Offset finalLoupePosition = screenBoundsAdjustedLoupeRect.topLeft;

    // The insets, from either edge, that the focal point should not point
    // past lest the loupe displays something out of bounds.
    final double horizontalMaxFocalPointEdgeInsets =
        (Loupe.kDefaultLoupeSize.width / 2) / Loupe._magnification;

    // Adjust the focal point horizontally such that none of the loupe
    // ever points to anything out of bounds.
    final double newGlobalFocalPointX;

    // If the text field is so narrow that we must show out of bounds,
    // then settle for pointing to the center all the time.
    if (selectionInfo.fieldBounds.width <
        horizontalMaxFocalPointEdgeInsets * 2) {
      newGlobalFocalPointX = selectionInfo.fieldBounds.center.dx;
    } else {
      // Otherwise, we can clamp the focal point to always point in bounds.
      newGlobalFocalPointX = clampDouble(
          screenBoundsAdjustedLoupeRect.center.dx,
          selectionInfo.fieldBounds.left + horizontalMaxFocalPointEdgeInsets,
          selectionInfo.fieldBounds.right - horizontalMaxFocalPointEdgeInsets);
    }

    // Since the previous value is now a global offset (i.e. `newGlobalFocalPoint
    // is now a global offset), we must subtract the loupe's global offset
    // to obtain the relative shift in the focal point.
    final double newRelativeFocalPointX =
        screenBoundsAdjustedLoupeRect.center.dx - newGlobalFocalPointX;

    // The Y component means that if we are pressed up against the top of the screen,
    // then we should adjust the focal point such that it now points to how far we moved
    // the loupe. screenBoundsAdjustedLoupeRect.top == unadjustedLoupeRect.top for most cases,
    // but when pressed up against the top of the screen, we adjust the focal point by
    // the amount that we shifted from our "natural" position.
    final Offset focalPointAdjustmentForScreenBoundsAdjustment = Offset(
        newRelativeFocalPointX,
        screenBoundsAdjustedLoupeRect.top - unadjustedLoupeRect.top);

    Timer? positionShouldBeAnimated = _positionShouldBeAnimatedTimer;

    if (_loupePosition != null && finalLoupePosition.dy != _loupePosition!.dy) {
      if (_positionShouldBeAnimatedTimer != null &&
          _positionShouldBeAnimatedTimer!.isActive) {
        _positionShouldBeAnimatedTimer!.cancel();
      }

      // Create a timer that deletes itself when the timer is complete.
      // This is `mounted` safe, since the timer is canceled in `dispose`.
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

    return AnimatedPositioned(
      top: _loupePosition!.dy,
      left: _loupePosition!.dx,
      // Material Loupe typically does not animate, unless we jump between lines,
      // in whichcase we animate between lines.
      duration: _positionShouldBeAnimated
          ? TextEditingLoupe.jumpBetweenLinesAnimationDuration
          : Duration.zero,
      child: Loupe(
        additionalFocalPointOffset: _extraFocalPointOffset,
      ),
    );
  }
}

/// A Material styled magnifying glass.
///
/// {@macro flutter.widgets.loupe.intro}
///
/// This widget focuses on mimicking the _style_ of the loupe on material. For a
/// widget that is focused on mimicking the behavior of a material loupe, see [TextEditingLoupe].
class Loupe extends StatelessWidget {
  /// Creates a [RawLoupe] in the Material style.
  ///
  /// {@macro widgets.material.loupe.androidDisclaimer}
  const Loupe({
    super.key,
    this.filmColor = const Color.fromARGB(8, 158, 158, 158),
    this.additionalFocalPointOffset = Offset.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(_borderRadius)),
    this.size = Loupe.kDefaultLoupeSize,
    this.shadows = const <BoxShadow>[
      BoxShadow(
          blurRadius: 1.5,
          offset: Offset(0, 2),
          spreadRadius: 0.75,
          color: Color.fromARGB(25, 0, 0, 0))
    ],
  });

  /// The default size of this [Loupe].
  ///
  /// The size of the loupe may be modified through the constructor;
  /// [kDefaultLoupeSize] is extracted from the default parameter of
  /// [Loupe]'s constructor so that positioners may depend on it.
  @visibleForTesting
  static const Size kDefaultLoupeSize = Size(77.37, 37.9);

  /// The vertical distance that the loupe should be above the focal point.
  ///
  /// [kStandardVerticalFocalPointShift] is an unmodifiable constant so that positioning of this
  /// [Loupe] can be done with a garunteed size, as opposed to an estimate.
  @visibleForTesting
  static const double kStandardVerticalFocalPointShift = -18;

  /// The color to tint the image in this [Loupe].
  ///
  /// On native Android, there is a almost transparent gray tint to the
  /// loupe, in orderoto better distinguish the contents of the lens from
  /// the background.
  final Color filmColor;

  static const double _borderRadius = 40;
  static const double _magnification = 1.25;

  /// The [Size] of this [Loupe].
  ///
  /// This size does not include the border.
  final Size size;

  /// The shadows for this [Loupe].
  final List<BoxShadow> shadows;

  /// The border radius for this loupe.
  final BorderRadius borderRadius;

  /// Any additional offset the focal point requires to "point"
  /// to the correct place.
  ///
  /// This is useful for instances where the loupe is not pointing to something
  /// directly below it.
  final Offset additionalFocalPointOffset;

  @override
  Widget build(BuildContext context) {
    return RawLoupe(
      decoration: LoupeDecoration(
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          shadows: shadows),
      magnificationScale: _magnification,
      focalPoint: additionalFocalPointOffset +
          Offset(0,
              kStandardVerticalFocalPointShift - kDefaultLoupeSize.height / 2),
      size: size,
      child: ColoredBox(
        color: filmColor,
      ),
    );
  }
}
