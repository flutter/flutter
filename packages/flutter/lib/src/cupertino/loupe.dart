// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// A [CupertinoLoupe], specifically for text editing.
///
/// Delegates styling to [CupertinoLoupe] with its positioned depending on
/// [loupeSelectionOverlayInfoBearer].
///
/// Specifically, the [CupertinoTextEditingLoupe] follows the following rules.
/// [CupertinoTextEditingLoupe]:
/// - is positioned horizontally outside the screen width, with _kHorizontalScreenEdgePadding padding.
/// - is hidden if a gesture is detected _kHideIfBelowThreshold units below the line that the loupe is on, shown otherwise.
/// - follows the X of the gesture directly (with respect to rule 1).
/// - has some vertical drag resistance; i.e. if a gesture is detected k units below the field,
/// then has vertical offset _kDragResistance * k.
class CupertinoTextEditingLoupe extends StatefulWidget {
  /// Construct a [RawLoupe] in the Cupertino style, positioning with respect to
  /// [loupeSelectionOverlayInfoBearer].
  ///
  /// The default constructor parameters and constants were eyeballed on
  /// an iPhone XR iOS v15.5.
  const CupertinoTextEditingLoupe({
    super.key,
    required this.controller,
    required this.loupeSelectionOverlayInfoBearer,
    this.dragResistance = 10.0,
    this.hideBelowThreshold = -48.0,
    this.horizontalScreenEdgePadding = 10.0,
    this.animationCurve = Curves.easeOut,
  });

  /// The curve used for the in / out animations.
  final Curve animationCurve;

  /// A drag resistance on the downward Y position of the lens.
  final double dragResistance;

  /// The difference in Y between the gesture position and the carat center
  /// so that the loupe hides itself.
  final double hideBelowThreshold;

  /// The padding on either edge of the screen that any part of the loupe
  /// cannot exist past.
  ///
  /// This includes the entire loupe, not just the center.
  ///
  /// If the screen has width w, then the loupe is bound to
  /// `_kHorizontalScreenEdgePadding, w - _kHorizontalScreenEdgePadding`.
  final double horizontalScreenEdgePadding;

  /// The duration that the loupe drags behind it's final position.
  static const Duration _kDragAnimationDuration = Duration(milliseconds: 45);

  /// This loupe's controller.
  ///
  /// The [CupertinoTextEditingLoupe] requires a [LoupeController]
  /// in order to show / hide itself without removing itself from the
  /// overlay.
  final LoupeController controller;

  /// [CupertinoTextEditingLoupe] will determine it's own positioning
  /// based on the [LoupeSelectionOverlayInfoBearer] of this notifier.
  final ValueNotifier<LoupeSelectionOverlayInfoBearer>
      loupeSelectionOverlayInfoBearer;

  @override
  State<CupertinoTextEditingLoupe> createState() =>
      _CupertinoTextEditingLoupeState();
}

class _CupertinoTextEditingLoupeState extends State<CupertinoTextEditingLoupe>
    with SingleTickerProviderStateMixin {
  // Initalize to dummy values for the event that the inital call to
  // _determineLoupePositionAndFocalPoint calls hide, and thus does not
  // set these values.
  Offset _currentAdjustedLoupePosition = Offset.zero;
  double _verticalFocalPointAdjustment = 0;
  late AnimationController _ioAnimationController;
  late Animation<double> _ioAnimation;

  @override
  void initState() {
    _ioAnimationController = AnimationController(
      value: 0,
      vsync: this,
      duration: CupertinoLoupe._kInOutAnimationDuration,
    )..addListener(() => setState(() {}));

    widget.controller.animationController = _ioAnimationController;
    widget.loupeSelectionOverlayInfoBearer
        .addListener(_determineLoupePositionAndFocalPoint);

    _ioAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
        parent: _ioAnimationController, curve: widget.animationCurve));

    super.initState();
  }

  @override
  void dispose() {
    widget.controller.animationController = null;
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
        widget.hideBelowThreshold) {
      // Only signal a hide if we are currently showing.
      if (widget.controller.shown) {
        widget.controller.hide(removeFromOverlay: false);
      }
      return;
    }

    // If we are gone, but got to this point, we shouldn't be: show.
    if (!widget.controller.shown) {
      _ioAnimationController.forward();
    }

    // Never go above the center of the line, but have some resistance
    // going downward if the drag goes too far.
    final double verticalPositionOfLens = math.max(
        verticalCenterOfCurrentLine,
        verticalCenterOfCurrentLine -
            (verticalCenterOfCurrentLine -
                    textEditingContext.globalGesturePosition.dy) /
                widget.dragResistance);

    // The raw position, tracking the gesture directly.
    final Offset rawLoupePosition = Offset(
      textEditingContext.globalGesturePosition.dx -
          CupertinoLoupe.kDefaultSize.width / 2,
      verticalPositionOfLens -
          (CupertinoLoupe.kDefaultSize.height -
              CupertinoLoupe.kLoupeAboveFocalPoint),
    );

    final Rect screenRect = Offset.zero & MediaQuery.of(context).size;

    // Adjust the loupe position so that it never exists outside the horizontal
    // padding.
    final Offset adjustedLoupePosition = LoupeController.shiftWithinBounds(
      bounds: Rect.fromLTRB(
          screenRect.left + widget.horizontalScreenEdgePadding,
          // iOS doesn't reposition for Y, so we should expand the threshold
          // so we can send the whole loupe out of bounds if need be.
          screenRect.top -
              (CupertinoLoupe.kDefaultSize.height +
                  CupertinoLoupe.kLoupeAboveFocalPoint),
          screenRect.right - widget.horizontalScreenEdgePadding,
          screenRect.bottom +
              (CupertinoLoupe.kDefaultSize.height +
                  CupertinoLoupe.kLoupeAboveFocalPoint)),
      rect: rawLoupePosition & CupertinoLoupe.kDefaultSize,
    ).topLeft;

    setState(() {
      _currentAdjustedLoupePosition = adjustedLoupePosition;
      // The lens should always point to the center of the line.
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
        inOutAnimation: _ioAnimation,
        additionalFocalPointOffset: Offset(0, _verticalFocalPointAdjustment),
      ),
    );
  }
}

/// A [RawLoupe] in the Cupertino style.
///
/// [CupertinoLoupe] is a wrapper around [RawLoupe] that handles styling
/// and transitions.
///
/// {@macro flutter.widgets.loupe.intro}
///
///
/// See also:
/// * [RawLoupe], the backing implementation.
/// * [CupertinoTextEditingLoupe], a widget that positions [CupertinoLoupe] based on
/// [LoupeSelectionOverlayInfoBearer].
/// * [LoupeController], the controller for this loupe.
class CupertinoLoupe extends StatelessWidget {
  /// Creates a [RawLoupe] in the Cupertino style.
  ///
  /// The default constructor parameters and constants were eyeballed on
  /// an iPhone XR iOS v15.5.
  const CupertinoLoupe({
    super.key,
    this.size = kDefaultSize,
    this.borderRadius = const BorderRadius.all(Radius.elliptical(60, 50)),
    this.additionalFocalPointOffset = Offset.zero,
    this.borderSide =
        const BorderSide(color: Color.fromARGB(255, 235, 235, 235)),
    this.inOutAnimation,
  });
  // These constants were eyeballed on an iPhone XR iOS v15.5.

  /// The border, or "rim", of this loupe.
  final BorderSide borderSide;

  /// The vertical offset, that the loupe is along the Y axis above
  /// the focal point.
  @visibleForTesting
  static const double kLoupeAboveFocalPoint = -25;

  /// The default size of the loupe.
  ///
  /// This is public so that positioners can choose to depend on it, although
  /// it is overrideable.
  @visibleForTesting
  static const Size kDefaultSize = Size(82.5, 45);

  /// The duration that this loupe animates in / out for.
  ///
  /// The animation is a translation and a fade. The translation
  /// begins at the focal point, and ends at [kLoupeAboveFocalPoint].
  /// The opacity begins at 0 and ends at 1.
  static const Duration _kInOutAnimationDuration = Duration(milliseconds: 150);

  /// The size of this loupe.
  final Size size;

  /// The border radius of this loupe.
  final BorderRadius borderRadius;

  /// This [RawLoupe]'s controller.
  ///
  /// Since [CupertinoLoupe] has no knowledge of shown / hidden state,
  /// this animation should be driven by an external actor.
  final Animation<double>? inOutAnimation;

  /// Any additional focal point offset, applied over the regular focal
  /// point offset defined in [loupeAboveFocalPoint].
  final Offset additionalFocalPointOffset;

  @override
  Widget build(BuildContext context) {
    Offset focalPointOffset =
        Offset(0, kLoupeAboveFocalPoint - kDefaultSize.height / 2);
    focalPointOffset.scale(1, inOutAnimation?.value ?? 1);
    focalPointOffset += additionalFocalPointOffset;

    return Transform.translate(
        offset: Offset.lerp(
          const Offset(0, -kLoupeAboveFocalPoint),
          Offset.zero,
          inOutAnimation?.value ?? 1,
        )!,
        child: RawLoupe(
          size: size,
          focalPoint: focalPointOffset,
          decoration: LoupeDecoration(
            opacity: inOutAnimation?.value ?? 1,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius,
              side: borderSide,
            ),
            shadows: const <BoxShadow>[
              BoxShadow(
                color: Color.fromARGB(34, 0, 0, 0),
                blurRadius: 5,
                spreadRadius: 0.2,
                offset: Offset(0, 3),
              )
            ],
          ),
        ));
  }
}
