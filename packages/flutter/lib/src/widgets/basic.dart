// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show Image, ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'debug.dart';
import 'framework.dart';
import 'localizations.dart';
import 'widget_span.dart';

export 'package:flutter/animation.dart';
export 'package:flutter/foundation.dart' show
  ChangeNotifier,
  FlutterErrorDetails,
  Listenable,
  TargetPlatform,
  ValueNotifier;
export 'package:flutter/painting.dart';
export 'package:flutter/rendering.dart' show
  AlignmentTween,
  AlignmentGeometryTween,
  Axis,
  BoxConstraints,
  CrossAxisAlignment,
  CustomClipper,
  CustomPainter,
  CustomPainterSemantics,
  DecorationPosition,
  FlexFit,
  FlowDelegate,
  FlowPaintingContext,
  FractionalOffsetTween,
  HitTestBehavior,
  LayerLink,
  MainAxisAlignment,
  MainAxisSize,
  MultiChildLayoutDelegate,
  Overflow,
  PaintingContext,
  PointerCancelEvent,
  PointerCancelEventListener,
  PointerDownEvent,
  PointerDownEventListener,
  PointerEvent,
  PointerMoveEvent,
  PointerMoveEventListener,
  PointerUpEvent,
  PointerUpEventListener,
  RelativeRect,
  SemanticsBuilderCallback,
  ShaderCallback,
  ShapeBorderClipper,
  SingleChildLayoutDelegate,
  StackFit,
  TextOverflow,
  ValueChanged,
  ValueGetter,
  WrapAlignment,
  WrapCrossAlignment;

// Examples can assume:
// class TestWidget extends StatelessWidget { @override Widget build(BuildContext context) => const Placeholder(); }
// WidgetTester tester;
// bool _visible;
// class Sky extends CustomPainter { @override void paint(Canvas c, Size s) => null; @override bool shouldRepaint(Sky s) => false; }
// BuildContext context;
// dynamic userAvatarUrl;

// BIDIRECTIONAL TEXT SUPPORT

/// A widget that determines the ambient directionality of text and
/// text-direction-sensitive render objects.
///
/// For example, [Padding] depends on the [Directionality] to resolve
/// [EdgeInsetsDirectional] objects into absolute [EdgeInsets] objects.
class Directionality extends InheritedWidget {
  /// Creates a widget that determines the directionality of text and
  /// text-direction-sensitive render objects.
  ///
  /// The [textDirection] and [child] arguments must not be null.
  const Directionality({
    Key key,
    @required this.textDirection,
    @required Widget child,
  }) : assert(textDirection != null),
       assert(child != null),
       super(key: key, child: child);

  /// The text direction for this subtree.
  final TextDirection textDirection;

  /// The text direction from the closest instance of this class that encloses
  /// the given context.
  ///
  /// If there is no [Directionality] ancestor widget in the tree at the given
  /// context, then this will return null.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// TextDirection textDirection = Directionality.of(context);
  /// ```
  static TextDirection of(BuildContext context) {
    final Directionality widget = context.inheritFromWidgetOfExactType(Directionality);
    return widget?.textDirection;
  }

  @override
  bool updateShouldNotify(Directionality oldWidget) => textDirection != oldWidget.textDirection;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
  }
}


// PAINTING NODES

/// A widget that makes its child partially transparent.
///
/// This class paints its child into an intermediate buffer and then blends the
/// child back into the scene partially transparent.
///
/// For values of opacity other than 0.0 and 1.0, this class is relatively
/// expensive because it requires painting the child into an intermediate
/// buffer. For the value 0.0, the child is simply not painted at all. For the
/// value 1.0, the child is painted immediately without an intermediate buffer.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=9hltevOHQBw}
///
/// {@tool sample}
///
/// This example shows some [Text] when the `_visible` member field is true, and
/// hides it when it is false:
///
/// ```dart
/// Opacity(
///   opacity: _visible ? 1.0 : 0.0,
///   child: const Text('Now you see me, now you don\'t!'),
/// )
/// ```
/// {@end-tool}
///
/// This is more efficient than adding and removing the child widget from the
/// tree on demand.
///
/// ## Performance considerations for opacity animation
///
/// Animating an [Opacity] widget directly causes the widget (and possibly its
/// subtree) to rebuild each frame, which is not very efficient. Consider using
/// an [AnimatedOpacity] instead.
///
/// ## Transparent image
///
/// If only a single [Image] or [Color] needs to be composited with an opacity
/// between 0.0 and 1.0, it's much faster to directly use them without [Opacity]
/// widgets.
///
/// For example, `Container(color: Color.fromRGBO(255, 0, 0, 0.5))` is much
/// faster than `Opacity(opacity: 0.5, child: Container(color: Colors.red))`.
///
/// {@tool sample}
///
/// The following example draws an [Image] with 0.5 opacity without using
/// [Opacity]:
///
/// ```dart
/// Image.network(
///   'https://raw.githubusercontent.com/flutter/assets-for-api-docs/master/packages/diagrams/assets/blend_mode_destination.jpeg',
///   color: Color.fromRGBO(255, 255, 255, 0.5),
///   colorBlendMode: BlendMode.modulate
/// )
/// ```
///
/// {@end-tool}
///
/// Directly drawing an [Image] or [Color] with opacity is faster than using
/// [Opacity] on top of them because [Opacity] could apply the opacity to a
/// group of widgets and therefore a costly offscreen buffer will be used.
/// Drawing content into the offscreen buffer may also trigger render target
/// switches and such switching is particularly slow in older GPUs.
///
/// See also:
///
///  * [Visibility], which can hide a child more efficiently (albeit less
///    subtly, because it is either visible or hidden, rather than allowing
///    fractional opacity values).
///  * [ShaderMask], which can apply more elaborate effects to its child.
///  * [Transform], which applies an arbitrary transform to its child widget at
///    paint time.
///  * [AnimatedOpacity], which uses an animation internally to efficiently
///    animate opacity.
///  * [FadeTransition], which uses a provided animation to efficiently animate
///    opacity.
///  * [Image], which can directly provide a partially transparent image with
///    much less performance hit.
class Opacity extends SingleChildRenderObjectWidget {
  /// Creates a widget that makes its child partially transparent.
  ///
  /// The [opacity] argument must not be null and must be between 0.0 and 1.0
  /// (inclusive).
  const Opacity({
    Key key,
    @required this.opacity,
    this.alwaysIncludeSemantics = false,
    Widget child,
  }) : assert(opacity != null && opacity >= 0.0 && opacity <= 1.0),
       assert(alwaysIncludeSemantics != null),
       super(key: key, child: child);

  /// The fraction to scale the child's alpha value.
  ///
  /// An opacity of 1.0 is fully opaque. An opacity of 0.0 is fully transparent
  /// (i.e., invisible).
  ///
  /// The opacity must not be null.
  ///
  /// Values 1.0 and 0.0 are painted with a fast path. Other values
  /// require painting the child into an intermediate buffer, which is
  /// expensive.
  final double opacity;

  /// Whether the semantic information of the children is always included.
  ///
  /// Defaults to false.
  ///
  /// When true, regardless of the opacity settings the child semantic
  /// information is exposed as if the widget were fully visible. This is
  /// useful in cases where labels may be hidden during animations that
  /// would otherwise contribute relevant semantics.
  final bool alwaysIncludeSemantics;

  @override
  RenderOpacity createRenderObject(BuildContext context) {
    return RenderOpacity(
      opacity: opacity,
      alwaysIncludeSemantics: alwaysIncludeSemantics,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderOpacity renderObject) {
    renderObject
      ..opacity = opacity
      ..alwaysIncludeSemantics = alwaysIncludeSemantics;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('opacity', opacity));
    properties.add(FlagProperty('alwaysIncludeSemantics', value: alwaysIncludeSemantics, ifTrue: 'alwaysIncludeSemantics'));
  }
}

/// A widget that applies a mask generated by a [Shader] to its child.
///
/// For example, [ShaderMask] can be used to gradually fade out the edge
/// of a child by using a [new ui.Gradient.linear] mask.
///
/// {@tool sample}
///
/// This example makes the text look like it is on fire:
///
/// ```dart
/// ShaderMask(
///   shaderCallback: (Rect bounds) {
///     return RadialGradient(
///       center: Alignment.topLeft,
///       radius: 1.0,
///       colors: <Color>[Colors.yellow, Colors.deepOrange.shade900],
///       tileMode: TileMode.mirror,
///     ).createShader(bounds);
///   },
///   child: const Text('I’m burning the memories'),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Opacity], which can apply a uniform alpha effect to its child.
///  * [CustomPaint], which lets you draw directly on the canvas.
///  * [DecoratedBox], for another approach at decorating child widgets.
///  * [BackdropFilter], which applies an image filter to the background.
class ShaderMask extends SingleChildRenderObjectWidget {
  /// Creates a widget that applies a mask generated by a [Shader] to its child.
  ///
  /// The [shaderCallback] and [blendMode] arguments must not be null.
  const ShaderMask({
    Key key,
    @required this.shaderCallback,
    this.blendMode = BlendMode.modulate,
    Widget child,
  }) : assert(shaderCallback != null),
       assert(blendMode != null),
       super(key: key, child: child);

  /// Called to create the [dart:ui.Shader] that generates the mask.
  ///
  /// The shader callback is called with the current size of the child so that
  /// it can customize the shader to the size and location of the child.
  ///
  /// Typically this will use a [LinearGradient], [RadialGradient], or
  /// [SweepGradient] to create the [dart:ui.Shader], though the
  /// [dart:ui.ImageShader] class could also be used.
  final ShaderCallback shaderCallback;

  /// The [BlendMode] to use when applying the shader to the child.
  ///
  /// The default, [BlendMode.modulate], is useful for applying an alpha blend
  /// to the child. Other blend modes can be used to create other effects.
  final BlendMode blendMode;

  @override
  RenderShaderMask createRenderObject(BuildContext context) {
    return RenderShaderMask(
      shaderCallback: shaderCallback,
      blendMode: blendMode,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderShaderMask renderObject) {
    renderObject
      ..shaderCallback = shaderCallback
      ..blendMode = blendMode;
  }
}

/// A widget that applies a filter to the existing painted content and then
/// paints [child].
///
/// The filter will be applied to all the area within its parent or ancestor
/// widget's clip. If there's no clip, the filter will be applied to the full
/// screen.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=dYRs7Q1vfYI}
///
/// {@tool sample}
/// If the [BackdropFilter] needs to be applied to an area that exactly matches
/// its child, wraps the [BackdropFilter] with a clip widget that clips exactly
/// to that child.
///
/// ```dart
/// Stack(
///   fit: StackFit.expand,
///   children: <Widget>[
///     Text('0' * 10000),
///     Center(
///       child: ClipRect(  // <-- clips to the 200x200 [Container] below
///         child: BackdropFilter(
///           filter: ui.ImageFilter.blur(
///             sigmaX: 5.0,
///             sigmaY: 5.0,
///           ),
///           child: Container(
///             alignment: Alignment.center,
///             width: 200.0,
///             height: 200.0,
///             child: Text('Hello World'),
///           ),
///         ),
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// This effect is relatively expensive, especially if the filter is non-local,
/// such as a blur.
///
/// See also:
///
///  * [DecoratedBox], which draws a background under (or over) a widget.
///  * [Opacity], which changes the opacity of the widget itself.
class BackdropFilter extends SingleChildRenderObjectWidget {
  /// Creates a backdrop filter.
  ///
  /// The [filter] argument must not be null.
  const BackdropFilter({
    Key key,
    @required this.filter,
    Widget child,
  }) : assert(filter != null),
       super(key: key, child: child);

  /// The image filter to apply to the existing painted content before painting the child.
  ///
  /// For example, consider using [ImageFilter.blur] to create a backdrop
  /// blur effect
  final ui.ImageFilter filter;

  @override
  RenderBackdropFilter createRenderObject(BuildContext context) {
    return RenderBackdropFilter(filter: filter);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBackdropFilter renderObject) {
    renderObject.filter = filter;
  }
}

/// A widget that provides a canvas on which to draw during the paint phase.
///
/// When asked to paint, [CustomPaint] first asks its [painter] to paint on the
/// current canvas, then it paints its child, and then, after painting its
/// child, it asks its [foregroundPainter] to paint. The coordinate system of the
/// canvas matches the coordinate system of the [CustomPaint] object. The
/// painters are expected to paint within a rectangle starting at the origin and
/// encompassing a region of the given size. (If the painters paint outside
/// those bounds, there might be insufficient memory allocated to rasterize the
/// painting commands and the resulting behavior is undefined.) To enforce
/// painting within those bounds, consider wrapping this [CustomPaint] with a
/// [ClipRect] widget.
///
/// Painters are implemented by subclassing [CustomPainter].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=kp14Y4uHpHs}
///
/// Because custom paint calls its painters during paint, you cannot call
/// `setState` or `markNeedsLayout` during the callback (the layout for this
/// frame has already happened).
///
/// Custom painters normally size themselves to their child. If they do not have
/// a child, they attempt to size themselves to the [size], which defaults to
/// [Size.zero]. [size] must not be null.
///
/// [isComplex] and [willChange] are hints to the compositor's raster cache
/// and must not be null.
///
/// {@tool sample}
///
/// This example shows how the sample custom painter shown at [CustomPainter]
/// could be used in a [CustomPaint] widget to display a background to some
/// text.
///
/// ```dart
/// CustomPaint(
///   painter: Sky(),
///   child: Center(
///     child: Text(
///       'Once upon a time...',
///       style: const TextStyle(
///         fontSize: 40.0,
///         fontWeight: FontWeight.w900,
///         color: Color(0xFFFFFFFF),
///       ),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [CustomPainter], the class to extend when creating custom painters.
///  * [Canvas], the class that a custom painter uses to paint.
class CustomPaint extends SingleChildRenderObjectWidget {
  /// Creates a widget that delegates its painting.
  const CustomPaint({
    Key key,
    this.painter,
    this.foregroundPainter,
    this.size = Size.zero,
    this.isComplex = false,
    this.willChange = false,
    Widget child,
  }) : assert(size != null),
       assert(isComplex != null),
       assert(willChange != null),
       super(key: key, child: child);

  /// The painter that paints before the children.
  final CustomPainter painter;

  /// The painter that paints after the children.
  final CustomPainter foregroundPainter;

  /// The size that this [CustomPaint] should aim for, given the layout
  /// constraints, if there is no child.
  ///
  /// Defaults to [Size.zero].
  ///
  /// If there's a child, this is ignored, and the size of the child is used
  /// instead.
  final Size size;

  /// Whether the painting is complex enough to benefit from caching.
  ///
  /// The compositor contains a raster cache that holds bitmaps of layers in
  /// order to avoid the cost of repeatedly rendering those layers on each
  /// frame. If this flag is not set, then the compositor will apply its own
  /// heuristics to decide whether the this layer is complex enough to benefit
  /// from caching.
  final bool isComplex;

  /// Whether the raster cache should be told that this painting is likely
  /// to change in the next frame.
  final bool willChange;

  @override
  RenderCustomPaint createRenderObject(BuildContext context) {
    return RenderCustomPaint(
      painter: painter,
      foregroundPainter: foregroundPainter,
      preferredSize: size,
      isComplex: isComplex,
      willChange: willChange,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderCustomPaint renderObject) {
    renderObject
      ..painter = painter
      ..foregroundPainter = foregroundPainter
      ..preferredSize = size
      ..isComplex = isComplex
      ..willChange = willChange;
  }

  @override
  void didUnmountRenderObject(RenderCustomPaint renderObject) {
    renderObject
      ..painter = null
      ..foregroundPainter = null;
  }
}

/// A widget that clips its child using a rectangle.
///
/// By default, [ClipRect] prevents its child from painting outside its
/// bounds, but the size and location of the clip rect can be customized using a
/// custom [clipper].
///
/// [ClipRect] is commonly used with these widgets, which commonly paint outside
/// their bounds:
///
///  * [CustomPaint]
///  * [CustomSingleChildLayout]
///  * [CustomMultiChildLayout]
///  * [Align] and [Center] (e.g., if [Align.widthFactor] or
///    [Align.heightFactor] is less than 1.0).
///  * [OverflowBox]
///  * [SizedOverflowBox]
///
/// {@tool sample}
///
/// For example, by combining a [ClipRect] with an [Align], one can show just
/// the top half of an [Image]:
///
/// ```dart
/// ClipRect(
///   child: Align(
///     alignment: Alignment.topCenter,
///     heightFactor: 0.5,
///     child: Image.network(userAvatarUrl),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [CustomClipper], for information about creating custom clips.
///  * [ClipRRect], for a clip with rounded corners.
///  * [ClipOval], for an elliptical clip.
///  * [ClipPath], for an arbitrarily shaped clip.
class ClipRect extends SingleChildRenderObjectWidget {
  /// Creates a rectangular clip.
  ///
  /// If [clipper] is null, the clip will match the layout size and position of
  /// the child.
  ///
  /// The [clipBehavior] argument must not be null or [Clip.none].
  const ClipRect({ Key key, this.clipper, this.clipBehavior = Clip.hardEdge, Widget child })
      : assert(clipBehavior != null),
        super(key: key, child: child);

  /// If non-null, determines which clip to use.
  final CustomClipper<Rect> clipper;

  /// {@macro flutter.clipper.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  @override
  RenderClipRect createRenderObject(BuildContext context) {
    assert(clipBehavior != Clip.none);
    return RenderClipRect(clipper: clipper, clipBehavior: clipBehavior);
  }

  @override
  void updateRenderObject(BuildContext context, RenderClipRect renderObject) {
    assert(clipBehavior != Clip.none);
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior;
  }

  @override
  void didUnmountRenderObject(RenderClipRect renderObject) {
    renderObject.clipper = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomClipper<Rect>>('clipper', clipper, defaultValue: null));
  }
}

/// A widget that clips its child using a rounded rectangle.
///
/// By default, [ClipRRect] uses its own bounds as the base rectangle for the
/// clip, but the size and location of the clip can be customized using a custom
/// [clipper].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=eI43jkQkrvs}
///
/// See also:
///
///  * [CustomClipper], for information about creating custom clips.
///  * [ClipRect], for more efficient clips without rounded corners.
///  * [ClipOval], for an elliptical clip.
///  * [ClipPath], for an arbitrarily shaped clip.
class ClipRRect extends SingleChildRenderObjectWidget {
  /// Creates a rounded-rectangular clip.
  ///
  /// The [borderRadius] defaults to [BorderRadius.zero], i.e. a rectangle with
  /// right-angled corners.
  ///
  /// If [clipper] is non-null, then [borderRadius] is ignored.
  ///
  /// The [clipBehavior] argument must not be null or [Clip.none].
  const ClipRRect({
    Key key,
    this.borderRadius,
    this.clipper,
    this.clipBehavior = Clip.antiAlias,
    Widget child,
  }) : assert(borderRadius != null || clipper != null),
       assert(clipBehavior != null),
       super(key: key, child: child);

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This value is ignored if [clipper] is non-null.
  final BorderRadius borderRadius;

  /// If non-null, determines which clip to use.
  final CustomClipper<RRect> clipper;

  /// {@macro flutter.clipper.clipBehavior}
  ///
  /// Defaults to [Clip.antiAlias].
  final Clip clipBehavior;

  @override
  RenderClipRRect createRenderObject(BuildContext context) {
    assert(clipBehavior != Clip.none);
    return RenderClipRRect(borderRadius: borderRadius, clipper: clipper, clipBehavior: clipBehavior);
  }

  @override
  void updateRenderObject(BuildContext context, RenderClipRRect renderObject) {
    assert(clipBehavior != Clip.none);
    renderObject
      ..borderRadius = borderRadius
      ..clipBehavior = clipBehavior
      ..clipper = clipper;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius, showName: false, defaultValue: null));
    properties.add(DiagnosticsProperty<CustomClipper<RRect>>('clipper', clipper, defaultValue: null));
  }
}

/// A widget that clips its child using an oval.
///
/// By default, inscribes an axis-aligned oval into its layout dimensions and
/// prevents its child from painting outside that oval, but the size and
/// location of the clip oval can be customized using a custom [clipper].
///
/// See also:
///
///  * [CustomClipper], for information about creating custom clips.
///  * [ClipRect], for more efficient clips without rounded corners.
///  * [ClipRRect], for a clip with rounded corners.
///  * [ClipPath], for an arbitrarily shaped clip.
class ClipOval extends SingleChildRenderObjectWidget {
  /// Creates an oval-shaped clip.
  ///
  /// If [clipper] is null, the oval will be inscribed into the layout size and
  /// position of the child.
  ///
  /// The [clipBehavior] argument must not be null or [Clip.none].
  const ClipOval({Key key, this.clipper, this.clipBehavior = Clip.antiAlias, Widget child})
      : assert(clipBehavior != null),
        super(key: key, child: child);

  /// If non-null, determines which clip to use.
  ///
  /// The delegate returns a rectangle that describes the axis-aligned
  /// bounding box of the oval. The oval's axes will themselves also
  /// be axis-aligned.
  ///
  /// If the [clipper] delegate is null, then the oval uses the
  /// widget's bounding box (the layout dimensions of the render
  /// object) instead.
  final CustomClipper<Rect> clipper;

  /// {@macro flutter.clipper.clipBehavior}
  ///
  /// Defaults to [Clip.antiAlias].
  final Clip clipBehavior;

  @override
  RenderClipOval createRenderObject(BuildContext context) {
    assert(clipBehavior != Clip.none);
    return RenderClipOval(clipper: clipper, clipBehavior: clipBehavior);
  }

  @override
  void updateRenderObject(BuildContext context, RenderClipOval renderObject) {
    assert(clipBehavior != Clip.none);
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior;
  }

  @override
  void didUnmountRenderObject(RenderClipOval renderObject) {
    renderObject.clipper = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomClipper<Rect>>('clipper', clipper, defaultValue: null));
  }
}

/// A widget that clips its child using a path.
///
/// Calls a callback on a delegate whenever the widget is to be
/// painted. The callback returns a path and the widget prevents the
/// child from painting outside the path.
///
/// Clipping to a path is expensive. Certain shapes have more
/// optimized widgets:
///
///  * To clip to a rectangle, consider [ClipRect].
///  * To clip to an oval or circle, consider [ClipOval].
///  * To clip to a rounded rectangle, consider [ClipRRect].
///
/// To clip to a particular [ShapeBorder], consider using either the
/// [ClipPath.shape] static method or the [ShapeBorderClipper] custom clipper
/// class.
class ClipPath extends SingleChildRenderObjectWidget {
  /// Creates a path clip.
  ///
  /// If [clipper] is null, the clip will be a rectangle that matches the layout
  /// size and location of the child. However, rather than use this default,
  /// consider using a [ClipRect], which can achieve the same effect more
  /// efficiently.
  ///
  /// The [clipBehavior] argument must not be null or [Clip.none].
  const ClipPath({
    Key key,
    this.clipper,
    this.clipBehavior = Clip.antiAlias,
    Widget child,
  }) : assert(clipBehavior != null),
       super(key: key, child: child);

  /// Creates a shape clip.
  ///
  /// Uses a [ShapeBorderClipper] to configure the [ClipPath] to clip to the
  /// given [ShapeBorder].
  static Widget shape({
    Key key,
    @required ShapeBorder shape,
    Clip clipBehavior = Clip.antiAlias,
    Widget child,
  }) {
    assert(clipBehavior != null);
    assert(clipBehavior != Clip.none);
    assert(shape != null);
    return Builder(
      key: key,
      builder: (BuildContext context) {
        return ClipPath(
          clipper: ShapeBorderClipper(
            shape: shape,
            textDirection: Directionality.of(context),
          ),
          clipBehavior: clipBehavior,
          child: child,
        );
      },
    );
  }

  /// If non-null, determines which clip to use.
  ///
  /// The default clip, which is used if this property is null, is the
  /// bounding box rectangle of the widget. [ClipRect] is a more
  /// efficient way of obtaining that effect.
  final CustomClipper<Path> clipper;

  /// {@macro flutter.clipper.clipBehavior}
  ///
  /// Defaults to [Clip.antiAlias].
  final Clip clipBehavior;

  @override
  RenderClipPath createRenderObject(BuildContext context) {
    assert(clipBehavior != Clip.none);
    return RenderClipPath(clipper: clipper, clipBehavior: clipBehavior);
  }

  @override
  void updateRenderObject(BuildContext context, RenderClipPath renderObject) {
    assert(clipBehavior != Clip.none);
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior;
  }

  @override
  void didUnmountRenderObject(RenderClipPath renderObject) {
    renderObject.clipper = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomClipper<Path>>('clipper', clipper, defaultValue: null));
  }
}

/// A widget representing a physical layer that clips its children to a shape.
///
/// Physical layers cast shadows based on an [elevation] which is nominally in
/// logical pixels, coming vertically out of the rendering surface.
///
/// For shapes that cannot be expressed as a rectangle with rounded corners use
/// [PhysicalShape].
///
/// See also:
///
///  * [AnimatedPhysicalModel], which animates property changes smoothly over
///    a given duration.
///  * [DecoratedBox], which can apply more arbitrary shadow effects.
///  * [ClipRect], which applies a clip to its child.
class PhysicalModel extends SingleChildRenderObjectWidget {
  /// Creates a physical model with a rounded-rectangular clip.
  ///
  /// The [color] is required; physical things have a color.
  ///
  /// The [shape], [elevation], [color], [clipBehavior], and [shadowColor] must
  /// not be null. Additionally, the [elevation] must be non-negative.
  const PhysicalModel({
    Key key,
    this.shape = BoxShape.rectangle,
    this.clipBehavior = Clip.none,
    this.borderRadius,
    this.elevation = 0.0,
    @required this.color,
    this.shadowColor = const Color(0xFF000000),
    Widget child,
  }) : assert(shape != null),
       assert(elevation != null && elevation >= 0.0),
       assert(color != null),
       assert(shadowColor != null),
       assert(clipBehavior != null),
       super(key: key, child: child);

  /// The type of shape.
  final BoxShape shape;

  /// {@macro flutter.widgets.Clip}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The border radius of the rounded corners.
  ///
  /// Values are clamped so that horizontal and vertical radii sums do not
  /// exceed width/height.
  ///
  /// This is ignored if the [shape] is not [BoxShape.rectangle].
  final BorderRadius borderRadius;

  /// The z-coordinate relative to the parent at which to place this physical
  /// object.
  ///
  /// The value is non-negative.
  final double elevation;

  /// The background color.
  final Color color;

  /// The shadow color.
  final Color shadowColor;

  @override
  RenderPhysicalModel createRenderObject(BuildContext context) {
    return RenderPhysicalModel(
      shape: shape,
      clipBehavior: clipBehavior,
      borderRadius: borderRadius,
      elevation: elevation, color: color,
      shadowColor: shadowColor,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPhysicalModel renderObject) {
    renderObject
      ..shape = shape
      ..clipBehavior = clipBehavior
      ..borderRadius = borderRadius
      ..elevation = elevation
      ..color = color
      ..shadowColor = shadowColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<BoxShape>('shape', shape));
    properties.add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(ColorProperty('color', color));
    properties.add(ColorProperty('shadowColor', shadowColor));
  }
}

/// A widget representing a physical layer that clips its children to a path.
///
/// Physical layers cast shadows based on an [elevation] which is nominally in
/// logical pixels, coming vertically out of the rendering surface.
///
/// [PhysicalModel] does the same but only supports shapes that can be expressed
/// as rectangles with rounded corners.
///
/// See also:
///
///  * [ShapeBorderClipper], which converts a [ShapeBorder] to a [CustomerClipper], as
///    needed by this widget.
class PhysicalShape extends SingleChildRenderObjectWidget {
  /// Creates a physical model with an arbitrary shape clip.
  ///
  /// The [color] is required; physical things have a color.
  ///
  /// The [clipper], [elevation], [color], [clipBehavior], and [shadowColor]
  /// must not be null. Additionally, the [elevation] must be non-negative.
  const PhysicalShape({
    Key key,
    @required this.clipper,
    this.clipBehavior = Clip.none,
    this.elevation = 0.0,
    @required this.color,
    this.shadowColor = const Color(0xFF000000),
    Widget child,
  }) : assert(clipper != null),
       assert(clipBehavior != null),
       assert(elevation != null && elevation >= 0.0),
       assert(color != null),
       assert(shadowColor != null),
       super(key: key, child: child);

  /// Determines which clip to use.
  ///
  /// If the path in question is expressed as a [ShapeBorder] subclass,
  /// consider using the [ShapeBorderClipper] delegate class to adapt the
  /// shape for use with this widget.
  final CustomClipper<Path> clipper;

  /// {@macro flutter.widgets.Clip}
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// The z-coordinate relative to the parent at which to place this physical
  /// object.
  ///
  /// The value is non-negative.
  final double elevation;

  /// The background color.
  final Color color;

  /// When elevation is non zero the color to use for the shadow color.
  final Color shadowColor;

  @override
  RenderPhysicalShape createRenderObject(BuildContext context) {
    return RenderPhysicalShape(
      clipper: clipper,
      clipBehavior: clipBehavior,
      elevation: elevation,
      color: color,
      shadowColor: shadowColor,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPhysicalShape renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior
      ..elevation = elevation
      ..color = color
      ..shadowColor = shadowColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomClipper<Path>>('clipper', clipper));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(ColorProperty('color', color));
    properties.add(ColorProperty('shadowColor', shadowColor));
  }
}

// POSITIONING AND SIZING NODES

/// A widget that applies a transformation before painting its child.
///
/// Unlike [RotatedBox], which applies a rotation prior to layout, this object
/// applies its transformation just prior to painting, which means the
/// transformation is not taken into account when calculating how much space
/// this widget's child (and thus this widget) consumes.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=9z_YNlRlWfA}
///
/// {@tool sample}
///
/// This example rotates and skews an orange box containing text, keeping the
/// top right corner pinned to its original position.
///
/// ```dart
/// Container(
///   color: Colors.black,
///   child: Transform(
///     alignment: Alignment.topRight,
///     transform: Matrix4.skewY(0.3)..rotateZ(-math.pi / 12.0),
///     child: Container(
///       padding: const EdgeInsets.all(8.0),
///       color: const Color(0xFFE8581C),
///       child: const Text('Apartment for rent!'),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [RotatedBox], which rotates the child widget during layout, not just
///    during painting.
///  * [FractionalTranslation], which applies a translation to the child
///    that is relative to the child's size.
///  * [FittedBox], which sizes and positions its child widget to fit the parent
///    according to a given [BoxFit] discipline.
class Transform extends SingleChildRenderObjectWidget {
  /// Creates a widget that transforms its child.
  ///
  /// The [transform] argument must not be null.
  const Transform({
    Key key,
    @required this.transform,
    this.origin,
    this.alignment,
    this.transformHitTests = true,
    Widget child,
  }) : assert(transform != null),
       super(key: key, child: child);

  /// Creates a widget that transforms its child using a rotation around the
  /// center.
  ///
  /// The `angle` argument must not be null. It gives the rotation in clockwise
  /// radians.
  ///
  /// {@tool sample}
  ///
  /// This example rotates an orange box containing text around its center by
  /// fifteen degrees.
  ///
  /// ```dart
  /// Transform.rotate(
  ///   angle: -math.pi / 12.0,
  ///   child: Container(
  ///     padding: const EdgeInsets.all(8.0),
  ///     color: const Color(0xFFE8581C),
  ///     child: const Text('Apartment for rent!'),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [RotationTransition], which animates changes in rotation smoothly
  ///    over a given duration.
  Transform.rotate({
    Key key,
    @required double angle,
    this.origin,
    this.alignment = Alignment.center,
    this.transformHitTests = true,
    Widget child,
  }) : transform = Matrix4.rotationZ(angle),
       super(key: key, child: child);

  /// Creates a widget that transforms its child using a translation.
  ///
  /// The `offset` argument must not be null. It specifies the translation.
  ///
  /// {@tool sample}
  ///
  /// This example shifts the silver-colored child down by fifteen pixels.
  ///
  /// ```dart
  /// Transform.translate(
  ///   offset: const Offset(0.0, 15.0),
  ///   child: Container(
  ///     padding: const EdgeInsets.all(8.0),
  ///     color: const Color(0xFF7F7F7F),
  ///     child: const Text('Quarter'),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  Transform.translate({
    Key key,
    @required Offset offset,
    this.transformHitTests = true,
    Widget child,
  }) : transform = Matrix4.translationValues(offset.dx, offset.dy, 0.0),
       origin = null,
       alignment = null,
       super(key: key, child: child);

  /// Creates a widget that scales its child uniformly.
  ///
  /// The `scale` argument must not be null. It gives the scalar by which
  /// to multiply the `x` and `y` axes.
  ///
  /// The [alignment] controls the origin of the scale; by default, this is
  /// the center of the box.
  ///
  /// {@tool sample}
  ///
  /// This example shrinks an orange box containing text such that each dimension
  /// is half the size it would otherwise be.
  ///
  /// ```dart
  /// Transform.scale(
  ///   scale: 0.5,
  ///   child: Container(
  ///     padding: const EdgeInsets.all(8.0),
  ///     color: const Color(0xFFE8581C),
  ///     child: const Text('Bad Idea Bears'),
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [ScaleTransition], which animates changes in scale smoothly
  ///    over a given duration.
  Transform.scale({
    Key key,
    @required double scale,
    this.origin,
    this.alignment = Alignment.center,
    this.transformHitTests = true,
    Widget child,
  }) : transform = Matrix4.diagonal3Values(scale, scale, 1.0),
       super(key: key, child: child);

  /// The matrix to transform the child by during painting.
  final Matrix4 transform;

  /// The origin of the coordinate system (relative to the upper left corder of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset origin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [origin], both are applied.
  ///
  /// An [AlignmentDirectional.start] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [textDirection] is
  /// [TextDirection.ltr], and `1.0` if [textDirection] is [TextDirection.rtl].
  /// Similarly [AlignmentDirectional.end] is the same as an [Alignment]
  /// whose [Alignment.x] value is `1.0` if [textDirection] is
  /// [TextDirection.ltr], and `-1.0` if [textDirection] is [TextDirection.rtl].
  final AlignmentGeometry alignment;

  /// Whether to apply the transformation when performing hit tests.
  final bool transformHitTests;

  @override
  RenderTransform createRenderObject(BuildContext context) {
    return RenderTransform(
      transform: transform,
      origin: origin,
      alignment: alignment,
      textDirection: Directionality.of(context),
      transformHitTests: transformHitTests,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTransform renderObject) {
    renderObject
      ..transform = transform
      ..origin = origin
      ..alignment = alignment
      ..textDirection = Directionality.of(context)
      ..transformHitTests = transformHitTests;
  }
}

/// A widget that can be targeted by a [CompositedTransformFollower].
///
/// When this widget is composited during the compositing phase (which comes
/// after the paint phase, as described in [WidgetsBinding.drawFrame]), it
/// updates the [link] object so that any [CompositedTransformFollower] widgets
/// that are subsequently composited in the same frame and were given the same
/// [LayerLink] can position themselves at the same screen location.
///
/// A single [CompositedTransformTarget] can be followed by multiple
/// [CompositedTransformFollower] widgets.
///
/// The [CompositedTransformTarget] must come earlier in the paint order than
/// any linked [CompositedTransformFollower]s.
///
/// See also:
///
///  * [CompositedTransformFollower], the widget that can target this one.
///  * [LeaderLayer], the layer that implements this widget's logic.
class CompositedTransformTarget extends SingleChildRenderObjectWidget {
  /// Creates a composited transform target widget.
  ///
  /// The [link] property must not be null, and must not be currently being used
  /// by any other [CompositedTransformTarget] object that is in the tree.
  const CompositedTransformTarget({
    Key key,
    @required this.link,
    Widget child,
  }) : assert(link != null),
       super(key: key, child: child);

  /// The link object that connects this [CompositedTransformTarget] with one or
  /// more [CompositedTransformFollower]s.
  ///
  /// This property must not be null. The object must not be associated with
  /// another [CompositedTransformTarget] that is also being painted.
  final LayerLink link;

  @override
  RenderLeaderLayer createRenderObject(BuildContext context) {
    return RenderLeaderLayer(
      link: link,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderLeaderLayer renderObject) {
    renderObject
      ..link = link;
  }
}

/// A widget that follows a [CompositedTransformTarget].
///
/// When this widget is composited during the compositing phase (which comes
/// after the paint phase, as described in [WidgetsBinding.drawFrame]), it
/// applies a transformation that causes it to provide its child with a
/// coordinate space that matches that of the linked [CompositedTransformTarget]
/// widget, offset by [offset].
///
/// The [LayerLink] object used as the [link] must be the same object as that
/// provided to the matching [CompositedTransformTarget].
///
/// The [CompositedTransformTarget] must come earlier in the paint order than
/// this [CompositedTransformFollower].
///
/// Hit testing on descendants of this widget will only work if the target
/// position is within the box that this widget's parent considers to be
/// hittable. If the parent covers the screen, this is trivially achievable, so
/// this widget is usually used as the root of an [OverlayEntry] in an app-wide
/// [Overlay] (e.g. as created by the [MaterialApp] widget's [Navigator]).
///
/// See also:
///
///  * [CompositedTransformTarget], the widget that this widget can target.
///  * [FollowerLayer], the layer that implements this widget's logic.
///  * [Transform], which applies an arbitrary transform to a child.
class CompositedTransformFollower extends SingleChildRenderObjectWidget {
  /// Creates a composited transform target widget.
  ///
  /// The [link] property must not be null. If it was also provided to a
  /// [CompositedTransformTarget], that widget must come earlier in the paint
  /// order.
  ///
  /// The [showWhenUnlinked] and [offset] properties must also not be null.
  const CompositedTransformFollower({
    Key key,
    @required this.link,
    this.showWhenUnlinked = true,
    this.offset = Offset.zero,
    Widget child,
  }) : assert(link != null),
       assert(showWhenUnlinked != null),
       assert(offset != null),
       super(key: key, child: child);

  /// The link object that connects this [CompositedTransformFollower] with a
  /// [CompositedTransformTarget].
  ///
  /// This property must not be null.
  final LayerLink link;

  /// Whether to show the widget's contents when there is no corresponding
  /// [CompositedTransformTarget] with the same [link].
  ///
  /// When the widget is linked, the child is positioned such that it has the
  /// same global position as the linked [CompositedTransformTarget].
  ///
  /// When the widget is not linked, then: if [showWhenUnlinked] is true, the
  /// child is visible and not repositioned; if it is false, then child is
  /// hidden.
  final bool showWhenUnlinked;

  /// The offset to apply to the origin of the linked
  /// [CompositedTransformTarget] to obtain this widget's origin.
  final Offset offset;

  @override
  RenderFollowerLayer createRenderObject(BuildContext context) {
    return RenderFollowerLayer(
      link: link,
      showWhenUnlinked: showWhenUnlinked,
      offset: offset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFollowerLayer renderObject) {
    renderObject
      ..link = link
      ..showWhenUnlinked = showWhenUnlinked
      ..offset = offset;
  }
}

/// Scales and positions its child within itself according to [fit].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=T4Uehk3_wlY}
///
/// See also:
///
///  * [Transform], which applies an arbitrary transform to its child widget at
///    paint time.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class FittedBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that scales and positions its child within itself according to [fit].
  ///
  /// The [fit] and [alignment] arguments must not be null.
  const FittedBox({
    Key key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    Widget child,
  }) : assert(fit != null),
       assert(alignment != null),
       super(key: key, child: child);

  /// How to inscribe the child into the space allocated during layout.
  final BoxFit fit;

  /// How to align the child within its parent's bounds.
  ///
  /// An alignment of (-1.0, -1.0) aligns the child to the top-left corner of its
  /// parent's bounds. An alignment of (1.0, 0.0) aligns the child to the middle
  /// of the right edge of its parent's bounds.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  @override
  RenderFittedBox createRenderObject(BuildContext context) {
    return RenderFittedBox(
      fit: fit,
      alignment: alignment,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFittedBox renderObject) {
    renderObject
      ..fit = fit
      ..alignment = alignment
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<BoxFit>('fit', fit));
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
  }
}

/// Applies a translation transformation before painting its child.
///
/// The translation is expressed as a [Offset] scaled to the child's size. For
/// example, an [Offset] with a `dx` of 0.25 will result in a horizontal
/// translation of one quarter the width of the child.
///
/// Hit tests will only be detected inside the bounds of the
/// [FractionalTranslation], even if the contents are offset such that
/// they overflow.
///
/// See also:
///
///  * [Transform], which applies an arbitrary transform to its child widget at
///    paint time.
///  * [new Transform.translate], which applies an absolute offset translation
///    transformation instead of an offset scaled to the child.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class FractionalTranslation extends SingleChildRenderObjectWidget {
  /// Creates a widget that translates its child's painting.
  ///
  /// The [translation] argument must not be null.
  const FractionalTranslation({
    Key key,
    @required this.translation,
    this.transformHitTests = true,
    Widget child,
  }) : assert(translation != null),
       super(key: key, child: child);

  /// The translation to apply to the child, scaled to the child's size.
  ///
  /// For example, an [Offset] with a `dx` of 0.25 will result in a horizontal
  /// translation of one quarter the width of the child.
  final Offset translation;

  /// Whether to apply the translation when performing hit tests.
  final bool transformHitTests;

  @override
  RenderFractionalTranslation createRenderObject(BuildContext context) {
    return RenderFractionalTranslation(
      translation: translation,
      transformHitTests: transformHitTests,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFractionalTranslation renderObject) {
    renderObject
      ..translation = translation
      ..transformHitTests = transformHitTests;
  }
}

/// A widget that rotates its child by a integral number of quarter turns.
///
/// Unlike [Transform], which applies a transform just prior to painting,
/// this object applies its rotation prior to layout, which means the entire
/// rotated box consumes only as much space as required by the rotated child.
///
/// {@tool sample}
///
/// This snippet rotates the child (some [Text]) so that it renders from bottom
/// to top, like an axis label on a graph:
///
/// ```dart
/// RotatedBox(
///   quarterTurns: 3,
///   child: const Text('Hello World!'),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Transform], which is a paint effect that allows you to apply an
///    arbitrary transform to a child.
///  * [new Transform.rotate], which applies a rotation paint effect.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class RotatedBox extends SingleChildRenderObjectWidget {
  /// A widget that rotates its child.
  ///
  /// The [quarterTurns] argument must not be null.
  const RotatedBox({
    Key key,
    @required this.quarterTurns,
    Widget child,
  }) : assert(quarterTurns != null),
       super(key: key, child: child);

  /// The number of clockwise quarter turns the child should be rotated.
  final int quarterTurns;

  @override
  RenderRotatedBox createRenderObject(BuildContext context) => RenderRotatedBox(quarterTurns: quarterTurns);

  @override
  void updateRenderObject(BuildContext context, RenderRotatedBox renderObject) {
    renderObject.quarterTurns = quarterTurns;
  }
}

/// A widget that insets its child by the given padding.
///
/// When passing layout constraints to its child, padding shrinks the
/// constraints by the given padding, causing the child to layout at a smaller
/// size. Padding then sizes itself to its child's size, inflated by the
/// padding, effectively creating empty space around the child.
///
/// {@tool sample}
///
/// This snippet indents the child (a [Card] with some [Text]) by eight pixels
/// in each direction:
///
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(8.0),
///   child: const Card(child: Text('Hello World!')),
/// )
/// ```
/// {@end-tool}
///
/// ## Design discussion
///
/// ### Why use a [Padding] widget rather than a [Container] with a [Container.padding] property?
///
/// There isn't really any difference between the two. If you supply a
/// [Container.padding] argument, [Container] simply builds a [Padding] widget
/// for you.
///
/// [Container] doesn't implement its properties directly. Instead, [Container]
/// combines a number of simpler widgets together into a convenient package. For
/// example, the [Container.padding] property causes the container to build a
/// [Padding] widget and the [Container.decoration] property causes the
/// container to build a [DecoratedBox] widget. If you find [Container]
/// convenient, feel free to use it. If not, feel free to build these simpler
/// widgets in whatever combination meets your needs.
///
/// In fact, the majority of widgets in Flutter are simply combinations of other
/// simpler widgets. Composition, rather than inheritance, is the primary
/// mechanism for building up widgets.
///
/// See also:
///
///  * [AnimatedPadding], which animates changes in [padding] over a given
///    duration.
///  * [EdgeInsets], the class that is used to describe the padding dimensions.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Padding extends SingleChildRenderObjectWidget {
  /// Creates a widget that insets its child.
  ///
  /// The [padding] argument must not be null.
  const Padding({
    Key key,
    @required this.padding,
    Widget child,
  }) : assert(padding != null),
       super(key: key, child: child);

  /// The amount of space by which to inset the child.
  final EdgeInsetsGeometry padding;

  @override
  RenderPadding createRenderObject(BuildContext context) {
    return RenderPadding(
      padding: padding,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPadding renderObject) {
    renderObject
      ..padding = padding
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}

/// A widget that aligns its child within itself and optionally sizes itself
/// based on the child's size.
///
/// For example, to align a box at the bottom right, you would pass this box a
/// tight constraint that is bigger than the child's natural size,
/// with an alignment of [Alignment.bottomRight].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=g2E7yl3MwMk}
///
/// This widget will be as big as possible if its dimensions are constrained and
/// [widthFactor] and [heightFactor] are null. If a dimension is unconstrained
/// and the corresponding size factor is null then the widget will match its
/// child's size in that dimension. If a size factor is non-null then the
/// corresponding dimension of this widget will be the product of the child's
/// dimension and the size factor. For example if widthFactor is 2.0 then
/// the width of this widget will always be twice its child's width.
///
/// ## How it works
///
/// The [alignment] property describes a point in the `child`'s coordinate system
/// and a different point in the coordinate system of this widget. The [Align]
/// widget positions the `child` such that both points are lined up on top of
/// each other.
///
/// {@tool sample}
/// The [Align] widget in this example uses one of the defined constants from
/// [Alignment], [topRight]. This places the [FlutterLogo] in the top right corner
/// of the parent blue [Container].
///
/// ![A blue square container with the Flutter logo in the top right corner.](https://flutter.github.io/assets-for-api-docs/assets/widgets/align_constant.png)
///
/// ```dart
/// Center(
///   child: Container(
///     height: 120.0,
///     width: 120.0,
///     color: Colors.blue[50],
///     child: Align(
///       alignment: Alignment.topRight,
///       child: FlutterLogo(
///         size: 60,
///       ),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// {@tool sample}
/// The [Alignment] used in the following example defines a single point:
///
///   * (0.2 * width of [FlutterLogo]/2 + width of [FlutterLogo]/2, 0.6 * height
///   of [FlutterLogo]/2 + height of [FlutterLogo]/2) = (36.0, 48.0).
///
/// The [Alignment] class uses a coordinate system with an origin in the center
/// of the [Container], as shown with the [Icon] above. [Align] will place the
/// [FlutterLogo] at (36.0, 48.0) according to this coordinate system.
///
/// ![A blue square container with the Flutter logo positioned according to the
/// Alignment specified above. A point is marked at the center of the container
/// for the origin of the Alignment coordinate system.](https://flutter.github.io/assets-for-api-docs/assets/widgets/align_alignment.png)
///
/// ```dart
/// Center(
///   child: Container(
///     height: 120.0,
///     width: 120.0,
///     color: Colors.blue[50],
///     child: Align(
///       alignment: Alignment(0.2, 0.6),
///       child: FlutterLogo(
///         size: 60,
///       ),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// {@tool sample}
/// The [FractionalOffset] used in the following example defines two points:
///
///   * (0.2 * width of [FlutterLogo], 0.6 * height of [FlutterLogo]) = (12.0, 36.0)
///     in the coordinate system of the blue container.
///   * (0.2 * width of [Align], 0.6 * height of [Align]) = (24.0, 72.0) in the
///     coordinate system of the [Align] widget.
///
/// The [Align] widget positions the [FlutterLogo] such that the two points are on
/// top of each other. In this example, the top left of the [FlutterLogo] will
/// be placed at (24.0, 72.0) - (12.0, 36.0) = (12.0, 36.0) from the top left of
/// the [Align] widget.
///
/// The [FractionalOffset] class uses a coordinate system with an origin in the top-left
/// corner of the [Container] in difference to the center-oriented system used in
/// the example above with [Alignment].
///
/// ![A blue square container with the Flutter logo positioned according to the
/// FractionalOffset specified above. A point is marked at the top left corner
/// of the container for the origin of the FractionalOffset coordinate system.](https://flutter.github.io/assets-for-api-docs/assets/widgets/align_fractional_offset.png)
///
/// ```dart
/// Center(
///   child: Container(
///     height: 120.0,
///     width: 120.0,
///     color: Colors.blue[50],
///     child: Align(
///       alignment: FractionalOffset(0.2, 0.6),
///       child: FlutterLogo(
///         size: 60,
///       ),
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [AnimatedAlign], which animates changes in [alignment] smoothly over a
///    given duration.
///  * [CustomSingleChildLayout], which uses a delegate to control the layout of
///    a single child.
///  * [Center], which is the same as [Align] but with the [alignment] always
///    set to [Alignment.center].
///  * [FractionallySizedBox], which sizes its child based on a fraction of its
///    own size and positions the child according to an [Alignment] value.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Align extends SingleChildRenderObjectWidget {
  /// Creates an alignment widget.
  ///
  /// The alignment defaults to [Alignment.center].
  const Align({
    Key key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    Widget child,
  }) : assert(alignment != null),
       assert(widthFactor == null || widthFactor >= 0.0),
       assert(heightFactor == null || heightFactor >= 0.0),
       super(key: key, child: child);

  /// How to align the child.
  ///
  /// The x and y values of the [Alignment] control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// See also:
  ///
  ///  * [Alignment], which has more details and some convenience constants for
  ///    common positions.
  ///  * [AlignmentDirectional], which has a horizontal coordinate orientation
  ///    that depends on the [TextDirection].
  final AlignmentGeometry alignment;

  /// If non-null, sets its width to the child's width multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  final double widthFactor;

  /// If non-null, sets its height to the child's height multiplied by this factor.
  ///
  /// Can be both greater and less than 1.0 but must be positive.
  final double heightFactor;

  @override
  RenderPositionedBox createRenderObject(BuildContext context) {
    return RenderPositionedBox(
      alignment: alignment,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPositionedBox renderObject) {
    renderObject
      ..alignment = alignment
      ..widthFactor = widthFactor
      ..heightFactor = heightFactor
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(DoubleProperty('widthFactor', widthFactor, defaultValue: null));
    properties.add(DoubleProperty('heightFactor', heightFactor, defaultValue: null));
  }
}

/// A widget that centers its child within itself.
///
/// This widget will be as big as possible if its dimensions are constrained and
/// [widthFactor] and [heightFactor] are null. If a dimension is unconstrained
/// and the corresponding size factor is null then the widget will match its
/// child's size in that dimension. If a size factor is non-null then the
/// corresponding dimension of this widget will be the product of the child's
/// dimension and the size factor. For example if widthFactor is 2.0 then
/// the width of this widget will always be twice its child's width.
///
/// See also:
///
///  * [Align], which lets you arbitrarily position a child within itself,
///    rather than just centering it.
///  * [Row], a widget that displays its children in a horizontal array.
///  * [Column], a widget that displays its children in a vertical array.
///  * [Container], a convenience widget that combines common painting,
///    positioning, and sizing widgets.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Center extends Align {
  /// Creates a widget that centers its child.
  const Center({ Key key, double widthFactor, double heightFactor, Widget child })
    : super(key: key, widthFactor: widthFactor, heightFactor: heightFactor, child: child);
}

/// A widget that defers the layout of its single child to a delegate.
///
/// The delegate can determine the layout constraints for the child and can
/// decide where to position the child. The delegate can also determine the size
/// of the parent, but the size of the parent cannot depend on the size of the
/// child.
///
/// See also:
///
///  * [SingleChildLayoutDelegate], which controls the layout of the child.
///  * [Align], which sizes itself based on its child's size and positions
///    the child according to an [Alignment] value.
///  * [FractionallySizedBox], which sizes its child based on a fraction of its own
///    size and positions the child according to an [Alignment] value.
///  * [CustomMultiChildLayout], which uses a delegate to position multiple
///    children.
class CustomSingleChildLayout extends SingleChildRenderObjectWidget {
  /// Creates a custom single child layout.
  ///
  /// The [delegate] argument must not be null.
  const CustomSingleChildLayout({
    Key key,
    @required this.delegate,
    Widget child,
  }) : assert(delegate != null),
       super(key: key, child: child);

  /// The delegate that controls the layout of the child.
  final SingleChildLayoutDelegate delegate;

  @override
  RenderCustomSingleChildLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomSingleChildLayoutBox(delegate: delegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderCustomSingleChildLayoutBox renderObject) {
    renderObject.delegate = delegate;
  }
}

/// Metadata for identifying children in a [CustomMultiChildLayout].
///
/// The [MultiChildLayoutDelegate.hasChild],
/// [MultiChildLayoutDelegate.layoutChild], and
/// [MultiChildLayoutDelegate.positionChild] methods use these identifiers.
class LayoutId extends ParentDataWidget<CustomMultiChildLayout> {
  /// Marks a child with a layout identifier.
  ///
  /// Both the child and the id arguments must not be null.
  LayoutId({
    Key key,
    @required this.id,
    @required Widget child,
  }) : assert(child != null),
       assert(id != null),
       super(key: key ?? ValueKey<Object>(id), child: child);

  /// An object representing the identity of this child.
  ///
  /// The [id] needs to be unique among the children that the
  /// [CustomMultiChildLayout] manages.
  final Object id;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is MultiChildLayoutParentData);
    final MultiChildLayoutParentData parentData = renderObject.parentData;
    if (parentData.id != id) {
      parentData.id = id;
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject)
        targetParent.markNeedsLayout();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('id', id));
  }
}

/// A widget that uses a delegate to size and position multiple children.
///
/// The delegate can determine the layout constraints for each child and can
/// decide where to position each child. The delegate can also determine the
/// size of the parent, but the size of the parent cannot depend on the sizes of
/// the children.
///
/// [CustomMultiChildLayout] is appropriate when there are complex relationships
/// between the size and positioning of a multiple widgets. To control the
/// layout of a single child, [CustomSingleChildLayout] is more appropriate. For
/// simple cases, such as aligning a widget to one or another edge, the [Stack]
/// widget is more appropriate.
///
/// Each child must be wrapped in a [LayoutId] widget to identify the widget for
/// the delegate.
///
/// See also:
///
///  * [MultiChildLayoutDelegate], for details about how to control the layout of
///    the children.
///  * [CustomSingleChildLayout], which uses a delegate to control the layout of
///    a single child.
///  * [Stack], which arranges children relative to the edges of the container.
///  * [Flow], which provides paint-time control of its children using transform
///    matrices.
class CustomMultiChildLayout extends MultiChildRenderObjectWidget {
  /// Creates a custom multi-child layout.
  ///
  /// The [delegate] argument must not be null.
  CustomMultiChildLayout({
    Key key,
    @required this.delegate,
    List<Widget> children = const <Widget>[],
  }) : assert(delegate != null),
       super(key: key, children: children);

  /// The delegate that controls the layout of the children.
  final MultiChildLayoutDelegate delegate;

  @override
  RenderCustomMultiChildLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomMultiChildLayoutBox(delegate: delegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderCustomMultiChildLayoutBox renderObject) {
    renderObject.delegate = delegate;
  }
}

/// A box with a specified size.
///
/// If given a child, this widget forces its child to have a specific width
/// and/or height (assuming values are permitted by this widget's parent). If
/// either the width or height is null, this widget will size itself to match
/// the child's size in that dimension.
///
/// If not given a child, [SizedBox] will try to size itself as close to the
/// specified height and width as possible given the parent's constraints. If
/// [height] or [width] is null or unspecified, it will be treated as zero.
///
/// The [new SizedBox.expand] constructor can be used to make a [SizedBox] that
/// sizes itself to fit the parent. It is equivalent to setting [width] and
/// [height] to [double.infinity].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=EHPu_DzRfqA}
///
/// {@tool sample}
///
/// This snippet makes the child widget (a [Card] with some [Text]) have the
/// exact size 200x300, parental constraints permitting:
///
/// ```dart
/// SizedBox(
///   width: 200.0,
///   height: 300.0,
///   child: const Card(child: Text('Hello World!')),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [ConstrainedBox], a more generic version of this class that takes
///    arbitrary [BoxConstraints] instead of an explicit width and height.
///  * [UnconstrainedBox], a container that tries to let its child draw without
///    constraints.
///  * [FractionallySizedBox], a widget that sizes its child to a fraction of
///    the total available space.
///  * [AspectRatio], a widget that attempts to fit within the parent's
///    constraints while also sizing its child to match a given aspect ratio.
///  * [FittedBox], which sizes and positions its child widget to fit the parent
///    according to a given [BoxFit] discipline.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class SizedBox extends SingleChildRenderObjectWidget {
  /// Creates a fixed size box. The [width] and [height] parameters can be null
  /// to indicate that the size of the box should not be constrained in
  /// the corresponding dimension.
  const SizedBox({ Key key, this.width, this.height, Widget child })
    : super(key: key, child: child);

  /// Creates a box that will become as large as its parent allows.
  const SizedBox.expand({ Key key, Widget child })
    : width = double.infinity,
      height = double.infinity,
      super(key: key, child: child);

  /// Creates a box that will become as small as its parent allows.
  const SizedBox.shrink({ Key key, Widget child })
    : width = 0.0,
      height = 0.0,
      super(key: key, child: child);

  /// Creates a box with the specified size.
  SizedBox.fromSize({ Key key, Widget child, Size size })
    : width = size?.width,
      height = size?.height,
      super(key: key, child: child);

  /// If non-null, requires the child to have exactly this width.
  final double width;

  /// If non-null, requires the child to have exactly this height.
  final double height;

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(
      additionalConstraints: _additionalConstraints,
    );
  }

  BoxConstraints get _additionalConstraints {
    return BoxConstraints.tightFor(width: width, height: height);
  }

  @override
  void updateRenderObject(BuildContext context, RenderConstrainedBox renderObject) {
    renderObject.additionalConstraints = _additionalConstraints;
  }

  @override
  String toStringShort() {
    String type;
    if (width == double.infinity && height == double.infinity) {
      type = '$runtimeType.expand';
    } else if (width == 0.0 && height == 0.0) {
      type = '$runtimeType.shrink';
    } else {
      type = '$runtimeType';
    }
    return key == null ? '$type' : '$type-$key';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    DiagnosticLevel level;
    if ((width == double.infinity && height == double.infinity) ||
        (width == 0.0 && height == 0.0)) {
      level = DiagnosticLevel.hidden;
    } else {
      level = DiagnosticLevel.info;
    }
    properties.add(DoubleProperty('width', width, defaultValue: null, level: level));
    properties.add(DoubleProperty('height', height, defaultValue: null, level: level));
  }
}

/// A widget that imposes additional constraints on its child.
///
/// For example, if you wanted [child] to have a minimum height of 50.0 logical
/// pixels, you could use `const BoxConstraints(minHeight: 50.0)` as the
/// [constraints].
///
/// {@tool sample}
///
/// This snippet makes the child widget (a [Card] with some [Text]) fill the
/// parent, by applying [BoxConstraints.expand] constraints:
///
/// ```dart
/// ConstrainedBox(
///   constraints: const BoxConstraints.expand(),
///   child: const Card(child: Text('Hello World!')),
/// )
/// ```
/// {@end-tool}
///
/// The same behavior can be obtained using the [new SizedBox.expand] widget.
///
/// See also:
///
///  * [BoxConstraints], the class that describes constraints.
///  * [UnconstrainedBox], a container that tries to let its child draw without
///    constraints.
///  * [SizedBox], which lets you specify tight constraints by explicitly
///    specifying the height or width.
///  * [FractionallySizedBox], which sizes its child based on a fraction of its
///    own size and positions the child according to an [Alignment] value.
///  * [AspectRatio], a widget that attempts to fit within the parent's
///    constraints while also sizing its child to match a given aspect ratio.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class ConstrainedBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that imposes additional constraints on its child.
  ///
  /// The [constraints] argument must not be null.
  ConstrainedBox({
    Key key,
    @required this.constraints,
    Widget child,
  }) : assert(constraints != null),
       assert(constraints.debugAssertIsValid()),
       super(key: key, child: child);

  /// The additional constraints to impose on the child.
  final BoxConstraints constraints;

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(additionalConstraints: constraints);
  }

  @override
  void updateRenderObject(BuildContext context, RenderConstrainedBox renderObject) {
    renderObject.additionalConstraints = constraints;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BoxConstraints>('constraints', constraints, showName: false));
  }
}

/// A widget that imposes no constraints on its child, allowing it to render
/// at its "natural" size.
///
/// This allows a child to render at the size it would render if it were alone
/// on an infinite canvas with no constraints. This container will then attempt
/// to adopt the same size, within the limits of its own constraints. If it ends
/// up with a different size, it will align the child based on [alignment].
/// If the box cannot expand enough to accommodate the entire child, the
/// child will be clipped.
///
/// In debug mode, if the child overflows the container, a warning will be
/// printed on the console, and black and yellow striped areas will appear where
/// the overflow occurs.
///
/// See also:
///
///  * [ConstrainedBox], for a box which imposes constraints on its child.
///  * [Align], which loosens the constraints given to the child rather than
///    removing them entirely.
///  * [Container], a convenience widget that combines common painting,
///    positioning, and sizing widgets.
///  * [OverflowBox], a widget that imposes different constraints on its child
///    than it gets from its parent, possibly allowing the child to overflow
///    the parent.
class UnconstrainedBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that imposes no constraints on its child, allowing it to
  /// render at its "natural" size. If the child overflows the parents
  /// constraints, a warning will be given in debug mode.
  const UnconstrainedBox({
    Key key,
    Widget child,
    this.textDirection,
    this.alignment = Alignment.center,
    this.constrainedAxis,
  }) : assert(alignment != null),
       super(key: key, child: child);

  /// The text direction to use when interpreting the [alignment] if it is an
  /// [AlignmentDirectional].
  final TextDirection textDirection;

  /// The alignment to use when laying out the child.
  ///
  /// If this is an [AlignmentDirectional], then [textDirection] must not be
  /// null.
  ///
  /// See also:
  ///
  ///  * [Alignment] for non-[Directionality]-aware alignments.
  ///  * [AlignmentDirectional] for [Directionality]-aware alignments.
  final AlignmentGeometry alignment;

  /// The axis to retain constraints on, if any.
  ///
  /// If not set, or set to null (the default), neither axis will retain its
  /// constraints. If set to [Axis.vertical], then vertical constraints will
  /// be retained, and if set to [Axis.horizontal], then horizontal constraints
  /// will be retained.
  final Axis constrainedAxis;

  @override
  void updateRenderObject(BuildContext context, covariant RenderUnconstrainedBox renderObject) {
    renderObject
      ..textDirection = textDirection ?? Directionality.of(context)
      ..alignment = alignment
      ..constrainedAxis = constrainedAxis;
  }

  @override
  RenderUnconstrainedBox createRenderObject(BuildContext context) => RenderUnconstrainedBox(
    textDirection: textDirection ?? Directionality.of(context),
    alignment: alignment,
    constrainedAxis: constrainedAxis,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<Axis>('constrainedAxis', constrainedAxis, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
  }
}

/// A widget that sizes its child to a fraction of the total available space.
/// For more details about the layout algorithm, see
/// [RenderFractionallySizedOverflowBox].
///
/// See also:
///
///  * [Align], which sizes itself based on its child's size and positions
///    the child according to an [Alignment] value.
///  * [OverflowBox], a widget that imposes different constraints on its child
///    than it gets from its parent, possibly allowing the child to overflow the
///    parent.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class FractionallySizedBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that sizes its child to a fraction of the total available space.
  ///
  /// If non-null, the [widthFactor] and [heightFactor] arguments must be
  /// non-negative.
  const FractionallySizedBox({
    Key key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    Widget child,
  }) : assert(alignment != null),
       assert(widthFactor == null || widthFactor >= 0.0),
       assert(heightFactor == null || heightFactor >= 0.0),
       super(key: key, child: child);

  /// If non-null, the fraction of the incoming width given to the child.
  ///
  /// If non-null, the child is given a tight width constraint that is the max
  /// incoming width constraint multiplied by this factor.
  ///
  /// If null, the incoming width constraints are passed to the child
  /// unmodified.
  final double widthFactor;

  /// If non-null, the fraction of the incoming height given to the child.
  ///
  /// If non-null, the child is given a tight height constraint that is the max
  /// incoming height constraint multiplied by this factor.
  ///
  /// If null, the incoming height constraints are passed to the child
  /// unmodified.
  final double heightFactor;

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  @override
  RenderFractionallySizedOverflowBox createRenderObject(BuildContext context) {
    return RenderFractionallySizedOverflowBox(
      alignment: alignment,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFractionallySizedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..widthFactor = widthFactor
      ..heightFactor = heightFactor
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(DoubleProperty('widthFactor', widthFactor, defaultValue: null));
    properties.add(DoubleProperty('heightFactor', heightFactor, defaultValue: null));
  }
}

/// A box that limits its size only when it's unconstrained.
///
/// If this widget's maximum width is unconstrained then its child's width is
/// limited to [maxWidth]. Similarly, if this widget's maximum height is
/// unconstrained then its child's height is limited to [maxHeight].
///
/// This has the effect of giving the child a natural dimension in unbounded
/// environments. For example, by providing a [maxHeight] to a widget that
/// normally tries to be as big as possible, the widget will normally size
/// itself to fit its parent, but when placed in a vertical list, it will take
/// on the given height.
///
/// This is useful when composing widgets that normally try to match their
/// parents' size, so that they behave reasonably in lists (which are
/// unbounded).
///
/// See also:
///
///  * [ConstrainedBox], which applies its constraints in all cases, not just
///    when the incoming constraints are unbounded.
///  * [SizedBox], which lets you specify tight constraints by explicitly
///    specifying the height or width.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class LimitedBox extends SingleChildRenderObjectWidget {
  /// Creates a box that limits its size only when it's unconstrained.
  ///
  /// The [maxWidth] and [maxHeight] arguments must not be null and must not be
  /// negative.
  const LimitedBox({
    Key key,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
    Widget child,
  }) : assert(maxWidth != null && maxWidth >= 0.0),
       assert(maxHeight != null && maxHeight >= 0.0),
       super(key: key, child: child);

  /// The maximum width limit to apply in the absence of a
  /// [BoxConstraints.maxWidth] constraint.
  final double maxWidth;

  /// The maximum height limit to apply in the absence of a
  /// [BoxConstraints.maxHeight] constraint.
  final double maxHeight;

  @override
  RenderLimitedBox createRenderObject(BuildContext context) {
    return RenderLimitedBox(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderLimitedBox renderObject) {
    renderObject
      ..maxWidth = maxWidth
      ..maxHeight = maxHeight;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('maxWidth', maxWidth, defaultValue: double.infinity));
    properties.add(DoubleProperty('maxHeight', maxHeight, defaultValue: double.infinity));
  }
}

/// A widget that imposes different constraints on its child than it gets
/// from its parent, possibly allowing the child to overflow the parent.
///
/// See also:
///
///  * [RenderConstrainedOverflowBox] for details about how [OverflowBox] is
///    rendered.
///  * [SizedOverflowBox], a widget that is a specific size but passes its
///    original constraints through to its child, which may then overflow.
///  * [ConstrainedBox], a widget that imposes additional constraints on its
///    child.
///  * [UnconstrainedBox], a container that tries to let its child draw without
///    constraints.
///  * [SizedBox], a box with a specified size.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class OverflowBox extends SingleChildRenderObjectWidget {
  /// Creates a widget that lets its child overflow itself.
  const OverflowBox({
    Key key,
    this.alignment = Alignment.center,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    Widget child,
  }) : super(key: key, child: child);

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The minimum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double minWidth;

  /// The maximum width constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double maxWidth;

  /// The minimum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double minHeight;

  /// The maximum height constraint to give the child. Set this to null (the
  /// default) to use the constraint from the parent instead.
  final double maxHeight;

  @override
  RenderConstrainedOverflowBox createRenderObject(BuildContext context) {
    return RenderConstrainedOverflowBox(
      alignment: alignment,
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderConstrainedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..minWidth = minWidth
      ..maxWidth = maxWidth
      ..minHeight = minHeight
      ..maxHeight = maxHeight
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(DoubleProperty('minWidth', minWidth, defaultValue: null));
    properties.add(DoubleProperty('maxWidth', maxWidth, defaultValue: null));
    properties.add(DoubleProperty('minHeight', minHeight, defaultValue: null));
    properties.add(DoubleProperty('maxHeight', maxHeight, defaultValue: null));
  }
}

/// A widget that is a specific size but passes its original constraints
/// through to its child, which may then overflow.
///
/// See also:
///
///  * [OverflowBox], A widget that imposes different constraints on its child
///    than it gets from its parent, possibly allowing the child to overflow the
///    parent.
///  * [ConstrainedBox], a widget that imposes additional constraints on its
///    child.
///  * [UnconstrainedBox], a container that tries to let its child draw without
///    constraints.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class SizedOverflowBox extends SingleChildRenderObjectWidget {
  /// Creates a widget of a given size that lets its child overflow.
  ///
  /// The [size] argument must not be null.
  const SizedOverflowBox({
    Key key,
    @required this.size,
    this.alignment = Alignment.center,
    Widget child,
  }) : assert(size != null),
       assert(alignment != null),
       super(key: key, child: child);

  /// How to align the child.
  ///
  /// The x and y values of the alignment control the horizontal and vertical
  /// alignment, respectively. An x value of -1.0 means that the left edge of
  /// the child is aligned with the left edge of the parent whereas an x value
  /// of 1.0 means that the right edge of the child is aligned with the right
  /// edge of the parent. Other values interpolate (and extrapolate) linearly.
  /// For example, a value of 0.0 means that the center of the child is aligned
  /// with the center of the parent.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The size this widget should attempt to be.
  final Size size;

  @override
  RenderSizedOverflowBox createRenderObject(BuildContext context) {
    return RenderSizedOverflowBox(
      alignment: alignment,
      requestedSize: size,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSizedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..requestedSize = size
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(DiagnosticsProperty<Size>('size', size, defaultValue: null));
  }
}

/// A widget that lays the child out as if it was in the tree, but without
/// painting anything, without making the child available for hit testing, and
/// without taking any room in the parent.
///
/// Animations continue to run in offstage children, and therefore use battery
/// and CPU time, regardless of whether the animations end up being visible.
///
/// [Offstage] can be used to measure the dimensions of a widget without
/// bringing it on screen (yet). To hide a widget from view while it is not
/// needed, prefer removing the widget from the tree entirely rather than
/// keeping it alive in an [Offstage] subtree.
///
/// See also:
///
///  * [Visibility], which can hide a child more efficiently (albeit less
///    subtly).
///  * [TickerMode], which can be used to disable animations in a subtree.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Offstage extends SingleChildRenderObjectWidget {
  /// Creates a widget that visually hides its child.
  const Offstage({ Key key, this.offstage = true, Widget child })
    : assert(offstage != null),
      super(key: key, child: child);

  /// Whether the child is hidden from the rest of the tree.
  ///
  /// If true, the child is laid out as if it was in the tree, but without
  /// painting anything, without making the child available for hit testing, and
  /// without taking any room in the parent.
  ///
  /// If false, the child is included in the tree as normal.
  final bool offstage;

  @override
  RenderOffstage createRenderObject(BuildContext context) => RenderOffstage(offstage: offstage);

  @override
  void updateRenderObject(BuildContext context, RenderOffstage renderObject) {
    renderObject.offstage = offstage;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('offstage', offstage));
  }

  @override
  _OffstageElement createElement() => _OffstageElement(this);
}

class _OffstageElement extends SingleChildRenderObjectElement {
  _OffstageElement(Offstage widget) : super(widget);

  @override
  Offstage get widget => super.widget;

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    if (!widget.offstage)
      super.debugVisitOnstageChildren(visitor);
  }
}

/// A widget that attempts to size the child to a specific aspect ratio.
///
/// The widget first tries the largest width permitted by the layout
/// constraints. The height of the widget is determined by applying the
/// given aspect ratio to the width, expressed as a ratio of width to height.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=XcnP3_mO_Ms}
///
/// For example, a 16:9 width:height aspect ratio would have a value of
/// 16.0/9.0. If the maximum width is infinite, the initial width is determined
/// by applying the aspect ratio to the maximum height.
///
/// Now consider a second example, this time with an aspect ratio of 2.0 and
/// layout constraints that require the width to be between 0.0 and 100.0 and
/// the height to be between 0.0 and 100.0. We'll select a width of 100.0 (the
/// biggest allowed) and a height of 50.0 (to match the aspect ratio).
///
/// In that same situation, if the aspect ratio is 0.5, we'll also select a
/// width of 100.0 (still the biggest allowed) and we'll attempt to use a height
/// of 200.0. Unfortunately, that violates the constraints because the child can
/// be at most 100.0 pixels tall. The widget will then take that value
/// and apply the aspect ratio again to obtain a width of 50.0. That width is
/// permitted by the constraints and the child receives a width of 50.0 and a
/// height of 100.0. If the width were not permitted, the widget would
/// continue iterating through the constraints. If the widget does not
/// find a feasible size after consulting each constraint, the widget
/// will eventually select a size for the child that meets the layout
/// constraints but fails to meet the aspect ratio constraints.
///
/// See also:
///
///  * [Align], a widget that aligns its child within itself and optionally
///    sizes itself based on the child's size.
///  * [ConstrainedBox], a widget that imposes additional constraints on its
///    child.
///  * [UnconstrainedBox], a container that tries to let its child draw without
///    constraints.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class AspectRatio extends SingleChildRenderObjectWidget {
  /// Creates a widget with a specific aspect ratio.
  ///
  /// The [aspectRatio] argument must not be null.
  const AspectRatio({
    Key key,
    @required this.aspectRatio,
    Widget child,
  }) : assert(aspectRatio != null),
       super(key: key, child: child);

  /// The aspect ratio to attempt to use.
  ///
  /// The aspect ratio is expressed as a ratio of width to height. For example,
  /// a 16:9 width:height aspect ratio would have a value of 16.0/9.0.
  final double aspectRatio;

  @override
  RenderAspectRatio createRenderObject(BuildContext context) => RenderAspectRatio(aspectRatio: aspectRatio);

  @override
  void updateRenderObject(BuildContext context, RenderAspectRatio renderObject) {
    renderObject.aspectRatio = aspectRatio;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('aspectRatio', aspectRatio));
  }
}

/// A widget that sizes its child to the child's intrinsic width.
///
/// Sizes its child's width to the child's maximum intrinsic width. If
/// [stepWidth] is non-null, the child's width will be snapped to a multiple of
/// the [stepWidth]. Similarly, if [stepHeight] is non-null, the child's height
/// will be snapped to a multiple of the [stepHeight].
///
/// This class is useful, for example, when unlimited width is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable width.
///
/// This class is relatively expensive, because it adds a speculative layout
/// pass before the final layout phase. Avoid using it where possible. In the
/// worst case, this widget can result in a layout that is O(N²) in the depth of
/// the tree.
///
/// See also:
///
///  * [The catalog of layout widgets](https://flutter.dev/widgets/layout/).
class IntrinsicWidth extends SingleChildRenderObjectWidget {
  /// Creates a widget that sizes its child to the child's intrinsic width.
  ///
  /// This class is relatively expensive. Avoid using it where possible.
  const IntrinsicWidth({ Key key, this.stepWidth, this.stepHeight, Widget child })
    : assert(stepWidth == null || stepWidth >= 0.0),
      assert(stepHeight == null || stepHeight >= 0.0),
      super(key: key, child: child);

  /// If non-null, force the child's width to be a multiple of this value.
  ///
  /// If null or 0.0 the child's width will be the same as its maximum
  /// intrinsic width.
  ///
  /// This value must not be negative.
  ///
  /// See also:
  ///
  ///  * [RenderBox.getMaxIntrinsicWidth], which defines a widget's max
  ///    intrinsic width  in general.
  final double stepWidth;

  /// If non-null, force the child's height to be a multiple of this value.
  ///
  /// If null or 0.0 the child's height will not be constrained.
  ///
  /// This value must not be negative.
  final double stepHeight;

  double get _stepWidth => stepWidth == 0.0 ? null : stepWidth;
  double get _stepHeight => stepHeight == 0.0 ? null : stepHeight;

  @override
  RenderIntrinsicWidth createRenderObject(BuildContext context) {
    return RenderIntrinsicWidth(stepWidth: _stepWidth, stepHeight: _stepHeight);
  }

  @override
  void updateRenderObject(BuildContext context, RenderIntrinsicWidth renderObject) {
    renderObject
      ..stepWidth = _stepWidth
      ..stepHeight = _stepHeight;
  }
}

/// A widget that sizes its child to the child's intrinsic height.
///
/// This class is useful, for example, when unlimited height is available and
/// you would like a child that would otherwise attempt to expand infinitely to
/// instead size itself to a more reasonable height.
///
/// This class is relatively expensive, because it adds a speculative layout
/// pass before the final layout phase. Avoid using it where possible. In the
/// worst case, this widget can result in a layout that is O(N²) in the depth of
/// the tree.
///
/// See also:
///
///  * [The catalog of layout widgets](https://flutter.dev/widgets/layout/).
class IntrinsicHeight extends SingleChildRenderObjectWidget {
  /// Creates a widget that sizes its child to the child's intrinsic height.
  ///
  /// This class is relatively expensive. Avoid using it where possible.
  const IntrinsicHeight({ Key key, Widget child }) : super(key: key, child: child);

  @override
  RenderIntrinsicHeight createRenderObject(BuildContext context) => RenderIntrinsicHeight();
}

/// A widget that positions its child according to the child's baseline.
///
/// This widget shifts the child down such that the child's baseline (or the
/// bottom of the child, if the child has no baseline) is [baseline]
/// logical pixels below the top of this box, then sizes this box to
/// contain the child. If [baseline] is less than the distance from
/// the top of the child to the baseline of the child, then the child
/// is top-aligned instead.
///
/// See also:
///
///  * [Align], a widget that aligns its child within itself and optionally
///    sizes itself based on the child's size.
///  * [Center], a widget that centers its child within itself.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Baseline extends SingleChildRenderObjectWidget {
  /// Creates a widget that positions its child according to the child's baseline.
  ///
  /// The [baseline] and [baselineType] arguments must not be null.
  const Baseline({
    Key key,
    @required this.baseline,
    @required this.baselineType,
    Widget child,
  }) : assert(baseline != null),
       assert(baselineType != null),
       super(key: key, child: child);

  /// The number of logical pixels from the top of this box at which to position
  /// the child's baseline.
  final double baseline;

  /// The type of baseline to use for positioning the child.
  final TextBaseline baselineType;

  @override
  RenderBaseline createRenderObject(BuildContext context) {
    return RenderBaseline(baseline: baseline, baselineType: baselineType);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBaseline renderObject) {
    renderObject
      ..baseline = baseline
      ..baselineType = baselineType;
  }
}


// SLIVERS

/// A sliver that contains a single box widget.
///
/// Slivers are special-purpose widgets that can be combined using a
/// [CustomScrollView] to create custom scroll effects. A [SliverToBoxAdapter]
/// is a basic sliver that creates a bridge back to one of the usual box-based
/// widgets.
///
/// Rather than using multiple [SliverToBoxAdapter] widgets to display multiple
/// box widgets in a [CustomScrollView], consider using [SliverList],
/// [SliverFixedExtentList], [SliverPrototypeExtentList], or [SliverGrid],
/// which are more efficient because they instantiate only those children that
/// are actually visible through the scroll view's viewport.
///
/// See also:
///
///  * [CustomScrollView], which displays a scrollable list of slivers.
///  * [SliverList], which displays multiple box widgets in a linear array.
///  * [SliverFixedExtentList], which displays multiple box widgets with the
///    same main-axis extent in a linear array.
///  * [SliverPrototypeExtentList], which displays multiple box widgets with the
///    same main-axis extent as a prototype item, in a linear array.
///  * [SliverGrid], which displays multiple box widgets in arbitrary positions.
class SliverToBoxAdapter extends SingleChildRenderObjectWidget {
  /// Creates a sliver that contains a single box widget.
  const SliverToBoxAdapter({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  RenderSliverToBoxAdapter createRenderObject(BuildContext context) => RenderSliverToBoxAdapter();
}

/// A sliver that applies padding on each side of another sliver.
///
/// Slivers are special-purpose widgets that can be combined using a
/// [CustomScrollView] to create custom scroll effects. A [SliverPadding]
/// is a basic sliver that insets another sliver by applying padding on each
/// side.
///
/// Applying padding to anything but the most mundane sliver is likely to have
/// undesired effects. For example, wrapping a [SliverPersistentHeader] with
/// `pinned:true` will cause the app bar to overlap earlier slivers (contrary to
/// the normal behavior of pinned app bars), and while the app bar is pinned,
/// the padding will scroll away.
///
/// See also:
///
///  * [CustomScrollView], which displays a scrollable list of slivers.
class SliverPadding extends SingleChildRenderObjectWidget {
  /// Creates a sliver that applies padding on each side of another sliver.
  ///
  /// The [padding] argument must not be null.
  const SliverPadding({
    Key key,
    @required this.padding,
    Widget sliver,
  }) : assert(padding != null),
       super(key: key, child: sliver);

  /// The amount of space by which to inset the child sliver.
  final EdgeInsetsGeometry padding;

  @override
  RenderSliverPadding createRenderObject(BuildContext context) {
    return RenderSliverPadding(
      padding: padding,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverPadding renderObject) {
    renderObject
      ..padding = padding
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}


// LAYOUT NODES

/// Returns the [AxisDirection] in the given [Axis] in the current
/// [Directionality] (or the reverse if `reverse` is true).
///
/// If `axis` is [Axis.vertical], this function returns [AxisDirection.down]
/// unless `reverse` is true, in which case this function returns
/// [AxisDirection.up].
///
/// If `axis` is [Axis.horizontal], this function checks the current
/// [Directionality]. If the current [Directionality] is right-to-left, then
/// this function returns [AxisDirection.left] (unless `reverse` is true, in
/// which case it returns [AxisDirection.right]). Similarly, if the current
/// [Directionality] is left-to-right, then this function returns
/// [AxisDirection.right] (unless `reverse` is true, in which case it returns
/// [AxisDirection.left]).
///
/// This function is used by a number of scrolling widgets (e.g., [ListView],
/// [GridView], [PageView], and [SingleChildScrollView]) as well as [ListBody]
/// to translate their [Axis] and `reverse` properties into a concrete
/// [AxisDirection].
AxisDirection getAxisDirectionFromAxisReverseAndDirectionality(
  BuildContext context,
  Axis axis,
  bool reverse,
) {
  switch (axis) {
    case Axis.horizontal:
      assert(debugCheckHasDirectionality(context));
      final TextDirection textDirection = Directionality.of(context);
      final AxisDirection axisDirection = textDirectionToAxisDirection(textDirection);
      return reverse ? flipAxisDirection(axisDirection) : axisDirection;
    case Axis.vertical:
      return reverse ? AxisDirection.up : AxisDirection.down;
  }
  return null;
}

/// A widget that arranges its children sequentially along a given axis, forcing
/// them to the dimension of the parent in the other axis.
///
/// This widget is rarely used directly. Instead, consider using [ListView],
/// which combines a similar layout algorithm with scrolling behavior, or
/// [Column], which gives you more flexible control over the layout of a
/// vertical set of boxes.
///
/// See also:
///
///  * [RenderListBody], which implements this layout algorithm and the
///    documentation for which describes some of its subtleties.
///  * [SingleChildScrollView], which is sometimes used with [ListBody] to
///    make the contents scrollable.
///  * [Column] and [Row], which implement a more elaborate version of
///    this layout algorithm (at the cost of being slightly less efficient).
///  * [ListView], which implements an efficient scrolling version of this
///    layout algorithm.
class ListBody extends MultiChildRenderObjectWidget {
  /// Creates a layout widget that arranges its children sequentially along a
  /// given axis.
  ///
  /// By default, the [mainAxis] is [Axis.vertical].
  ListBody({
    Key key,
    this.mainAxis = Axis.vertical,
    this.reverse = false,
    List<Widget> children = const <Widget>[],
  }) : assert(mainAxis != null),
       super(key: key, children: children);

  /// The direction to use as the main axis.
  final Axis mainAxis;

  /// Whether the list body positions children in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right and
  /// [mainAxis] is [Axis.horizontal], then the list body positions children
  /// from left to right when [reverse] is false and from right to left when
  /// [reverse] is true.
  ///
  /// Similarly, if [mainAxis] is [Axis.vertical], then the list body positions
  /// from top to bottom when [reverse] is false and from bottom to top when
  /// [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  AxisDirection _getDirection(BuildContext context) {
    return getAxisDirectionFromAxisReverseAndDirectionality(context, mainAxis, reverse);
  }

  @override
  RenderListBody createRenderObject(BuildContext context) {
    return RenderListBody(axisDirection: _getDirection(context));
  }

  @override
  void updateRenderObject(BuildContext context, RenderListBody renderObject) {
    renderObject.axisDirection = _getDirection(context);
  }
}

/// A widget that positions its children relative to the edges of its box.
///
/// This class is useful if you want to overlap several children in a simple
/// way, for example having some text and an image, overlaid with a gradient and
/// a button attached to the bottom.
///
/// Each child of a [Stack] widget is either _positioned_ or _non-positioned_.
/// Positioned children are those wrapped in a [Positioned] widget that has at
/// least one non-null property. The stack sizes itself to contain all the
/// non-positioned children, which are positioned according to [alignment]
/// (which defaults to the top-left corner in left-to-right environments and the
/// top-right corner in right-to-left environments). The positioned children are
/// then placed relative to the stack according to their top, right, bottom, and
/// left properties.
///
/// The stack paints its children in order with the first child being at the
/// bottom. If you want to change the order in which the children paint, you
/// can rebuild the stack with the children in the new order. If you reorder
/// the children in this way, consider giving the children non-null keys.
/// These keys will cause the framework to move the underlying objects for
/// the children to their new locations rather than recreate them at their
/// new location.
///
/// For more details about the stack layout algorithm, see [RenderStack].
///
/// If you want to lay a number of children out in a particular pattern, or if
/// you want to make a custom layout manager, you probably want to use
/// [CustomMultiChildLayout] instead. In particular, when using a [Stack] you
/// can't position children relative to their size or the stack's own size.
///
/// {@tool sample}
///
/// Using a [Stack] you can position widgets over one another.
///
/// ![A screenshot of the Stack widget](https://flutter.github.io/assets-for-api-docs/assets/widgets/stack.png)
///
/// ```dart
/// Stack(
///   children: <Widget>[
///     Container(
///       width: 100,
///       height: 100,
///       color: Colors.red,
///     ),
///     Container(
///       width: 90,
///       height: 90,
///       color: Colors.green,
///     ),
///     Container(
///       width: 80,
///       height: 80,
///       color: Colors.blue,
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// {@tool sample}
///
/// This example shows how [Stack] can be used to enhance text visibility
/// by adding gradient backdrops.
///
/// ![A screenshot of the Stack widget using a gradient to enhance text visibility](https://flutter.github.io/assets-for-api-docs/assets/widgets/stack_with_gradient.png)
///
/// ```dart
/// SizedBox(
///   width: 250,
///   height: 250,
///   child: Stack(
///     children: <Widget>[
///       Container(
///         width: 250,
///         height: 250,
///         color: Colors.white,
///       ),
///       Container(
///         padding: EdgeInsets.all(5.0),
///         alignment: Alignment.bottomCenter,
///         decoration: BoxDecoration(
///           gradient: LinearGradient(
///             begin: Alignment.topCenter,
///             end: Alignment.bottomCenter,
///             colors: <Color>[
///               Colors.black.withAlpha(0),
///               Colors.black12,
///               Colors.black45
///             ],
///           ),
///         ),
///         child: Text(
///           "Foreground Text",
///           style: TextStyle(color: Colors.white, fontSize: 20.0),
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Align], which sizes itself based on its child's size and positions
///    the child according to an [Alignment] value.
///  * [CustomSingleChildLayout], which uses a delegate to control the layout of
///    a single child.
///  * [CustomMultiChildLayout], which uses a delegate to position multiple
///    children.
///  * [Flow], which provides paint-time control of its children using transform
///    matrices.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Stack extends MultiChildRenderObjectWidget {
  /// Creates a stack layout widget.
  ///
  /// By default, the non-positioned children of the stack are aligned by their
  /// top left corners.
  Stack({
    Key key,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = StackFit.loose,
    this.overflow = Overflow.clip,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  /// How to align the non-positioned and partially-positioned children in the
  /// stack.
  ///
  /// The non-positioned children are placed relative to each other such that
  /// the points determined by [alignment] are co-located. For example, if the
  /// [alignment] is [Alignment.topLeft], then the top left corner of
  /// each non-positioned child will be located at the same global coordinate.
  ///
  /// Partially-positioned children, those that do not specify an alignment in a
  /// particular axis (e.g. that have neither `top` nor `bottom` set), use the
  /// alignment to determine how they should be positioned in that
  /// under-specified axis.
  ///
  /// Defaults to [AlignmentDirectional.topStart].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The text direction with which to resolve [alignment].
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection textDirection;

  /// How to size the non-positioned children in the stack.
  ///
  /// The constraints passed into the [Stack] from its parent are either
  /// loosened ([StackFit.loose]) or tightened to their biggest size
  /// ([StackFit.expand]).
  final StackFit fit;

  /// Whether overflowing children should be clipped. See [Overflow].
  ///
  /// Some children in a stack might overflow its box. When this flag is set to
  /// [Overflow.clip], children cannot paint outside of the stack's box.
  final Overflow overflow;

  @override
  RenderStack createRenderObject(BuildContext context) {
    return RenderStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.of(context),
      fit: fit,
      overflow: overflow,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderStack renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.of(context)
      ..fit = fit
      ..overflow = overflow;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(EnumProperty<StackFit>('fit', fit));
    properties.add(EnumProperty<Overflow>('overflow', overflow));
  }
}

/// A [Stack] that shows a single child from a list of children.
///
/// The displayed child is the one with the given [index]. The stack is
/// always as big as the largest child.
///
/// If value is null, then nothing is displayed.
///
/// See also:
///
///  * [Stack], for more details about stacks.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class IndexedStack extends Stack {
  /// Creates a [Stack] widget that paints a single child.
  ///
  /// The [index] argument must not be null.
  IndexedStack({
    Key key,
    AlignmentGeometry alignment = AlignmentDirectional.topStart,
    TextDirection textDirection,
    StackFit sizing = StackFit.loose,
    this.index = 0,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, alignment: alignment, textDirection: textDirection, fit: sizing, children: children);

  /// The index of the child to show.
  final int index;

  @override
  RenderIndexedStack createRenderObject(BuildContext context) {
    return RenderIndexedStack(
      index: index,
      alignment: alignment,
      textDirection: textDirection ?? Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderIndexedStack renderObject) {
    renderObject
      ..index = index
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.of(context);
  }
}

/// A widget that controls where a child of a [Stack] is positioned.
///
/// A [Positioned] widget must be a descendant of a [Stack], and the path from
/// the [Positioned] widget to its enclosing [Stack] must contain only
/// [StatelessWidget]s or [StatefulWidget]s (not other kinds of widgets, like
/// [RenderObjectWidget]s).
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=EgtPleVwxBQ}
///
/// If a widget is wrapped in a [Positioned], then it is a _positioned_ widget
/// in its [Stack]. If the [top] property is non-null, the top edge of this child
/// will be positioned [top] layout units from the top of the stack widget. The
/// [right], [bottom], and [left] properties work analogously.
///
/// If both the [top] and [bottom] properties are non-null, then the child will
/// be forced to have exactly the height required to satisfy both constraints.
/// Similarly, setting the [right] and [left] properties to non-null values will
/// force the child to have a particular width. Alternatively the [width] and
/// [height] properties can be used to give the dimensions, with one
/// corresponding position property (e.g. [top] and [height]).
///
/// If all three values on a particular axis are null, then the
/// [Stack.alignment] property is used to position the child.
///
/// If all six values are null, the child is a non-positioned child. The [Stack]
/// uses only the non-positioned children to size itself.
///
/// See also:
///
///  * [AnimatedPositioned], which automatically transitions the child's
///    position over a given duration whenever the given position changes.
///  * [PositionedTransition], which takes a provided [Animation] to transition
///    changes in the child's position over a given duration.
///  * [PositionedDirectional], which adapts to the ambient [Directionality].
class Positioned extends ParentDataWidget<Stack> {
  /// Creates a widget that controls where a child of a [Stack] is positioned.
  ///
  /// Only two out of the three horizontal values ([left], [right],
  /// [width]), and only two out of the three vertical values ([top],
  /// [bottom], [height]), can be set. In each case, at least one of
  /// the three must be null.
  ///
  /// See also:
  ///
  ///  * [Positioned.directional], which specifies the widget's horizontal
  ///    position using `start` and `end` rather than `left` and `right`.
  ///  * [PositionedDirectional], which is similar to [Positioned.directional]
  ///    but adapts to the ambient [Directionality].
  const Positioned({
    Key key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    @required Widget child,
  }) : assert(left == null || right == null || width == null),
       assert(top == null || bottom == null || height == null),
       super(key: key, child: child);

  /// Creates a Positioned object with the values from the given [Rect].
  ///
  /// This sets the [left], [top], [width], and [height] properties
  /// from the given [Rect]. The [right] and [bottom] properties are
  /// set to null.
  Positioned.fromRect({
    Key key,
    Rect rect,
    @required Widget child,
  }) : left = rect.left,
       top = rect.top,
       width = rect.width,
       height = rect.height,
       right = null,
       bottom = null,
       super(key: key, child: child);

  /// Creates a Positioned object with the values from the given [RelativeRect].
  ///
  /// This sets the [left], [top], [right], and [bottom] properties from the
  /// given [RelativeRect]. The [height] and [width] properties are set to null.
  Positioned.fromRelativeRect({
    Key key,
    RelativeRect rect,
    @required Widget child,
  }) : left = rect.left,
       top = rect.top,
       right = rect.right,
       bottom = rect.bottom,
       width = null,
       height = null,
       super(key: key, child: child);

  /// Creates a Positioned object with [left], [top], [right], and [bottom] set
  /// to 0.0 unless a value for them is passed.
  const Positioned.fill({
    Key key,
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
    @required Widget child,
  }) : width = null,
       height = null,
       super(key: key, child: child);

  /// Creates a widget that controls where a child of a [Stack] is positioned.
  ///
  /// Only two out of the three horizontal values (`start`, `end`,
  /// [width]), and only two out of the three vertical values ([top],
  /// [bottom], [height]), can be set. In each case, at least one of
  /// the three must be null.
  ///
  /// If `textDirection` is [TextDirection.rtl], then the `start` argument is
  /// used for the [right] property and the `end` argument is used for the
  /// [left] property. Otherwise, if `textDirection` is [TextDirection.ltr],
  /// then the `start` argument is used for the [left] property and the `end`
  /// argument is used for the [right] property.
  ///
  /// The `textDirection` argument must not be null.
  ///
  /// See also:
  ///
  ///  * [PositionedDirectional], which adapts to the ambient [Directionality].
  factory Positioned.directional({
    Key key,
    @required TextDirection textDirection,
    double start,
    double top,
    double end,
    double bottom,
    double width,
    double height,
    @required Widget child,
  }) {
    assert(textDirection != null);
    double left;
    double right;
    switch (textDirection) {
      case TextDirection.rtl:
        left = end;
        right = start;
        break;
      case TextDirection.ltr:
        left = start;
        right = end;
        break;
    }
    return Positioned(
      key: key,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  }

  /// The distance that the child's left edge is inset from the left of the stack.
  ///
  /// Only two out of the three horizontal values ([left], [right], [width]) can be
  /// set. The third must be null.
  ///
  /// If all three are null, the [Stack.alignment] is used to position the child
  /// horizontally.
  final double left;

  /// The distance that the child's top edge is inset from the top of the stack.
  ///
  /// Only two out of the three vertical values ([top], [bottom], [height]) can be
  /// set. The third must be null.
  ///
  /// If all three are null, the [Stack.alignment] is used to position the child
  /// vertically.
  final double top;

  /// The distance that the child's right edge is inset from the right of the stack.
  ///
  /// Only two out of the three horizontal values ([left], [right], [width]) can be
  /// set. The third must be null.
  ///
  /// If all three are null, the [Stack.alignment] is used to position the child
  /// horizontally.
  final double right;

  /// The distance that the child's bottom edge is inset from the bottom of the stack.
  ///
  /// Only two out of the three vertical values ([top], [bottom], [height]) can be
  /// set. The third must be null.
  ///
  /// If all three are null, the [Stack.alignment] is used to position the child
  /// vertically.
  final double bottom;

  /// The child's width.
  ///
  /// Only two out of the three horizontal values ([left], [right], [width]) can be
  /// set. The third must be null.
  ///
  /// If all three are null, the [Stack.alignment] is used to position the child
  /// horizontally.
  final double width;

  /// The child's height.
  ///
  /// Only two out of the three vertical values ([top], [bottom], [height]) can be
  /// set. The third must be null.
  ///
  /// If all three are null, the [Stack.alignment] is used to position the child
  /// vertically.
  final double height;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StackParentData);
    final StackParentData parentData = renderObject.parentData;
    bool needsLayout = false;

    if (parentData.left != left) {
      parentData.left = left;
      needsLayout = true;
    }

    if (parentData.top != top) {
      parentData.top = top;
      needsLayout = true;
    }

    if (parentData.right != right) {
      parentData.right = right;
      needsLayout = true;
    }

    if (parentData.bottom != bottom) {
      parentData.bottom = bottom;
      needsLayout = true;
    }

    if (parentData.width != width) {
      parentData.width = width;
      needsLayout = true;
    }

    if (parentData.height != height) {
      parentData.height = height;
      needsLayout = true;
    }

    if (needsLayout) {
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject)
        targetParent.markNeedsLayout();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('left', left, defaultValue: null));
    properties.add(DoubleProperty('top', top, defaultValue: null));
    properties.add(DoubleProperty('right', right, defaultValue: null));
    properties.add(DoubleProperty('bottom', bottom, defaultValue: null));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
  }
}

/// A widget that controls where a child of a [Stack] is positioned without
/// committing to a specific [TextDirection].
///
/// The ambient [Directionality] is used to determine whether [start] is to the
/// left or to the right.
///
/// A [PositionedDirectional] widget must be a descendant of a [Stack], and the
/// path from the [PositionedDirectional] widget to its enclosing [Stack] must
/// contain only [StatelessWidget]s or [StatefulWidget]s (not other kinds of
/// widgets, like [RenderObjectWidget]s).
///
/// If a widget is wrapped in a [PositionedDirectional], then it is a
/// _positioned_ widget in its [Stack]. If the [top] property is non-null, the
/// top edge of this child/ will be positioned [top] layout units from the top
/// of the stack widget. The [start], [bottom], and [end] properties work
/// analogously.
///
/// If both the [top] and [bottom] properties are non-null, then the child will
/// be forced to have exactly the height required to satisfy both constraints.
/// Similarly, setting the [start] and [end] properties to non-null values will
/// force the child to have a particular width. Alternatively the [width] and
/// [height] properties can be used to give the dimensions, with one
/// corresponding position property (e.g. [top] and [height]).
///
/// See also:
///
///  * [Positioned], which specifies the widget's position visually.
///  * [Positioned.directional], which also specifies the widget's horizontal
///    position using [start] and [end] but has an explicit [TextDirection].
///  * [AnimatedPositionedDirectional], which automatically transitions
///    the child's position over a given duration whenever the given position
///    changes.
class PositionedDirectional extends StatelessWidget {
  /// Creates a widget that controls where a child of a [Stack] is positioned.
  ///
  /// Only two out of the three horizontal values (`start`, `end`,
  /// [width]), and only two out of the three vertical values ([top],
  /// [bottom], [height]), can be set. In each case, at least one of
  /// the three must be null.
  ///
  /// See also:
  ///
  ///  * [Positioned.directional], which also specifies the widget's horizontal
  ///    position using [start] and [end] but has an explicit [TextDirection].
  const PositionedDirectional({
    Key key,
    this.start,
    this.top,
    this.end,
    this.bottom,
    this.width,
    this.height,
    @required this.child,
  }) : super(key: key);

  /// The distance that the child's leading edge is inset from the leading edge
  /// of the stack.
  ///
  /// Only two out of the three horizontal values ([start], [end], [width]) can be
  /// set. The third must be null.
  final double start;

  /// The distance that the child's top edge is inset from the top of the stack.
  ///
  /// Only two out of the three vertical values ([top], [bottom], [height]) can be
  /// set. The third must be null.
  final double top;

  /// The distance that the child's trailing edge is inset from the trailing
  /// edge of the stack.
  ///
  /// Only two out of the three horizontal values ([start], [end], [width]) can be
  /// set. The third must be null.
  final double end;

  /// The distance that the child's bottom edge is inset from the bottom of the stack.
  ///
  /// Only two out of the three vertical values ([top], [bottom], [height]) can be
  /// set. The third must be null.
  final double bottom;

  /// The child's width.
  ///
  /// Only two out of the three horizontal values ([start], [end], [width]) can be
  /// set. The third must be null.
  final double width;

  /// The child's height.
  ///
  /// Only two out of the three vertical values ([top], [bottom], [height]) can be
  /// set. The third must be null.
  final double height;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      start: start,
      top: top,
      end: end,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  }
}

/// A widget that displays its children in a one-dimensional array.
///
/// The [Flex] widget allows you to control the axis along which the children are
/// placed (horizontal or vertical). This is referred to as the _main axis_. If
/// you know the main axis in advance, then consider using a [Row] (if it's
/// horizontal) or [Column] (if it's vertical) instead, because that will be less
/// verbose.
///
/// To cause a child to expand to fill the available space in the [direction]
/// of this widget's main axis, wrap the child in an [Expanded] widget.
///
/// The [Flex] widget does not scroll (and in general it is considered an error
/// to have more children in a [Flex] than will fit in the available room). If
/// you have some widgets and want them to be able to scroll if there is
/// insufficient room, consider using a [ListView].
///
/// If you only have one child, then rather than using [Flex], [Row], or
/// [Column], consider using [Align] or [Center] to position the child.
///
/// ## Layout algorithm
///
/// _This section describes how a [Flex] is rendered by the framework._
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// Layout for a [Flex] proceeds in six steps:
///
/// 1. Layout each child a null or zero flex factor (e.g., those that are not
///    [Expanded]) with unbounded main axis constraints and the incoming
///    cross axis constraints. If the [crossAxisAlignment] is
///    [CrossAxisAlignment.stretch], instead use tight cross axis constraints
///    that match the incoming max extent in the cross axis.
/// 2. Divide the remaining main axis space among the children with non-zero
///    flex factors (e.g., those that are [Expanded]) according to their flex
///    factor. For example, a child with a flex factor of 2.0 will receive twice
///    the amount of main axis space as a child with a flex factor of 1.0.
/// 3. Layout each of the remaining children with the same cross axis
///    constraints as in step 1, but instead of using unbounded main axis
///    constraints, use max axis constraints based on the amount of space
///    allocated in step 2. Children with [Flexible.fit] properties that are
///    [FlexFit.tight] are given tight constraints (i.e., forced to fill the
///    allocated space), and children with [Flexible.fit] properties that are
///    [FlexFit.loose] are given loose constraints (i.e., not forced to fill the
///    allocated space).
/// 4. The cross axis extent of the [Flex] is the maximum cross axis extent of
///    the children (which will always satisfy the incoming constraints).
/// 5. The main axis extent of the [Flex] is determined by the [mainAxisSize]
///    property. If the [mainAxisSize] property is [MainAxisSize.max], then the
///    main axis extent of the [Flex] is the max extent of the incoming main
///    axis constraints. If the [mainAxisSize] property is [MainAxisSize.min],
///    then the main axis extent of the [Flex] is the sum of the main axis
///    extents of the children (subject to the incoming constraints).
/// 6. Determine the position for each child according to the
///    [mainAxisAlignment] and the [crossAxisAlignment]. For example, if the
///    [mainAxisAlignment] is [MainAxisAlignment.spaceBetween], any main axis
///    space that has not been allocated to children is divided evenly and
///    placed between the children.
///
/// See also:
///
///  * [Row], for a version of this widget that is always horizontal.
///  * [Column], for a version of this widget that is always vertical.
///  * [Expanded], to indicate children that should take all the remaining room.
///  * [Flexible], to indicate children that should share the remaining room.
///  * [Spacer], a widget that takes up space proportional to it's flex value.
///    that may be sized smaller (leaving some remaining room unused).
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Flex extends MultiChildRenderObjectWidget {
  /// Creates a flex layout.
  ///
  /// The [direction] is required.
  ///
  /// The [direction], [mainAxisAlignment], [crossAxisAlignment], and
  /// [verticalDirection] arguments must not be null. If [crossAxisAlignment] is
  /// [CrossAxisAlignment.baseline], then [textBaseline] must not be null.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to decide which direction to lay the children in or to
  /// disambiguate `start` or `end` values for the main or cross axis
  /// directions, the [textDirection] must not be null.
  Flex({
    Key key,
    @required this.direction,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    List<Widget> children = const <Widget>[],
  }) : assert(direction != null),
       assert(mainAxisAlignment != null),
       assert(mainAxisSize != null),
       assert(crossAxisAlignment != null),
       assert(verticalDirection != null),
       assert(crossAxisAlignment != CrossAxisAlignment.baseline || textBaseline != null),
       super(key: key, children: children);

  /// The direction to use as the main axis.
  ///
  /// If you know the axis in advance, then consider using a [Row] (if it's
  /// horizontal) or [Column] (if it's vertical) instead of a [Flex], since that
  /// will be less verbose. (For [Row] and [Column] this property is fixed to
  /// the appropriate axis.)
  final Axis direction;

  /// How the children should be placed along the main axis.
  ///
  /// For example, [MainAxisAlignment.start], the default, places the children
  /// at the start (i.e., the left for a [Row] or the top for a [Column]) of the
  /// main axis.
  final MainAxisAlignment mainAxisAlignment;

  /// How much space should be occupied in the main axis.
  ///
  /// After allocating space to children, there might be some remaining free
  /// space. This value controls whether to maximize or minimize the amount of
  /// free space, subject to the incoming layout constraints.
  ///
  /// If some children have a non-zero flex factors (and none have a fit of
  /// [FlexFit.loose]), they will expand to consume all the available space and
  /// there will be no remaining free space to maximize or minimize, making this
  /// value irrelevant to the final layout.
  final MainAxisSize mainAxisSize;

  /// How the children should be placed along the cross axis.
  ///
  /// For example, [CrossAxisAlignment.center], the default, centers the
  /// children in the cross axis (e.g., horizontally for a [Column]).
  final CrossAxisAlignment crossAxisAlignment;

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// Defaults to the ambient [Directionality].
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// the children are positioned (left-to-right or right-to-left), and the
  /// meaning of the [mainAxisAlignment] property's [MainAxisAlignment.start] and
  /// [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [mainAxisAlignment] is either [MainAxisAlignment.start] or
  /// [MainAxisAlignment.end], or there's more than one child, then the
  /// [textDirection] (or the ambient [Directionality]) must not be null.
  ///
  /// If the [direction] is [Axis.vertical], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [textDirection] (or the ambient [Directionality]) must not be null.
  final TextDirection textDirection;

  /// Determines the order to lay children out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  ///
  /// Defaults to [VerticalDirection.down].
  ///
  /// If the [direction] is [Axis.vertical], this controls which order children
  /// are painted in (down or up), the meaning of the [mainAxisAlignment]
  /// property's [MainAxisAlignment.start] and [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [mainAxisAlignment]
  /// is either [MainAxisAlignment.start] or [MainAxisAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  final VerticalDirection verticalDirection;

  /// If aligning items according to their baseline, which baseline to use.
  final TextBaseline textBaseline;

  bool get _needTextDirection {
    assert(direction != null);
    switch (direction) {
      case Axis.horizontal:
        return true; // because it affects the layout order.
      case Axis.vertical:
        assert(crossAxisAlignment != null);
        return crossAxisAlignment == CrossAxisAlignment.start
            || crossAxisAlignment == CrossAxisAlignment.end;
    }
    return null;
  }

  /// The value to pass to [RenderFlex.textDirection].
  ///
  /// This value is derived from the [textDirection] property and the ambient
  /// [Directionality]. The value is null if there is no need to specify the
  /// text direction. In practice there's always a need to specify the direction
  /// except for vertical flexes (e.g. [Column]s) whose [crossAxisAlignment] is
  /// not dependent on the text direction (not `start` or `end`). In particular,
  /// a [Row] always needs a text direction because the text direction controls
  /// its layout order. (For [Column]s, the layout order is controlled by
  /// [verticalDirection], which is always specified as it does not depend on an
  /// inherited widget and defaults to [VerticalDirection.down].)
  ///
  /// This method exists so that subclasses of [Flex] that create their own
  /// render objects that are derived from [RenderFlex] can do so and still use
  /// the logic for providing a text direction only when it is necessary.
  @protected
  TextDirection getEffectiveTextDirection(BuildContext context) {
    return textDirection ?? (_needTextDirection ? Directionality.of(context) : null);
  }

  @override
  RenderFlex createRenderObject(BuildContext context) {
    return RenderFlex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderFlex renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = getEffectiveTextDirection(context)
      ..verticalDirection = verticalDirection
      ..textBaseline = textBaseline;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<MainAxisAlignment>('mainAxisAlignment', mainAxisAlignment));
    properties.add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize, defaultValue: MainAxisSize.max));
    properties.add(EnumProperty<CrossAxisAlignment>('crossAxisAlignment', crossAxisAlignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>('verticalDirection', verticalDirection, defaultValue: VerticalDirection.down));
    properties.add(EnumProperty<TextBaseline>('textBaseline', textBaseline, defaultValue: null));
  }
}

/// A widget that displays its children in a horizontal array.
///
/// To cause a child to expand to fill the available horizontal space, wrap the
/// child in an [Expanded] widget.
///
/// The [Row] widget does not scroll (and in general it is considered an error
/// to have more children in a [Row] than will fit in the available room). If
/// you have a line of widgets and want them to be able to scroll if there is
/// insufficient room, consider using a [ListView].
///
/// For a vertical variant, see [Column].
///
/// If you only have one child, then consider using [Align] or [Center] to
/// position the child.
///
/// {@tool sample}
///
/// This example divides the available space into three (horizontally), and
/// places text centered in the first two cells and the Flutter logo centered in
/// the third:
///
/// ![A screenshot of the Row widget](https://flutter.github.io/assets-for-api-docs/assets/widgets/row.png)
///
/// ```dart
/// Row(
///   children: <Widget>[
///     Expanded(
///       child: Text('Deliver features faster', textAlign: TextAlign.center),
///     ),
///     Expanded(
///       child: Text('Craft beautiful UIs', textAlign: TextAlign.center),
///     ),
///     Expanded(
///       child: FittedBox(
///         fit: BoxFit.contain, // otherwise the logo will be tiny
///         child: const FlutterLogo(),
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// ## Troubleshooting
///
/// ### Why does my row have a yellow and black warning stripe?
///
/// If the non-flexible contents of the row (those that are not wrapped in
/// [Expanded] or [Flexible] widgets) are together wider than the row itself,
/// then the row is said to have overflowed. When a row overflows, the row does
/// not have any remaining space to share between its [Expanded] and [Flexible]
/// children. The row reports this by drawing a yellow and black striped
/// warning box on the edge that is overflowing. If there is room on the outside
/// of the row, the amount of overflow is printed in red lettering.
///
/// #### Story time
///
/// Suppose, for instance, that you had this code:
///
/// ```dart
/// Row(
///   children: <Widget>[
///     const FlutterLogo(),
///     const Text('Flutter\'s hot reload helps you quickly and easily experiment, build UIs, add features, and fix bug faster. Experience sub-second reload times, without losing state, on emulators, simulators, and hardware for iOS and Android.'),
///     const Icon(Icons.sentiment_very_satisfied),
///   ],
/// )
/// ```
///
/// The row first asks its first child, the [FlutterLogo], to lay out, at
/// whatever size the logo would like. The logo is friendly and happily decides
/// to be 24 pixels to a side. This leaves lots of room for the next child. The
/// row then asks that next child, the text, to lay out, at whatever size it
/// thinks is best.
///
/// At this point, the text, not knowing how wide is too wide, says "Ok, I will
/// be thiiiiiiiiiiiiiiiiiiiis wide.", and goes well beyond the space that the
/// row has available, not wrapping. The row responds, "That's not fair, now I
/// have no more room available for my other children!", and gets angry and
/// sprouts a yellow and black strip.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/widgets/row_error.png)
///
/// The fix is to wrap the second child in an [Expanded] widget, which tells the
/// row that the child should be given the remaining room:
///
/// ```dart
/// Row(
///   children: <Widget>[
///     const FlutterLogo(),
///     const Expanded(
///       child: Text('Flutter\'s hot reload helps you quickly and easily experiment, build UIs, add features, and fix bug faster. Experience sub-second reload times, without losing state, on emulators, simulators, and hardware for iOS and Android.'),
///     ),
///     const Icon(Icons.sentiment_very_satisfied),
///   ],
/// )
/// ```
///
/// Now, the row first asks the logo to lay out, and then asks the _icon_ to lay
/// out. The [Icon], like the logo, is happy to take on a reasonable size (also
/// 24 pixels, not coincidentally, since both [FlutterLogo] and [Icon] honor the
/// ambient [IconTheme]). This leaves some room left over, and now the row tells
/// the text exactly how wide to be: the exact width of the remaining space. The
/// text, now happy to comply to a reasonable request, wraps the text within
/// that width, and you end up with a paragraph split over several lines.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/widgets/row_fixed.png)
///
/// ## Layout algorithm
///
/// _This section describes how a [Row] is rendered by the framework._
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// Layout for a [Row] proceeds in six steps:
///
/// 1. Layout each child a null or zero flex factor (e.g., those that are not
///    [Expanded]) with unbounded horizontal constraints and the incoming
///    vertical constraints. If the [crossAxisAlignment] is
///    [CrossAxisAlignment.stretch], instead use tight vertical constraints that
///    match the incoming max height.
/// 2. Divide the remaining horizontal space among the children with non-zero
///    flex factors (e.g., those that are [Expanded]) according to their flex
///    factor. For example, a child with a flex factor of 2.0 will receive twice
///    the amount of horizontal space as a child with a flex factor of 1.0.
/// 3. Layout each of the remaining children with the same vertical constraints
///    as in step 1, but instead of using unbounded horizontal constraints, use
///    horizontal constraints based on the amount of space allocated in step 2.
///    Children with [Flexible.fit] properties that are [FlexFit.tight] are
///    given tight constraints (i.e., forced to fill the allocated space), and
///    children with [Flexible.fit] properties that are [FlexFit.loose] are
///    given loose constraints (i.e., not forced to fill the allocated space).
/// 4. The height of the [Row] is the maximum height of the children (which will
///    always satisfy the incoming vertical constraints).
/// 5. The width of the [Row] is determined by the [mainAxisSize] property. If
///    the [mainAxisSize] property is [MainAxisSize.max], then the width of the
///    [Row] is the max width of the incoming constraints. If the [mainAxisSize]
///    property is [MainAxisSize.min], then the width of the [Row] is the sum
///    of widths of the children (subject to the incoming constraints).
/// 6. Determine the position for each child according to the
///    [mainAxisAlignment] and the [crossAxisAlignment]. For example, if the
///    [mainAxisAlignment] is [MainAxisAlignment.spaceBetween], any horizontal
///    space that has not been allocated to children is divided evenly and
///    placed between the children.
///
/// See also:
///
///  * [Column], for a vertical equivalent.
///  * [Flex], if you don't know in advance if you want a horizontal or vertical
///    arrangement.
///  * [Expanded], to indicate children that should take all the remaining room.
///  * [Flexible], to indicate children that should share the remaining room but
///    that may by sized smaller (leaving some remaining room unused).
///  * [Spacer], a widget that takes up space proportional to it's flex value.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Row extends Flex {
  /// Creates a horizontal array of children.
  ///
  /// The [direction], [mainAxisAlignment], [mainAxisSize],
  /// [crossAxisAlignment], and [verticalDirection] arguments must not be null.
  /// If [crossAxisAlignment] is [CrossAxisAlignment.baseline], then
  /// [textBaseline] must not be null.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to determine the layout order (which is always the case
  /// unless the row has no children or only one child) or to disambiguate
  /// `start` or `end` values for the [mainAxisAlignment], the [textDirection]
  /// must not be null.
  Row({
    Key key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
    List<Widget> children = const <Widget>[],
  }) : super(
    children: children,
    key: key,
    direction: Axis.horizontal,
    mainAxisAlignment: mainAxisAlignment,
    mainAxisSize: mainAxisSize,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection,
    verticalDirection: verticalDirection,
    textBaseline: textBaseline,
  );
}

/// A widget that displays its children in a vertical array.
///
/// To cause a child to expand to fill the available vertical space, wrap the
/// child in an [Expanded] widget.
///
/// The [Column] widget does not scroll (and in general it is considered an error
/// to have more children in a [Column] than will fit in the available room). If
/// you have a line of widgets and want them to be able to scroll if there is
/// insufficient room, consider using a [ListView].
///
/// For a horizontal variant, see [Row].
///
/// If you only have one child, then consider using [Align] or [Center] to
/// position the child.
///
/// {@tool sample}
///
/// This example uses a [Column] to arrange three widgets vertically, the last
/// being made to fill all the remaining space.
///
/// ![A screenshot of the Column widget](https://flutter.github.io/assets-for-api-docs/assets/widgets/column.png)
///
/// ```dart
/// Column(
///   children: <Widget>[
///     Text('Deliver features faster'),
///     Text('Craft beautiful UIs'),
///     Expanded(
///       child: FittedBox(
///         fit: BoxFit.contain, // otherwise the logo will be tiny
///         child: const FlutterLogo(),
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
/// {@tool sample}
///
/// In the sample above, the text and the logo are centered on each line. In the
/// following example, the [crossAxisAlignment] is set to
/// [CrossAxisAlignment.start], so that the children are left-aligned. The
/// [mainAxisSize] is set to [MainAxisSize.min], so that the column shrinks to
/// fit the children.
///
/// ![A screenshot of the Column widget with a customized crossAxisAlignment and mainAxisSize](https://flutter.github.io/assets-for-api-docs/assets/widgets/column_properties.png)
///
/// ```dart
/// Column(
///   crossAxisAlignment: CrossAxisAlignment.start,
///   mainAxisSize: MainAxisSize.min,
///   children: <Widget>[
///     Text('We move under cover and we move as one'),
///     Text('Through the night, we have one shot to live another day'),
///     Text('We cannot let a stray gunshot give us away'),
///     Text('We will fight up close, seize the moment and stay in it'),
///     Text('It’s either that or meet the business end of a bayonet'),
///     Text('The code word is ‘Rochambeau,’ dig me?'),
///     Text('Rochambeau!', style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0)),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// ## Troubleshooting
///
/// ### When the incoming vertical constraints are unbounded
///
/// When a [Column] has one or more [Expanded] or [Flexible] children, and is
/// placed in another [Column], or in a [ListView], or in some other context
/// that does not provide a maximum height constraint for the [Column], you will
/// get an exception at runtime saying that there are children with non-zero
/// flex but the vertical constraints are unbounded.
///
/// The problem, as described in the details that accompany that exception, is
/// that using [Flexible] or [Expanded] means that the remaining space after
/// laying out all the other children must be shared equally, but if the
/// incoming vertical constraints are unbounded, there is infinite remaining
/// space.
///
/// The key to solving this problem is usually to determine why the [Column] is
/// receiving unbounded vertical constraints.
///
/// One common reason for this to happen is that the [Column] has been placed in
/// another [Column] (without using [Expanded] or [Flexible] around the inner
/// nested [Column]). When a [Column] lays out its non-flex children (those that
/// have neither [Expanded] or [Flexible] around them), it gives them unbounded
/// constraints so that they can determine their own dimensions (passing
/// unbounded constraints usually signals to the child that it should
/// shrink-wrap its contents). The solution in this case is typically to just
/// wrap the inner column in an [Expanded] to indicate that it should take the
/// remaining space of the outer column, rather than being allowed to take any
/// amount of room it desires.
///
/// Another reason for this message to be displayed is nesting a [Column] inside
/// a [ListView] or other vertical scrollable. In that scenario, there really is
/// infinite vertical space (the whole point of a vertical scrolling list is to
/// allow infinite space vertically). In such scenarios, it is usually worth
/// examining why the inner [Column] should have an [Expanded] or [Flexible]
/// child: what size should the inner children really be? The solution in this
/// case is typically to remove the [Expanded] or [Flexible] widgets from around
/// the inner children.
///
/// For more discussion about constraints, see [BoxConstraints].
///
/// ### The yellow and black striped banner
///
/// When the contents of a [Column] exceed the amount of space available, the
/// [Column] overflows, and the contents are clipped. In debug mode, a yellow
/// and black striped bar is rendered at the overflowing edge to indicate the
/// problem, and a message is printed below the [Column] saying how much
/// overflow was detected.
///
/// The usual solution is to use a [ListView] rather than a [Column], to enable
/// the contents to scroll when vertical space is limited.
///
/// ## Layout algorithm
///
/// _This section describes how a [Column] is rendered by the framework._
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// Layout for a [Column] proceeds in six steps:
///
/// 1. Layout each child a null or zero flex factor (e.g., those that are not
///    [Expanded]) with unbounded vertical constraints and the incoming
///    horizontal constraints. If the [crossAxisAlignment] is
///    [CrossAxisAlignment.stretch], instead use tight horizontal constraints
///    that match the incoming max width.
/// 2. Divide the remaining vertical space among the children with non-zero
///    flex factors (e.g., those that are [Expanded]) according to their flex
///    factor. For example, a child with a flex factor of 2.0 will receive twice
///    the amount of vertical space as a child with a flex factor of 1.0.
/// 3. Layout each of the remaining children with the same horizontal
///    constraints as in step 1, but instead of using unbounded vertical
///    constraints, use vertical constraints based on the amount of space
///    allocated in step 2. Children with [Flexible.fit] properties that are
///    [FlexFit.tight] are given tight constraints (i.e., forced to fill the
///    allocated space), and children with [Flexible.fit] properties that are
///    [FlexFit.loose] are given loose constraints (i.e., not forced to fill the
///    allocated space).
/// 4. The width of the [Column] is the maximum width of the children (which
///    will always satisfy the incoming horizontal constraints).
/// 5. The height of the [Column] is determined by the [mainAxisSize] property.
///    If the [mainAxisSize] property is [MainAxisSize.max], then the height of
///    the [Column] is the max height of the incoming constraints. If the
///    [mainAxisSize] property is [MainAxisSize.min], then the height of the
///    [Column] is the sum of heights of the children (subject to the incoming
///    constraints).
/// 6. Determine the position for each child according to the
///    [mainAxisAlignment] and the [crossAxisAlignment]. For example, if the
///    [mainAxisAlignment] is [MainAxisAlignment.spaceBetween], any vertical
///    space that has not been allocated to children is divided evenly and
///    placed between the children.
///
/// See also:
///
///  * [Row], for a horizontal equivalent.
///  * [Flex], if you don't know in advance if you want a horizontal or vertical
///    arrangement.
///  * [Expanded], to indicate children that should take all the remaining room.
///  * [Flexible], to indicate children that should share the remaining room but
///    that may size smaller (leaving some remaining room unused).
///  * [SingleChildScrollView], whose documentation discusses some ways to
///    use a [Column] inside a scrolling container.
///  * [Spacer], a widget that takes up space proportional to it's flex value.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Column extends Flex {
  /// Creates a vertical array of children.
  ///
  /// The [direction], [mainAxisAlignment], [mainAxisSize],
  /// [crossAxisAlignment], and [verticalDirection] arguments must not be null.
  /// If [crossAxisAlignment] is [CrossAxisAlignment.baseline], then
  /// [textBaseline] must not be null.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to disambiguate `start` or `end` values for the
  /// [crossAxisAlignment], the [textDirection] must not be null.
  Column({
    Key key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
    List<Widget> children = const <Widget>[],
  }) : super(
    children: children,
    key: key,
    direction: Axis.vertical,
    mainAxisAlignment: mainAxisAlignment,
    mainAxisSize: mainAxisSize,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection,
    verticalDirection: verticalDirection,
    textBaseline: textBaseline,
  );
}

/// A widget that controls how a child of a [Row], [Column], or [Flex] flexes.
///
/// Using a [Flexible] widget gives a child of a [Row], [Column], or [Flex]
/// the flexibility to expand to fill the available space in the main axis
/// (e.g., horizontally for a [Row] or vertically for a [Column]), but, unlike
/// [Expanded], [Flexible] does not require the child to fill the available
/// space.
///
/// A [Flexible] widget must be a descendant of a [Row], [Column], or [Flex],
/// and the path from the [Flexible] widget to its enclosing [Row], [Column], or
/// [Flex] must contain only [StatelessWidget]s or [StatefulWidget]s (not other
/// kinds of widgets, like [RenderObjectWidget]s).
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=CI7x0mAZiY0}
///
/// See also:
///
///  * [Expanded], which forces the child to expand to fill the available space.
///  * [Spacer], a widget that takes up space proportional to it's flex value.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Flexible extends ParentDataWidget<Flex> {
  /// Creates a widget that controls how a child of a [Row], [Column], or [Flex]
  /// flexes.
  const Flexible({
    Key key,
    this.flex = 1,
    this.fit = FlexFit.loose,
    @required Widget child,
  }) : super(key: key, child: child);

  /// The flex factor to use for this child
  ///
  /// If null or zero, the child is inflexible and determines its own size. If
  /// non-zero, the amount of space the child's can occupy in the main axis is
  /// determined by dividing the free space (after placing the inflexible
  /// children) according to the flex factors of the flexible children.
  final int flex;

  /// How a flexible child is inscribed into the available space.
  ///
  /// If [flex] is non-zero, the [fit] determines whether the child fills the
  /// space the parent makes available during layout. If the fit is
  /// [FlexFit.tight], the child is required to fill the available space. If the
  /// fit is [FlexFit.loose], the child can be at most as large as the available
  /// space (but is allowed to be smaller).
  final FlexFit fit;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is FlexParentData);
    final FlexParentData parentData = renderObject.parentData;
    bool needsLayout = false;

    if (parentData.flex != flex) {
      parentData.flex = flex;
      needsLayout = true;
    }

    if (parentData.fit != fit) {
      parentData.fit = fit;
      needsLayout = true;
    }

    if (needsLayout) {
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject)
        targetParent.markNeedsLayout();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('flex', flex));
  }
}

/// A widget that expands a child of a [Row], [Column], or [Flex]
/// so that the child fills the available space.
///
/// Using an [Expanded] widget makes a child of a [Row], [Column], or [Flex]
/// expand to fill the available space along the main axis (e.g., horizontally for
/// a [Row] or vertically for a [Column]). If multiple children are expanded,
/// the available space is divided among them according to the [flex] factor.
///
/// An [Expanded] widget must be a descendant of a [Row], [Column], or [Flex],
/// and the path from the [Expanded] widget to its enclosing [Row], [Column], or
/// [Flex] must contain only [StatelessWidget]s or [StatefulWidget]s (not other
/// kinds of widgets, like [RenderObjectWidget]s).
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=_rnZaagadyo}
///
/// {@tool snippet --template=stateless_widget_material}
/// This example shows how to use an [Expanded] widget in a [Column] so that
/// it's middle child, a [Container] here, expands to fill the space.
///
/// ![An example using Expanded widget in a Column](https://flutter.github.io/assets-for-api-docs/assets/widgets/expanded_column.png)
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: Text('Expanded Column Sample'),
///     ),
///     body: Center(
///        child: Column(
///         children: <Widget>[
///           Container(
///             color: Colors.blue,
///             height: 100,
///             width: 100,
///           ),
///           Expanded(
///             child: Container(
///               color: Colors.amber,
///               width: 100,
///             ),
///           ),
///           Container(
///             color: Colors.blue,
///             height: 100,
///             width: 100,
///           ),
///         ],
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet --template=stateless_widget_material}
/// This example shows how to use an [Expanded] widget in a [Row] with multiple
/// children expanded, utilizing the [flex] factor to prioritize available space.
///
/// ![An example using Expanded widget in a Row](https://flutter.github.io/assets-for-api-docs/assets/widgets/expanded_row.png)
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: Text('Expanded Row Sample'),
///     ),
///     body: Center(
///       child: Row(
///         children: <Widget>[
///           Expanded(
///             flex: 2,
///             child: Container(
///               color: Colors.amber,
///               height: 100,
///             ),
///           ),
///           Container(
///             color: Colors.blue,
///             height: 100,
///             width: 50,
///           ),
///           Expanded(
///             flex: 1,
///             child: Container(
///               color: Colors.amber,
///               height: 100,
///             ),
///           ),
///         ],
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Flexible], which does not force the child to fill the available space.
///  * [Spacer], a widget that takes up space proportional to it's flex value.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Expanded extends Flexible {
  /// Creates a widget that expands a child of a [Row], [Column], or [Flex]
  /// so that the child fills the available space along the flex widget's
  /// main axis.
  const Expanded({
    Key key,
    int flex = 1,
    @required Widget child,
  }) : super(key: key, flex: flex, fit: FlexFit.tight, child: child);
}

/// A widget that displays its children in multiple horizontal or vertical runs.
///
/// A [Wrap] lays out each child and attempts to place the child adjacent to the
/// previous child in the main axis, given by [direction], leaving [spacing]
/// space in between. If there is not enough space to fit the child, [Wrap]
/// creates a new _run_ adjacent to the existing children in the cross axis.
///
/// After all the children have been allocated to runs, the children within the
/// runs are positioned according to the [alignment] in the main axis and
/// according to the [crossAxisAlignment] in the cross axis.
///
/// The runs themselves are then positioned in the cross axis according to the
/// [runSpacing] and [runAlignment].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=z5iw2SeFx2M}
///
/// {@tool sample}
///
/// This example renders some [Chip]s representing four contacts in a [Wrap] so
/// that they flow across lines as necessary.
///
/// ```dart
/// Wrap(
///   spacing: 8.0, // gap between adjacent chips
///   runSpacing: 4.0, // gap between lines
///   children: <Widget>[
///     Chip(
///       avatar: CircleAvatar(backgroundColor: Colors.blue.shade900, child: Text('AH')),
///       label: Text('Hamilton'),
///     ),
///     Chip(
///       avatar: CircleAvatar(backgroundColor: Colors.blue.shade900, child: Text('ML')),
///       label: Text('Lafayette'),
///     ),
///     Chip(
///       avatar: CircleAvatar(backgroundColor: Colors.blue.shade900, child: Text('HM')),
///       label: Text('Mulligan'),
///     ),
///     Chip(
///       avatar: CircleAvatar(backgroundColor: Colors.blue.shade900, child: Text('JL')),
///       label: Text('Laurens'),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Row], which places children in one line, and gives control over their
///    alignment and spacing.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
class Wrap extends MultiChildRenderObjectWidget {
  /// Creates a wrap layout.
  ///
  /// By default, the wrap layout is horizontal and both the children and the
  /// runs are aligned to the start.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to decide which direction to lay the children in or to
  /// disambiguate `start` or `end` values for the main or cross axis
  /// directions, the [textDirection] must not be null.
  Wrap({
    Key key,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.spacing = 0.0,
    this.runAlignment = WrapAlignment.start,
    this.runSpacing = 0.0,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  /// The direction to use as the main axis.
  ///
  /// For example, if [direction] is [Axis.horizontal], the default, the
  /// children are placed adjacent to one another in a horizontal run until the
  /// available horizontal space is consumed, at which point a subsequent
  /// children are placed in a new run vertically adjacent to the previous run.
  final Axis direction;

  /// How the children within a run should be placed in the main axis.
  ///
  /// For example, if [alignment] is [WrapAlignment.center], the children in
  /// each run are grouped together in the center of their run in the main axis.
  ///
  /// Defaults to [WrapAlignment.start].
  ///
  /// See also:
  ///
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  ///  * [crossAxisAlignment], which controls how the children within each run
  ///    are placed relative to each other in the cross axis.
  final WrapAlignment alignment;

  /// How much space to place between children in a run in the main axis.
  ///
  /// For example, if [spacing] is 10.0, the children will be spaced at least
  /// 10.0 logical pixels apart in the main axis.
  ///
  /// If there is additional free space in a run (e.g., because the wrap has a
  /// minimum size that is not filled or because some runs are longer than
  /// others), the additional free space will be allocated according to the
  /// [alignment].
  ///
  /// Defaults to 0.0.
  final double spacing;

  /// How the runs themselves should be placed in the cross axis.
  ///
  /// For example, if [runAlignment] is [WrapAlignment.center], the runs are
  /// grouped together in the center of the overall [Wrap] in the cross axis.
  ///
  /// Defaults to [WrapAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the children within each run are placed
  ///    relative to each other in the main axis.
  ///  * [crossAxisAlignment], which controls how the children within each run
  ///    are placed relative to each other in the cross axis.
  final WrapAlignment runAlignment;

  /// How much space to place between the runs themselves in the cross axis.
  ///
  /// For example, if [runSpacing] is 10.0, the runs will be spaced at least
  /// 10.0 logical pixels apart in the cross axis.
  ///
  /// If there is additional free space in the overall [Wrap] (e.g., because
  /// the wrap has a minimum size that is not filled), the additional free space
  /// will be allocated according to the [runAlignment].
  ///
  /// Defaults to 0.0.
  final double runSpacing;

  /// How the children within a run should be aligned relative to each other in
  /// the cross axis.
  ///
  /// For example, if this is set to [WrapCrossAlignment.end], and the
  /// [direction] is [Axis.horizontal], then the children within each
  /// run will have their bottom edges aligned to the bottom edge of the run.
  ///
  /// Defaults to [WrapCrossAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the children within each run are placed
  ///    relative to each other in the main axis.
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  final WrapCrossAlignment crossAxisAlignment;

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// Defaults to the ambient [Directionality].
  ///
  /// If the [direction] is [Axis.horizontal], this controls order in which the
  /// children are positioned (left-to-right or right-to-left), and the meaning
  /// of the [alignment] property's [WrapAlignment.start] and
  /// [WrapAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [alignment] is either [WrapAlignment.start] or [WrapAlignment.end], or
  /// there's more than one child, then the [textDirection] (or the ambient
  /// [Directionality]) must not be null.
  ///
  /// If the [direction] is [Axis.vertical], this controls the order in which
  /// runs are positioned, the meaning of the [runAlignment] property's
  /// [WrapAlignment.start] and [WrapAlignment.end] values, as well as the
  /// [crossAxisAlignment] property's [WrapCrossAlignment.start] and
  /// [WrapCrossAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the
  /// [runAlignment] is either [WrapAlignment.start] or [WrapAlignment.end], the
  /// [crossAxisAlignment] is either [WrapCrossAlignment.start] or
  /// [WrapCrossAlignment.end], or there's more than one child, then the
  /// [textDirection] (or the ambient [Directionality]) must not be null.
  final TextDirection textDirection;

  /// Determines the order to lay children out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  ///
  /// If the [direction] is [Axis.vertical], this controls which order children
  /// are painted in (down or up), the meaning of the [alignment] property's
  /// [WrapAlignment.start] and [WrapAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [alignment]
  /// is either [WrapAlignment.start] or [WrapAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// runs are positioned, the meaning of the [runAlignment] property's
  /// [WrapAlignment.start] and [WrapAlignment.end] values, as well as the
  /// [crossAxisAlignment] property's [WrapCrossAlignment.start] and
  /// [WrapCrossAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [runAlignment] is either [WrapAlignment.start] or [WrapAlignment.end], the
  /// [crossAxisAlignment] is either [WrapCrossAlignment.start] or
  /// [WrapCrossAlignment.end], or there's more than one child, then the
  /// [verticalDirection] must not be null.
  final VerticalDirection verticalDirection;

  @override
  RenderWrap createRenderObject(BuildContext context) {
    return RenderWrap(
      direction: direction,
      alignment: alignment,
      spacing: spacing,
      runAlignment: runAlignment,
      runSpacing: runSpacing,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection ?? Directionality.of(context),
      verticalDirection: verticalDirection,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderWrap renderObject) {
    renderObject
      ..direction = direction
      ..alignment = alignment
      ..spacing = spacing
      ..runAlignment = runAlignment
      ..runSpacing = runSpacing
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = textDirection ?? Directionality.of(context)
      ..verticalDirection = verticalDirection;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<WrapAlignment>('alignment', alignment));
    properties.add(DoubleProperty('spacing', spacing));
    properties.add(EnumProperty<WrapAlignment>('runAlignment', runAlignment));
    properties.add(DoubleProperty('runSpacing', runSpacing));
    properties.add(DoubleProperty('crossAxisAlignment', runSpacing));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>('verticalDirection', verticalDirection, defaultValue: VerticalDirection.down));
  }
}

/// A widget that sizes and positions children efficiently, according to the
/// logic in a [FlowDelegate].
///
/// Flow layouts are optimized for repositioning children using transformation
/// matrices.
///
/// The flow container is sized independently from the children by the
/// [FlowDelegate.getSize] function of the delegate. The children are then sized
/// independently given the constraints from the
/// [FlowDelegate.getConstraintsForChild] function.
///
/// Rather than positioning the children during layout, the children are
/// positioned using transformation matrices during the paint phase using the
/// matrices from the [FlowDelegate.paintChildren] function. The children can be
/// repositioned efficiently by simply repainting the flow, which happens
/// without the children being laid out again (contrast this with a [Stack],
/// which does the sizing and positioning together during layout).
///
/// The most efficient way to trigger a repaint of the flow is to supply an
/// animation to the constructor of the [FlowDelegate]. The flow will listen to
/// this animation and repaint whenever the animation ticks, avoiding both the
/// build and layout phases of the pipeline.
///
/// See also:
///
///  * [Wrap], which provides the layout model that some other frameworks call
///    "flow", and is otherwise unrelated to [Flow].
///  * [FlowDelegate], which controls the visual presentation of the children.
///  * [Stack], which arranges children relative to the edges of the container.
///  * [CustomSingleChildLayout], which uses a delegate to control the layout of
///    a single child.
///  * [CustomMultiChildLayout], which uses a delegate to position multiple
///    children.
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
///
///
/// {@animation 450 100 https://flutter.github.io/assets-for-api-docs/assets/widgets/flow_menu.mp4}
///
/// {@tool snippet --template=freeform}
///
/// This example uses the [Flow] widget to create a menu that opens and closes
/// as it is interacted with, shown above. The color of the button in the menu
/// changes to indicate which one has been selected.
///
/// ```dart main
/// import 'package:flutter/material.dart';
///
/// void main() => runApp(FlowApp());
///
/// class FlowApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         appBar: AppBar(
///           title: const Text('Flow Example'),
///         ),
///         body: FlowMenu(),
///       ),
///     );
///   }
/// }
///
/// class FlowMenu extends StatefulWidget {
///   @override
///   _FlowMenuState createState() => _FlowMenuState();
/// }
///
/// class _FlowMenuState extends State<FlowMenu> with SingleTickerProviderStateMixin {
///   AnimationController menuAnimation;
///   IconData lastTapped = Icons.notifications;
///   final List<IconData> menuItems = <IconData>[
///     Icons.home,
///     Icons.new_releases,
///     Icons.notifications,
///     Icons.settings,
///     Icons.menu,
///   ];
///
///   void _updateMenu(IconData icon) {
///     if (icon != Icons.menu)
///       setState(() => lastTapped = icon);
///   }
///
///   @override
///   void initState() {
///     super.initState();
///     menuAnimation = AnimationController(
///       duration: const Duration(milliseconds: 250),
///       vsync: this,
///     );
///   }
///
///   Widget flowMenuItem(IconData icon) {
///     final double buttonDiameter = MediaQuery.of(context).size.width / menuItems.length;
///     return Padding(
///       padding: const EdgeInsets.symmetric(vertical: 8.0),
///       child: RawMaterialButton(
///         fillColor: lastTapped == icon ? Colors.amber[700] : Colors.blue,
///         splashColor: Colors.amber[100],
///         shape: CircleBorder(),
///         constraints: BoxConstraints.tight(Size(buttonDiameter, buttonDiameter)),
///         onPressed: () {
///           _updateMenu(icon);
///           menuAnimation.status == AnimationStatus.completed
///             ? menuAnimation.reverse()
///             : menuAnimation.forward();
///         },
///         child: Icon(
///           icon,
///           color: Colors.white,
///           size: 45.0,
///         ),
///       ),
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Container(
///       child: Flow(
///         delegate: FlowMenuDelegate(menuAnimation: menuAnimation),
///         children: menuItems.map<Widget>((IconData icon) => flowMenuItem(icon)).toList(),
///       ),
///     );
///   }
/// }
///
/// class FlowMenuDelegate extends FlowDelegate {
///   FlowMenuDelegate({this.menuAnimation}) : super(repaint: menuAnimation);
///
///   final Animation<double> menuAnimation;
///
///   @override
///   bool shouldRepaint(FlowMenuDelegate oldDelegate) {
///     return menuAnimation != oldDelegate.menuAnimation;
///   }
///
///   @override
///   void paintChildren(FlowPaintingContext context) {
///     double dx = 0.0;
///     for (int i = 0; i < context.childCount; ++i) {
///       dx = context.getChildSize(i).width * i;
///       context.paintChild(
///         i,
///         transform: Matrix4.translationValues(
///           dx * menuAnimation.value,
///           0,
///           0,
///         ),
///       );
///     }
///   }
/// }
/// ```
/// {@end-tool}
///
class Flow extends MultiChildRenderObjectWidget {
  /// Creates a flow layout.
  ///
  /// Wraps each of the given children in a [RepaintBoundary] to avoid
  /// repainting the children when the flow repaints.
  ///
  /// The [delegate] argument must not be null.
  Flow({
    Key key,
    @required this.delegate,
    List<Widget> children = const <Widget>[],
  }) : assert(delegate != null),
       super(key: key, children: RepaintBoundary.wrapAll(children));
       // https://github.com/dart-lang/sdk/issues/29277

  /// Creates a flow layout.
  ///
  /// Does not wrap the given children in repaint boundaries, unlike the default
  /// constructor. Useful when the child is trivial to paint or already contains
  /// a repaint boundary.
  ///
  /// The [delegate] argument must not be null.
  Flow.unwrapped({
    Key key,
    @required this.delegate,
    List<Widget> children = const <Widget>[],
  }) : assert(delegate != null),
       super(key: key, children: children);

  /// The delegate that controls the transformation matrices of the children.
  final FlowDelegate delegate;

  @override
  RenderFlow createRenderObject(BuildContext context) => RenderFlow(delegate: delegate);

  @override
  void updateRenderObject(BuildContext context, RenderFlow renderObject) {
    renderObject
      ..delegate = delegate;
  }
}

/// A paragraph of rich text.
///
/// The [RichText] widget displays text that uses multiple different styles. The
/// text to display is described using a tree of [TextSpan] objects, each of
/// which has an associated style that is used for that subtree. The text might
/// break across multiple lines or might all be displayed on the same line
/// depending on the layout constraints.
///
/// Text displayed in a [RichText] widget must be explicitly styled. When
/// picking which style to use, consider using [DefaultTextStyle.of] the current
/// [BuildContext] to provide defaults. For more details on how to style text in
/// a [RichText] widget, see the documentation for [TextStyle].
///
/// Consider using the [Text] widget to integrate with the [DefaultTextStyle]
/// automatically. When all the text uses the same style, the default constructor
/// is less verbose. The [Text.rich] constructor allows you to style multiple
/// spans with the default text style while still allowing specified styles per
/// span.
///
/// {@tool sample}
///
/// ```dart
/// RichText(
///   text: TextSpan(
///     text: 'Hello ',
///     style: DefaultTextStyle.of(context).style,
///     children: <TextSpan>[
///       TextSpan(text: 'bold', style: TextStyle(fontWeight: FontWeight.bold)),
///       TextSpan(text: ' world!'),
///     ],
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [TextStyle], which discusses how to style text.
///  * [TextSpan], which is used to describe the text in a paragraph.
///  * [Text], which automatically applies the ambient styles described by a
///    [DefaultTextStyle] to a single string.
///  * [Text.rich], a const text widget that provides similar functionality
///    as [RichText]. [Text.rich] will inherit [TextStyle] from [DefaultTextStyle].
class RichText extends MultiChildRenderObjectWidget {
  /// Creates a paragraph of rich text.
  ///
  /// The [text], [textAlign], [softWrap], [overflow], and [textScaleFactor]
  /// arguments must not be null.
  ///
  /// The [maxLines] property may be null (and indeed defaults to null), but if
  /// it is not null, it must be greater than zero.
  ///
  /// The [textDirection], if null, defaults to the ambient [Directionality],
  /// which in that case must not be null.
  RichText({
    Key key,
    @required this.text,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
  }) : assert(text != null),
       assert(textAlign != null),
       assert(softWrap != null),
       assert(overflow != null),
       assert(textScaleFactor != null),
       assert(maxLines == null || maxLines > 0),
       assert(textWidthBasis != null),
       super(key: key, children: _extractChildren(text));

  // Traverses the InlineSpan tree and depth-first collects the list of
  // child widgets that are created in WidgetSpans.
  static List<Widget> _extractChildren(InlineSpan span) {
    final List<Widget> result = <Widget>[];
    span.visitChildren((InlineSpan span) {
      if (span is WidgetSpan) {
        result.add(span.child);
      }
      return true;
    });
    return result;
  }

  /// The text to display in this widget.
  final InlineSpan text;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any. If there is no ambient
  /// [Directionality], then this must not be null.
  final TextDirection textDirection;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  final int maxLines;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale locale;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle strutStyle;

  /// {@macro flutter.widgets.text.DefaultTextStyle.textWidthBasis}
  final TextWidthBasis textWidthBasis;

  @override
  RenderParagraph createRenderObject(BuildContext context) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    return RenderParagraph(text,
      textAlign: textAlign,
      textDirection: textDirection ?? Directionality.of(context),
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      locale: locale ?? Localizations.localeOf(context, nullOk: true),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderParagraph renderObject) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    renderObject
      ..text = text
      ..textAlign = textAlign
      ..textDirection = textDirection ?? Directionality.of(context)
      ..softWrap = softWrap
      ..overflow = overflow
      ..textScaleFactor = textScaleFactor
      ..maxLines = maxLines
      ..strutStyle = strutStyle
      ..textWidthBasis = textWidthBasis
      ..locale = locale ?? Localizations.localeOf(context, nullOk: true);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: TextAlign.start));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(FlagProperty('softWrap', value: softWrap, ifTrue: 'wrapping at box width', ifFalse: 'no wrapping except at line break characters', showName: true));
    properties.add(EnumProperty<TextOverflow>('overflow', overflow, defaultValue: TextOverflow.clip));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
    properties.add(IntProperty('maxLines', maxLines, ifNull: 'unlimited'));
    properties.add(EnumProperty<TextWidthBasis>('textWidthBasis', textWidthBasis, defaultValue: TextWidthBasis.parent));
    properties.add(StringProperty('text', text.toPlainText()));
  }
}

/// A widget that displays a [dart:ui.Image] directly.
///
/// The image is painted using [paintImage], which describes the meanings of the
/// various fields on this class in more detail.
///
/// This widget is rarely used directly. Instead, consider using [Image].
class RawImage extends LeafRenderObjectWidget {
  /// Creates a widget that displays an image.
  ///
  /// The [scale], [alignment], [repeat], [matchTextDirection] and [filterQuality] arguments must
  /// not be null.
  const RawImage({
    Key key,
    this.image,
    this.width,
    this.height,
    this.scale = 1.0,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
  }) : assert(scale != null),
       assert(alignment != null),
       assert(repeat != null),
       assert(matchTextDirection != null),
       super(key: key);

  /// The image to display.
  final ui.Image image;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio.
  final double height;

  /// Specifies the image's scale.
  ///
  /// Used when determining the best display size for the image.
  final double scale;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color color;

  /// Used to set the filterQuality of the image
  /// Use the "low" quality setting to scale the image, which corresponds to
  /// bilinear interpolation, rather than the default "none" which corresponds
  /// to nearest-neighbor.
  final FilterQuality filterQuality;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode colorBlendMode;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// To display a subpart of an image, consider using a [CustomPainter] and
  /// [Canvas.drawImageRect].
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect centerSlice;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with images in right-to-left environments, for
  /// images that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip images with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// Whether the colors of the image are inverted when drawn.
  ///
  /// inverting the colors of an image applies a new color filter to the paint.
  /// If there is another specified color filter, the invert will be applied
  /// after it. This is primarily used for implementing smart invert on iOS.
  ///
  /// See also:
  ///
  ///  * [Paint.invertColors], for the dart:ui implementation.
  final bool invertColors;

  @override
  RenderImage createRenderObject(BuildContext context) {
    assert((!matchTextDirection && alignment is Alignment) || debugCheckHasDirectionality(context));
    return RenderImage(
      image: image,
      width: width,
      height: height,
      scale: scale,
      color: color,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      textDirection: matchTextDirection || alignment is! Alignment ? Directionality.of(context) : null,
      invertColors: invertColors,
      filterQuality: filterQuality,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderImage renderObject) {
    renderObject
      ..image = image
      ..width = width
      ..height = height
      ..scale = scale
      ..color = color
      ..colorBlendMode = colorBlendMode
      ..alignment = alignment
      ..fit = fit
      ..repeat = repeat
      ..centerSlice = centerSlice
      ..matchTextDirection = matchTextDirection
      ..textDirection = matchTextDirection || alignment is! Alignment ? Directionality.of(context) : null
      ..invertColors = invertColors
      ..filterQuality = filterQuality;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ui.Image>('image', image));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(DoubleProperty('scale', scale, defaultValue: 1.0));
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(EnumProperty<BlendMode>('colorBlendMode', colorBlendMode, defaultValue: null));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment, defaultValue: null));
    properties.add(EnumProperty<ImageRepeat>('repeat', repeat, defaultValue: ImageRepeat.noRepeat));
    properties.add(DiagnosticsProperty<Rect>('centerSlice', centerSlice, defaultValue: null));
    properties.add(FlagProperty('matchTextDirection', value: matchTextDirection, ifTrue: 'match text direction'));
    properties.add(DiagnosticsProperty<bool>('invertColors', invertColors));
    properties.add(EnumProperty<FilterQuality>('filterQuality', filterQuality));
  }
}

/// A widget that determines the default asset bundle for its descendants.
///
/// For example, used by [Image] to determine which bundle to use for
/// [AssetImage]s if no bundle is specified explicitly.
///
/// {@tool sample}
///
/// This can be used in tests to override what the current asset bundle is, thus
/// allowing specific resources to be injected into the widget under test.
///
/// For example, a test could create a test asset bundle like this:
///
/// ```dart
/// class TestAssetBundle extends CachingAssetBundle {
///   @override
///   Future<ByteData> load(String key) async {
///     if (key == 'resources/test')
///       return ByteData.view(Uint8List.fromList(utf8.encode('Hello World!')).buffer);
///     return null;
///   }
/// }
/// ```
/// {@end-tool}
/// {@tool sample}
///
/// ...then wrap the widget under test with a [DefaultAssetBundle] using this
/// bundle implementation:
///
/// ```dart
/// await tester.pumpWidget(
///   MaterialApp(
///     home: DefaultAssetBundle(
///       bundle: TestAssetBundle(),
///       child: TestWidget(),
///     ),
///   ),
/// );
/// ```
/// {@end-tool}
///
/// Assuming that `TestWidget` uses [DefaultAssetBundle.of] to obtain its
/// [AssetBundle], it will now see the [TestAssetBundle]'s "Hello World!" data
/// when requesting the "resources/test" asset.
///
/// See also:
///
///  * [AssetBundle], the interface for asset bundles.
///  * [rootBundle], the default default asset bundle.
class DefaultAssetBundle extends InheritedWidget {
  /// Creates a widget that determines the default asset bundle for its descendants.
  ///
  /// The [bundle] and [child] arguments must not be null.
  const DefaultAssetBundle({
    Key key,
    @required this.bundle,
    @required Widget child,
  }) : assert(bundle != null),
       assert(child != null),
       super(key: key, child: child);

  /// The bundle to use as a default.
  final AssetBundle bundle;

  /// The bundle from the closest instance of this class that encloses
  /// the given context.
  ///
  /// If there is no [DefaultAssetBundle] ancestor widget in the tree
  /// at the given context, then this will return the [rootBundle].
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// AssetBundle bundle = DefaultAssetBundle.of(context);
  /// ```
  static AssetBundle of(BuildContext context) {
    final DefaultAssetBundle result = context.inheritFromWidgetOfExactType(DefaultAssetBundle);
    return result?.bundle ?? rootBundle;
  }

  @override
  bool updateShouldNotify(DefaultAssetBundle oldWidget) => bundle != oldWidget.bundle;
}

/// An adapter for placing a specific [RenderBox] in the widget tree.
///
/// A given render object can be placed at most once in the widget tree. This
/// widget enforces that restriction by keying itself using a [GlobalObjectKey]
/// for the given render object.
class WidgetToRenderBoxAdapter extends LeafRenderObjectWidget {
  /// Creates an adapter for placing a specific [RenderBox] in the widget tree.
  ///
  /// The [renderBox] argument must not be null.
  WidgetToRenderBoxAdapter({
    @required this.renderBox,
    this.onBuild,
  }) : assert(renderBox != null),
       // WidgetToRenderBoxAdapter objects are keyed to their render box. This
       // prevents the widget being used in the widget hierarchy in two different
       // places, which would cause the RenderBox to get inserted in multiple
       // places in the RenderObject tree.
       super(key: GlobalObjectKey(renderBox));

  /// The render box to place in the widget tree.
  final RenderBox renderBox;

  /// Called when it is safe to update the render box and its descendants. If
  /// you update the RenderObject subtree under this widget outside of
  /// invocations of this callback, features like hit-testing will fail as the
  /// tree will be dirty.
  final VoidCallback onBuild;

  @override
  RenderBox createRenderObject(BuildContext context) => renderBox;

  @override
  void updateRenderObject(BuildContext context, RenderBox renderObject) {
    if (onBuild != null)
      onBuild();
  }
}


// EVENT HANDLING

/// A widget that calls callbacks in response to common pointer events.
///
/// It listens to events that can construct gestures, such as when the
/// pointer is pressed, moved, then released or canceled.
///
/// It does not listen to events that are exclusive to mouse, such as when the
/// mouse enters, exits or hovers a region without pressing any buttons. For
/// these events, use [MouseRegion].
///
/// Rather than listening for raw pointer events, consider listening for
/// higher-level gestures using [GestureDetector].
///
/// ## Layout behavior
///
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// If it has a child, this widget defers to the child for sizing behavior. If
/// it does not have a child, it grows to fit the parent instead.
///
/// {@tool snippet --template=stateful_widget_scaffold}
/// This example makes a [Container] react to being touched, showing a count of
/// the number of pointer downs and ups.
///
/// ```dart imports
/// import 'package:flutter/widgets.dart';
/// ```
///
/// ```dart
/// int _downCounter = 0;
/// int _upCounter = 0;
/// double x = 0.0;
/// double y = 0.0;
///
/// void _incrementDown(PointerEvent details) {
///   _updateLocation(details);
///   setState(() {
///     _downCounter++;
///   });
/// }
/// void _incrementUp(PointerEvent details) {
///   _updateLocation(details);
///   setState(() {
///     _upCounter++;
///   });
/// }
/// void _updateLocation(PointerEvent details) {
///   setState(() {
///     x = details.position.dx;
///     y = details.position.dy;
///   });
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   return Center(
///     child: ConstrainedBox(
///       constraints: new BoxConstraints.tight(Size(300.0, 200.0)),
///       child: Listener(
///         onPointerDown: _incrementDown,
///         onPointerMove: _updateLocation,
///         onPointerUp: _incrementUp,
///         child: Container(
///           color: Colors.lightBlueAccent,
///           child: Column(
///             mainAxisAlignment: MainAxisAlignment.center,
///             children: <Widget>[
///               Text('You have pressed or released in this area this many times:'),
///               Text(
///                 '$_downCounter presses\n$_upCounter releases',
///                 style: Theme.of(context).textTheme.display1,
///               ),
///               Text(
///                 'The cursor is here: (${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})',
///               ),
///             ],
///           ),
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
class Listener extends StatelessWidget {
  /// Creates a widget that forwards point events to callbacks.
  ///
  /// The [behavior] argument defaults to [HitTestBehavior.deferToChild].
  const Listener({
    Key key,
    this.onPointerDown,
    this.onPointerMove,
    // We have to ignore the lint rule here in order to use deprecated
    // parameters and keep backward compatibility.
    // TODO(tongmu): After it goes stable, remove these 3 parameters from Listener
    // and Listener should no longer need an intermediate class _PointerListener.
    // https://github.com/flutter/flutter/issues/36085
    @Deprecated('Use MouseRegion.onEnter instead')
    this.onPointerEnter, // ignore: deprecated_member_use_from_same_package
    @Deprecated('Use MouseRegion.onExit instead')
    this.onPointerExit, // ignore: deprecated_member_use_from_same_package
    @Deprecated('Use MouseRegion.onHover instead')
    this.onPointerHover, // ignore: deprecated_member_use_from_same_package
    this.onPointerUp,
    this.onPointerCancel,
    this.onPointerSignal,
    this.behavior = HitTestBehavior.deferToChild,
    Widget child,
  }) : assert(behavior != null),
       _child = child,
       super(key: key);

  /// Called when a pointer comes into contact with the screen (for touch
  /// pointers), or has its button pressed (for mouse pointers) at this widget's
  /// location.
  final PointerDownEventListener onPointerDown;

  /// Called when a pointer that triggered an [onPointerDown] changes position.
  final PointerMoveEventListener onPointerMove;

  /// Called when a pointer enters the region for this widget.
  ///
  /// This is only fired for pointers which report their location when not down
  /// (e.g. mouse pointers, but not most touch pointers).
  ///
  /// If this is a mouse pointer, this will fire when the mouse pointer enters
  /// the region defined by this widget, or when the widget appears under the
  /// pointer.
  final PointerEnterEventListener onPointerEnter;

  /// Called when a pointer that has not triggered an [onPointerDown] changes
  /// position.
  ///
  /// This is only fired for pointers which report their location when not down
  /// (e.g. mouse pointers, but not most touch pointers).
  final PointerHoverEventListener onPointerHover;

  /// Called when a pointer leaves the region for this widget.
  ///
  /// This is only fired for pointers which report their location when not down
  /// (e.g. mouse pointers, but not most touch pointers).
  ///
  /// If this is a mouse pointer, this will fire when the mouse pointer leaves
  /// the region defined by this widget, or when the widget disappears from
  /// under the pointer.
  final PointerExitEventListener onPointerExit;

  /// Called when a pointer that triggered an [onPointerDown] is no longer in
  /// contact with the screen.
  final PointerUpEventListener onPointerUp;

  /// Called when the input from a pointer that triggered an [onPointerDown] is
  /// no longer directed towards this receiver.
  final PointerCancelEventListener onPointerCancel;

  /// Called when a pointer signal occurs over this object.
  final PointerSignalEventListener onPointerSignal;

  /// How to behave during hit testing.
  final HitTestBehavior behavior;

  // The widget listened to by the listener.
  //
  // The reason why we don't expose it is that once the deprecated methods are
  // removed, Listener will no longer need to store the child, but will pass
  // the child to `super` instead.
  final Widget _child;

  @override
  Widget build(BuildContext context) {
    Widget result = _child;
    if (onPointerEnter != null ||
        onPointerExit != null ||
        onPointerHover != null) {
      result = MouseRegion(
        onEnter: onPointerEnter,
        onExit: onPointerExit,
        onHover: onPointerHover,
        child: result,
      );
    }
    result = _PointerListener(
      onPointerDown: onPointerDown,
      onPointerUp: onPointerUp,
      onPointerMove: onPointerMove,
      onPointerCancel: onPointerCancel,
      onPointerSignal: onPointerSignal,
      behavior: behavior,
      child: result,
    );
    return result;
  }
}

class _PointerListener extends SingleChildRenderObjectWidget {
  const _PointerListener({
    Key key,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    this.onPointerSignal,
    this.behavior = HitTestBehavior.deferToChild,
    Widget child,
  }) : assert(behavior != null),
       super(key: key, child: child);

  final PointerDownEventListener onPointerDown;
  final PointerMoveEventListener onPointerMove;
  final PointerUpEventListener onPointerUp;
  final PointerCancelEventListener onPointerCancel;
  final PointerSignalEventListener onPointerSignal;
  final HitTestBehavior behavior;

  @override
  RenderPointerListener createRenderObject(BuildContext context) {
    return RenderPointerListener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      onPointerSignal: onPointerSignal,
      behavior: behavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPointerListener renderObject) {
    renderObject
      ..onPointerDown = onPointerDown
      ..onPointerMove = onPointerMove
      ..onPointerUp = onPointerUp
      ..onPointerCancel = onPointerCancel
      ..onPointerSignal = onPointerSignal
      ..behavior = behavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final List<String> listeners = <String>[];
    if (onPointerDown != null)
      listeners.add('down');
    if (onPointerMove != null)
      listeners.add('move');
    if (onPointerUp != null)
      listeners.add('up');
    if (onPointerCancel != null)
      listeners.add('cancel');
    if (onPointerSignal != null)
      listeners.add('signal');
    properties.add(IterableProperty<String>('listeners', listeners, ifEmpty: '<none>'));
    properties.add(EnumProperty<HitTestBehavior>('behavior', behavior));
  }
}

/// A widget that tracks the movement of mice, even when no button is pressed.
///
/// It does not listen to events that can construct gestures, such as when the
/// pointer is pressed, moved, then released or canceled. For these events,
/// use [Listener], or more preferably, [GestureDetector].
///
/// ## Layout behavior
///
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// If it has a child, this widget defers to the child for sizing behavior. If
/// it does not have a child, it grows to fit the parent instead.
///
/// {@tool snippet --template=stateful_widget_scaffold}
/// This example makes a [Container] react to being entered by a mouse
/// pointer, showing a count of the number of entries and exits.
///
/// ```dart imports
/// import 'package:flutter/widgets.dart';
/// ```
///
/// ```dart
/// int _enterCounter = 0;
/// int _exitCounter = 0;
/// double x = 0.0;
/// double y = 0.0;
///
/// void _incrementEnter(PointerEvent details) {
///   setState(() {
///     _enterCounter++;
///   });
/// }
/// void _incrementExit(PointerEvent details) {
///   setState(() {
///     _exitCounter++;
///   });
/// }
/// void _updateLocation(PointerEvent details) {
///   setState(() {
///     x = details.position.dx;
///     y = details.position.dy;
///   });
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   return Center(
///     child: ConstrainedBox(
///       constraints: new BoxConstraints.tight(Size(300.0, 200.0)),
///       child: MouseRegion(
///         onEnter: _incrementEnter,
///         onHover: _updateLocation,
///         onExit: _incrementExit,
///         child: Container(
///           color: Colors.lightBlueAccent,
///           child: Column(
///             mainAxisAlignment: MainAxisAlignment.center,
///             children: <Widget>[
///               Text('You have entered or exited this box this many times:'),
///               Text(
///                 '$_enterCounter Entries\n$_exitCounter Exits',
///                 style: Theme.of(context).textTheme.display1,
///               ),
///               Text(
///                 'The cursor is here: (${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})',
///               ),
///             ],
///           ),
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Listener], a similar widget that tracks pointer events when the pointer
///    have buttons pressed.
class MouseRegion extends SingleChildRenderObjectWidget {
  /// Creates a widget that forwards mouse events to callbacks.
  const MouseRegion({
    Key key,
    this.onEnter,
    this.onExit,
    this.onHover,
    Widget child,
  }) : super(key: key, child: child);

  /// Called when a mouse pointer (with or without buttons pressed) enters the
  /// region defined by this widget, or when the widget appears under the
  /// pointer.
  final PointerEnterEventListener onEnter;

  /// Called when a mouse pointer (with or without buttons pressed) changes
  /// position, and the new position is within the region defined by this widget.
  final PointerHoverEventListener onHover;

  /// Called when a mouse pointer (with or without buttons pressed) leaves the
  /// region defined by this widget, or when the widget disappears from under
  /// the pointer.
  final PointerExitEventListener onExit;

  @override
  _ListenerElement createElement() => _ListenerElement(this);

  @override
  RenderMouseRegion createRenderObject(BuildContext context) {
    return RenderMouseRegion(
      onEnter: onEnter,
      onHover: onHover,
      onExit: onExit,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMouseRegion renderObject) {
    renderObject
      ..onEnter = onEnter
      ..onHover = onHover
      ..onExit = onExit;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final List<String> listeners = <String>[];
    if (onEnter != null)
      listeners.add('enter');
    if (onExit != null)
      listeners.add('exit');
    if (onHover != null)
      listeners.add('hover');
    properties.add(IterableProperty<String>('listeners', listeners, ifEmpty: '<none>'));
  }
}

class _ListenerElement extends SingleChildRenderObjectElement {
  _ListenerElement(SingleChildRenderObjectWidget widget) : super(widget);

  @override
  void activate() {
    super.activate();
    final RenderMouseRegion renderMouseListener = renderObject;
    renderMouseListener.postActivate();
  }

  @override
  void deactivate() {
    final RenderMouseRegion renderMouseListener = renderObject;
    renderMouseListener.preDeactivate();
    super.deactivate();
  }
}

/// A widget that creates a separate display list for its child.
///
/// This widget creates a separate display list for its child, which
/// can improve performance if the subtree repaints at different times than
/// the surrounding parts of the tree.
///
/// This is useful since [RenderObject.paint] may be triggered even if its
/// associated [Widget] instances did not change or rebuild. A [RenderObject]
/// will repaint whenever any [RenderObject] that shares the same [Layer] is
/// marked as being dirty and needing paint (see [RenderObject.markNeedsPaint]),
/// such as when an ancestor scrolls or when an ancestor or descendant animates.
///
/// Containing [RenderObject.paint] to parts of the render subtree that are
/// actually visually changing using [RepaintBoundary] explicitly or implicitly
/// is therefore critical to minimizing redundant work and improving the app's
/// performance.
///
/// When a [RenderObject] is flagged as needing to paint via
/// [RenderObject.markNeedsPaint], the nearest ancestor [RenderObject] with
/// [RenderObject.isRepaintBoundary], up to possibly the root of the application,
/// is requested to repaint. That nearest ancestor's [RenderObject.paint] method
/// will cause _all_ of its descendant [RenderObject]s to repaint in the same
/// layer.
///
/// [RepaintBoundary] is therefore used, both while propagating the
/// `markNeedsPaint` flag up the render tree and while traversing down the
/// render tree via [RenderObject.paintChild], to strategically contain repaints
/// to the render subtree that visually changed for performance. This is done
/// because the [RepaintBoundary] widget creates a [RenderObject] that always
/// has a [Layer], decoupling ancestor render objects from the descendant
/// render objects.
///
/// [RepaintBoundary] has the further side-effect of possibly hinting to the
/// engine that it should further optimize animation performance if the render
/// subtree behind the [RepaintBoundary] is sufficiently complex and is static
/// while the surrounding tree changes frequently. In those cases, the engine
/// may choose to pay a one time cost of rasterizing and caching the pixel
/// values of the subtree for faster future GPU re-rendering speed.
///
/// Several framework widgets insert [RepaintBoundary] widgets to mark natural
/// separation points in applications. For instance, contents in Material Design
/// drawers typically don't change while the drawer opens and closes, so
/// repaints are automatically contained to regions inside or outside the drawer
/// when using the [Drawer] widget during transitions.
///
/// See also:
///
///  * [debugRepaintRainbowEnabled], a debugging flag to help visually monitor
///    render tree repaints in a running app.
///  * [debugProfilePaintsEnabled], a debugging flag to show render tree
///    repaints in the observatory's timeline view.
class RepaintBoundary extends SingleChildRenderObjectWidget {
  /// Creates a widget that isolates repaints.
  const RepaintBoundary({ Key key, Widget child }) : super(key: key, child: child);

  /// Wraps the given child in a [RepaintBoundary].
  ///
  /// The key for the [RepaintBoundary] is derived either from the child's key
  /// (if the child has a non-null key) or from the given `childIndex`.
  factory RepaintBoundary.wrap(Widget child, int childIndex) {
    assert(child != null);
    final Key key = child.key != null ? ValueKey<Key>(child.key) : ValueKey<int>(childIndex);
    return RepaintBoundary(key: key, child: child);
  }

  /// Wraps each of the given children in [RepaintBoundary]s.
  ///
  /// The key for each [RepaintBoundary] is derived either from the wrapped
  /// child's key (if the wrapped child has a non-null key) or from the wrapped
  /// child's index in the list.
  static List<RepaintBoundary> wrapAll(List<Widget> widgets) {
    final List<RepaintBoundary> result = List<RepaintBoundary>(widgets.length);
    for (int i = 0; i < result.length; ++i)
      result[i] = RepaintBoundary.wrap(widgets[i], i);
    return result;
  }

  @override
  RenderRepaintBoundary createRenderObject(BuildContext context) => RenderRepaintBoundary();
}

/// A widget that is invisible during hit testing.
///
/// When [ignoring] is true, this widget (and its subtree) is invisible
/// to hit testing. It still consumes space during layout and paints its child
/// as usual. It just cannot be the target of located events, because it returns
/// false from [RenderBox.hitTest].
///
/// When [ignoringSemantics] is true, the subtree will be invisible to
/// the semantics layer (and thus e.g. accessibility tools). If
/// [ignoringSemantics] is null, it uses the value of [ignoring].
///
/// See also:
///
///  * [AbsorbPointer], which also prevents its children from receiving pointer
///    events but is itself visible to hit testing.
class IgnorePointer extends SingleChildRenderObjectWidget {
  /// Creates a widget that is invisible to hit testing.
  ///
  /// The [ignoring] argument must not be null. If [ignoringSemantics], this
  /// render object will be ignored for semantics if [ignoring] is true.
  const IgnorePointer({
    Key key,
    this.ignoring = true,
    this.ignoringSemantics,
    Widget child,
  }) : assert(ignoring != null),
       super(key: key, child: child);

  /// Whether this widget is ignored during hit testing.
  ///
  /// Regardless of whether this widget is ignored during hit testing, it will
  /// still consume space during layout and be visible during painting.
  final bool ignoring;

  /// Whether the semantics of this widget is ignored when compiling the semantics tree.
  ///
  /// If null, defaults to value of [ignoring].
  ///
  /// See [SemanticsNode] for additional information about the semantics tree.
  final bool ignoringSemantics;

  @override
  RenderIgnorePointer createRenderObject(BuildContext context) {
    return RenderIgnorePointer(
      ignoring: ignoring,
      ignoringSemantics: ignoringSemantics,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderIgnorePointer renderObject) {
    renderObject
      ..ignoring = ignoring
      ..ignoringSemantics = ignoringSemantics;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('ignoring', ignoring));
    properties.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics, defaultValue: null));
  }
}

/// A widget that absorbs pointers during hit testing.
///
/// When [absorbing] is true, this widget prevents its subtree from receiving
/// pointer events by terminating hit testing at itself. It still consumes space
/// during layout and paints its child as usual. It just prevents its children
/// from being the target of located events, because it returns true from
/// [RenderBox.hitTest].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=65HoWqBboI8}
///
/// See also:
///
///  * [IgnorePointer], which also prevents its children from receiving pointer
///    events but is itself invisible to hit testing.
class AbsorbPointer extends SingleChildRenderObjectWidget {
  /// Creates a widget that absorbs pointers during hit testing.
  ///
  /// The [absorbing] argument must not be null
  const AbsorbPointer({
    Key key,
    this.absorbing = true,
    Widget child,
    this.ignoringSemantics,
  }) : assert(absorbing != null),
       super(key: key, child: child);

  /// Whether this widget absorbs pointers during hit testing.
  ///
  /// Regardless of whether this render object absorbs pointers during hit
  /// testing, it will still consume space during layout and be visible during
  /// painting.
  final bool absorbing;

  /// Whether the semantics of this render object is ignored when compiling the
  /// semantics tree.
  ///
  /// If null, defaults to the value of [absorbing].
  ///
  /// See [SemanticsNode] for additional information about the semantics tree.
  final bool ignoringSemantics;

  @override
  RenderAbsorbPointer createRenderObject(BuildContext context) {
    return RenderAbsorbPointer(
      absorbing: absorbing,
      ignoringSemantics: ignoringSemantics,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderAbsorbPointer renderObject) {
    renderObject
      ..absorbing = absorbing
      ..ignoringSemantics = ignoringSemantics;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
    properties.add(DiagnosticsProperty<bool>('ignoringSemantics', ignoringSemantics, defaultValue: null));
  }
}

/// Holds opaque meta data in the render tree.
///
/// Useful for decorating the render tree with information that will be consumed
/// later. For example, you could store information in the render tree that will
/// be used when the user interacts with the render tree but has no visual
/// impact prior to the interaction.
class MetaData extends SingleChildRenderObjectWidget {
  /// Creates a widget that hold opaque meta data.
  ///
  /// The [behavior] argument defaults to [HitTestBehavior.deferToChild].
  const MetaData({
    Key key,
    this.metaData,
    this.behavior = HitTestBehavior.deferToChild,
    Widget child,
  }) : super(key: key, child: child);

  /// Opaque meta data ignored by the render tree
  final dynamic metaData;

  /// How to behave during hit testing.
  final HitTestBehavior behavior;

  @override
  RenderMetaData createRenderObject(BuildContext context) {
    return RenderMetaData(
      metaData: metaData,
      behavior: behavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMetaData renderObject) {
    renderObject
      ..metaData = metaData
      ..behavior = behavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HitTestBehavior>('behavior', behavior));
    properties.add(DiagnosticsProperty<dynamic>('metaData', metaData));
  }
}


// UTILITY NODES

/// A widget that annotates the widget tree with a description of the meaning of
/// the widgets.
///
/// Used by accessibility tools, search engines, and other semantic analysis
/// software to determine the meaning of the application.
///
/// See also:
///
///  * [MergeSemantics], which marks a subtree as being a single node for
///    accessibility purposes.
///  * [ExcludeSemantics], which excludes a subtree from the semantics tree
///    (which might be useful if it is, e.g., totally decorative and not
///    important to the user).
///  * [RenderObject.semanticsAnnotator], the rendering library API through which
///    the [Semantics] widget is actually implemented.
///  * [SemanticsNode], the object used by the rendering library to represent
///    semantics in the semantics tree.
///  * [SemanticsDebugger], an overlay to help visualize the semantics tree. Can
///    be enabled using [WidgetsApp.showSemanticsDebugger] or
///    [MaterialApp.showSemanticsDebugger].
@immutable
class Semantics extends SingleChildRenderObjectWidget {
  /// Creates a semantic annotation.
  ///
  /// The [container] argument must not be null. To create a `const` instance
  /// of [Semantics], use the [Semantics.fromProperties] constructor.
  ///
  /// See also:
  ///
  ///  * [SemanticsSortKey] for a class that determines accessibility traversal
  ///    order.
  Semantics({
    Key key,
    Widget child,
    bool container = false,
    bool explicitChildNodes = false,
    bool excludeSemantics = false,
    bool enabled,
    bool checked,
    bool selected,
    bool toggled,
    bool button,
    bool header,
    bool textField,
    bool readOnly,
    bool focused,
    bool inMutuallyExclusiveGroup,
    bool obscured,
    bool multiline,
    bool scopesRoute,
    bool namesRoute,
    bool hidden,
    bool image,
    bool liveRegion,
    String label,
    String value,
    String increasedValue,
    String decreasedValue,
    String hint,
    String onTapHint,
    String onLongPressHint,
    TextDirection textDirection,
    SemanticsSortKey sortKey,
    VoidCallback onTap,
    VoidCallback onLongPress,
    VoidCallback onScrollLeft,
    VoidCallback onScrollRight,
    VoidCallback onScrollUp,
    VoidCallback onScrollDown,
    VoidCallback onIncrease,
    VoidCallback onDecrease,
    VoidCallback onCopy,
    VoidCallback onCut,
    VoidCallback onPaste,
    VoidCallback onDismiss,
    MoveCursorHandler onMoveCursorForwardByCharacter,
    MoveCursorHandler onMoveCursorBackwardByCharacter,
    SetSelectionHandler onSetSelection,
    VoidCallback onDidGainAccessibilityFocus,
    VoidCallback onDidLoseAccessibilityFocus,
    Map<CustomSemanticsAction, VoidCallback> customSemanticsActions,
  }) : this.fromProperties(
    key: key,
    child: child,
    container: container,
    explicitChildNodes: explicitChildNodes,
    excludeSemantics: excludeSemantics,
    properties: SemanticsProperties(
      enabled: enabled,
      checked: checked,
      toggled: toggled,
      selected: selected,
      button: button,
      header: header,
      textField: textField,
      readOnly: readOnly,
      focused: focused,
      inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
      obscured: obscured,
      multiline: multiline,
      scopesRoute: scopesRoute,
      namesRoute: namesRoute,
      hidden: hidden,
      image: image,
      liveRegion: liveRegion,
      label: label,
      value: value,
      increasedValue: increasedValue,
      decreasedValue: decreasedValue,
      hint: hint,
      textDirection: textDirection,
      sortKey: sortKey,
      onTap: onTap,
      onLongPress: onLongPress,
      onScrollLeft: onScrollLeft,
      onScrollRight: onScrollRight,
      onScrollUp: onScrollUp,
      onScrollDown: onScrollDown,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      onCopy: onCopy,
      onCut: onCut,
      onPaste: onPaste,
      onMoveCursorForwardByCharacter: onMoveCursorForwardByCharacter,
      onMoveCursorBackwardByCharacter: onMoveCursorBackwardByCharacter,
      onDidGainAccessibilityFocus: onDidGainAccessibilityFocus,
      onDidLoseAccessibilityFocus: onDidLoseAccessibilityFocus,
      onDismiss: onDismiss,
      onSetSelection: onSetSelection,
      customSemanticsActions: customSemanticsActions,
      hintOverrides: onTapHint != null || onLongPressHint != null ?
        SemanticsHintOverrides(
          onTapHint: onTapHint,
          onLongPressHint: onLongPressHint,
        ) : null,
    ),
  );

  /// Creates a semantic annotation using [SemanticsProperties].
  ///
  /// The [container] and [properties] arguments must not be null.
  const Semantics.fromProperties({
    Key key,
    Widget child,
    this.container = false,
    this.explicitChildNodes = false,
    this.excludeSemantics = false,
    @required this.properties,
  }) : assert(container != null),
       assert(properties != null),
       super(key: key, child: child);

  /// Contains properties used by assistive technologies to make the application
  /// more accessible.
  final SemanticsProperties properties;

  /// If [container] is true, this widget will introduce a new
  /// node in the semantics tree. Otherwise, the semantics will be
  /// merged with the semantics of any ancestors (if the ancestor allows that).
  ///
  /// Whether descendants of this widget can add their semantic information to the
  /// [SemanticsNode] introduced by this configuration is controlled by
  /// [explicitChildNodes].
  final bool container;

  /// Whether descendants of this widget are allowed to add semantic information
  /// to the [SemanticsNode] annotated by this widget.
  ///
  /// When set to false descendants are allowed to annotate [SemanticNode]s of
  /// their parent with the semantic information they want to contribute to the
  /// semantic tree.
  /// When set to true the only way for descendants to contribute semantic
  /// information to the semantic tree is to introduce new explicit
  /// [SemanticNode]s to the tree.
  ///
  /// If the semantics properties of this node include
  /// [SemanticsProperties.scopesRoute] set to true, then [explicitChildNodes]
  /// must be true also.
  ///
  /// This setting is often used in combination with [SemanticsConfiguration.isSemanticBoundary]
  /// to create semantic boundaries that are either writable or not for children.
  final bool explicitChildNodes;

  /// Whether to replace all child semantics with this node.
  ///
  /// Defaults to false.
  ///
  /// When this flag is set to true, all child semantics nodes are ignored.
  /// This can be used as a convenience for cases where a child is wrapped in
  /// an [ExcludeSemantics] widget and then another [Semantics] widget.
  final bool excludeSemantics;

  @override
  RenderSemanticsAnnotations createRenderObject(BuildContext context) {
    return RenderSemanticsAnnotations(
      container: container,
      explicitChildNodes: explicitChildNodes,
      excludeSemantics: excludeSemantics,
      enabled: properties.enabled,
      checked: properties.checked,
      toggled: properties.toggled,
      selected: properties.selected,
      button: properties.button,
      header: properties.header,
      textField: properties.textField,
      readOnly: properties.readOnly,
      focused: properties.focused,
      liveRegion: properties.liveRegion,
      inMutuallyExclusiveGroup: properties.inMutuallyExclusiveGroup,
      obscured: properties.obscured,
      multiline: properties.multiline,
      scopesRoute: properties.scopesRoute,
      namesRoute: properties.namesRoute,
      hidden: properties.hidden,
      image: properties.image,
      label: properties.label,
      value: properties.value,
      increasedValue: properties.increasedValue,
      decreasedValue: properties.decreasedValue,
      hint: properties.hint,
      hintOverrides: properties.hintOverrides,
      textDirection: _getTextDirection(context),
      sortKey: properties.sortKey,
      onTap: properties.onTap,
      onLongPress: properties.onLongPress,
      onScrollLeft: properties.onScrollLeft,
      onScrollRight: properties.onScrollRight,
      onScrollUp: properties.onScrollUp,
      onScrollDown: properties.onScrollDown,
      onIncrease: properties.onIncrease,
      onDecrease: properties.onDecrease,
      onCopy: properties.onCopy,
      onDismiss: properties.onDismiss,
      onCut: properties.onCut,
      onPaste: properties.onPaste,
      onMoveCursorForwardByCharacter: properties.onMoveCursorForwardByCharacter,
      onMoveCursorBackwardByCharacter: properties.onMoveCursorBackwardByCharacter,
      onMoveCursorForwardByWord: properties.onMoveCursorForwardByWord,
      onMoveCursorBackwardByWord: properties.onMoveCursorBackwardByWord,
      onSetSelection: properties.onSetSelection,
      onDidGainAccessibilityFocus: properties.onDidGainAccessibilityFocus,
      onDidLoseAccessibilityFocus: properties.onDidLoseAccessibilityFocus,
      customSemanticsActions: properties.customSemanticsActions,
    );
  }

  TextDirection _getTextDirection(BuildContext context) {
    if (properties.textDirection != null)
      return properties.textDirection;

    final bool containsText = properties.label != null || properties.value != null || properties.hint != null;

    if (!containsText)
      return null;

    return Directionality.of(context);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSemanticsAnnotations renderObject) {
    renderObject
      ..container = container
      ..explicitChildNodes = explicitChildNodes
      ..excludeSemantics = excludeSemantics
      ..scopesRoute = properties.scopesRoute
      ..enabled = properties.enabled
      ..checked = properties.checked
      ..toggled = properties.toggled
      ..selected = properties.selected
      ..button = properties.button
      ..header = properties.header
      ..textField = properties.textField
      ..readOnly = properties.readOnly
      ..focused = properties.focused
      ..inMutuallyExclusiveGroup = properties.inMutuallyExclusiveGroup
      ..obscured = properties.obscured
      ..multiline = properties.multiline
      ..hidden = properties.hidden
      ..image = properties.image
      ..liveRegion = properties.liveRegion
      ..label = properties.label
      ..value = properties.value
      ..increasedValue = properties.increasedValue
      ..decreasedValue = properties.decreasedValue
      ..hint = properties.hint
      ..hintOverrides = properties.hintOverrides
      ..namesRoute = properties.namesRoute
      ..textDirection = _getTextDirection(context)
      ..sortKey = properties.sortKey
      ..onTap = properties.onTap
      ..onLongPress = properties.onLongPress
      ..onScrollLeft = properties.onScrollLeft
      ..onScrollRight = properties.onScrollRight
      ..onScrollUp = properties.onScrollUp
      ..onScrollDown = properties.onScrollDown
      ..onIncrease = properties.onIncrease
      ..onDismiss = properties.onDismiss
      ..onDecrease = properties.onDecrease
      ..onCopy = properties.onCopy
      ..onCut = properties.onCut
      ..onPaste = properties.onPaste
      ..onMoveCursorForwardByCharacter = properties.onMoveCursorForwardByCharacter
      ..onMoveCursorBackwardByCharacter = properties.onMoveCursorForwardByCharacter
      ..onMoveCursorForwardByWord = properties.onMoveCursorForwardByWord
      ..onMoveCursorBackwardByWord = properties.onMoveCursorBackwardByWord
      ..onSetSelection = properties.onSetSelection
      ..onDidGainAccessibilityFocus = properties.onDidGainAccessibilityFocus
      ..onDidLoseAccessibilityFocus = properties.onDidLoseAccessibilityFocus
      ..customSemanticsActions = properties.customSemanticsActions;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('container', container));
    properties.add(DiagnosticsProperty<SemanticsProperties>('properties', this.properties));
    this.properties.debugFillProperties(properties);
  }
}

/// A widget that merges the semantics of its descendants.
///
/// Causes all the semantics of the subtree rooted at this node to be
/// merged into one node in the semantics tree. For example, if you
/// have a widget with a Text node next to a checkbox widget, this
/// could be used to merge the label from the Text node with the
/// "checked" semantic state of the checkbox into a single node that
/// had both the label and the checked state. Otherwise, the label
/// would be presented as a separate feature than the checkbox, and
/// the user would not be able to be sure that they were related.
///
/// Be aware that if two nodes in the subtree have conflicting
/// semantics, the result may be nonsensical. For example, a subtree
/// with a checked checkbox and an unchecked checkbox will be
/// presented as checked. All the labels will be merged into a single
/// string (with newlines separating each label from the other). If
/// multiple nodes in the merged subtree can handle semantic gestures,
/// the first one in tree order will be the one to receive the
/// callbacks.
class MergeSemantics extends SingleChildRenderObjectWidget {
  /// Creates a widget that merges the semantics of its descendants.
  const MergeSemantics({ Key key, Widget child }) : super(key: key, child: child);

  @override
  RenderMergeSemantics createRenderObject(BuildContext context) => RenderMergeSemantics();
}

/// A widget that drops the semantics of all widget that were painted before it
/// in the same semantic container.
///
/// This is useful to hide widgets from accessibility tools that are painted
/// behind a certain widget, e.g. an alert should usually disallow interaction
/// with any widget located "behind" the alert (even when they are still
/// partially visible). Similarly, an open [Drawer] blocks interactions with
/// any widget outside the drawer.
///
/// See also:
///
///  * [ExcludeSemantics] which drops all semantics of its descendants.
class BlockSemantics extends SingleChildRenderObjectWidget {
  /// Creates a widget that excludes the semantics of all widgets painted before
  /// it in the same semantic container.
  const BlockSemantics({ Key key, this.blocking = true, Widget child }) : super(key: key, child: child);

  /// Whether this widget is blocking semantics of all widget that were painted
  /// before it in the same semantic container.
  final bool blocking;

  @override
  RenderBlockSemantics createRenderObject(BuildContext context) => RenderBlockSemantics(blocking: blocking);

  @override
  void updateRenderObject(BuildContext context, RenderBlockSemantics renderObject) {
    renderObject.blocking = blocking;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('blocking', blocking));
  }
}

/// A widget that drops all the semantics of its descendants.
///
/// When [excluding] is true, this widget (and its subtree) is excluded from
/// the semantics tree.
///
/// This can be used to hide descendant widgets that would otherwise be
/// reported but that would only be confusing. For example, the
/// material library's [Chip] widget hides the avatar since it is
/// redundant with the chip label.
///
/// See also:
///
///  * [BlockSemantics] which drops semantics of widgets earlier in the tree.
class ExcludeSemantics extends SingleChildRenderObjectWidget {
  /// Creates a widget that drops all the semantics of its descendants.
  const ExcludeSemantics({
    Key key,
    this.excluding = true,
    Widget child,
  }) : assert(excluding != null),
       super(key: key, child: child);

  /// Whether this widget is excluded in the semantics tree.
  final bool excluding;

  @override
  RenderExcludeSemantics createRenderObject(BuildContext context) => RenderExcludeSemantics(excluding: excluding);

  @override
  void updateRenderObject(BuildContext context, RenderExcludeSemantics renderObject) {
    renderObject.excluding = excluding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('excluding', excluding));
  }
}

/// A widget that annotates the child semantics with an index.
///
/// Semantic indexes are used by TalkBack/Voiceover to make announcements about
/// the current scroll state. Certain widgets like the [ListView] will
/// automatically provide a child index for building semantics. A user may wish
/// to manually provide semantic indexes if not all child of the scrollable
/// contribute semantics.
///
/// {@tool sample}
///
/// The example below handles spacers in a scrollable that don't contribute
/// semantics. The automatic indexes would give the spaces a semantic index,
/// causing scroll announcements to erroneously state that there are four items
/// visible.
///
/// ```dart
/// ListView(
///   addSemanticIndexes: false,
///   semanticChildCount: 2,
///   children: const <Widget>[
///     IndexedSemantics(index: 0, child: Text('First')),
///     Spacer(),
///     IndexedSemantics(index: 1, child: Text('Second')),
///     Spacer(),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [CustomScrollView], for an explanation of index semantics.
class IndexedSemantics extends SingleChildRenderObjectWidget {
  /// Creates a widget that annotated the first child semantics node with an index.
  ///
  /// [index] must not be null.
  const IndexedSemantics({
    Key key,
    @required this.index,
    Widget child,
  }) : assert(index != null),
       super(key: key, child: child);

  /// The index used to annotate the first child semantics node.
  final int index;

  @override
  RenderIndexedSemantics createRenderObject(BuildContext context) => RenderIndexedSemantics(index: index);

  @override
  void updateRenderObject(BuildContext context, RenderIndexedSemantics renderObject) {
    renderObject.index = index;
  }
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<int>('index', index));
  }
}

/// A widget that builds its child.
///
/// Useful for attaching a key to an existing widget.
class KeyedSubtree extends StatelessWidget {
  /// Creates a widget that builds its child.
  const KeyedSubtree({
    Key key,
    @required this.child,
  }) : assert(child != null),
       super(key: key);

  /// Creates a KeyedSubtree for child with a key that's based on the child's existing key or childIndex.
  factory KeyedSubtree.wrap(Widget child, int childIndex) {
    final Key key = child.key != null ? ValueKey<Key>(child.key) : ValueKey<int>(childIndex);
    return KeyedSubtree(key: key, child: child);
  }

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Wrap each item in a KeyedSubtree whose key is based on the item's existing key or
  /// the sum of its list index and `baseIndex`.
  static List<Widget> ensureUniqueKeysForList(Iterable<Widget> items, { int baseIndex = 0 }) {
    if (items == null || items.isEmpty)
      return items;

    final List<Widget> itemsWithUniqueKeys = <Widget>[];
    int itemIndex = baseIndex;
    for (Widget item in items) {
      itemsWithUniqueKeys.add(KeyedSubtree.wrap(item, itemIndex));
      itemIndex += 1;
    }

    assert(!debugItemsHaveDuplicateKeys(itemsWithUniqueKeys));
    return itemsWithUniqueKeys;
  }

  @override
  Widget build(BuildContext context) => child;
}

/// A platonic widget that calls a closure to obtain its child widget.
///
/// See also:
///
///  * [StatefulBuilder], a platonic widget which also has state.
class Builder extends StatelessWidget {
  /// Creates a widget that delegates its build to a callback.
  ///
  /// The [builder] argument must not be null.
  const Builder({
    Key key,
    @required this.builder,
  }) : assert(builder != null),
       super(key: key);

  /// Called to obtain the child widget.
  ///
  /// This function is called whenever this widget is included in its parent's
  /// build and the old widget (if any) that it synchronizes with has a distinct
  /// object identity. Typically the parent's build method will construct
  /// a new tree of widgets and so a new Builder child will not be [identical]
  /// to the corresponding old one.
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => builder(context);
}

/// Signature for the builder callback used by [StatefulBuilder].
///
/// Call [setState] to schedule the [StatefulBuilder] to rebuild.
typedef StatefulWidgetBuilder = Widget Function(BuildContext context, StateSetter setState);

/// A platonic widget that both has state and calls a closure to obtain its child widget.
///
/// The [StateSetter] function passed to the [builder] is used to invoke a
/// rebuild instead of a typical [State]'s [State.setState].
///
/// Since the [builder] is re-invoked when the [StateSetter] is called, any
/// variables that represents state should be kept outside the [builder] function.
///
/// {@tool sample}
///
/// This example shows using an inline StatefulBuilder that rebuilds and that
/// also has state.
///
/// ```dart
/// await showDialog<void>(
///   context: context,
///   builder: (BuildContext context) {
///     int selectedRadio = 0;
///     return AlertDialog(
///       content: StatefulBuilder(
///         builder: (BuildContext context, StateSetter setState) {
///           return Column(
///             mainAxisSize: MainAxisSize.min,
///             children: List<Widget>.generate(4, (int index) {
///               return Radio<int>(
///                 value: index,
///                 groupValue: selectedRadio,
///                 onChanged: (int value) {
///                   setState(() => selectedRadio = value);
///                 },
///               );
///             }),
///           );
///         },
///       ),
///     );
///   },
/// );
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Builder], the platonic stateless widget.
class StatefulBuilder extends StatefulWidget {
  /// Creates a widget that both has state and delegates its build to a callback.
  ///
  /// The [builder] argument must not be null.
  const StatefulBuilder({
    Key key,
    @required this.builder,
  }) : assert(builder != null),
       super(key: key);

  /// Called to obtain the child widget.
  ///
  /// This function is called whenever this widget is included in its parent's
  /// build and the old widget (if any) that it synchronizes with has a distinct
  /// object identity. Typically the parent's build method will construct
  /// a new tree of widgets and so a new Builder child will not be [identical]
  /// to the corresponding old one.
  final StatefulWidgetBuilder builder;

  @override
  _StatefulBuilderState createState() => _StatefulBuilderState();
}

class _StatefulBuilderState extends State<StatefulBuilder> {
  @override
  Widget build(BuildContext context) => widget.builder(context, setState);
}
