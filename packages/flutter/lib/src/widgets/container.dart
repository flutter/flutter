// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'image.dart';

/// A widget that paints a [Decoration] either before or after its child paints.
///
/// [Container] insets its child by the widths of the borders; this widget does
/// not.
///
/// Commonly used with [BoxDecoration].
///
/// ## Sample code
///
/// This sample shows a radial gradient that draws a moon on a night sky:
///
/// ```dart
/// new DecoratedBox(
///   decoration: new BoxDecoration(
///     gradient: new RadialGradient(
///       center: const FractionalOffset(0.25, 0.3),
///       radius: 0.15,
///       colors: <Color>[
///         const Color(0xFFEEEEEE),
///         const Color(0xFF111133),
///       ],
///       stops: <double>[0.9, 1.0],
///     ),
///   ),
/// )
/// ```
///
/// See also:
///
///  * [DecoratedBoxTransition], the version of this class that animates on the
///    [decoration] property.
///  * [Decoration], which you can extend to provide other effects with
///    [DecoratedBox].
///  * [CustomPaint], another way to draw custom effects from the widget layer.
class DecoratedBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that paints a [Decoration].
  ///
  /// The [decoration] and [position] arguments must not be null. By default the
  /// decoration paints behind the child.
  const DecoratedBox({
    Key key,
    @required this.decoration,
    this.position: DecorationPosition.background,
    Widget child
  }) : assert(decoration != null),
       assert(position != null),
       super(key: key, child: child);

  /// What decoration to paint.
  ///
  /// Commonly a [BoxDecoration].
  final Decoration decoration;

  /// Whether to paint the box decoration behind or in front of the child.
  final DecorationPosition position;

  @override
  RenderDecoratedBox createRenderObject(BuildContext context) {
    return new RenderDecoratedBox(
      decoration: decoration,
      position: position,
      configuration: createLocalImageConfiguration(context)
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderDecoratedBox renderObject) {
    renderObject
      ..decoration = decoration
      ..configuration = createLocalImageConfiguration(context)
      ..position = position;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    String label;
    if (position != null) {
      switch (position) {
        case DecorationPosition.background:
          label = 'bg';
          break;
        case DecorationPosition.foreground:
          label = 'fg';
          break;
      }
    } else {
      description.add('position: NULL');
      label = 'decoration';
    }
    description.add(decoration != null ? '$label: $decoration' : 'no decoration');
  }
}

/// A convenience widget that combines common painting, positioning, and sizing
/// widgets.
///
/// A container first surrounds the child with [padding] (inflated by any
/// borders present in the [decoration]) and then applies additional
/// [constraints] to the padded extent (incorporating the `width` and `height`
/// as constraints, if either is non-null). The container is then surrounded by
/// additional empty space described from the [margin].
///
/// During painting, the container first applies the given [transform], then
/// paints the [decoration] to fill the padded extent, then it paints the child,
/// and finally paints the [foregroundDecoration], also filling the padded
/// extent.
///
/// Containers with no children try to be as big as possible unless the incoming
/// constraints are unbounded, in which case they try to be as small as
/// possible. Containers with children size themselves to their children. The
/// `width`, `height`, and [constraints] arguments to the constructor override
/// this.
///
/// ## Layout behavior
///
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// Since [Container] combines a number of other widgets each with their own
/// layout behavior, [Container]'s layout behaviour is somewhat complicated.
///
/// tl;dr: [Container] tries, in order: to honor [alignment], to size itself to
/// the [child], to honor the `width`, `height`, and [constraints], to expand to
/// fit the parent, to be as small as possible.
///
/// More specifically:
///
/// If the widget has no child, no `height`, no `width`, no [constraints],
/// and the parent provides unbounded constraints, then [Container] tries to
/// size as small as possible.
///
/// If the widget has no child and no [alignment], but a `height`, `width`, or
/// [constraints] are provided, then the [Container] tries to be as small as
/// possible given the combination of those constraints and the parent's
/// constraints.
///
/// If the widget has no child, no `height`, no `width`, no [constraints], and
/// no [alignment], but the parent provides bounded constraints, then
/// [Container] expands to fit the constraints provided by the parent.
///
/// If the widget has an [alignment], and the parent provides unbounded
/// constraints, then the [Container] tries to size itself around the child.
///
/// If the widget has an [alignment], and the parent provides bounded
/// constraints, then the [Container] tries to expand to fit the parent, and
/// then positions the child within itself as per the [alignment].
///
/// Otherwise, the widget has a [child] but no `height`, no `width`, no
/// [constraints], and no [alignment], and the [Container] passes the
/// constraints from the parent to the child and sizes itself to match the
/// child.
///
/// The [margin] and [padding] properties also affect the layout, as described
/// in the documentation for those properties. (Their effects merely augment the
/// rules described above.) The [decoration] can implicitly increase the
/// [padding] (e.g. borders in a [BoxDecoration] contribute to the [padding]);
/// see [Decoration.padding].
///
/// ## Sample code
///
/// This example shows a 48x48 green square (placed inside a [Center] widget in
/// case the parent widget has its own opinions regarding the size that the
/// [Container] should take), with a margin so that it stays away from
/// neighboring widgets:
///
/// ```dart
/// new Center(
///   child: new Container(
///     margin: const EdgeInsets.all(10.0),
///     color: const Color(0xFF00FF00),
///     width: 48.0,
///     height: 48.0,
///   ),
/// )
/// ```
///
/// This example shows how to use many of the features of [Container] at once.
/// The [constraints] are set to fit the font size plus ample headroom
/// vertically, while expanding horizontally to fit the parent. The [padding] is
/// used to make sure there is space between the contents and the text. The
/// `color` makes the box teal. The [alignment] causes the [child] to be
/// centered in the box. The [foregroundDecoration] overlays a nine-patch image
/// onto the text. Finally, the [transform] applies a slight rotation to the
/// entire contraption to complete the effect.
///
/// ```dart
/// new Container(
///   constraints: new BoxConstraints.expand(
///     height: Theme.of(context).textTheme.display1.fontSize * 1.1 + 200.0,
///   ),
///   padding: const EdgeInsets.all(8.0),
///   color: Colors.teal.shade700,
///   alignment: FractionalOffset.center,
///   child: new Text('Hello World', style: Theme.of(context).textTheme.display1.copyWith(color: Colors.white)),
///   foregroundDecoration: new BoxDecoration(
///     image: new DecorationImage(
///       image: new NetworkImage('https://www.example.com/images/frame.png'),
///       centerSlice: new Rect.fromLTRB(270.0, 180.0, 1360.0, 730.0),
///     ),
///   ),
///   transform: new Matrix4.rotationZ(0.1),
/// )
/// ```
///
/// See also:
///
///  * [AnimatedContainer], a variant that smoothly animates the properties when
///    they change.
///  * [Border], which has a sample which uses [Container] heavily.
class Container extends StatelessWidget {
  /// Creates a widget that combines common painting, positioning, and sizing widgets.
  ///
  /// The `height` and `width` values include the padding.
  ///
  /// The `color` argument is a shorthand for `decoration: new
  /// BoxDecoration(color: color)`, which means you cannot supply both a `color`
  /// and a `decoration` argument. If you want to have both a `color` and a
  /// `decoration`, you can pass the color as the `color` argument to the
  /// `BoxDecoration`.
  Container({
    Key key,
    this.alignment,
    this.padding,
    Color color,
    Decoration decoration,
    this.foregroundDecoration,
    double width,
    double height,
    BoxConstraints constraints,
    this.margin,
    this.transform,
    this.child,
  }) : assert(margin == null || margin.isNonNegative),
       assert(padding == null || padding.isNonNegative),
       assert(decoration == null || decoration.debugAssertIsValid()),
       assert(constraints == null || constraints.debugAssertIsValid()),
       assert(color == null || decoration == null,
         'Cannot provide both a color and a decoration\n'
         'The color argument is just a shorthand for "decoration: new BoxDecoration(color: color)".'
       ),
       decoration = decoration ?? (color != null ? new BoxDecoration(color: color) : null),
       constraints =
        (width != null || height != null)
          ? constraints?.tighten(width: width, height: height)
            ?? new BoxConstraints.tightFor(width: width, height: height)
          : constraints,
       super(key: key);

  /// The [child] contained by the container.
  ///
  /// If null, and if the [constraints] are unbounded or also null, the
  /// container will expand to fill all available space in its parent, unless
  /// the parent provides unbounded constraints, in which case the container
  /// will attempt to be as small as possible.
  final Widget child;

  /// Align the [child] within the container.
  ///
  /// If non-null, the container will expand to fill its parent and position its
  /// child within itself according to the given value. If the incoming
  /// constraints are unbounded, then the child will be shrink-wrapped instead.
  ///
  /// Ignored if [child] is null.
  final FractionalOffset alignment;

  /// Empty space to inscribe inside the [decoration]. The [child], if any, is
  /// placed inside this padding.
  final EdgeInsets padding;

  /// The decoration to paint behind the [child].
  ///
  /// A shorthand for specifying just a solid color is available in the
  /// constructor: set the `color` argument instead of the `decoration`
  /// argument.
  final Decoration decoration;

  /// The decoration to paint in front of the [child].
  final Decoration foregroundDecoration;

  /// Additional constraints to apply to the child.
  ///
  /// The constructor `width` and `height` arguments are combined with the
  /// `constraints` argument to set this property.
  ///
  /// The [padding] goes inside the constraints.
  final BoxConstraints constraints;

  /// Empty space to surround the [decoration] and [child].
  final EdgeInsets margin;

  /// The transformation matrix to apply before painting the container.
  final Matrix4 transform;

  EdgeInsets get _paddingIncludingDecoration {
    if (decoration == null || decoration.padding == null)
      return padding;
    final EdgeInsets decorationPadding = decoration.padding;
    if (padding == null)
      return decorationPadding;
    return padding + decorationPadding;
  }

  @override
  Widget build(BuildContext context) {
    Widget current = child;

    if (child == null && (constraints == null || !constraints.isTight)) {
      current = new LimitedBox(
        maxWidth: 0.0,
        maxHeight: 0.0,
        child: new ConstrainedBox(constraints: const BoxConstraints.expand())
      );
    }

    if (alignment != null)
      current = new Align(alignment: alignment, child: current);

    final EdgeInsets effectivePadding = _paddingIncludingDecoration;
    if (effectivePadding != null)
      current = new Padding(padding: effectivePadding, child: current);

    if (decoration != null)
      current = new DecoratedBox(decoration: decoration, child: current);

    if (foregroundDecoration != null) {
      current = new DecoratedBox(
        decoration: foregroundDecoration,
        position: DecorationPosition.foreground,
        child: current
      );
    }

    if (constraints != null)
      current = new ConstrainedBox(constraints: constraints, child: current);

    if (margin != null)
      current = new Padding(padding: margin, child: current);

    if (transform != null)
      current = new Transform(transform: transform, child: current);

    return current;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (alignment != null)
      description.add('$alignment');
    if (padding != null)
      description.add('padding: $padding');
    if (decoration != null)
      description.add('bg: $decoration');
    if (foregroundDecoration != null)
      description.add('fg: $foregroundDecoration');
    if (constraints != null)
      description.add('$constraints');
    if (margin != null)
      description.add('margin: $margin');
    if (transform != null)
      description.add('has transform');
  }
}
