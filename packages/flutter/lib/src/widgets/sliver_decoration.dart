// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'image.dart';

/// A sliver widget that paints a [Decoration] either before or after its child
/// paints.
///
/// Unlike [DecoratedBox], this widget expects its child to be a sliver, and
/// must be placed in a widget that expects a sliver. This can allow decorating the
/// background of a [SliverList] without resorting to a shrink-wrapped list view or
/// column layout.
///
/// Commonly used with [BoxDecoration].
///
/// The [child] is not clipped. To clip a child to the shape of a particular
/// [ShapeDecoration], consider using a [ClipPath] widget.
///
/// {@tool snippet}
///
/// This sample shows a radial gradient that draws a moon on a night sky:
///
/// ```dart
/// SliverDecoration(
///   decoration: const BoxDecoration(
///     gradient: RadialGradient(
///       center: Alignment(-0.5, -0.6),
///       radius: 0.15,
///       colors: <Color>[
///         Color(0xFFEEEEEE),
///         Color(0xFF111133),
///       ],
///       stops: <double>[0.9, 1.0],
///     ),
///   ),
///   sliver: SliverList(
///     delegate: SliverChildListDelegate(<Widget>[
///        const Text('Goodnight Moon'),
///     ]),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [DecoratedBox], the version of this class that works with regular widgets.
///  * [Decoration], which you can extend to provide other effects with
///    [SliverDecoration].
///  * [CustomPaint], another way to draw custom effects from the widget layer.
class SliverDecoration extends SingleChildRenderObjectWidget {
  /// Creates a widget that paints a [Decoration].
  ///
  /// The [decoration] and [position] arguments must not be null. By default the
  /// decoration paints behind the child.
  const SliverDecoration({
    super.key,
    required this.decoration,
    this.position = DecorationPosition.background,
    Widget? sliver,
  }) : super(child: sliver);

  /// What decoration to paint.
  ///
  /// Commonly a [BoxDecoration].
  final Decoration decoration;

  /// Whether to paint the box decoration behind or in front of the child.
  final DecorationPosition position;

  @override
  RenderSliverDecoration createRenderObject(BuildContext context) {
    return RenderSliverDecoration(
      decoration: decoration,
      position: position,
      configuration: createLocalImageConfiguration(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverDecoration renderObject) {
    renderObject
      ..decoration = decoration
      ..position = position
      ..configuration = createLocalImageConfiguration(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final String label;
    switch (position) {
      case DecorationPosition.background:
        label = 'bg';
        break;
      case DecorationPosition.foreground:
        label = 'fg';
        break;
    }
    properties.add(EnumProperty<DecorationPosition>('position', position, level: DiagnosticLevel.hidden));
    properties.add(DiagnosticsProperty<Decoration>(label, decoration));
  }
}

/// Paints a [Decoration] either before or after its child paints.
class RenderSliverDecoration extends RenderProxySliver {
  /// Creates a decorated sliver.
  ///
  /// The [decoration], [position], and [configuration] arguments must not be
  /// null. By default the decoration paints behind the child.
  ///
  /// The [ImageConfiguration] will be passed to the decoration (with the size
  /// filled in) to let it resolve images.
  RenderSliverDecoration({
    required Decoration decoration,
    DecorationPosition position = DecorationPosition.background,
    ImageConfiguration configuration = ImageConfiguration.empty,
  }) : _decoration = decoration,
       _position = position,
       _configuration = configuration;

  /// What decoration to paint.
  ///
  /// Commonly a [BoxDecoration].
  Decoration get decoration => _decoration;
  Decoration _decoration;
  set decoration(Decoration value) {
    if (value == decoration) {
      return;
    }
    _decoration = value;
    _painter?.dispose();
    _painter = decoration.createBoxPainter(markNeedsPaint);
    markNeedsPaint();
  }

  /// Whether to paint the box decoration behind or in front of the child.
  DecorationPosition get position => _position;
  DecorationPosition _position;
  set position(DecorationPosition value) {
    if (value == position) {
      return;
    }
    _position = value;
    markNeedsPaint();
  }

  /// The settings to pass to the decoration when painting, so that it can
  /// resolve images appropriately. See [ImageProvider.resolve] and
  /// [BoxPainter.paint].
  ///
  /// The [ImageConfiguration.textDirection] field is also used by
  /// direction-sensitive [Decoration]s for painting and hit-testing.
  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    if (value == configuration) {
      return;
    }
    _configuration = value;
    markNeedsPaint();
  }

  BoxPainter? _painter;

  @override
  void attach(covariant PipelineOwner owner) {
    _painter = decoration.createBoxPainter(markNeedsPaint);
    super.attach(owner);
  }

  @override
  void detach() {
    _painter?.dispose();
    _painter = null;
    super.detach();
  }

  @override
  void dispose() {
    _painter?.dispose();
    _painter = null;
    super.dispose();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && child!.geometry!.visible) {
      final SliverPhysicalParentData childParentData = child!.parentData! as SliverPhysicalParentData;
      final Size childSize = Size(constraints.crossAxisExtent, child!.geometry!.paintExtent);
      final Offset childOffset = offset + childParentData.paintOffset;

      if (position == DecorationPosition.background) {
        _painter!.paint(context.canvas, childOffset, configuration.copyWith(size: childSize));
      }
      context.paintChild(child!, offset + childParentData.paintOffset);

      if (position == DecorationPosition.foreground) {
        _painter!.paint(context.canvas, childOffset, configuration.copyWith(size: childSize));
      }
    }
  }
}
