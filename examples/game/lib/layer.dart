part of sprites;

class Layer extends Node with SpritePaint {
  Rect layerRect;

  Layer([Rect this.layerRect = null]);

  Paint _cachedPaint = new Paint()
    ..setFilterQuality(FilterQuality.low)
    ..isAntiAlias = false;

  void _prePaint(PaintingCanvas canvas, Matrix4 matrix) {
    super._prePaint(canvas, matrix);

    _updatePaint(_cachedPaint);
    canvas.saveLayer(layerRect, _cachedPaint);
  }

  void _postPaint(PaintingCanvas canvas, Matrix4 totalMatrix) {
    canvas.restore();
    super._postPaint(canvas, totalMatrix);
  }
}
