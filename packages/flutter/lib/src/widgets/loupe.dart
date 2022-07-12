// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// {@template flutter.widgets.loupe.loupeControllerWidgetBuilder}
/// A builder that builds a Widget with a [LoupeController].
///
/// the [controller] should be passed into [Loupe.controller]. The third paramater
/// is any additional info passed to the loupe, if desired.
/// {@endtemplate}
typedef LoupeControllerWidgetBuilder<T> = Widget Function(
    BuildContext context, LoupeController controller, T data);

/// Controls an instance of a [Loupe], if this [LoupeController] is passed to [Loupe.controller].
/// If unattached to any [Loupe] (i.e., not passed to a [Loupe]), does nothing.
///
/// [LoupeController] handles driving [Loupe.transitionAnimationController]'s in / out animation
/// based on calls to show / hide, respectively.
class LoupeController {
  /// This stream is used to tell the loupe that it should begin it's enter / hide animation.
  /// The [LoupeController] sends its loupe true or false for show / hide respectively,
  /// and then waits for an acknowledgement on the stream by the loupe.
  ///
  /// The show / hide is done in this fashion because [LoupeController] shouldn't
  /// clean up the overlay until the loupe is done animating out.
  final StreamController<AnimationStatus> _animationStatus =
      StreamController<AnimationStatus>.broadcast();

  /// The loupe's [OverlayEntry], if currently visible.
  ///
  /// This is public in case other overlay entries need to be positioned
  /// above or below this [overlayEntry]. Anything in the paint order after
  /// the [Loupe] will not be displaued in the loupe; this means that if it
  /// is desired for an overlay entry to be displayed in the loupe,
  /// it _must_ be positioned below the loupe.
  ///
  /// {@tool snippet}
  /// ```dart
  ///  final myLoupeController = LoupeController();
  ///
  /// // Placed below the loupe, so it will show.
  /// Overlay.of(context).insert(
  ///   OverlayEntry(builder: (context) => Text('I WILL display in the loupe'))
  /// );
  ///
  /// /// Will display in the loupe, since this entry was passed to [show].
  /// final displayInLoupeEvenThoughPlacedBeforeChronologically = OverlayEntry(builer: (context) => Text('I WILL display in the loupe');
  /// Overlay.of(context).insert(displayInLoupeEvenThoughPlacedBeforeChronologically);
  ///
  /// myLoupeController.show(
  ///   context,
  ///   below: displayInLoupeEvenThoughPlacedBeforeChronologically,
  ///   builder: (context) => Loupe(...)
  /// );
  ///
  /// // By default, new entries will be placed over the top entry.
  /// Overlay.of(context).insert(
  ///   OverlayEntry(builer: (context) => Text('I WILL NOT display in the loupe'))
  /// );
  ///
  ///
  /// Overlay.of(context).insert(
  ///   below: myLoupeController.overlayEntry, // Explicitly placed below the loupe.
  ///   OverlayEntry(builer: (context) => Text('I WILL display in the loupe'))
  /// );
  /// ```
  /// {@end-tool}
  OverlayEntry? overlayEntry;

  /// The current status of the loupe.
  ///
  /// If the loupe is not shown (i.e. the default, or if  [hide] was called recently) [status]
  /// will be  [AnimationStatus.dismissed].  If the loupe is shown, [status] will be
  /// [AnimationStatus.completed]. If the loupe is transitioning from [AnimationStatus.dismissed]
  /// to [AnimationStatus.completed] or visa versa, [status] will be [AnimationStatus.completed] and
  /// [AnimationStatus.reverse], respectively.
  ValueNotifier<AnimationStatus> status =
      ValueNotifier<AnimationStatus>(AnimationStatus.dismissed);

  /// Shows the [Loupe] that this controller controlls.
  /// Returns a future that completes when the loupe is fully shown, i.e. done
  /// with it's entry animation.
  ///
  /// To control what overlays are shown in the loupe, utilize [below]. See
  /// [overlayEntry] for more details on how to utilize [below].
  Future<void> show({
    required BuildContext context,
    required WidgetBuilder builder,
    Widget? debugRequiredFor,
    OverlayEntry? below,
  }) {
    _forceHide();
    final OverlayState? overlayState = Overlay.of(
      context,
      rootOverlay: true,
      debugRequiredFor: debugRequiredFor,
    );

    final CapturedThemes capturedThemes = InheritedTheme.capture(
      from: context,
      to: Navigator.maybeOf(context)?.context,
    );

    overlayEntry = OverlayEntry(
      builder: (BuildContext context) => capturedThemes.wrap(builder(context)),
    );
    overlayState!.insert(below: below, overlayEntry!);

    return signalShow();
  }

  /// If there is a loupe in the overlay, but it is not shown (i.e. [hide] was called with
  /// removeFromOverlay = false), then we should reshow it. Otherwise, do nothing.
  Future<void> signalShow() async {
    if (status.value == AnimationStatus.completed ||
        status.value == AnimationStatus.forward) {
      return;
    }

    // Schedule the animation to begin in the next frame, since
    // we need the the loupe to begin listening to the status stream.
    final Completer<void> didRecieveAck = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If the loupe was force removed between this and last frame,
      // we shouldn't attempt to get an acknowledgement, since the future
      // will wait forever.
      if (overlayEntry == null) {
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

  /// hide does not immediately remove the loupe.
  Future<void> hide({bool removeFromOverlay = true}) async {
    if (overlayEntry == null) {
      return;
    }

    await _sendAnimationStatudAndAwaitAcknowledgement(
      AnimationStatus.reverse,
      AnimationStatus.dismissed,
    );

    if (removeFromOverlay) {
      _forceHide();
    }
  }

  /// Immediately hide the loupe, ignoring any exit animation.
  void _forceHide() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  Future<AnimationStatus> _sendAnimationStatudAndAwaitAcknowledgement(
      AnimationStatus message, AnimationStatus ack) async {
    assert(overlayEntry != null,
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
}

/// A decoration for a [Loupe].
///
/// [LoupeDecoration] does not expose [ShapeDecoration.color], [ShapeDecoration.image],
/// or [ShapeDecoration.gradient], since they will be covered by the [Loupe]'s lense.
///
/// Also takes an [opacity].
/// {@template flutter.widgets.loupe.opacity.reason}
/// This is because [Loupe]'s lens is backed by [BackdropFilter],
/// which, to have any opacity, must be the first decendant of [Opacity].
/// (see https://github.com/flutter/engine/pull/34435)
/// {@endtemplate}
class LoupeDecoration extends ShapeDecoration {
  /// Constructs a [LoupeDecoration].
  ///
  /// By default, is a rectangular loupe with no shadows, and fully opaque.
  const LoupeDecoration({
    this.opacity = 1,
    super.shadows,
    super.shape = const RoundedRectangleBorder(),
  });

  /// The loupe's opacity.
  ///
  /// {@macro flutter.widgets.loupe.opacity.reason}
  final double opacity;

  @override
  bool operator ==(Object other) =>
      super == other && other is LoupeDecoration && other.opacity == opacity;

  @override
  int get hashCode => Object.hash(super.hashCode, opacity);
}

/// A common building base for [Loupe]s.
///
/// A loupe can be convienently managed by [LoupeController], which handles
/// showing and hiding the loupe, with an optional entry / exit animation.
///
/// {@tool snippet}
/// A custom loupe over an image of dash, with an entry and exit animation:
///
/// {@endtool snippet}
///
/// See:
/// * [LoupeController], a controller to handle loupes in an overlay.
/// * [AndroidLoupe], the Android-style consumer of [Loupe].
/// * [CupertinoLoupe], the iOS-style consumer of [Loupe].
class Loupe extends StatefulWidget {
  /// Constructs a [Loupe].
  ///
  /// {@template flutter.widgets.loupe.loupe.invisibility_warning}
  /// By default, this loupe uses the default [LoupeDecoration],
  /// the focal point is directly under the loupe, and there is no magnification:
  /// This means that a default loupe will be entirely invisible to the user,
  /// since it is painting exactly what is under it, exactly where it was painted
  /// orignally.
  /// {@endtemplate}
  const Loupe(
      {super.key,
      required this.controller,
      this.magnificationScale = 1,
      required this.size,
      this.focalPoint = Offset.zero,
      this.child,
      this.decoration = const LoupeDecoration(),
      this.transitionAnimationController})
      : assert(magnificationScale != 0,
            'Magnification scale of 0 results in undefined behavior.');

  /// The animation controller that controls this loupes IO animations.
  ///
  /// If no [transitionAnimationController] is passed, no animations will be played
  /// and [LoupeController.show] and [LoupeController.hide] will be effectively synchronous.
  ///
  /// This animation controller will be driven forward and backwards depending
  /// on [LoupeController.show] and [LoupeController.hide]. If manually stopped
  /// during a transition, the [Loupe] will wait for the transition to complete
  /// to signal to the controller that it can be safely removed.
  final AnimationController? transitionAnimationController;

  /// This loupe's decoration.
  ///
  /// {@macro flutter.widgets.loupe.loupe.invisibility_warning}
  final LoupeDecoration decoration;

  /// The [LoupeController] for this loupe.
  ///
  /// This [Loupe] will show / hide itself based on the controller's show / hide calls.
  /// This [Loupe]'s status is always in sync with [controller.status].
  final LoupeController controller;

  /// The size of the loupe.
  ///
  /// This does not include added border; it only includes
  /// the size of the magnifier.
  final Size size;

  /// The offset of the loupe from the widget's origin.
  ///
  /// If [offset] is [Offset.zero], the loupe will be positioned
  /// with it's center directly on the the top-left corner of the draw
  /// position. The focal point will always be exactly on the draw position.
  final Offset focalPoint;

  /// An optional widget to posiiton inside the len of the [Loupe].
  ///
  /// This is positioned over the [Loupe] - it may be useful for tinting the
  /// [Loupe], or drawing a crosshair like UI.
  final Widget? child;

  /// How "zoomed in" the magnification subject is in the lens.
  final double magnificationScale;

  @override
  State<Loupe> createState() => _LoupeState();
}

class _LoupeState extends State<Loupe> {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Opacity(
          opacity: widget.decoration.opacity,
          child: _Magnifier(
              focalPoint: widget.focalPoint,
              shape: widget.decoration.shape,
              magnificationScale: widget.magnificationScale,
              child: SizedBox.fromSize(
                size: widget.size,
                child: widget.child,
              )),
        ),
        Opacity(
          opacity: widget.decoration.opacity,
          child: _LoupeStyle(
            widget.decoration,
            size: widget.size,
          ),
        )
      ],
    );
  }
}

class _LoupeStyle extends StatelessWidget {
  const _LoupeStyle(this.decoration, {required this.size});

  final LoupeDecoration decoration;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipBehavior: Clip.hardEdge,
      clipper: _DonutClip(
        shape: decoration.shape,
      ),
      child: DecoratedBox(
        decoration: decoration,
        child: SizedBox.fromSize(
          size: size,
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

class _Magnifier extends SingleChildRenderObjectWidget {
  /// Construct a [_Magnifier],
  _Magnifier(
      {super.child,
      ShapeBorder? shape,
      this.magnificationScale = 1,
      this.focalPoint = Offset.zero})
      : clip = shape != null
            ? ShapeBorderClipper(
                shape: shape,
              )
            : null;

  ///  [focalPoint] of the magnifier is the area the center of the
  /// [_Magnifier] points to, relative to the center of the magnifier.
  /// If left as [Offset.zero], the magnifier will magnify whatever is directly
  /// below it.
  final Offset focalPoint;

  /// The scale of the magnification.
  ///
  /// A [magnificationScale] of 1 means that the content magi
  final double magnificationScale;

  /// The shape of the magnifier is dictated by [clip], which clips
  /// the magnifier to the shape. If null, the shape will be rectangular.
  final ShapeBorderClipper? clip;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMagnification(focalPoint, magnificationScale, clip);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMagnification renderObject) {
    renderObject
      ..focalPoint = focalPoint
      ..clip = clip
      ..magnificationScale = magnificationScale;
  }
}

class _RenderMagnification extends RenderProxyBox {
  _RenderMagnification(
    this._focalPoint,
    this._magnificationScale,
    this._clip, {
    RenderBox? child,
  }) : super(child);

  Offset get focalPoint => _focalPoint;
  Offset _focalPoint;
  set focalPoint(Offset value) {
    if (_focalPoint == value) {
      return;
    }
    _focalPoint = value;
    markNeedsLayout();
  }

  double get magnificationScale => _magnificationScale;
  double _magnificationScale;
  set magnificationScale(double value) {
    if (_magnificationScale == value) {
      return;
    }
    _magnificationScale = value;
    markNeedsLayout();
  }

  CustomClipper<Path>? get clip => _clip;
  CustomClipper<Path>? _clip;
  set clip(CustomClipper<Path>? value) {
    if (_clip == value) {
      return;
    }
    _clip = value;
    markNeedsLayout();
  }

  @override
  _MagnificationLayer? get layer => super.layer as _MagnificationLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (layer == null) {
      layer = _MagnificationLayer(
          size: size,
          globalPosition: offset,
          focalPoint: focalPoint,
          clip: clip,
          magnificationScale: magnificationScale);
    } else {
      layer!
        ..magnificationScale = magnificationScale
        ..size = size
        ..globalPosition = offset
        ..focalPoint = focalPoint;
    }

    BackdropFilterLayer()
    context.pushLayer(layer!, super.paint, offset);
  }
}

class _MagnificationLayer extends ContainerLayer {
  _MagnificationLayer(
      {required this.size,
      required this.globalPosition,
      required this.clip,
      required this.focalPoint,
      required this.magnificationScale});

  Offset globalPosition;
  Size size;

  Offset focalPoint;
  double magnificationScale;

  CustomClipper<Path>? clip;

  ClipPathEngineLayer? _clipPathEngineLayer;
  BackdropFilterEngineLayer? _backdropFilterLayer;

  @override
  void addToScene(SceneBuilder builder) {
    _clipPathEngineLayer = builder.pushClipPath(
        clip!.getClip(size).shift(globalPosition),
        oldLayer: _clipPathEngineLayer);

    // Create and push transform.
    final Offset thisCenter = Alignment.center.alongSize(size) + globalPosition;
    final Matrix4 matrix = Matrix4.identity()
      ..translate(
          magnificationScale * (focalPoint.dx - thisCenter.dx) + thisCenter.dx,
          magnificationScale * (focalPoint.dy - thisCenter.dy) + thisCenter.dy)
      ..scale(magnificationScale);

    _backdropFilterLayer = builder.pushBackdropFilter(
        ImageFilter.matrix(matrix.storage),
        oldLayer: _backdropFilterLayer);

    builder.pop();

    super.addToScene(builder);
    builder.pop();
  }
}
