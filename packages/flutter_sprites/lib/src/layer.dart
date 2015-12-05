part of flutter_sprites;

/// A [Node] that provides an intermediate rendering surface in the sprite
/// rendering tree. A [Layer] can be used to change the opacity, color, or to
/// apply an effect to a set of nodes. All nodes that are children to the
/// [Layer] will be rendered into the surface. If the area that is needed for
/// the children to be drawn is know, the [layerRect] property should be set as
/// this can enhance performance.
class Layer extends Node with SpritePaint {

  /// The area that the children of the [Layer] will occupy. This value is
  /// treated as a hint to the rendering system and may in some cases be
  /// ignored. If the area isn't known, the layerRect can be set to [null].
  ///
  ///     myLayer.layerRect = new Rect.fromLTRB(0.0, 0.0, 200.0, 100.0);
  Rect layerRect;

  /// Creates a new layer. The layerRect can optionally be passed as an argument
  /// if it is known.
  ///
  ///     var myLayer = new Layer();
  Layer([this.layerRect = null]);

  Paint _cachedPaint = new Paint()
    ..filterQuality = ui.FilterQuality.low
    ..isAntiAlias = false;

  void _prePaint(Canvas canvas, Matrix4 matrix) {
    super._prePaint(canvas, matrix);

    _updatePaint(_cachedPaint);
    canvas.saveLayer(layerRect, _cachedPaint);
  }

  void _postPaint(Canvas canvas, Matrix4 totalMatrix) {
    canvas.restore();
    super._postPaint(canvas, totalMatrix);
  }
}
