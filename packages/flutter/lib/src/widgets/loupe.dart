// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A builder function that builds a loupe with a given offset.
///
/// This function should be called exactly once when the loupe should
/// be displayed, and then any time the loupe needs to be moved, the
/// passed-by-refrence [ValueNotifier]'s offset should be updated.
///
/// If called again, the loupe builder will build another loupe,
/// not update the position of the old one - this is so that the
/// Loupe can respect animations as well as restrain it's own position
/// so it remains on screen.
///
/// Although this builder can theoretically return any widget,
/// it should be a widget composed around a [Loupe], and that [Loupe]
/// should be passed the [LoupeConfiguration]. The [LoupeConfiguration]
/// handles the positioning and overlay management.
typedef LoupeBuilder = Widget Function(BuildContext, LoupeConfiguration);

class LoupeConfiguration {
  LoupeConfiguration._(Offset initalOffset)
      : _loupePosition = ValueNotifier<Offset>(initalOffset);

  /// We use a global offset as opposed to a layerLink and relative offset (like other
  /// text-related overlays, like toolbar or handles) because the loupe manages it's own
  /// animations, as well as has the responsibility of repositioning itself on the screen
  /// so that it never overflows.
  final ValueNotifier<Offset> _loupePosition;

  /// This stream is used to tell the loupe that it should begin it's enter / hide animation.
  /// The [LoupeController] sends its loupe true or false for show / hide respectively,
  /// and then waits for an acknowledgement on the stream by the loupe.
  ///
  /// The show / hide is done in this fashion because [LoupeController] shouldn't
  /// clean up the overlay until the loupe is done animating out.
  final StreamController<AnimationStatus> _animationStatus =
      StreamController<AnimationStatus>.broadcast();
}

/// Controls an instance of a [Loupe].
class LoupeController {
  final LoupeBuilder _loupeBuilder;

  LoupeController({required LoupeBuilder loupeBuilder})
      : _loupeBuilder = loupeBuilder;

  OverlayEntry? _loupeEntry;
  LoupeConfiguration? _currentLoupeConfiguation;

  /// If the loupe managed by this controller is shown or not.
  ///
  /// If the loupe is mid out animation, this will be true until the loupe is done animating out.
  bool get isShown => _loupeEntry != null;


  /// Returns a future that completes when the loupe is fully shown, i.e. done
  /// with it's entry animation.
  Future<void> show({
    required BuildContext context,
    Widget? debugRequiredFor,
    Offset initalPosition = Offset.zero,
  }) async {
    _forceHide();
    _currentLoupeConfiguation = LoupeConfiguration._(initalPosition);
    final OverlayState? overlayState = Overlay.of(
      context,
      rootOverlay: true,
      debugRequiredFor: debugRequiredFor,
    );

    final CapturedThemes capturedThemes = InheritedTheme.capture(
      from: context,
      to: Navigator.maybeOf(context)?.context,
    );

    _loupeEntry = OverlayEntry(
      builder: (BuildContext context) => capturedThemes
          .wrap(_loupeBuilder(context, _currentLoupeConfiguation!)),
    );
    overlayState!.insert(_loupeEntry!);
    await _sendMessageAndAwaitAcknowledgement(
      _currentLoupeConfiguation!._animationStatus,
      AnimationStatus.forward,
      AnimationStatus.completed,
    );
  }

  /// hide does not immediately remove the loupe, since it's possible that
  Future<void> hide() async {
    if (_currentLoupeConfiguation == null || _loupeEntry == null) {
      return;
    }

    await _sendMessageAndAwaitAcknowledgement<AnimationStatus>(
      _currentLoupeConfiguation!._animationStatus,
      AnimationStatus.reverse,
      AnimationStatus.dismissed,
    );
    _forceHide();
  }

  /// Immediately hide the loupe, not executing any exit animation.
  void _forceHide() {
    _loupeEntry?.remove();
    _loupeEntry = null;
    _currentLoupeConfiguation = null;
  }

  static Future<T> _sendMessageAndAwaitAcknowledgement<T>(
      StreamController<T> streamController, T message, T ack) {
    // Setup a future that waits for the acknowledgement. Skip the first message, since it's
    // the initalization message.
    final Future<T> acknowedgementFuture = streamController.stream
        .skip(1)
        .firstWhere((T element) => element == message);

    // Send initalization message.
    streamController.sink.add(message);

    return acknowedgementFuture;
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
      this.borderRadius = Radius.zero,
      required this.shadowColor,
      this.magnificationScale = 1,
      this.elevation = 0,
      required this.size,
      this.verticalOffset = 0,
      this.child,
      required this.configuration,
      this.positionAnimationDuration = Duration.zero,
      this.positionAnimation = Curves.linear,
      this.transitionAnimationController})
      : assert(magnificationScale != 0,
            'Magnification scale of 0 results in undefined behavior.');

  final AnimationController? transitionAnimationController;

  final Duration positionAnimationDuration;
  final Curve positionAnimation;

  final LoupeConfiguration configuration;

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
  final double verticalOffset;

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
  late Offset _lensPosition;
  late Offset _focalPointOffsetFromCenter;

  late StreamSubscription<AnimationStatus> _animationRequestsSubscription;

  @override
  void initState() {
    widget.configuration._loupePosition
        .addListener(_setAdjustedFocalPointAndLensPosition);

    if (widget.transitionAnimationController == null) {
      _animationRequestsSubscription = widget
          .configuration._animationStatus.stream
          .listen(_onNoAnimationTransitionRequest);
    } else {
      _animationRequestsSubscription = widget
          .configuration._animationStatus.stream
          .listen(_onAnimateTransitionRequest);
    }

    super.initState();
  }

  @override
  void dispose() {
    _animationRequestsSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _setAdjustedFocalPointAndLensPosition();
    super.didChangeDependencies();
  }

  // Automatically signals to the controller that the animation is complete,
  // since there is no animation to run.
  void _onNoAnimationTransitionRequest(AnimationStatus animationStatus) {
    switch (animationStatus) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        break;
      case AnimationStatus.forward:
        widget.configuration._animationStatus.sink
            .add(AnimationStatus.completed);
        break;
      case AnimationStatus.reverse:
        widget.configuration._animationStatus.sink
            .add(AnimationStatus.dismissed);
        break;
    }
  }

  // Runs the animation in the desired direction, then, when the animation is
  // complete, signals to the controller that the animation is complete.
  void _onAnimateTransitionRequest(AnimationStatus animationStatus) {
    switch (animationStatus) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        break;
      case AnimationStatus.forward:
        widget.transitionAnimationController!.forward().then((_) => widget
            .configuration._animationStatus.sink
            .add(AnimationStatus.completed));
        break;
      case AnimationStatus.reverse:
        widget.transitionAnimationController!.reverse().then((_) => widget
            .configuration._animationStatus.sink
            .add(AnimationStatus.dismissed));
        break;
    }
  }

  /// Adjust both the focal point and the lens position.
  ///
  /// The adjustments are made based on two factors:
  /// 1. Since the Loupe should never go out of bounds, but the Y axis should show
  void _setAdjustedFocalPointAndLensPosition() {
    final Size screenSize = MediaQuery.of(context).size;

    // The raw position that the lens would be at, prior to any adjustment.
    final Offset unadjustedLensPosition =
        widget.configuration._loupePosition.value -
            Alignment.bottomCenter.alongSize(widget.size) +
            Offset(0, widget.verticalOffset);

    // Adjust the lens position so that even if the offset "asks" us to draw the lens off the screen,
    // the lens position gets adjusted so that it does not draw off the screen.
    final Offset adjustedLensPosition = _lensPosition = Offset(
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
        (_lensPosition.dx - unadjustedLensPosition.dx)
            .clamp(-horizontalFocalPointClamp, horizontalFocalPointClamp),
        (widget.verticalOffset - Alignment.center.alongSize(widget.size).dy) +
            (_lensPosition.dy - unadjustedLensPosition.dy));

    setState(() {
      _focalPointOffsetFromCenter = adjustedFocalPointOffsetFromCenter;
      _lensPosition = adjustedLensPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The most canon anchor positon for the loupe is the exact middle.
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        SizedBox.fromSize(
          size: widget.size,
          child: _Magnifier(
            magnificationScale: widget.magnificationScale,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(widget.borderRadius),
            ),
            focalPoint: _focalPointOffsetFromCenter,
            child: widget.child,
          ),
        ),
        _LoupeStyle(
            borderRadius: widget.borderRadius,
            elevation: widget.elevation,
            size: widget.size,
            border: widget.border,
            shadowColor: widget.shadowColor)
      ],
    );
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

/// A widget that magnifies a screen region relative to itself.
///
/// [_Magnifier] may have a [child], which will be drawn over the lens. This is useful
/// for overlays, like tinting the lens.
///
/// Some caveats for using the magnifier:
/// * [_Magnifier] may only display widgets that come before it in the paint order; for example,
/// if magnifier comes before `widget A` in a column, then you will not be able to see `widget A`
/// in the magnifier.
/// *  If the magnifier points out of the bounds of the app, will have undefined behavior. This
/// generally results in the magnifier having undesired transparency, i.e. showing the layers
/// underneath it.
///
///
/// This widget's magnification does not lower resolution of the subject
/// in the [_Magnifier].
///
/// See also:
/// * [BackdropFilter], which [_Magnifier] uses along with [ImageFilter.matrix] to
/// Magnify a screen region.
/// * [Loupe], which uses [_Magnifier] to magnify text.
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
      BuildContext context, covariant RenderProxyBox renderObject) {
    (renderObject as _RenderMagnification)
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

  @override
  void addToScene(SceneBuilder builder) {
    // If shape is null, can push the most optimized clip, a regular rectangle.
    if (clip == null) {
      builder.pushClipRect(globalPosition & size);
    } else {
      builder.pushClipPath(clip!.getClip(size).shift(globalPosition));
    }

    // Create and push transform.
    final Offset thisCenter = Alignment.center.alongSize(size) + globalPosition;
    final Matrix4 matrix = Matrix4.identity()
      ..translate(
          magnificationScale * (focalPoint.dx - thisCenter.dx) + thisCenter.dx,
          magnificationScale * (focalPoint.dy - thisCenter.dy) + thisCenter.dy)
      ..scale(magnificationScale);
    builder.pushBackdropFilter(ImageFilter.matrix(matrix.storage));
    builder.pop();

    super.addToScene(builder);
    builder.pop();
  }
}
