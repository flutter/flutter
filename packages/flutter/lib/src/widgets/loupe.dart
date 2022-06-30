// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A builder that builds a Widget with a [LoupeController].
///
/// Used in contexts where a loupe may or may not display, since a [Loupe] requires a
/// [LoupeController].
typedef LoupeControllerWidgetBuilder = Widget Function(
    BuildContext context, LoupeController controller);

/// Controls an instance of a [Loupe].
class LoupeController {
  /// This stream is used to tell the loupe that it should begin it's enter / hide animation.
  /// The [LoupeController] sends its loupe true or false for show / hide respectively,
  /// and then waits for an acknowledgement on the stream by the loupe.
  ///
  /// The show / hide is done in this fashion because [LoupeController] shouldn't
  /// clean up the overlay until the loupe is done animating out.
  final StreamController<AnimationStatus> _animationStatus =
      StreamController<AnimationStatus>.broadcast();

  OverlayEntry? _loupeEntry;

  /// If the loupe managed by this controller is shown or not.
  ///
  /// If the loupe is mid out animation, this will be true until the loupe is done animating out.
  ValueNotifier<AnimationStatus> status =
      ValueNotifier<AnimationStatus>(AnimationStatus.dismissed);

  final ValueNotifier<Offset> requestedPosition =
      ValueNotifier<Offset>(Offset.zero);

  /// Returns a future that completes when the loupe is fully shown, i.e. done
  /// with it's entry animation.
  Future<void> show({
    required BuildContext context,
    required WidgetBuilder builder,
    Widget? debugRequiredFor,
    Offset initalPosition = Offset.zero,
  }) async {
    _forceHide();
    final OverlayState? overlayState = Overlay.of(
      context,
      rootOverlay: true,
      debugRequiredFor: debugRequiredFor,
    );

    requestedPosition.value = initalPosition;

    final CapturedThemes capturedThemes = InheritedTheme.capture(
      from: context,
      to: Navigator.maybeOf(context)?.context,
    );

    _loupeEntry = OverlayEntry(
      builder: (BuildContext context) => capturedThemes.wrap(builder(context)),
    );
    overlayState!.insert(_loupeEntry!);

    // Schedule the animation to begin in the next frame, since
    // we need the the loupe to begin listening to the status stream.
    final Completer<void> didRecieveAck = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If the loupe was force removed between this and last frame,
      // we shouldn't attempt to get an acknowledgement, since the future
      // will wait forever.
      if (_loupeEntry == null) {
        didRecieveAck.complete();
        return;
      }

      _sendAnimationStatudAndAwaitAcknowledgement(
        AnimationStatus.forward,
        AnimationStatus.completed,
      ).then((_) => didRecieveAck.complete());
    });

    return didRecieveAck.future;
  }

  /// hide does not immediately remove the loupe, since it's possible that
  Future<void> hide() async {
    if (_loupeEntry == null) {
      return;
    }

    await _sendAnimationStatudAndAwaitAcknowledgement(
      AnimationStatus.reverse,
      AnimationStatus.dismissed,
    );
    _forceHide();
  }

  /// Immediately hide the loupe, not executing any exit animation.
  void _forceHide() {
    _loupeEntry?.remove();
    _loupeEntry = null;
  }

  Future<AnimationStatus> _sendAnimationStatudAndAwaitAcknowledgement(
      AnimationStatus message, AnimationStatus ack) async {
    assert(_loupeEntry != null,
        'attempted to update animation status with no loupe.');

    // Setup a future that waits for the acknowledgement. Skip the first message,
    //since it's the initalization message.
    final Future<AnimationStatus> acknowedgementFuture = _animationStatus.stream
        .skip(1)
        .firstWhere((AnimationStatus element) => element == ack);

    status.value = message;
    _animationStatus.add(message);

    await acknowedgementFuture;

    status.value = ack;
    return ack;
  }

  /// A utility for calculating a new [Rect] from this rect such that
  /// [rect] is fully constrained within [bounds], that is, any point
  /// in the output rect is guaranteed to also be a point in [bounds].
  ///
  /// It is a runtime error for [rect.width] to be greater than [bounds.width],
  /// and it is also an error for [rect.height] to be greater than [bounds.height].
  ///
  /// This algorithm makes no guarantees about where this is placed within [bounds],
  /// only that the entirety of the output rect is inside [bounds].
  ///
  /// It is perfectly valid for the output rect to have a point along the edge of the
  /// [bounds]. If the desired output rect requires that no edges are parrellel to edges
  /// of [bounds], see [Rect.deflate] by 1 on [bounds] to achieve this effect.
  static Rect shiftWithinBounds({
    required Rect rect,
    required Rect bounds,
  }) {
    assert(rect.width <= bounds.width,
        'attempted to shift $rect within $bounds, but the rect has a greater width.');
    assert(rect.height <= bounds.height,
        'attempted to shift $rect within $bounds, but the rect has a greater height.');

    Offset rectShift = Offset.zero;
    if (rect.left < bounds.left) {
      rectShift += Offset(bounds.left - rect.left, 0);
    } else if (rect.right > bounds.right) {
      rectShift += Offset(bounds.right - rect.right, 0);
    }

    if (rect.top < bounds.top) {
      rectShift += Offset(0, bounds.top - rect.top);
    } else if (rect.bottom > bounds.bottom) {
      rectShift += Offset(0, bounds.bottom - rect.bottom);
    }

    return rect.shift(rectShift);
  }

  /// A utility for calculating a new focal point based off of an old focal point,
  /// as well as
  static Offset shiftFocalPoint({
    required Offset oldFocalPoint,
  }) {
    return oldFocalPoint;
  }
}

/// A common building base for Loupes, that is managed nby a
///
/// See:
/// * [LoupeController], a convienence class to handle loupes in an overlay.
/// * [AndroidLoupe], the Android-style consumer of [Loupe].
/// * [CupertinoLoupe], the iOS-style consumer of [Loupe].
class Loupe extends StatefulWidget {
  const Loupe(
      {super.key,
      this.border,
      required this.controller,
      this.shape = const RoundedRectangleBorder(),
      required this.shadowColor,
      this.magnificationScale = 1,
      this.elevation = 0,
      required this.size,
      this.focalPoint = Offset.zero,
      this.child,
      this.positionAnimationDuration = Duration.zero,
      this.positionAnimation = Curves.linear,
      this.transitionAnimationController})
      : assert(magnificationScale != 0,
            'Magnification scale of 0 results in undefined behavior.');

  final AnimationController? transitionAnimationController;

  final Duration positionAnimationDuration;
  final Curve positionAnimation;

  final LoupeController controller;

  /// The size of the loupe.
  ///
  /// This does not include added border; it only includes
  /// the size of the underlying [_Magnifier].
  final Size size;

  /// The offset of the loupe from the widget's origin.
  ///
  /// If [offset] is [Offset.zero], the loupe will be positioned
  /// with it's center directly on the the top-left corner of the draw
  /// position. The focal point will always be exactly on the draw position.
  ///
  /// Since the loupe is never displayed out of bounds, this offset will be shrunk
  /// in the case that the offset
  final Offset focalPoint;

  /// The corner radius of the loupe.
  final Radius borderRadius;

  /// An optional border for the loupe.
  ///
  /// This border respects [borderRadius] and wraps the
  /// entire [_Magnifier].
  final Border? border;

  /// The color of the shadow that the [Loupe] casts.
  ///
  /// The shadow will not be shown in the [Loupe], irrespective of
  /// [offset] and [elevation].
  final Color shadowColor;

  /// The elevation of the loupe, backed by [PhysicalModel.elevation].
  final double elevation;

  /// An optional widget to posiiton inside the len of the [_Magnifier].
  ///
  /// This is positioned over the [_Magnifier] - it may be useful for tinting the
  /// [_Magnifier], or drawing a crosshair like UI.
  final Widget? child;

  /// How "zoomed in" the magnification subject is in the lens.
  ///
  /// this is a pass-through paramater for [_Magnifier.magnificationScale].
  final double magnificationScale;

  @override
  State<Loupe> createState() => _LoupeState();
}

class _LoupeState extends State<Loupe> with SingleTickerProviderStateMixin {
  late StreamSubscription<AnimationStatus> _animationRequestsSubscription;

  @override
  void initState() {
    if (widget.transitionAnimationController == null) {
      _animationRequestsSubscription = widget.controller._animationStatus.stream
          .listen(_onNoAnimationTransitionRequest);
    } else {
      _animationRequestsSubscription = widget.controller._animationStatus.stream
          .listen(_onAnimateTransitionRequest);
    }

    super.initState();
  }

  @override
  void dispose() {
    _animationRequestsSubscription.cancel();
    super.dispose();
  }

  // Automatically signals to the controller that the animation is complete,
  // since there is no animation to run.
  void _onNoAnimationTransitionRequest(AnimationStatus animationStatus) {
    switch (animationStatus) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        break;
      case AnimationStatus.forward:
        widget.controller._animationStatus.add(AnimationStatus.completed);
        break;
      case AnimationStatus.reverse:
        widget.controller._animationStatus.add(AnimationStatus.dismissed);
        break;
    }
  }

  // Runs the animation in the desired direction, then, when the animation is
  // complete, signals to the controller that the animation is complete.
  void _onAnimateTransitionRequest(AnimationStatus animationStatus) async {
    switch (animationStatus) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        break;
      case AnimationStatus.forward:
        await widget.transitionAnimationController!.forward();
        widget.controller._animationStatus.add(AnimationStatus.completed);
        break;
      case AnimationStatus.reverse:
        await widget.transitionAnimationController!.reverse();
        widget.controller._animationStatus.add(AnimationStatus.dismissed);
        break;
    }
  }

  /*
  /// Adjust both the focal point and the lens position.
  ///
  /// The adjustments are made based on two factors:
  /// 1. Since the Loupe should never go out of bounds, but the Y axis should show
  void _setAdjustedFocalPointAndLensPosition() {
    final Size screenSize = MediaQuery.of(context).size;

    // The raw position that the lens would be at, prior to any adjustment.
    final Offset unadjustedLensPosition =
        widget.configuration._rawLoupePosition.value -
            Alignment.bottomCenter.alongSize(widget.size) +
            Offset(0, widget.verticalOffset);

    // Adjust the lens position so that even if the offset "asks" us to draw the lens off the screen,
    // the lens position gets adjusted so that it does not draw off the screen.
    final Offset adjustedLensPosition = Offset(
      unadjustedLensPosition.dx.clamp(0, screenSize.width - widget.size.width),
      unadjustedLensPosition.dy
          .clamp(0, screenSize.height - widget.size.height),
    );

    //how far the focal point can be away from the border before it starts to peer out
    final double horizontalFocalPointClamp = (widget.magnificationScale - 1) *
        (widget.size.width / (2 * widget.magnificationScale));

    // Adjust the focal point so that if the lens presses up against the top of the screen and
    // the lens stops moving, the focal point continues to track the offset. Clamped
    // so that the lens doesn't ever point offscreen.
    final Offset adjustedFocalPointOffsetFromCenter = Offset(
        (adjustedLensPosition.dx - unadjustedLensPosition.dx)
            .clamp(-horizontalFocalPointClamp, horizontalFocalPointClamp),
        (widget.verticalOffset - Alignment.center.alongSize(widget.size).dy) +
            (adjustedLensPosition.dy - unadjustedLensPosition.dy));

    // setState not called here because parent widget calls setState when
    // value notifier gets updated.,
    _focalPointOffsetFromCenter = adjustedFocalPointOffsetFromCenter;
    widget.configuration._adjustedLoupePosition.value = adjustedLensPosition;
  }
  */

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        ClipPath.shape(
          shape: widget.shape,
          child: BackdropFilter(
            filter: _createMagnificationFilter(),
            blendMode: BlendMode.src,
            child: SizedBox.fromSize(size: widget.size, child: widget.child),
          ),
        ),
        _LoupeStyle(
            shape: widget.shape,
            elevation: widget.elevation,
            size: widget.size,
            border: widget.border,
            shadowColor: widget.shadowColor)
      ],
    );
  }

  ImageFilter _createMagnificationFilter() {
    final magnifierMatrix = Matrix4.identity()
      ..translate(widget.focalPoint.dx * widget.magnificationScale,
          widget.focalPoint.dy * widget.magnificationScale)
      ..scale(widget.magnificationScale, widget.magnificationScale);

    return ImageFilter.matrix(magnifierMatrix.storage);
  }
}

class _LoupeStyle extends StatelessWidget {
  const _LoupeStyle(
      {required this.borderRadius,
      required this.elevation,
      required this.size,
      required this.shadowColor,
      this.border});

  final Radius borderRadius;
  final double elevation;
  final Size size;
  final Color shadowColor;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(borderRadius), border: border),
      child: ClipPath(
        clipBehavior: Clip.hardEdge,
        clipper: _DonutClip(
          borderRadius: borderRadius,
        ),
        child: PhysicalModel(
          borderRadius: BorderRadius.all(borderRadius),
          shadowColor: shadowColor,
          elevation: elevation,
          color: const Color.fromARGB(255, 255, 255, 255),
          child: Container(
            decoration:
                BoxDecoration(borderRadius: BorderRadius.all(borderRadius)),
            child: SizedBox.fromSize(
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}

/// A clipPath that looks like a donut if you were to fill it's area.
///
/// This is necessary because the shadow must be added after the loupe is drawn,
/// so that the shadow does not end up in the loupe. Without this clip, the loupe would be
/// entirely covered by the shadow.
///
/// The negative space of the donut is clipped out (the donut hole, outside the donut).
/// Rhe donut hole is cut out exactly like the shape of the Loupe.
class _DonutClip extends CustomClipper<Path> {
  _DonutClip({required this.borderRadius});

  /// this constant is derrived from [RenderPhysicalShape].
  /// https://github.com/flutter/flutter/blob/ac7e29a40f9ecf701508f76f0ea91cca9ab147b0/packages/flutter/lib/src/rendering/proxy_box.dart#L2061-L2067
  static const double _kEstimatedWidestShadowLoupeBounds = 20.0;

  /// The border radius of the inner bounds of the shadow.
  final Radius borderRadius;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final RRect rect =
        RRect.fromRectAndRadius(Offset.zero & size, borderRadius);
    path.addRRect(rect);
    path.fillType = PathFillType.evenOdd;
    final RRect outerRect = rect.inflate(_kEstimatedWidestShadowLoupeBounds);
    path.addRRect(outerRect);
    return path;
  }

  @override
  bool shouldReclip(_DonutClip oldClipper) =>
      oldClipper.borderRadius != borderRadius;
}
