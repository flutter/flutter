// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'container.dart';
import 'framework.dart';
import 'inherited_theme.dart';
import 'navigator.dart';
import 'overlay.dart';

/// {@template flutter.widgets.magnifier.MagnifierBuilder}
/// Signature for a builder that builds a [Widget] with a [MagnifierController].
///
/// Consuming [MagnifierController] or [ValueNotifier]<[MagnifierOverlayInfoBearer]> is not
/// required, although if a Widget intends to have entry or exit animations, it should take
/// [MagnifierController] and provide it an [AnimationController], so that [MagnifierController]
/// can wait before removing it from the overlay.
/// {@endtemplate}
///
/// See also:
///
/// - [MagnifierOverlayInfoBearer], the data class that updates the
///   magnifier.
typedef MagnifierBuilder = Widget? Function(
    BuildContext context,
    MagnifierController controller,
    ValueNotifier<MagnifierOverlayInfoBearer> magnifierOverlayInfoBearer,
);

/// A data class that contains the geometry information of text layouts
/// and selection gestures, used to position magnifiers.
@immutable
class MagnifierOverlayInfoBearer {
  /// Constructs a [MagnifierOverlayInfoBearer] from provided geometry values.
  const MagnifierOverlayInfoBearer({
    required this.globalGesturePosition,
    required this.caretRect,
    required this.fieldBounds,
    required this.currentLineBoundaries,
  });

  /// Const [MagnifierOverlayInfoBearer] with all values set to 0.
  static const MagnifierOverlayInfoBearer empty = MagnifierOverlayInfoBearer(
    globalGesturePosition: Offset.zero,
    caretRect: Rect.zero,
    currentLineBoundaries: Rect.zero,
    fieldBounds: Rect.zero,
  );

  /// The offset of the gesture position that the magnifier should be shown at.
  final Offset globalGesturePosition;

  /// The rect of the current line the magnifier should be shown at,
  /// without taking into account any padding of the field; only the position
  /// of the first and last character.
  final Rect currentLineBoundaries;

  /// The rect of the handle that the magnifier should follow.
  final Rect caretRect;

  /// The bounds of the entire text field that the magnifier is bound to.
  final Rect fieldBounds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MagnifierOverlayInfoBearer
        && other.globalGesturePosition == globalGesturePosition
        && other.caretRect == caretRect
        && other.currentLineBoundaries == currentLineBoundaries
        && other.fieldBounds == fieldBounds;
  }

  @override
  int get hashCode => Object.hash(
    globalGesturePosition,
    caretRect,
    fieldBounds,
    currentLineBoundaries,
  );
}

/// {@template flutter.widgets.magnifier.TextMagnifierConfiguration.intro}
/// A configuration object for a magnifier.
/// {@endtemplate}
///
/// {@macro flutter.widgets.magnifier.intro}
///
/// {@template flutter.widgets.magnifier.TextMagnifierConfiguration.details}
/// In general, most features of the magnifier can be configured through
/// [MagnifierBuilder]. [TextMagnifierConfiguration] is used to configure
/// the magnifier's behavior through the [SelectionOverlay].
/// {@endtemplate}
class TextMagnifierConfiguration {
  /// Constructs a [TextMagnifierConfiguration] from parts.
  ///
  /// If [magnifierBuilder] is null, a default [MagnifierBuilder] will be used
  /// that never builds a magnifier.
  const TextMagnifierConfiguration({
    MagnifierBuilder? magnifierBuilder,
    this.shouldDisplayHandlesInMagnifier = true
  }) : _magnifierBuilder = magnifierBuilder;

  /// The passed in [MagnifierBuilder].
  ///
  /// This is nullable because [disabled] needs to be static const,
  /// so that it can be used as a default parameter. If left null,
  /// the [magnifierBuilder] getter will be a function that always returns
  /// null.
  final MagnifierBuilder? _magnifierBuilder;

  /// {@macro flutter.widgets.magnifier.MagnifierBuilder}
  MagnifierBuilder get magnifierBuilder => _magnifierBuilder ?? (_, __, ___) => null;

  /// Determines whether a magnifier should show the text editing handles or not.
  final bool shouldDisplayHandlesInMagnifier;

  /// A constant for a [TextMagnifierConfiguration] that is disabled.
  ///
  /// In particular, this [TextMagnifierConfiguration] is considered disabled
  /// because it never builds anything, regardless of platform.
  static const TextMagnifierConfiguration disabled = TextMagnifierConfiguration();
}

/// [MagnifierController]'s main benefit over holding a raw [OverlayEntry] is that
/// [MagnifierController] will handle logic around waiting for a magnifier to animate in or out.
///
/// If a magnifier chooses to have an entry / exit animation, it should provide the animation
/// controller to [MagnifierController.animationController]. [MagnifierController] will then drive
/// the [AnimationController] and wait for it to be complete before removing it from the
/// [Overlay].
///
/// To check the status of the magnifier, see [MagnifierController.shown].
// TODO(antholeole): This whole paradigm can be removed once portals
// lands - then the magnifier can be controlled though a widget in the tree.
// https://github.com/flutter/flutter/pull/105335
class MagnifierController {
  /// If there is no in / out animation for the magnifier, [animationController] should be left
  /// null.
  MagnifierController({this.animationController}) {
    animationController?.value = 0;
  }

  /// The controller that will be driven in / out when show / hide is triggered,
  /// respectively.
  AnimationController? animationController;

  /// The magnifier's [OverlayEntry], if currently in the overlay.
  ///
  /// This is public in case other overlay entries need to be positioned
  /// above or below this [overlayEntry]. Anything in the paint order after
  /// the [RawMagnifier] will not be displayed in the magnifier; this means that if it
  /// is desired for an overlay entry to be displayed in the magnifier,
  /// it _must_ be positioned below the magnifier.
  ///
  /// {@tool snippet}
  /// ```dart
  /// void magnifierShowExample(BuildContext context) {
  ///   final MagnifierController myMagnifierController = MagnifierController();
  ///
  ///   // Placed below the magnifier, so it will show.
  ///   Overlay.of(context).insert(OverlayEntry(
  ///       builder: (BuildContext context) => const Text('I WILL display in the magnifier')));
  ///
  ///   // Will display in the magnifier, since this entry was passed to show.
  ///   final OverlayEntry displayInMagnifier = OverlayEntry(
  ///       builder: (BuildContext context) =>
  ///           const Text('I WILL display in the magnifier'));
  ///
  ///   Overlay.of(context)
  ///       .insert(displayInMagnifier);
  ///   myMagnifierController.show(
  ///       context: context,
  ///       below: displayInMagnifier,
  ///       builder: (BuildContext context) => const RawMagnifier(
  ///             size: Size(100, 100),
  ///           ));
  ///
  ///   // By default, new entries will be placed over the top entry.
  ///   Overlay.of(context).insert(OverlayEntry(
  ///       builder: (BuildContext context) => const Text('I WILL NOT display in the magnifier')));
  ///
  ///   Overlay.of(context).insert(
  ///       below:
  ///           myMagnifierController.overlayEntry, // Explicitly placed below the magnifier.
  ///       OverlayEntry(
  ///           builder: (BuildContext context) => const Text('I WILL display in the magnifier')));
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// A null check on [overlayEntry] will not suffice to check if a magnifier is in the
  /// overlay or not; instead, you should check [shown]. This is because it is possible,
  /// such as in cases where [hide] was called with `removeFromOverlay` false, that the magnifier
  /// is not shown, but the entry is not null.
  OverlayEntry? get overlayEntry => _overlayEntry;
  OverlayEntry? _overlayEntry;

  /// If the magnifier is shown or not.
  ///
  /// [shown] is:
  /// - false when nothing is in the overlay.
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

  /// Shows the [RawMagnifier] that this controller controls.
  ///
  /// Returns a future that completes when the magnifier is fully shown, i.e. done
  /// with its entry animation.
  ///
  /// To control what overlays are shown in the magnifier, utilize [below]. See
  /// [overlayEntry] for more details on how to utilize [below].
  ///
  /// If the magnifier already exists (i.e. [overlayEntry] != null), then [show] will
  /// override the old overlay and not play an exit animation. Consider awaiting [hide]
  /// first, to guarantee
  Future<void> show({
    required BuildContext context,
    required WidgetBuilder builder,
    Widget? debugRequiredFor,
    OverlayEntry? below,
  }) async {
    if (overlayEntry != null) {
        overlayEntry!.remove();
    }

    final OverlayState overlayState = Overlay.of(
      context,
      rootOverlay: true,
      debugRequiredFor: debugRequiredFor,
    );

    final CapturedThemes capturedThemes = InheritedTheme.capture(
      from: context,
      to: Navigator.maybeOf(context)?.context,
    );

   _overlayEntry = OverlayEntry(
      builder: (BuildContext context) => capturedThemes.wrap(builder(context)),
    );
    overlayState.insert(overlayEntry!, below: below);

    if (animationController != null) {
      await animationController?.forward();
    }
  }

  /// Schedules a hide of the magnifier.
  ///
  /// If this [MagnifierController] has an [AnimationController],
  /// then [hide] reverses the animation controller and waits
  /// for the animation to complete. Then, if [removeFromOverlay]
  /// is true, remove the magnifier from the overlay.
  ///
  /// In general, `removeFromOverlay` should be true, unless
  /// the magnifier needs to preserve states between shows / hides.
  ///
  /// See also:
  ///
  ///  * [removeFromOverlay] which removes the [OverlayEntry] from the [Overlay]
  ///    synchronously.
  Future<void> hide({bool removeFromOverlay = true}) async {
    if (overlayEntry == null) {
      return;
    }

    if (animationController != null) {
      await animationController?.reverse();
    }

    if (removeFromOverlay) {
      this.removeFromOverlay();
    }
  }

  /// Remove the [OverlayEntry] from the [Overlay].
  ///
  /// This method removes the [OverlayEntry] synchronously,
  /// regardless of exit animation: this leads to abrupt removals
  /// of [OverlayEntry]s with animations.
  ///
  /// To allow the [OverlayEntry] to play its exit animation, consider calling
  /// [hide] instead, with `removeFromOverlay` set to true, and optionally await
  /// the returned Future.
  @visibleForTesting
  void removeFromOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
  /// [bounds]. If the desired output rect requires that no edges are parallel to edges
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

/// A decoration for a [RawMagnifier].
///
/// [MagnifierDecoration] does not expose [ShapeDecoration.color], [ShapeDecoration.image],
/// or [ShapeDecoration.gradient], since they will be covered by the [RawMagnifier]'s lens.
///
/// Also takes an [opacity] (see https://github.com/flutter/engine/pull/34435).
class MagnifierDecoration extends ShapeDecoration {
  /// Constructs a [MagnifierDecoration].
  ///
  /// By default, [MagnifierDecoration] is a rectangular magnifier with no shadows, and
  /// fully opaque.
  const MagnifierDecoration({
    this.opacity = 1,
    super.shadows,
    super.shape = const RoundedRectangleBorder(),
  });

  /// The magnifier's opacity.
  final double opacity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return super == other && other is MagnifierDecoration && other.opacity == opacity;
  }

  @override
  int get hashCode => Object.hash(super.hashCode, opacity);
}

/// A common base class for magnifiers.
///
/// {@template flutter.widgets.magnifier.intro}
/// This magnifying glass is useful for scenarios on mobile devices where
/// the user's finger may be covering part of the screen where a granular
/// action is being performed, such as navigating a small cursor with a drag
/// gesture, on an image or text.
/// {@endtemplate}
///
/// A magnifier can be conveniently managed by [MagnifierController], which handles
/// showing and hiding the magnifier, with an optional entry / exit animation.
///
/// See:
/// * [MagnifierController], a controller to handle magnifiers in an overlay.
class RawMagnifier extends StatelessWidget {
  /// Constructs a [RawMagnifier].
  ///
  /// {@template flutter.widgets.magnifier.RawMagnifier.invisibility_warning}
  /// By default, this magnifier uses the default [MagnifierDecoration],
  /// the focal point is directly under the magnifier, and there is no magnification:
  /// This means that a default magnifier will be entirely invisible to the naked eye,
  /// since it is painting exactly what is under it, exactly where it was painted
  /// originally.
  /// {@endtemplate}
  const RawMagnifier({
      super.key,
      this.child,
      this.decoration = const MagnifierDecoration(),
      this.focalPointOffset = Offset.zero,
      this.magnificationScale = 1,
      required this.size,
      }) : assert(magnificationScale != 0,
            'Magnification scale of 0 results in undefined behavior.');

  /// An optional widget to position inside the len of the [RawMagnifier].
  ///
  /// This is positioned over the [RawMagnifier] - it may be useful for tinting the
  /// [RawMagnifier], or drawing a crosshair like UI.
  final Widget? child;

  /// This magnifier's decoration.
  ///
  /// {@macro flutter.widgets.magnifier.RawMagnifier.invisibility_warning}
  final MagnifierDecoration decoration;


  /// The offset of the magnifier from [RawMagnifier]'s center.
  ///
  /// {@template flutter.widgets.magnifier.offset}
  /// For example, if [RawMagnifier] is globally positioned at Offset(100, 100),
  /// and [focalPointOffset] is Offset(-20, -20), then [RawMagnifier] will see
  /// the content at global offset (80, 80).
  ///
  /// If left as [Offset.zero], the [RawMagnifier] will show the content that
  /// is directly below it.
  /// {@endtemplate}
  final Offset focalPointOffset;

  /// How "zoomed in" the magnification subject is in the lens.
  final double magnificationScale;

  /// The size of the magnifier.
  ///
  /// This does not include added border; it only includes
  /// the size of the magnifier.
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        ClipPath.shape(
          shape: decoration.shape,
          child: Opacity(
            opacity: decoration.opacity,
            child: _Magnifier(
              shape: decoration.shape,
              focalPointOffset: focalPointOffset,
              magnificationScale: magnificationScale,
              child: SizedBox.fromSize(
                size: size,
                child: child,
              ),
            ),
          ),
        ),
        // Because `BackdropFilter` will filter any widgets before it, we should
        // apply the style after (i.e. in a younger sibling) to avoid the magnifier
        // from seeing its own styling.
        Opacity(
          opacity: decoration.opacity,
          child: _MagnifierStyle(
            decoration,
            size: size,
          ),
        )
      ],
    );
  }
}

class _MagnifierStyle extends StatelessWidget {
  const _MagnifierStyle(this.decoration, {required this.size});

  final MagnifierDecoration decoration;
  final Size size;

  @override
  Widget build(BuildContext context) {
    double largestShadow = 0;
    for (final BoxShadow shadow in decoration.shadows ?? <BoxShadow>[]) {
      largestShadow = math.max(
          largestShadow,
          (shadow.blurRadius + shadow.spreadRadius) +
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

/// A `clipPath` that looks like a donut if you were to fill its area.
///
/// This is necessary because the shadow must be added after the magnifier is drawn,
/// so that the shadow does not end up in the magnifier. Without this clip, the magnifier would be
/// entirely covered by the shadow.
///
/// The negative space of the donut is clipped out (the donut hole, outside the donut).
/// The donut hole is cut out exactly like the shape of the magnifier.
class _DonutClip extends CustomClipper<Path> {
  _DonutClip({required this.shape, required this.spreadRadius});

  final double spreadRadius;
  final ShapeBorder shape;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final Rect rect = Offset.zero & size;

    path.fillType = PathFillType.evenOdd;
    path.addPath(shape.getOuterPath(rect.inflate(spreadRadius)), Offset.zero);
    path.addPath(shape.getInnerPath(rect), Offset.zero);
    return path;
  }

  @override
  bool shouldReclip(_DonutClip oldClipper) => oldClipper.shape != shape;
}

class _Magnifier extends SingleChildRenderObjectWidget {
  const _Magnifier({
    super.child,
    required this.shape,
    this.magnificationScale = 1,
    this.focalPointOffset = Offset.zero,
  });

  // The Offset that the center of the _Magnifier points to, relative
  // to the center of the magnifier.
  final Offset focalPointOffset;

  // The enlarge multiplier of the magnification.
  //
  // If equal to 1.0, the content in the magnifier is true to its real size.
  // If greater than 1.0, the content appears bigger in the magnifier.
  final double magnificationScale;

  // Shape of the magnifier.
  final ShapeBorder shape;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMagnification(focalPointOffset, magnificationScale, shape);
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderMagnification renderObject) {
    renderObject
      ..focalPointOffset = focalPointOffset
      ..shape = shape
      ..magnificationScale = magnificationScale;
  }
}

class _RenderMagnification extends RenderProxyBox {
  _RenderMagnification(
    this._focalPointOffset,
    this._magnificationScale,
    this._shape, {
    RenderBox? child,
  }) : super(child);

  Offset get focalPointOffset => _focalPointOffset;
  Offset _focalPointOffset;
  set focalPointOffset(Offset value) {
    if (_focalPointOffset == value) {
      return;
    }
    _focalPointOffset = value;
    markNeedsPaint();
  }

  double get magnificationScale => _magnificationScale;
  double _magnificationScale;
  set magnificationScale(double value) {
    if (_magnificationScale == value) {
      return;
    }
    _magnificationScale = value;
    markNeedsPaint();
  }

  ShapeBorder get shape => _shape;
  ShapeBorder _shape;
  set shape(ShapeBorder value) {
    if (_shape == value) {
      return;
    }
    _shape = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  BackdropFilterLayer? get layer => super.layer as BackdropFilterLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    final Offset thisCenter = Alignment.center.alongSize(size) + offset;
    final Matrix4 matrix = Matrix4.identity()
      ..translate(
          magnificationScale * ((focalPointOffset.dx * -1) - thisCenter.dx) + thisCenter.dx,
          magnificationScale * ((focalPointOffset.dy * -1) - thisCenter.dy) + thisCenter.dy)
      ..scale(magnificationScale);
    final ImageFilter filter = ImageFilter.matrix(matrix.storage, filterQuality: FilterQuality.high);

    if (layer == null) {
      layer = BackdropFilterLayer(
        filter: filter,
      );
    } else {
      layer!.filter = filter;
    }

    context.pushLayer(layer!, super.paint, offset);
  }
}
