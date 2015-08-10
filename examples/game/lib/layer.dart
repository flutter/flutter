part of sprites;

class Layer extends Node with SpritePaint {
  Paint _cachedPaint = new Paint()
    ..setFilterQuality(FilterQuality.low)
    ..isAntiAlias = false;

  void _prePaint(PaintingCanvas canvas, Matrix4 matrix) {
    super._prePaint(canvas, matrix);

    _updatePaint(_cachedPaint);
    canvas.saveLayer(null, _cachedPaint);
  }

  void _postPaint(PaintingCanvas canvas, Matrix4 totalMatrix) {
    canvas.restore();
    super._postPaint(canvas, totalMatrix);
  }
}
