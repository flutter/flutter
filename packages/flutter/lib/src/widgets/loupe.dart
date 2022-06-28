// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A common building base for Loupes.
///
/// {@template loupe_padding}
/// This widget is globally positioned based on a [CompositedTransformTarget], but respects
/// horizontal and vertical padding screen "safe area". For example, if the [CompositedTransformTarget]
/// is at global position (-100, 10), but horizontal padding is 10, the loupe is positioned at 10.
///
/// In essence, [globalPosition] is clamped to (0 + padding, screenDimension - padding).
///
/// If [verticalViewportSafeAreaPadding] or [horizontalViewportSafeAreaPadding] is null, then no safe area is respected,
/// and loupe may go out of the viewport. If desired to perfectly clamp to the viewport,
/// [verticalViewportSafeAreaPadding] and [horizontalViewportSafeAreaPadding] should each be set to 0.
/// {@endtemplate}
///
/// See:
/// * [AndroidLoupe], the Android-style consumer of [Loupe].
/// * [CupertinoLoupe], the iOS-style consumer of [Loupe].
class Loupe extends StatefulWidget {
  /// i am a doc
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
      required this.position})
      : assert(magnificationScale != 0,
            'Magnification scale of 0 results in undefined behavior.'),
        animationDuration = Duration.zero,
        curve = Curves.bounceIn;

  const Loupe.animated(
      {super.key,
      this.border,
      this.borderRadius = Radius.zero,
      required this.shadowColor,
      this.magnificationScale = 1,
      this.elevation = 0,
      required this.size,
      this.verticalOffset = 0,
      this.child,
      required this.position,
      required this.animationDuration,
      required this.curve})
      : assert(magnificationScale != 0,
            'Magnification scale of 0 results in undefined behavior.');

  final Duration animationDuration;
  final Curve curve;

  final ValueNotifier<Offset> position;

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

class _LoupeState extends State<Loupe> {
  late Offset _lensPosition;
  late Offset _focalPointOffsetFromCenter;

  @override
  void initState() {
    //TODO need to use calced vars
    _focalPointOffsetFromCenter = Offset(0, widget.verticalOffset);
    _lensPosition = widget.position.value;
    widget.position.addListener(_calculateAdjustedFocalPointAndLensPosition);
    super.initState();
  }

  /// Adjust both the focal point and the lens position.
  ///
  /// The adjustments are made based on two factors:
  /// 1. Since the Loupe should never go out of bounds, but the Y axis should show
  void _calculateAdjustedFocalPointAndLensPosition() {
    final Size screenSize = MediaQuery.of(context).size;

    // The raw position that the lens would be at, prior to any adjustment.
    final Offset unadjustedLensPosition = widget.position.value -
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
    return AnimatedPositioned(
      duration: widget.animationDuration,
      curve: widget.curve,
      top: _lensPosition.dy,
      left: _lensPosition.dx,
      child: Stack(
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
      ),
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
