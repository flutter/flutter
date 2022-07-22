// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// [LoupeController]'s main benefit over holding a raw [OverlayEntry] is that
/// [LoupeController] will handle logic around waiting for a loupe to animate in or out.
///
/// If a loupe chooses to have an entry / exit animation, it should provide the animation
/// controller to [LoupeController.animationController]. [LoupeController] will then drive
/// the [AnimationController] and wait for it to be complete before removing it from the
/// [Overlay].
///
/// To check the status of the loupe, see [LoupeController.shown].
// TODO(antholeole): This whole paradigm can be removed once portals
// lands - then the loupe can be controlled though a widget in the tree.
// https://github.com/flutter/flutter/pull/105335
class LoupeController {
  /// If there is no in / out animation for the loupe, [animationController] should be left
  /// null.
  LoupeController({this.animationController}) {
    animationController?.value = 0;
  }

  /// The controller that will be driven in / out when show / hide is triggered,
  /// respectively.
  AnimationController? animationController;

  /// The loupe's [OverlayEntry], if currently in the overlay.
  ///
  /// It may be possible that this is not null, but
  ///
  /// This is public in case other overlay entries need to be positioned
  /// above or below this [overlayEntry]. Anything in the paint order after
  /// the [RawLoupe] will not be displaued in the loupe; this means that if it
  /// is desired for an overlay entry to be displayed in the loupe,
  /// it _must_ be positioned below the loupe.
  ///
  /// {@tool snippet}
  /// ```dart
  /// void loupeShowExample(BuildContext context) {
  ///   final LoupeController myLoupeController = LoupeController();
  ///
  ///   // Placed below the loupe, so it will show.
  ///   Overlay.of(context)!.insert(OverlayEntry(
  ///       builder: (BuildContext context) => const Text('I WILL display in the loupe')));
  ///
  ///   // Will display in the loupe, since this entry was passed to show.
  ///   final displayInLoupeEvenThoughPlacedBeforeChronologically = OverlayEntry(
  ///       builder: (BuildContext context) =>
  ///           const Text('I WILL display in the loupe'));
  ///
  ///   Overlay.of(context)!
  ///       .insert(displayInLoupeEvenThoughPlacedBeforeChronologically);
  ///   myLoupeController.show(
  ///       context: context,
  ///       below: displayInLoupeEvenThoughPlacedBeforeChronologically,
  ///       builder: (BuildContext context) => const RawLoupe(
  ///             size: Size(100, 100),
  ///           ));
  ///
  ///   // By default, new entries will be placed over the top entry.
  ///   Overlay.of(context)!.insert(OverlayEntry(
  ///       builder: (BuildContext context) => const Text('I WILL NOT display in the loupe')));
  ///
  ///   Overlay.of(context)!.insert(
  ///       below:
  ///           myLoupeController.overlayEntry, // Explicitly placed below the loupe.
  ///       OverlayEntry(
  ///           builder: (BuildContext context) => const Text('I WILL display in the loupe')));
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// A null check on [overlayEntry] will not suffice to check if a loupe is in the
  /// overlay or not; instead, you should check [shown]. This is because it is possible,
  /// such as in cases where [hide] was called with removeFromOverlay false, that the loupe
  /// is not shown, but the entry is not null.
  OverlayEntry? overlayEntry;

  /// If the loupe is shown or not.
  ///
  /// [shown] is:
  /// - false when nothing is in the overlay
  /// - false when [animationController] is [AnimationStatus.dismissed].
  /// - false when [animationController] is animating out.
  /// and true in all other circumstances.
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

  /// Shows the [RawLoupe] that this controller controls.
  ///
  /// Returns a future that completes when the loupe is fully shown, i.e. done
  /// with its entry animation.
  ///
  /// To control what overlays are shown in the loupe, utilize [below]. See
  /// [overlayEntry] for more details on how to utilize [below].
  ///
  /// If the loupe already exists (i.e. [overlayEntry] != null), then [show] will
  /// reshow the old overlay.
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

  /// A utility for calculating a new [Rect] from [rect] such that
  /// [rect] is fully constrained within [bounds].
  ///
  /// Any point in the output rect is guaranteed to also be a point contained in [bounds].
  ///
  /// It is a runtime error for [rect].width to be greater than [bounds].width,
  /// and it is also an error for [rect].height to be greater than [bounds].height.
  ///
  /// This algorithm translates [rect] the shortest distance such that it is entirely within
  /// [bounds].
  ///
  /// If [rect] is already within [bounds], no shift will be applied to [rect] and
  /// [rect] will be returned as-is.
  ///
  /// It is perfectly valid for the output rect to have a point along the edge of the
  /// [bounds]. If the desired output rect requires that no edges are parellel to edges
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
/// Also takes an [opacity] (see https://github.com/flutter/engine/pull/34435).
class LoupeDecoration extends ShapeDecoration {
  /// Constructs a [LoupeDecoration].
  ///
  /// By default, [LoupeDecoration] is a rectangular loupe with no shadows, and
  /// fully opaque.
  const LoupeDecoration({
    this.opacity = 1,
    super.shadows,
    super.shape = const RoundedRectangleBorder(),
  });

  /// The loupe's opacity.
  final double opacity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return super == other && other is LoupeDecoration && other.opacity == opacity;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, opacity);
}

/// A common building base for Loupes.
///
/// {@template flutter.widgets.loupe.intro}
/// This magnifying glass is useful for scenarios on mobile devices where
/// the user's finger may be covering part of the screen where a granular
/// action is being performed, such as navigating a small cursor with a drag
/// gesture, on an image or text.
/// {@endtemplate}
///
/// A loupe can be convienently managed by [LoupeController], which handles
/// showing and hiding the loupe, with an optional entry / exit animation.
///
/// See:
/// * [LoupeController], a controller to handle loupes in an overlay.
class RawLoupe extends StatelessWidget {
  /// Constructs a [RawLoupe].
  ///
  /// {@template flutter.widgets.loupe.loupe.invisibility_warning}
  /// By default, this loupe uses the default [LoupeDecoration],
  /// the focal point is directly under the loupe, and there is no magnification:
  /// This means that a default loupe will be entirely invisible to the naked eye,
  /// since it is painting exactly what is under it, exactly where it was painted
  /// orignally.
  /// {@endtemplate}
  const RawLoupe({
      super.key,
      this.magnificationScale = 1,
      required this.size,
      this.focalPoint = Offset.zero,
      this.child,
      this.decoration = const LoupeDecoration()
      }) : assert(magnificationScale != 0,
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

  /// The offset of the loupe from [RawLoupe]'s center.
  ///
  /// If [focalPoint] is [Offset.zero], then the [focalPoint]
  /// will point directly below this [RawLoupe].
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
              magnificationScale: magnificationScale,
              child: SizedBox.fromSize(
                size: size,
                child: child,
              ),
            ),
          ),
        ),

      // Because `BackdropFilter` will filter any widgets before it, we should
      // apply the style after (i.e. in a younger sibling) to avoid the loupe
      // from seeing its own styling.
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

class _LoupeStyle extends StatelessWidget {
  const _LoupeStyle(this.decoration, {required this.size});

  final LoupeDecoration decoration;
  final Size size;

  @override
  Widget build(BuildContext context) {
    double largestShadow = 0;
    for (final BoxShadow shadow in decoration.shadows ?? <BoxShadow>[]) {
      largestShadow = math.max(
          largestShadow,
          shadow.spreadRadius +
              math.max(shadow.offset.dy.abs(), shadow.offset.dx.abs()));
    }

    return ClipPath(
      clipBehavior: Clip.hardEdge,
      clipper: _DonutClip(
        shape: decoration.shape,
        spreadRadius: largestShadow,
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

/// A clipPath that looks like a donut if you were to fill its area.
///
/// This is necessary because the shadow must be added after the loupe is drawn,
/// so that the shadow does not end up in the loupe. Without this clip, the loupe would be
/// entirely covered by the shadow.
///
/// The negative space of the donut is clipped out (the donut hole, outside the donut).
/// The donut hole is cut out exactly like the shape of the Loupe.
class _DonutClip extends CustomClipper<Path> {
  _DonutClip({required this.shape, required this.spreadRadius});

  final double spreadRadius;
  final ShapeBorder shape;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final Rect rect = Offset.zero & size;

    path.fillType = PathFillType.evenOdd;
    path.addPath(shape.getOuterPath(Offset.zero & size), Offset.zero);
    path.addRect(rect.inflate(spreadRadius));
    return path;
  }

  @override
  bool shouldReclip(_DonutClip oldClipper) => oldClipper.shape != shape;
}

class _Magnifier extends SingleChildRenderObjectWidget {
  /// Construct a [_Magnifier].
  const _Magnifier({
      super.child,
      this.magnificationScale = 1,
      this.focalPoint = Offset.zero,
  });

  /// [focalPoint] of the magnifier is the area the center of the
  /// [_Magnifier] points to, relative to the center of the magnifier.
  /// If left as [Offset.zero], the magnifier will magnify whatever is directly
  /// below it.
  final Offset focalPoint;

  /// The scale of the magnification.
  ///
  /// A [magnificationScale] of 1 means that the content magi
  final double magnificationScale;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMagnification(focalPoint, magnificationScale);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMagnification renderObject) {
    renderObject
      ..focalPoint = focalPoint
      ..magnificationScale = magnificationScale;
  }
}

class _RenderMagnification extends RenderProxyBox {
  _RenderMagnification(
    this._focalPoint,
    this._magnificationScale, {
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
