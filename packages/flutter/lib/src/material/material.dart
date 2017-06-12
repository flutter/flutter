// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'theme.dart';

/// Signature for the callback used by ink effects to obtain the rectangle for the effect.
///
/// Used by [InkHighlight] and [InkSplash], for example.
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

/// An interface for creating [InkSplash]s and [InkHighlight]s on a material.
///
/// Typically obtained via [Material.of].
abstract class MaterialInkController {
  /// The color of the material.
  Color get color;

  /// The ticker provider used by the controller.
  ///
  /// Ink features that are added to this controller with [addInkFeature] should
  /// use this vsync to drive their animations.
  TickerProvider get vsync;

  /// Add an [InkFeature], such as an [InkSplash] or an [InkHighlight].
  ///
  /// The ink feature will paint as part of this controller.
  void addInkFeature(InkFeature feature);

  /// Notifies the controller that one of its ink features needs to repaint.
  void markNeedsPaint();
}

/// A piece of material.
///
/// Material is the central metaphor in material design. Each piece of material
/// exists at a given elevation, which influences how that piece of material
/// visually relates to other pieces of material and how that material casts
/// shadows.
///
/// Most user interface elements are either conceptually printed on a piece of
/// material or themselves made of material. Material reacts to user input using
/// [InkSplash] and [InkHighlight] effects. To trigger a reaction on the
/// material, use a [MaterialInkController] obtained via [Material.of].
///
/// If a material has a non-zero [elevation], then the material will clip its
/// contents because content that is conceptually printing on a separate piece
/// of material cannot be printed beyond the bounds of the material.
///
/// If the layout changes (e.g. because there's a list on the paper, and it's
/// been scrolled), a LayoutChangedNotification must be dispatched at the
/// relevant subtree. (This in particular means that Transitions should not be
/// placed inside Material.) Otherwise, in-progress ink features (e.g., ink
/// splashes and ink highlights) won't move to account for the new layout.
///
/// In general, the features of a [Material] should not change over time (e.g. a
/// [Material] should not change its [color] or [type]). The one exception is
/// the [elevation], changes to which will be animated.
///
/// See also:
///
/// * [MergeableMaterial], a piece of material that can split and remerge.
/// * [Card], a wrapper for a [Material] of [type] [MaterialType.card].
/// * <https://material.google.com/>
class Material extends StatefulWidget {
  /// Creates a piece of material.
  ///
  /// The [type] and the [elevation] arguments must not be null.
  const Material({
    Key key,
    this.type: MaterialType.canvas,
    this.elevation: 0.0,
    this.color,
    this.textStyle,
    this.borderRadius,
    this.child,
  }) : assert(type != null),
       assert(elevation != null),
       assert(!(identical(type, MaterialType.circle) && borderRadius != null)),
       super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The kind of material to show (e.g., card or canvas). This
  /// affects the shape of the widget, the roundness of its corners if
  /// the shape is rectangular, and the default color.
  final MaterialType type;

  /// The z-coordinate at which to place this material. This controls the size
  /// of the shadow below the material.
  ///
  /// If this is non-zero, the contents of the card are clipped, because the
  /// widget conceptually defines an independent printed piece of material.
  ///
  /// Defaults to 0. Changing this value will cause the shadow to animate over
  /// [kThemeChangeDuration].
  final double elevation;

  /// The color to paint the material.
  ///
  /// Must be opaque. To create a transparent piece of material, use
  /// [MaterialType.transparency].
  ///
  /// By default, the color is derived from the [type] of material.
  final Color color;

  /// The typographical style to use for text within this material.
  final TextStyle textStyle;

  /// If non-null, the corners of this box are rounded by this [BorderRadius].
  /// Otherwise, the corners specified for the current [type] of material are
  /// used.
  ///
  /// Must be null if [type] is [MaterialType.circle].
  final BorderRadius borderRadius;

  /// The ink controller from the closest instance of this class that
  /// encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// MaterialInkController inkController = Material.of(context);
  /// ```
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
    description.add('elevation: ${elevation.toStringAsFixed(1)}');
    if (color != null)
      description.add('color: $color');
    if (textStyle != null) {
      for (String entry in '$textStyle'.split('\n'))
        description.add('textStyle.$entry');
    }
    if (borderRadius != null)
      description.add('borderRadius: $borderRadius');
  }

  /// The default radius of an ink splash in logical pixels.
  static const double defaultSplashRadius = 35.0;
}

class _MaterialState extends State<Material> with TickerProviderStateMixin {
  final GlobalKey _inkFeatureRenderer = new GlobalKey(debugLabel: 'ink renderer');

  Color _getBackgroundColor(BuildContext context) {
    if (widget.color != null)
      return widget.color;
    switch (widget.type) {
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
    final Color backgroundColor = _getBackgroundColor(context);
    assert(backgroundColor != null || widget.type == MaterialType.transparency);
    Widget contents = widget.child;
    final BorderRadius radius = widget.borderRadius ?? kMaterialEdges[widget.type];
    if (contents != null) {
      contents = new AnimatedDefaultTextStyle(
        style: widget.textStyle ?? Theme.of(context).textTheme.body1,
        duration: kThemeChangeDuration,
        child: contents
      );
    }
    contents = new NotificationListener<LayoutChangedNotification>(
      onNotification: (LayoutChangedNotification notification) {
        final _RenderInkFeatures renderer = _inkFeatureRenderer.currentContext.findRenderObject();
        renderer._didChangeLayout();
        return true;
      },
      child: new _InkFeatures(
        key: _inkFeatureRenderer,
        color: backgroundColor,
        child: contents,
        vsync: this,
      )
    );

    if (widget.type == MaterialType.circle) {
      contents = new AnimatedPhysicalModel(
        curve: Curves.fastOutSlowIn,
        duration: kThemeChangeDuration,
        shape: BoxShape.circle,
        elevation: widget.elevation,
        color: backgroundColor,
        animateColor: false,
        child: contents,
      );
    } else if (widget.type == MaterialType.transparency) {
      if (radius == null) {
        contents = new ClipRect(child: contents);
      } else {
        contents = new ClipRRect(
          borderRadius: radius,
          child: contents
        );
      }
    } else {
      contents = new AnimatedPhysicalModel(
        curve: Curves.fastOutSlowIn,
        duration: kThemeChangeDuration,
        shape: BoxShape.rectangle,
        borderRadius: radius ?? BorderRadius.zero,
        elevation: widget.elevation,
        color: backgroundColor,
        animateColor: false,
        child: contents,
      );
    }

    return contents;
  }
}

const Duration _kHighlightFadeDuration = const Duration(milliseconds: 200);

class _RenderInkFeatures extends RenderProxyBox implements MaterialInkController {
  _RenderInkFeatures({ RenderBox child, @required this.vsync, this.color }) : super(child) {
    assert(vsync != null);
  }

  // This class should exist in a 1:1 relationship with a MaterialState object,
  // since there's no current support for dynamically changing the ticker
  // provider.
  @override
  final TickerProvider vsync;

  // This is here to satisfy the MaterialInkController contract.
  // The actual painting of this color is done by a Container in the
  // MaterialState build method.
  @override
  Color color;

  final List<InkFeature> _inkFeatures = <InkFeature>[];

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

  void _didChangeLayout() {
    if (_inkFeatures.isNotEmpty)
      markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_inkFeatures.isNotEmpty) {
      final Canvas canvas = context.canvas;
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.clipRect(Offset.zero & size);
      for (InkFeature inkFeature in _inkFeatures)
        inkFeature._paint(canvas);
      canvas.restore();
    }
    super.paint(context, offset);
  }
}

class _InkFeatures extends SingleChildRenderObjectWidget {
  const _InkFeatures({ Key key, this.color, Widget child, @required this.vsync }) : super(key: key, child: child);

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
    @required MaterialInkController controller,
    @required this.referenceBox,
    this.onRemoved
  }) : assert(controller != null),
       assert(referenceBox != null),
       _controller = controller;

  /// The [MaterialInkController] associated with this [InkFeature].
  ///
  /// Typically used by subclasses to call
  /// [MaterialInkController.markNeedsPaint] when they need to repaint.
  MaterialInkController get controller => _controller;
  _RenderInkFeatures _controller;

  /// The render box whose visual position defines the frame of reference for this ink feature.
  final RenderBox referenceBox;

  /// Called when the ink feature is no longer visible on the material.
  final VoidCallback onRemoved;

  bool _debugDisposed = false;

  /// Free up the resources associated with this ink feature.
  @mustCallSuper
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
    final List<RenderObject> descendants = <RenderObject>[referenceBox];
    RenderObject node = referenceBox;
    while (node != _controller) {
      node = node.parent;
      assert(node != null);
      descendants.add(node);
    }
    // determine the transform that gets our coordinate system to be like theirs
    final Matrix4 transform = new Matrix4.identity();
    assert(descendants.length >= 2);
    for (int index = descendants.length - 1; index > 0; index -= 1)
      descendants[index].applyPaintTransform(descendants[index - 1], transform);
    paintFeature(canvas, transform);
  }

  /// Override this method to paint the ink feature.
  ///
  /// The transform argument gives the coordinate conversion from the coordinate
  /// system of the canvas to the coodinate system of the [referenceBox].
  @protected
  void paintFeature(Canvas canvas, Matrix4 transform);

  @override
  String toString() => '$runtimeType#$hashCode';
}
