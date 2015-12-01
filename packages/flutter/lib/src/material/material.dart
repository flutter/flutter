// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

import 'constants.dart';
import 'shadows.dart';
import 'theme.dart';

enum MaterialType {
  /// Infinite extent using default theme canvas color.
  canvas,

  /// Rounded edges, card theme color.
  card,

  /// A circle, no color by default (used for floating action buttons).
  circle,

  /// Rounded edges, no color by default (used for MaterialButton buttons).
  button
}

const Map<MaterialType, double> kMaterialEdges = const <MaterialType, double>{
  MaterialType.canvas: null,
  MaterialType.card: 2.0,
  MaterialType.circle: null,
  MaterialType.button: 2.0,
};

abstract class InkSplash {
  void confirm();
  void cancel();
  void dispose();
}

abstract class InkHighlight {
  void activate();
  void deactivate();
  void dispose();
  bool get active;
  Color get color;
  void set color(Color value);
}

abstract class MaterialInkController {
  /// The color of the material
  Color get color;

  /// Begin a splash, centered at position relative to referenceBox.
  /// If containedInWell is true, then the splash will be sized to fit
  /// the referenceBox, then clipped to it when drawn.
  /// When the splash is removed, onRemoved will be invoked.
  InkSplash splashAt({ RenderBox referenceBox, Point position, bool containedInWell, VoidCallback onRemoved });

  /// Begin a highlight, coincident with the referenceBox.
  InkHighlight highlightRectAt({ RenderBox referenceBox, Color color, VoidCallback onRemoved });

  /// Add an arbitrary InkFeature to this InkController.
  void addInkFeature(InkFeature feature);
}

/// Describes a sheet of Material. If the layout changes (e.g. because there's a
/// list on the paper, and it's been scrolled), a LayoutChangedNotification must
/// be dispatched at the relevant subtree. (This in particular means that
/// Transitions should not be placed inside Material.)
class Material extends StatefulComponent {
  Material({
    Key key,
    this.child,
    this.type: MaterialType.canvas,
    this.elevation: 0,
    this.color,
    this.textStyle
  }) : super(key: key) {
    assert(elevation != null);
  }

  final Widget child;
  final MaterialType type;
  final int elevation;
  final Color color;
  final TextStyle textStyle;

  static MaterialInkController of(BuildContext context) {
    final RenderInkFeatures result = context.ancestorRenderObjectOfType(RenderInkFeatures);
    return result;
  }

  _MaterialState createState() => new _MaterialState();
}

class _MaterialState extends State<Material> {
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

  Widget build(BuildContext context) {
    Color backgroundColor = _getBackgroundColor(context);
    Widget contents = config.child;
    if (contents != null) {
      contents = new DefaultTextStyle(
        style: config.textStyle ?? Theme.of(context).text.body1,
        child: contents
      );
    }
    contents = new NotificationListener<LayoutChangedNotification>(
      onNotification: (LayoutChangedNotification notification) {
        _inkFeatureRenderer.currentContext.findRenderObject().markNeedsPaint();
      },
      child: new InkFeatures(
        key: _inkFeatureRenderer,
        color: backgroundColor,
        child: contents
      )
    );
    if (config.type == MaterialType.circle) {
      contents = new ClipOval(child: contents);
    } else if (kMaterialEdges[config.type] != null) {
      contents = new ClipRRect(
        xRadius: kMaterialEdges[config.type],
        yRadius: kMaterialEdges[config.type],
        child: contents
      );
    }
    contents = new AnimatedContainer(
      curve: Curves.ease,
      duration: kThemeChangeDuration,
      decoration: new BoxDecoration(
        backgroundColor: backgroundColor,
        borderRadius: kMaterialEdges[config.type],
        boxShadow: config.elevation == 0 ? null : elevationToShadow[config.elevation],
        shape: config.type == MaterialType.circle ? Shape.circle : Shape.rectangle
      ),
      child: contents
    );
    return contents;
  }
}

const Duration _kHighlightFadeDuration = const Duration(milliseconds: 100);

const double _kDefaultSplashRadius = 35.0; // logical pixels
const int _kSplashInitialAlpha = 0x30; // 0..255
const double _kSplashCanceledVelocity = 0.7; // logical pixels per millisecond
const double _kSplashConfirmedVelocity = 0.7; // logical pixels per millisecond
const double _kSplashInitialSize = 0.0; // logical pixels
const double _kSplashUnconfirmedVelocity = 0.2; // logical pixels per millisecond

class RenderInkFeatures extends RenderProxyBox implements MaterialInkController {
  RenderInkFeatures({ RenderBox child, this.color }) : super(child);

  // This is here to satisfy the MaterialInkController contract.
  // The actual painting of this color is done by a Container in the
  // MaterialState build method.
  Color color;

  final List<InkFeature> _inkFeatures = <InkFeature>[];

  InkSplash splashAt({ RenderBox referenceBox, Point position, bool containedInWell, VoidCallback onRemoved }) {
    double radius;
    if (containedInWell) {
      radius = _getSplashTargetSize(referenceBox.size, position);
    } else {
      radius = _kDefaultSplashRadius;
    }
    _InkSplash splash = new _InkSplash(
      renderer: this,
      referenceBox: referenceBox,
      position: position,
      targetRadius: radius,
      clipToReferenceBox: containedInWell,
      onRemoved: onRemoved
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

  InkHighlight highlightRectAt({ RenderBox referenceBox, Color color, VoidCallback onRemoved }) {
    _InkHighlight highlight = new _InkHighlight(
      renderer: this,
      referenceBox: referenceBox,
      color: color,
      onRemoved: onRemoved
    );
    addInkFeature(highlight);
    return highlight;
  }

  void addInkFeature(InkFeature feature) {
    assert(!feature._debugDisposed);
    assert(feature.renderer == this);
    assert(!_inkFeatures.contains(feature));
    _inkFeatures.add(feature);
    markNeedsPaint();
  }

  void _removeFeature(InkFeature feature) {
    _inkFeatures.remove(feature);
    markNeedsPaint();
  }

  bool hitTestSelf(Point position) => true;

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

class InkFeatures extends OneChildRenderObjectWidget {
  InkFeatures({ Key key, this.color, Widget child }) : super(key: key, child: child);

  final Color color;

  RenderInkFeatures createRenderObject() => new RenderInkFeatures(color: color);

  void updateRenderObject(RenderInkFeatures renderObject, InkFeatures oldWidget) {
    renderObject.color = color;
  }
}

abstract class InkFeature {
  InkFeature({
    this.renderer,
    this.referenceBox,
    this.onRemoved
  });

  final RenderInkFeatures renderer;
  final RenderBox referenceBox;
  final VoidCallback onRemoved;

  bool _debugDisposed = false;

  void dispose() {
    assert(!_debugDisposed);
    assert(() { _debugDisposed = true; return true; });
    renderer._removeFeature(this);
    if (onRemoved != null)
      onRemoved();
  }

  void _paint(Canvas canvas) {
    assert(referenceBox.attached);
    assert(!_debugDisposed);
    // find the chain of renderers from us to the feature's referenceBox
    List<RenderBox> descendants = <RenderBox>[];
    RenderBox node = referenceBox;
    while (node != renderer) {
      descendants.add(node);
      node = node.parent;
      assert(node != null);
    }
    // determine the transform that gets our coordinate system to be like theirs
    Matrix4 transform = new Matrix4.identity();
    for (RenderBox descendant in descendants.reversed)
      descendant.applyPaintTransform(transform);
    paintFeature(canvas, transform);
  }

  void paintFeature(Canvas canvas, Matrix4 transform);

  String toString() => "$runtimeType@$hashCode";
}

class _InkSplash extends InkFeature implements InkSplash {
  _InkSplash({
    RenderInkFeatures renderer,
    RenderBox referenceBox,
    this.position,
    this.targetRadius,
    this.clipToReferenceBox,
    VoidCallback onRemoved
  }) : super(renderer: renderer, referenceBox: referenceBox, onRemoved: onRemoved) {
    _radius = new ValuePerformance<double>(
      variable: new AnimatedValue<double>(
        _kSplashInitialSize,
        end: targetRadius,
        curve: Curves.easeOut
      ),
      duration: new Duration(milliseconds: (targetRadius / _kSplashUnconfirmedVelocity).floor())
    )..addListener(_handleRadiusChange)
     ..play();
  }

  final Point position;
  final double targetRadius;
  final bool clipToReferenceBox;

  double _pinnedRadius;
  ValuePerformance<double> _radius;

  void confirm() {
    _updateVelocity(_kSplashConfirmedVelocity);
  }

  void cancel() {
    _updateVelocity(_kSplashCanceledVelocity);
    _pinnedRadius = _radius.value;
  }

  void _updateVelocity(double velocity) {
    int duration = (targetRadius / velocity).floor();
    _radius.duration = new Duration(milliseconds: duration);
    _radius.play();
  }

  void _handleRadiusChange() {
    if (_radius.value == targetRadius)
      dispose();
    else
      renderer.markNeedsPaint();
  }

  void dispose() {
    _radius.stop();
    super.dispose();
  }

  void paintFeature(Canvas canvas, Matrix4 transform) {
    int alpha = (_kSplashInitialAlpha * (1.1 - (_radius.value / targetRadius))).floor();
    Paint paint = new Paint()..color = new Color(alpha << 24); // TODO(ianh): in dark theme, this isn't very visible
    double radius = _pinnedRadius == null ? _radius.value : _pinnedRadius;
    Offset originOffset = MatrixUtils.getAsTranslation(transform);
    if (originOffset == null) {
      canvas.save();
      canvas.concat(transform.storage);
      if (clipToReferenceBox)
        canvas.clipRect(Point.origin & referenceBox.size);
      canvas.drawCircle(position, radius, paint);
      canvas.restore();
    } else {
      if (clipToReferenceBox) {
        canvas.save();
        canvas.clipRect(originOffset.toPoint() & referenceBox.size);
      }
      canvas.drawCircle(position + originOffset, radius, paint);
      if (clipToReferenceBox)
        canvas.restore();
    }
  }
}

class _InkHighlight extends InkFeature implements InkHighlight {
  _InkHighlight({
    RenderInkFeatures renderer,
    RenderBox referenceBox,
    Color color,
    VoidCallback onRemoved
  }) : _color = color,
       super(renderer: renderer, referenceBox: referenceBox, onRemoved: onRemoved) {
    _alpha = new ValuePerformance<int>(
      variable: new AnimatedIntValue(
        0,
        end: color.alpha,
        curve: Curves.linear
      ),
      duration: _kHighlightFadeDuration
    )..addListener(_handleAlphaChange)
     ..play();
  }

  Color get color => _color;
  Color _color;
  void set color(Color value) {
    if (value == _color)
      return;
    _color = value;
    renderer.markNeedsPaint();
  }

  bool get active => _active;
  bool _active = true;
  ValuePerformance<int> _alpha;

  void activate() {
    _active = true;
    _alpha.forward();
  }

  void deactivate() {
    _active = false;
    _alpha.reverse();
  }

  void _handleAlphaChange() {
    if (_alpha.value == 0.0 && !_active)
      dispose();
    else
      renderer.markNeedsPaint();
  }

  void dispose() {
    _alpha.stop();
    super.dispose();
  }

  void paintFeature(Canvas canvas, Matrix4 transform) {
    Paint paint = new Paint()..color = color.withAlpha(_alpha.value);
    Offset originOffset = MatrixUtils.getAsTranslation(transform);
    if (originOffset == null) {
      canvas.save();
      canvas.concat(transform.storage);
      canvas.drawRect(Point.origin & referenceBox.size, paint);
      canvas.restore();
    } else {
      canvas.drawRect(originOffset.toPoint() & referenceBox.size, paint);
    }
  }

}
