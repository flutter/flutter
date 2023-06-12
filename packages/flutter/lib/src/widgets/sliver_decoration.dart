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
/// must be placed in a widget that expects a sliver.
///
/// Commonly used with [BoxDecoration].
///
/// The [child] is not clipped. To clip a child to the shape of a particular
/// [ShapeDecoration], consider using a [ClipPath] widget.
///
/// {@tool dartpad}
/// This sample shows a radial gradient that draws a moon on a night sky:
///
/// ** See code in examples/api/lib/widgets/sliver/sliver_decoration.0.dart **
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
      case DecorationPosition.foreground:
        label = 'fg';
    }
    properties.add(EnumProperty<DecorationPosition>('position', position, level: DiagnosticLevel.hidden));
    properties.add(DiagnosticsProperty<Decoration>(label, decoration));
  }
}
