// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';

import 'constants.dart';
import 'shadows.dart';
import 'theme.dart';

/// Signature for callback used by ink effects to obtain the rectangle for the effect.
typedef Rect RectCallback();

/// The various kinds of material in material design. Used to
/// configure the default behavior of [Material] widgets.
///
/// See also:
///
///  * [Material], in particular [Material.type]
///  * [kMaterialEdges]
enum MaterialType {
  /// Infinite extent using default theme canvas color.
  canvas,

  /// Rounded edges, card theme color.
  card,

  /// A circle, no color by default (used for floating action buttons).
  circle,

  /// Rounded edges, no color by default (used for [MaterialButton] buttons).
  button,

  /// A transparent piece of material that draws ink splashes and highlights.
  transparency
}

/// The border radii used by the various kinds of material in material design.
///
/// See also:
///
///  * [MaterialType]
///  * [Material]
final Map<MaterialType, BorderRadius> kMaterialEdges = <MaterialType, BorderRadius> {
  MaterialType.canvas: null,
  MaterialType.card: new BorderRadius.circular(2.0),
  MaterialType.circle: null,
  MaterialType.button: new BorderRadius.circular(2.0),
  MaterialType.transparency: null,
};

/// A visual reaction on a piece of [Material] to user input.
///
/// Typically created by [MaterialInkController.splashAt].
abstract class InkSplash {
  /// The user input is confirmed.
  ///
  /// Causes the reaction to propagate faster across the material.
  void confirm();

  /// The user input was canceled.
  ///
  /// Causes the reaction to gradually disappear.
  void cancel();

  /// Free up the resources associated with this reaction.
  void dispose();

  /// The default radius of an ink splash in logical pixels.
  static const double defaultRadius = 35.0;
}

/// A visual emphasis on a part of a [Material] receiving user interaction.
///
/// Typically created by [MaterialInkController.highlightAt].
abstract class InkHighlight {
  /// Start visually emphasizing this part of the material.
  void activate();

  /// Stop visually emphasizing this part of the material.
  void deactivate();

  /// Free up the resources associated with this highlight.
  void dispose();

  /// Whether this part of the material is being visually emphasized.
  bool get active;

  /// The color of the ink used to emphasize part of the material.
  Color get color;
  set color(Color value);
}

/// An interface for creating [InkSplash]s and [InkHighlight]s on a material.
///
/// Typically obtained via [Material.of].
abstract class MaterialInkController {
  /// The color of the material.
  Color get color;

  /// Begin a splash, centered at position relative to referenceBox.
  ///
  /// If containedInkWell is true, then the splash will be sized to fit
  /// the well rectangle, then clipped to it when drawn. The well
  /// rectangle is the box returned by rectCallback, if provided, or
  /// otherwise is the bounds of the referenceBox.
  ///
  /// If containedInkWell is false, then rectCallback should be null.
  /// The ink splash is clipped only to the edges of the [Material].
  /// This is the default.
  ///
  /// When the splash is removed, onRemoved will be called.
  InkSplash splashAt({
    RenderBox referenceBox,
    Point position,
    Color color,
    bool containedInkWell: false,
    RectCallback rectCallback,
    VoidCallback onRemoved,
    double radius,
  });

  /// Begin a highlight animation. If a rectCallback is given, then it
  /// provides the highlight rectangle, otherwise, the highlight
  /// rectangle is coincident with the referenceBox.
  InkHighlight highlightAt({
    RenderBox referenceBox,
    Color color,
    BoxShape shape: BoxShape.rectangle,
    RectCallback rectCallback,
    VoidCallback onRemoved
  });

  /// Add an arbitrary InkFeature to this InkController.
  void addInkFeature(InkFeature feature);
}

/// A piece of material.
///
/// Material is the central metaphor in material design. Each piece of material
/// exists at a given elevation, which influences how that piece of material
/// visually relates to other pieces of material and how that material casts
/// shadows on other pieces of material.
///
/// Most user interface elements are either conceptually printed on a piece of
/// material or themselves made of material. Material reacts to user input using
/// [InkSplash] and [InkHighlight] effects. To trigger a reaction on the
/// material, use a [MaterialInkController] obtained via [Material.of].
///
/// If the layout changes (e.g. because there's a list on the paper, and it's
/// been scrolled), a LayoutChangedNotification must be dispatched at the
/// relevant subtree. (This in particular means that Transitions should not be
/// placed inside Material.) Otherwise, in-progress ink features (e.g., ink
/// splashes and ink highlights) won't move to account for the new layout.
///
/// See also:
///
/// * <https://www.google.com/design/spec/material-design/introduction.html>
class Material extends StatefulWidget {
  /// Creates a piece of material.
  ///
  /// The [type] and the [elevation] arguments must not be null.
  Material({
    Key key,
    this.type: MaterialType.canvas,
    this.elevation: 0,
    this.color,
    this.textStyle,
    this.child
  }) : super(key: key) {
    assert(type != null);
    assert(elevation != null);
  }

  /// The widget below this widget in the tree.
  final Widget child;

  /// The kind of material to show (e.g., card or canvas). This
  /// affects the shape of the widget, the roundness of its corners if
  /// the shape is rectangular, and the default color.
  final MaterialType type;

  /// The z-coordinate at which to place this material.
  ///
  /// The following elevations have defined shadows: 1, 2, 3, 4, 6, 8, 9, 12, 16, 24
  final int elevation;

  /// The color to paint the material.
  ///
  /// Must be opaque. To create a transparent piece of material, use
  /// [MaterialType.transparency].
  ///
  /// By default, the color is derived from the [type] of material.
  final Color color;

  /// The typographical style to use for text within this material.
  final TextStyle textStyle;

  /// The ink controller from the closest instance of this class that
  /// encloses the given context.
  static MaterialInkController of(BuildContext context) {
    final _RenderInkFeatures result = context.ancestorRenderObjectOfType(const TypeMatcher<_RenderInkFeatures>());
    return result;
  }

  @override
  _MaterialState createState() => new _MaterialState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$type');
    description.add('elevation: $elevation');
    if (color != null)
      description.add('color: $color');
  }
}

class _MaterialState extends State<Material> with TickerProviderStateMixin {
  final GlobalKey _inkFeatureRenderer = new GlobalKey(debugLabel: 'ink renderer');

  Color _getBackgroundColor(BuildContext context) {
    if (config.color != null)
      return config.color;
    switch (config.type) {
      case MaterialType.canvas:
        return Theme.of(context).canvasColor;
      case MaterialType.card:
        return Theme.of(context).cardColor;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = _getBackgroundColor(context);
    Widget contents = config.child;
    if (contents != null) {
      contents = new AnimatedDefaultTextStyle(
        style: config.textStyle ?? Theme.of(context).textTheme.body1,
        duration: kThemeChangeDuration,
        child: contents
      );
    }
    contents = new NotificationListener<LayoutChangedNotification>(
      onNotification: (LayoutChangedNotification notification) {
        _inkFeatureRenderer.currentContext.findRenderObject().markNeedsPaint();
        return true;
      },
      child: new _InkFeatures(
        key: _inkFeatureRenderer,
        color: backgroundColor,
        child: contents,
        vsync: this,
      )
    );
    if (config.type == MaterialType.circle) {
      contents = new ClipOval(child: contents);
    } else if (kMaterialEdges[config.type] != null) {
      contents = new ClipRRect(
        borderRadius: kMaterialEdges[config.type],
        child: contents
      );
    }
    if (config.type != MaterialType.transparency) {
      contents = new AnimatedContainer(
        curve: Curves.fastOutSlowIn,
        duration: kThemeChangeDuration,
        decoration: new BoxDecoration(
          borderRadius: kMaterialEdges[config.type],
          boxShadow: config.elevation == 0 ? null : kElevationToShadow[config.elevation],
          shape: config.type == MaterialType.circle ? BoxShape.circle : BoxShape.rectangle
        ),
        child: new Container(
          decoration: new BoxDecoration(
            borderRadius: kMaterialEdges[config.type],
            backgroundColor: backgroundColor,
            shape: config.type == MaterialType.circle ? BoxShape.circle : BoxShape.rectangle
          ),
          child: contents
        )
      );
    }
    return contents;
  }
}

const Duration _kHighlightFadeDuration = const Duration(milliseconds: 200);
const Duration _kUnconfirmedSplashDuration = const Duration(seconds: 1);

const double _kSplashConfirmedVelocity = 1.0; // logical pixels per millisecond
const double _kSplashInitialSize = 0.0; // logical pixels

class _RenderInkFeatures extends RenderProxyBox implements MaterialInkController {
  _RenderInkFeatures({ RenderBox child, @required this.vsync, this.color }) : super(child) {
    assert(vsync != null);
  }

  // This class should exist in a 1:1 relationship with a MaterialState object,
  // since there's no current support for dynamically changing the ticker
  // provider.
  final TickerProvider vsync;

  // This is here to satisfy the MaterialInkController contract.
  // The actual painting of this color is done by a Container in the
  // MaterialState build method.
  @override
  Color color;

  final List<InkFeature> _inkFeatures = <InkFeature>[];

  @override
  InkSplash splashAt({
    RenderBox referenceBox,
    Point position,
    Color color,
    bool containedInkWell: false,
    RectCallback rectCallback,
    VoidCallback onRemoved,
    double radius,
  }) {
    RectCallback clipCallback;
    if (containedInkWell) {
      Size size;
      if (rectCallback != null) {
        size = rectCallback().size;
        clipCallback = rectCallback;
      } else {
        size = referenceBox.size;
        clipCallback = () => Point.origin & referenceBox.size;
      }
      radius ??= _getSplashTargetSize(size, position);
    } else {
      assert(rectCallback == null);
      radius ??= InkSplash.defaultRadius;
    }
    _InkSplash splash = new _InkSplash(
      controller: this,
      referenceBox: referenceBox,
      position: position,
      color: color,
      targetRadius: radius,
      clipCallback: clipCallback,
      repositionToReferenceBox: !containedInkWell,
      onRemoved: onRemoved,
      vsync: vsync,
    );
    addInkFeature(splash);
    return splash;
  }

  double _getSplashTargetSize(Size bounds, Point position) {
    double d1 = (position - bounds.topLeft(Point.origin)).distance;
    double d2 = (position - bounds.topRight(Point.origin)).distance;
    double d3 = (position - bounds.bottomLeft(Point.origin)).distance;
    double d4 = (position - bounds.bottomRight(Point.origin)).distance;
    return math.max(math.max(d1, d2), math.max(d3, d4)).ceilToDouble();
  }

  @override
  InkHighlight highlightAt({
    RenderBox referenceBox,
    Color color,
    BoxShape shape: BoxShape.rectangle,
    RectCallback rectCallback,
    VoidCallback onRemoved
  }) {
    _InkHighlight highlight = new _InkHighlight(
      controller: this,
      referenceBox: referenceBox,
      color: color,
      shape: shape,
      rectCallback: rectCallback,
      onRemoved: onRemoved,
      vsync: vsync,
    );
    addInkFeature(highlight);
    return highlight;
  }

  @override
  void addInkFeature(InkFeature feature) {
    assert(!feature._debugDisposed);
    assert(feature._controller == this);
    assert(!_inkFeatures.contains(feature));
    _inkFeatures.add(feature);
    markNeedsPaint();
  }

  void _removeFeature(InkFeature feature) {
    _inkFeatures.remove(feature);
    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Point position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_inkFeatures.isNotEmpty) {
      final Canvas canvas = context.canvas;
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.clipRect(Point.origin & size);
      for (InkFeature inkFeature in _inkFeatures)
        inkFeature._paint(canvas);
      canvas.restore();
    }
    super.paint(context, offset);
  }
}

class _InkFeatures extends SingleChildRenderObjectWidget {
  _InkFeatures({ Key key, this.color, Widget child, @required this.vsync }) : super(key: key, child: child);

  // This widget must be owned by a MaterialState, which must be provided as the vsync.
  // This relationship must be 1:1 and cannot change for the lifetime of the MaterialState.

  final Color color;

  final TickerProvider vsync;

  @override
  _RenderInkFeatures createRenderObject(BuildContext context) {
    return new _RenderInkFeatures(
      color: color,
      vsync: vsync
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderInkFeatures renderObject) {
    renderObject.color = color;
    assert(vsync == renderObject.vsync);
  }
}

/// A visual reaction on a piece of [Material].
///
/// To add an ink feature to a piece of [Material], obtain the
/// [MaterialInkController] via [Material.of] and call
/// [MaterialInkController.addInkFeature].
abstract class InkFeature {
  /// Initializes fields for subclasses.
  InkFeature({
    MaterialInkController controller,
    this.referenceBox,
    this.onRemoved
  }) : _controller = controller;

  _RenderInkFeatures _controller;

  /// The render box whose visual position defines the frame of reference for this ink feature.
  final RenderBox referenceBox;

  /// Called when the ink feature is no longer visible on the material.
  final VoidCallback onRemoved;

  bool _debugDisposed = false;

  /// Free up the resources associated with this ink feature.
  void dispose() {
    assert(!_debugDisposed);
    assert(() { _debugDisposed = true; return true; });
    _controller._removeFeature(this);
    if (onRemoved != null)
      onRemoved();
  }

  void _paint(Canvas canvas) {
    assert(referenceBox.attached);
    assert(!_debugDisposed);
    // find the chain of renderers from us to the feature's referenceBox
    List<RenderBox> descendants = <RenderBox>[referenceBox];
    RenderBox node = referenceBox;
    while (node != _controller) {
      node = node.parent;
      assert(node != null);
      descendants.add(node);
    }
    // determine the transform that gets our coordinate system to be like theirs
    Matrix4 transform = new Matrix4.identity();
    assert(descendants.length >= 2);
    for (int index = descendants.length - 1; index > 0; index -= 1)
      descendants[index].applyPaintTransform(descendants[index - 1], transform);
    paintFeature(canvas, transform);
  }

  /// Override this method to paint the ink feature.
  ///
  /// The transform argument gives the coordinate conversion from the coordinate
  /// system of the canvas to the coodinate system of the [referenceBox].
  void paintFeature(Canvas canvas, Matrix4 transform);

  @override
  String toString() => "$runtimeType@$hashCode";
}

class _InkSplash extends InkFeature implements InkSplash {
  _InkSplash({
    _RenderInkFeatures controller,
    RenderBox referenceBox,
    this.position,
    this.color,
    this.targetRadius,
    this.clipCallback,
    this.repositionToReferenceBox,
    VoidCallback onRemoved,
    @required TickerProvider vsync,
  }) : super(controller: controller, referenceBox: referenceBox, onRemoved: onRemoved) {
    _radiusController = new AnimationController(duration: _kUnconfirmedSplashDuration, vsync: vsync)
      ..addListener(controller.markNeedsPaint)
      ..forward();
    _radius = new Tween<double>(
      begin: _kSplashInitialSize,
      end: targetRadius
    ).animate(_radiusController);
    _alphaController = new AnimationController(duration: _kHighlightFadeDuration, vsync: vsync)
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener(_handleAlphaStatusChanged);
    _alpha = new IntTween(
      begin: color.alpha,
      end: 0
    ).animate(_alphaController);
  }

  final Point position;
  final Color color;
  final double targetRadius;
  final RectCallback clipCallback;
  final bool repositionToReferenceBox;

  Animation<double> _radius;
  AnimationController _radiusController;

  Animation<int> _alpha;
  AnimationController _alphaController;

  @override
  void confirm() {
    int duration = (targetRadius / _kSplashConfirmedVelocity).floor();
    _radiusController
      ..duration = new Duration(milliseconds: duration)
      ..forward();
    _alphaController.forward();
  }

  @override
  void cancel() {
    _alphaController.forward();
  }

  void _handleAlphaStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed)
      dispose();
  }

  @override
  void dispose() {
    _radiusController.stop();
    _alphaController.stop();
    super.dispose();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    Paint paint = new Paint()..color = color.withAlpha(_alpha.value);
    Point center = position;
    if (repositionToReferenceBox)
      center = Point.lerp(center, referenceBox.size.center(Point.origin), _radiusController.value);
    Offset originOffset = MatrixUtils.getAsTranslation(transform);
    if (originOffset == null) {
      canvas.save();
      canvas.transform(transform.storage);
      if (clipCallback != null)
        canvas.clipRect(clipCallback());
      canvas.drawCircle(center, _radius.value, paint);
      canvas.restore();
    } else {
      if (clipCallback != null) {
        canvas.save();
        canvas.clipRect(clipCallback().shift(originOffset));
      }
      canvas.drawCircle(center + originOffset, _radius.value, paint);
      if (clipCallback != null)
        canvas.restore();
    }
  }
}

class _InkHighlight extends InkFeature implements InkHighlight {
  _InkHighlight({
    _RenderInkFeatures controller,
    RenderBox referenceBox,
    this.rectCallback,
    Color color,
    this.shape,
    VoidCallback onRemoved,
    @required TickerProvider vsync,
  }) : _color = color,
       super(controller: controller, referenceBox: referenceBox, onRemoved: onRemoved) {
    _alphaController = new AnimationController(duration: _kHighlightFadeDuration, vsync: vsync)
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener(_handleAlphaStatusChanged)
      ..forward();
    _alpha = new IntTween(
      begin: 0,
      end: color.alpha
    ).animate(_alphaController);
  }

  final RectCallback rectCallback;

  @override
  Color get color => _color;
  Color _color;

  @override
  set color(Color value) {
    if (value == _color)
      return;
    _color = value;
    _controller.markNeedsPaint();
  }

  final BoxShape shape;

  @override
  bool get active => _active;
  bool _active = true;

  Animation<int> _alpha;
  AnimationController _alphaController;

  @override
  void activate() {
    _active = true;
    _alphaController.forward();
  }

  @override
  void deactivate() {
    _active = false;
    _alphaController.reverse();
  }

  void _handleAlphaStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_active)
      dispose();
  }

  @override
  void dispose() {
    _alphaController.stop();
    super.dispose();
  }

  void _paintHighlight(Canvas canvas, Rect rect, Paint paint) {
    if (shape == BoxShape.rectangle)
      canvas.drawRect(rect, paint);
    else
      canvas.drawCircle(rect.center, InkSplash.defaultRadius, paint);
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    Paint paint = new Paint()..color = color.withAlpha(_alpha.value);
    Offset originOffset = MatrixUtils.getAsTranslation(transform);
    final Rect rect = (rectCallback != null ? rectCallback() : Point.origin & referenceBox.size);
    if (originOffset == null) {
      canvas.save();
      canvas.transform(transform.storage);
      _paintHighlight(canvas, rect, paint);
      canvas.restore();
    } else {
      _paintHighlight(canvas, rect.shift(originOffset), paint);
    }
  }
}
