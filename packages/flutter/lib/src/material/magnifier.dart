// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// {@template widgets.material.magnifier.magnifier}
/// A [Magnifier] positioned by rules dictated by the native Android magnifier.
/// {@endtemplate}
///
/// {@template widgets.material.magnifier.positionRules}
/// Positions itself based on [magnifierInfo]. Specifically, follows the
/// following rules:
/// - Tracks the gesture's x coordinate, but clamped to the beginning and end of the
///   currently editing line.
/// - Focal point may never contain anything out of bounds.
/// - Never goes out of bounds vertically; offset until the entire magnifier is in the screen. The
///   focal point, regardless of this transformation, always points to the touch y coordinate.
/// - If just jumped between lines (prevY != currentY) then animate for duration
///   [jumpBetweenLinesAnimationDuration].
/// {@endtemplate}
class TextMagnifier extends StatefulWidget {
  /// {@macro widgets.material.magnifier.magnifier}
  ///
  /// {@template widgets.material.magnifier.androidDisclaimer}
  /// These constants and default parameters were taken from the
  /// Android 12 source code where directly transferable, and eyeballed on
  /// a Pixel 6 running Android 12 otherwise.
  /// {@endtemplate}
  ///
  /// {@macro widgets.material.magnifier.positionRules}
  const TextMagnifier({
    super.key,
    required this.magnifierInfo,
  });

  /// A [TextMagnifierConfiguration] that returns a [CupertinoTextMagnifier] on iOS,
  /// [TextMagnifier] on Android, and null on all other platforms, and shows the editing handles
  /// only on iOS.
  static TextMagnifierConfiguration adaptiveMagnifierConfiguration = TextMagnifierConfiguration(
    shouldDisplayHandlesInMagnifier: defaultTargetPlatform == TargetPlatform.iOS,
    magnifierBuilder: (
      BuildContext context,
      MagnifierController controller,
      ValueNotifier<MagnifierOverlayInfoBearer> magnifierOverlayInfoBearer,
    ) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          return CupertinoTextMagnifier(
            controller: controller,
            magnifierOverlayInfoBearer: magnifierOverlayInfoBearer,
          );
        case TargetPlatform.android:
          return TextMagnifier(
              magnifierInfo: magnifierOverlayInfoBearer,
          );
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          return null;
      }
    }
  );

  /// The duration that the position is animated if [TextMagnifier] just switched
  /// between lines.
  @visibleForTesting
  static const Duration jumpBetweenLinesAnimationDuration =
      Duration(milliseconds: 70);

  /// [TextMagnifier] positions itself based on [magnifierInfo].
  ///
  /// {@macro widgets.material.magnifier.positionRules}
  final ValueNotifier<MagnifierOverlayInfoBearer>
      magnifierInfo;

  @override
  State<TextMagnifier> createState() => _TextMagnifierState();
}

class _TextMagnifierState extends State<TextMagnifier> {
  // Should _only_ be null on construction. This is because of the animation logic.
  //
  // Animations are added when `last_build_y != current_build_y`. This condition
  // is true on the inital render, which would mean that the inital
  // build would be animated - this is undesired. Thus, this is null for the
  // first frame and the condition becomes `magnifierPosition != null && last_build_y != this_build_y`.
  Offset? _magnifierPosition;

  // A timer that unsets itself after an animation duration.
  // If the timer exists, then the magnifier animates its position -
  // if this timer does not exist, the magnifier tracks the gesture (with respect
  // to the positioning rules) directly.
  Timer? _positionShouldBeAnimatedTimer;
  bool get _positionShouldBeAnimated => _positionShouldBeAnimatedTimer != null;

  Offset _extraFocalPointOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    widget.magnifierInfo
        .addListener(_determineMagnifierPositionAndFocalPoint);
  }

  @override
  void dispose() {
    widget.magnifierInfo
        .removeListener(_determineMagnifierPositionAndFocalPoint);
    _positionShouldBeAnimatedTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _determineMagnifierPositionAndFocalPoint();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(TextMagnifier oldWidget) {
    if (oldWidget.magnifierInfo != widget.magnifierInfo) {
      oldWidget.magnifierInfo.removeListener(_determineMagnifierPositionAndFocalPoint);
      widget.magnifierInfo.addListener(_determineMagnifierPositionAndFocalPoint);
    }
    super.didUpdateWidget(oldWidget);
  }

  /// {@macro widgets.material.magnifier.positionRules}
  void _determineMagnifierPositionAndFocalPoint() {
    final MagnifierOverlayInfoBearer selectionInfo =
        widget.magnifierInfo.value;
    final Rect screenRect = Offset.zero & MediaQuery.of(context).size;

    // Since by default we draw at the top left corner, this offset
    // shifts the magnifier so we draw at the center, and then also includes
    // the "above touch point" shift.
    final Offset basicMagnifierOffset = Offset(
        Magnifier.kDefaultMagnifierSize.width / 2,
        Magnifier.kDefaultMagnifierSize.height +
            Magnifier.kStandardVerticalFocalPointShift);

    // Since the magnifier should not go past the edges of the line,
    // but must track the gesture otherwise, constrain the X of the magnifier
    // to always stay between line start and end.
    final double magnifierX = clampDouble(
        selectionInfo.globalGesturePosition.dx,
        selectionInfo.currentLineBoundaries.left,
        selectionInfo.currentLineBoundaries.right);

    // Place the magnifier at the previously calculated X, and the Y should be
    // exactly at the center of the handle.
    final Rect unadjustedMagnifierRect =
        Offset(magnifierX, selectionInfo.caretRect.center.dy) - basicMagnifierOffset &
            Magnifier.kDefaultMagnifierSize;

    // Shift the magnifier so that, if we are ever out of the screen, we become in bounds.
    // This probably won't have much of an effect on the X, since it is already bound
    // to the currentLineBoundaries, but will shift vertically if the magnifier is out of bounds.
    final Rect screenBoundsAdjustedMagnifierRect =
        MagnifierController.shiftWithinBounds(
            bounds: screenRect, rect: unadjustedMagnifierRect);

    // Done with the magnifier position!
    final Offset finalMagnifierPosition = screenBoundsAdjustedMagnifierRect.topLeft;

    // The insets, from either edge, that the focal point should not point
    // past lest the magnifier displays something out of bounds.
    final double horizontalMaxFocalPointEdgeInsets =
        (Magnifier.kDefaultMagnifierSize.width / 2) / Magnifier._magnification;

    // Adjust the focal point horizontally such that none of the magnifier
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
          screenBoundsAdjustedMagnifierRect.center.dx,
          selectionInfo.fieldBounds.left + horizontalMaxFocalPointEdgeInsets,
          selectionInfo.fieldBounds.right - horizontalMaxFocalPointEdgeInsets);
    }

    // Since the previous value is now a global offset (i.e. `newGlobalFocalPoint`
    // is now a global offset), we must subtract the magnifier's global offset
    // to obtain the relative shift in the focal point.
    final double newRelativeFocalPointX =
        newGlobalFocalPointX - screenBoundsAdjustedMagnifierRect.center.dx;

    // The Y component means that if we are pressed up against the top of the screen,
    // then we should adjust the focal point such that it now points to how far we moved
    // the magnifier. screenBoundsAdjustedMagnifierRect.top == unadjustedMagnifierRect.top for most cases,
    // but when pressed up against the top of the screen, we adjust the focal point by
    // the amount that we shifted from our "natural" position.
    final Offset focalPointAdjustmentForScreenBoundsAdjustment = Offset(
        newRelativeFocalPointX,
        unadjustedMagnifierRect.top - screenBoundsAdjustedMagnifierRect.top,
    );

    Timer? positionShouldBeAnimated = _positionShouldBeAnimatedTimer;

    if (_magnifierPosition != null && finalMagnifierPosition.dy != _magnifierPosition!.dy) {
      if (_positionShouldBeAnimatedTimer != null &&
          _positionShouldBeAnimatedTimer!.isActive) {
        _positionShouldBeAnimatedTimer!.cancel();
      }

      // Create a timer that deletes itself when the timer is complete.
      // This is `mounted` safe, since the timer is canceled in `dispose`.
      positionShouldBeAnimated = Timer(
          TextMagnifier.jumpBetweenLinesAnimationDuration,
          () => setState(() {
                _positionShouldBeAnimatedTimer = null;
              }));
    }

    setState(() {
      _magnifierPosition = finalMagnifierPosition;
      _positionShouldBeAnimatedTimer = positionShouldBeAnimated;
      _extraFocalPointOffset = focalPointAdjustmentForScreenBoundsAdjustment;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(_magnifierPosition != null,
        'Magnifier position should only be null before the first build.');

    return AnimatedPositioned(
      top: _magnifierPosition!.dy,
      left: _magnifierPosition!.dx,
      // Material magnifier typically does not animate, unless we jump between lines,
      // in which case we animate between lines.
      duration: _positionShouldBeAnimated
          ? TextMagnifier.jumpBetweenLinesAnimationDuration
          : Duration.zero,
      child: Magnifier(
        additionalFocalPointOffset: _extraFocalPointOffset,
      ),
    );
  }
}

/// A Material styled magnifying glass.
///
/// {@macro flutter.widgets.magnifier.intro}
///
/// This widget focuses on mimicking the _style_ of the magnifier on material. For a
/// widget that is focused on mimicking the behavior of a material magnifier, see [TextMagnifier].
class Magnifier extends StatelessWidget {
  /// Creates a [RawMagnifier] in the Material style.
  ///
  /// {@macro widgets.material.magnifier.androidDisclaimer}
  const Magnifier({
    super.key,
    this.additionalFocalPointOffset = Offset.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(_borderRadius)),
    this.filmColor = const Color.fromARGB(8, 158, 158, 158),
    this.shadows = const <BoxShadow>[
      BoxShadow(
          blurRadius: 1.5,
          offset: Offset(0, 2),
          spreadRadius: 0.75,
          color: Color.fromARGB(25, 0, 0, 0))
    ],
    this.size = Magnifier.kDefaultMagnifierSize,
  });

  /// The default size of this [Magnifier].
  ///
  /// The size of the magnifier may be modified through the constructor;
  /// [kDefaultMagnifierSize] is extracted from the default parameter of
  /// [Magnifier]'s constructor so that positioners may depend on it.
  @visibleForTesting
  static const Size kDefaultMagnifierSize = Size(77.37, 37.9);

  /// The vertical distance that the magnifier should be above the focal point.
  ///
  /// [kStandardVerticalFocalPointShift] is an unmodifiable constant so that positioning of this
  /// [Magnifier] can be done with a guaranteed size, as opposed to an estimate.
  @visibleForTesting
  static const double kStandardVerticalFocalPointShift = 22;

  static const double _borderRadius = 40;
  static const double _magnification = 1.25;

  /// Any additional offset the focal point requires to "point"
  /// to the correct place.
  ///
  /// This is useful for instances where the magnifier is not pointing to something
  /// directly below it.
  final Offset additionalFocalPointOffset;

  /// The border radius for this magnifier.
  final BorderRadius borderRadius;

  /// The color to tint the image in this [Magnifier].
  ///
  /// On native Android, there is a almost transparent gray tint to the
  /// magnifier, in order to better distinguish the contents of the lens from
  /// the background.
  final Color filmColor;

  /// The shadows for this [Magnifier].
  final List<BoxShadow> shadows;

  /// The [Size] of this [Magnifier].
  ///
  /// This size does not include the border.
  final Size size;

  @override
  Widget build(BuildContext context) {
    return RawMagnifier(
      decoration: MagnifierDecoration(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        shadows: shadows,
      ),
      magnificationScale: _magnification,
      focalPointOffset: additionalFocalPointOffset +
          Offset(0, kStandardVerticalFocalPointShift + kDefaultMagnifierSize.height / 2),
      size: size,
      child: ColoredBox(
        color: filmColor,
      ),
    );
  }
}
