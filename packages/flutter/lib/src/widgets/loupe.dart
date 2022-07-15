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
/// the [LoupeController] should be passed into [RawLoupe.controller]. The third paramater
/// is any additional info passed to the loupe, if desired.
/// {@endtemplate}
typedef LoupeControllerWidgetBuilder<T> = Widget? Function(
    BuildContext context, LoupeController controller, T data);

/// Controls an instance of a [RawLoupe], if this [LoupeController] is passed to [RawLoupe.controller].
/// If unattached to any [RawLoupe] (i.e., not passed to a [RawLoupe]), does nothing.
///
/// [LoupeController] handles driving [RawLoupe.transitionAnimationController]'s in / out animation
/// based on calls to show / hide, respectively.
///
/// To check the status of the loupe, see [LoupeController.status].
// TODO(antholeole): This whole paradigm can be removed once portals
// lands - then the loupe can be controlled though a widget in the tree.
// https://github.com/flutter/flutter/pull/105335
class LoupeController {
  /// If the loupe show / hide is controlled by an animation, then it should be passed here,
  /// where this [LoupeController] will wait for the animation to complete before removing
  /// it from the overlay.
  ///
  /// If there is no in / out animation for the loupe, [animationController] should be left
  /// null.
  LoupeController({this.animationController}) {
    animationController?.value = 0;
  }

  /// The controller that will be driven in / out when show / hide is triggered,
  /// respectively.
  AnimationController? animationController;

  /// The loupe's [OverlayEntry], if currently visible.
  ///
  /// This is public in case other overlay entries need to be positioned
  /// above or below this [overlayEntry]. Anything in the paint order after
  /// the [RawLoupe] will not be displaued in the loupe; this means that if it
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
  ///
  /// A null check on [overlayEntry] will not suffice to check if a loupe is in the
  /// overlay or not; instead, you should check [shown]. This is because it is possible,
  /// such as in cases where [hide] was called with removeFromOverlay false, that the loupe
  /// is not shown, but the entry is not null.
  OverlayEntry? overlayEntry;

  /// If the loupe is shown or not.
  bool get shown {
    if (overlayEntry == null) {
      return false;
    }

    if (animationController != null) {
      return animationController!.status == AnimationStatus.completed ||
          animationController!.status == AnimationStatus.forward;
    }

    return true;
  }

  /// The current status of the loupe.
  ///
  /// If the loupe is not shown (i.e. the default, or if  [hide] was called recently) [status]
  /// will be  [AnimationStatus.dismissed].  If the loupe is shown, [status] will be
  /// [AnimationStatus.completed]. If the loupe is transitioning from [AnimationStatus.dismissed]
  /// to [AnimationStatus.completed] or visa versa, [status] will be [AnimationStatus.completed] and
  /// [AnimationStatus.reverse], respectively.
  ValueNotifier<AnimationStatus> status =
      ValueNotifier<AnimationStatus>(AnimationStatus.dismissed);

  /// Function that returns a function and the other function checks platform to check if the builder should be null
  ///
  ///
  /// Shows the [RawLoupe] that this controller controlls.
  ///
  /// Returns a future that completes when the loupe is fully shown, i.e. done
  /// with it's entry animation.
  ///
  /// To control what overlays are shown in the loupe, utilize [below]. See
  /// [overlayEntry] for more details on how to utilize [below].
  ///
  /// If the loupe already exists (i.e. [overlayEntry] != null), then [show] will
  /// reshow the old overl.
  Future<void> show({
    required BuildContext context,
    required WidgetBuilder builder,
    Widget? debugRequiredFor,
    OverlayEntry? below,
  }) async {
    if (overlayEntry != null) {
      if (animationController?.status == AnimationStatus.dismissed) {
        await animationController!.forward();
      }

      return;
    }

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
    overlayState!.insert(overlayEntry!, below: below);

    if (animationController != null) {
      await animationController?.forward();
    }
  }

  /// Schedules a hide of the loupe.
  ///
  /// If this [LoupeController] has an [AnimationController],
  /// then [hide] reverses the animation controller and waits
  /// for the animation to complete. Then, if [removeFromOverlay]
  /// is true, remove the loupe from the overlay.
  ///
  /// In general, [removeFromOverlay] should be true, unless
  /// the loupe needs to preserve states between shows / hides.
  Future<void> hide({bool removeFromOverlay = true}) async {
    if (overlayEntry == null) {
      return;
    }

    if (animationController != null) {
      await animationController?.reverse();
    }

    if (removeFromOverlay) {
      overlayEntry?.remove();
      overlayEntry = null;
    }
  }

  /// A utility for calculating a new [Rect] from this rect such that
  /// [rect] is fully constrained within [bounds], that is, any point
  /// in the output rect is guaranteed to also be a point in [bounds].
  ///
  /// It is a runtime error for [rect].width to be greater than [bounds].width,
  /// and it is also an error for [rect].height to be greater than [bounds].height.
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

/// A decoration for a [RawLoupe].
///
/// [LoupeDecoration] does not expose [ShapeDecoration.color], [ShapeDecoration.image],
/// or [ShapeDecoration.gradient], since they will be covered by the [RawLoupe]'s lense.
///
/// Also takes an [opacity].
/// {@template flutter.widgets.loupe.opacity.reason}
/// This is because [RawLoupe]'s lens is backed by [BackdropFilter],
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

/// A common building base for [RawLoupe]s.
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
class RawLoupe extends StatelessWidget {
  /// Constructs a [RawLoupe].
  ///
  /// {@template flutter.widgets.loupe.loupe.invisibility_warning}
  /// By default, this loupe uses the default [LoupeDecoration],
  /// the focal point is directly under the loupe, and there is no magnification:
  /// This means that a default loupe will be entirely invisible to the user,
  /// since it is painting exactly what is under it, exactly where it was painted
  /// orignally.
  /// {@endtemplate}
  const RawLoupe(
      {super.key,
      this.magnificationScale = 1,
      required this.size,
      this.focalPoint = Offset.zero,
      this.child,
      this.decoration = const LoupeDecoration()})
      : assert(magnificationScale != 0,
            'Magnification scale of 0 results in undefined behavior.');

  /// This loupe's decoration.
  ///
  /// {@macro flutter.widgets.loupe.loupe.invisibility_warning}
  final LoupeDecoration decoration;

  /// The size of the loupe.
  ///
  /// This does not include added border; it only includes
  /// the size of the magnifier.
  final Size size;

  /// The offset of the loupe from the widget's origin.
  ///
  /// If [focalPoint] is [Offset.zero], the loupe will be positioned
  /// with it's center directly on the the top-left corner of the draw
  /// position. The focal point will always be exactly on the draw position.
  final Offset focalPoint;

  /// An optional widget to posiiton inside the len of the [RawLoupe].
  ///
  /// This is positioned over the [RawLoupe] - it may be useful for tinting the
  /// [RawLoupe], or drawing a crosshair like UI.
  final Widget? child;

  /// How "zoomed in" the magnification subject is in the lens.
  final double magnificationScale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        ClipPath.shape(
          shape: decoration.shape,
          child: Opacity(
            opacity: decoration.opacity,
            child: _Magnifier(
                focalPoint: focalPoint,
                shape: decoration.shape,
                magnificationScale: magnificationScale,
                child: SizedBox.fromSize(
                  size: size,
                  child: child,
                )),
          ),
        ),
        Opacity(
          opacity: decoration.opacity,
          child: _LoupeStyle(
            decoration,
            size: size,
          ),
        )
      ],
    );
  }
}

/// Because backdrop filter will filter any widgets before it, we should
/// apply the style after (i.e. in a younger sibling) to avoid the loupe
/// from seeing it's own styling.
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
  _DonutClip({required this.shape});

  // A very large clip; will display all but the most
  // unreasonably large shadows.
  static const double _kEstimatedWidestShadowLoupeBounds = 90.0;

  final ShapeBorder shape;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final Rect rect = Offset.zero & size;

    path.fillType = PathFillType.evenOdd;
    path.addPath(shape.getOuterPath(Offset.zero & size), Offset.zero);
    path.addRect(rect.inflate(_kEstimatedWidestShadowLoupeBounds));
    return path;
  }

  @override
  bool shouldReclip(_DonutClip oldClipper) => oldClipper.shape != shape;
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

  /// [focalPoint] of the magnifier is the area the center of the
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
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    final Offset thisCenter = Alignment.center.alongSize(size) + offset;
    final Matrix4 matrix = Matrix4.identity()
      ..translate(
          magnificationScale * (focalPoint.dx - thisCenter.dx) + thisCenter.dx,
          magnificationScale * (focalPoint.dy - thisCenter.dy) + thisCenter.dy)
      ..scale(magnificationScale);

    if (layer == null) {
      layer = BackdropFilterLayer(filter: ImageFilter.matrix(matrix.storage));
    } else {
      layer!.filter = ImageFilter.matrix(matrix.storage);
    }

    context.pushLayer(layer!, super.paint, offset);
  }
}
