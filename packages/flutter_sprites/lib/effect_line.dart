part of skysprites;

enum EffectLineWidthMode {
  linear,
  barrel,
}

enum EffectLineAnimationMode {
  none,
  scroll,
  random,
}

class EffectLine extends Node {

  EffectLine({
    this.texture: null,
    List<Point> points,
    this.widthMode : EffectLineWidthMode.linear,
    this.minWidth: 10.0,
    this.maxWidth: 10.0,
    this.animationMode: EffectLineAnimationMode.none,
    this.scrollSpeed: 0.1,
    this.fadeDuration: null,
    this.fadeAfterDelay: null,
    this.textureLoopLength: null,
    this.simplify: true,
    ColorSequence colorSequence
  }) {
    if (points == null) this.points = [];
    else this.points = points;

    _colorSequence = colorSequence;
    if (_colorSequence == null)
      _colorSequence = new ColorSequence.fromStartAndEndColor(
        new Color(0xffffffff),
        new Color(0xffffffff));

    _painter = new TexturedLinePainter(points, _colors, _widths, texture);
    _painter.textureLoopLength = textureLoopLength;
  }

  final Texture texture;

  final EffectLineWidthMode widthMode;
  final double minWidth;
  final double maxWidth;

  final EffectLineAnimationMode animationMode;
  final double scrollSpeed;
  ColorSequence _colorSequence;
  ColorSequence get colorSequence => _colorSequence;

  List<Point> _points;

  List<Point> get points => _points;

  set points(List<Point> points) {
    _points = points;
    _pointAges = [];
    for (int i = 0; i < _points.length; i++) {
      _pointAges.add(0.0);
    }
  }

  List<double> _pointAges;
  List<Color> _colors;
  List<double> _widths;

  final double fadeDuration;
  final double fadeAfterDelay;

  final double textureLoopLength;

  final bool simplify;

  TexturedLinePainter _painter;
  double _offset = 0.0;

  void update(double dt) {
    // Update scrolling position
    if (animationMode == EffectLineAnimationMode.scroll) {
      _offset += dt * scrollSpeed;
      _offset %= 1.0;
    } else if (animationMode == EffectLineAnimationMode.random) {
      _offset = randomDouble();
    }

    // Update age of line points, and remove if neccessary
    if (fadeDuration != null && fadeAfterDelay != null) {
      for (int i = _points.length - 1; i >= 0; i--) {
        _pointAges[i] += dt;
        if (_pointAges[i] > (fadeDuration + fadeAfterDelay)) {
          _pointAges.removeAt(i);
          _points.removeAt(i);
        }
      }
    }
  }

  void paint(PaintingCanvas canvas) {
    if (points.length < 2) return;

    //_painter.textureLoopLength = textureLoopLength;

    _painter.points = points;

    // Calculate colors
    List<double> stops = _painter.calculatedTextureStops;

    List<Color> colors = [];
    for (int i = 0; i < stops.length; i++) {
      double stop = stops[i];
      Color color = _colorSequence.colorAtPosition(stop);

      if (fadeDuration != null && fadeAfterDelay != null) {
        double age = _pointAges[i];
        if (age > fadeAfterDelay) {
          double fade = 1.0 - (age - fadeAfterDelay) / fadeDuration;
          int alpha = (color.alpha * fade).toInt().clamp(0, 255);
          color = new Color.fromARGB(alpha, color.red, color.green, color.blue);
        }
      }
      colors.add(color);
    }
    _painter.colors = colors;

    // Calculate widths
    List<double> widths = [];
    for (double stop in stops) {
      if (widthMode == EffectLineWidthMode.linear) {
        double width = minWidth + (maxWidth - minWidth) * stop;
        widths.add(width);
      } else if (widthMode == EffectLineWidthMode.barrel) {
        double width = minWidth + math.sin(stop * math.PI) * (maxWidth - minWidth);
        widths.add(width);
      }
    }
    _painter.widths = widths;

    _painter.textureStopOffset = _offset;

    _painter.paint(canvas);
  }

  void addPoint(Point point) {
    // Skip duplicate points
    if (points.length > 0 && point.x == points[points.length - 1].x && point.y == points[points.length - 1].y)
      return;

    if (simplify) {

    }

    // Add point and point's age
    _points.add(point);
    _pointAges.add(0.0);
  }
}
