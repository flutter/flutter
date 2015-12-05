part of flutter_sprites;

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
    this.transferMode: ui.TransferMode.dstOver,
    List<Point> points,
    this.widthMode : EffectLineWidthMode.linear,
    this.minWidth: 10.0,
    this.maxWidth: 10.0,
    this.widthGrowthSpeed: 0.0,
    this.animationMode: EffectLineAnimationMode.none,
    this.scrollSpeed: 0.1,
    double scrollStart: 0.0,
    this.fadeDuration: null,
    this.fadeAfterDelay: null,
    this.textureLoopLength: null,
    this.simplify: true,
    ColorSequence colorSequence
  }) {
    if (points == null)
      this.points = <Point>[];
    else
      this.points = points;

    _colorSequence = colorSequence;
    if (_colorSequence == null) {
      _colorSequence = new ColorSequence.fromStartAndEndColor(
        new Color(0xffffffff),
        new Color(0xffffffff)
      );
    }

    _offset = scrollStart;

    _painter = new TexturedLinePainter(points, _colors, _widths, texture);
    _painter.textureLoopLength = textureLoopLength;
  }

  final Texture texture;

  final ui.TransferMode transferMode;

  final EffectLineWidthMode widthMode;
  final double minWidth;
  final double maxWidth;
  final double widthGrowthSpeed;

  final EffectLineAnimationMode animationMode;
  final double scrollSpeed;
  ColorSequence _colorSequence;
  ColorSequence get colorSequence => _colorSequence;

  List<Point> _points;

  List<Point> get points => _points;

  set points(List<Point> points) {
    _points = points;
    _pointAges = <double>[];
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

    // Update age of line points and remove if neccesasry
    if (fadeDuration != null && fadeAfterDelay != null) {
      // Increase age of points
      for (int i = _points.length - 1; i >= 0; i--) {
        _pointAges[i] += dt;
      }

      // Check if the first/oldest point should be removed
      while(_points.length > 0 && _pointAges[0] > (fadeDuration + fadeAfterDelay)) {
        // Update scroll if it isn't the last and only point that is about to removed
        if (_points.length > 1 && textureLoopLength != null) {
          double dist = GameMath.distanceBetweenPoints(_points[0], _points[1]);
          _offset = (_offset - (dist / textureLoopLength)) % 1.0;
          if (_offset < 0.0) _offset += 1;
        }

        // Remove the point
        _pointAges.removeAt(0);
        _points.removeAt(0);
      }
    }
  }

  void paint(Canvas canvas) {
    if (points.length < 2) return;

    _painter.points = points;

    // Calculate colors
    List<double> stops = _painter.calculatedTextureStops;

    List<Color> colors = <Color>[];
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
    List<double> widths = <double>[];
    for (int i = 0; i < stops.length; i++) {
      double stop = stops[i];
      double growth = math.max(widthGrowthSpeed * _pointAges[i], 0.0);
      if (widthMode == EffectLineWidthMode.linear) {
        double width = minWidth + (maxWidth - minWidth) * stop + growth;
        widths.add(width);
      } else if (widthMode == EffectLineWidthMode.barrel) {
        double width = minWidth + math.sin(stop * math.PI) * (maxWidth - minWidth) + growth;
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

    if (simplify && points.length >= 2 && GameMath.distanceBetweenPoints(point, points[points.length - 2]) < 10.0) {
      // Check if we should remove last point before adding the new one

      // Calculate the square distance from the middle point to the line of the
      // new point and the second to last point
      double dist2 = _distToSeqment2(
        points[points.length - 1],
        point,
        points[points.length - 2]
      );

      // If the point is on the line, remove it
      if (dist2 < 1.0) {
        _points.removeAt(_points.length - 1);
      }
    }

    // Add point and point's age
    _points.add(point);
    _pointAges.add(0.0);
  }

  double _sqr(double x) => x * x;

  double _dist2(Point v, Point w) => _sqr(v.x - w.x) + _sqr(v.y - w.y);

  double _distToSeqment2(Point p, Point v, Point w) {
    double l2 = _dist2(v, w);
    if (l2 == 0.0) return _dist2(p, v);
    double t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2;
    if (t < 0) return _dist2(p, v);
    if (t > 1) return _dist2(p, w);
    return _dist2(p, new Point(v.x + t * (w.x - v.x), v.y + t * (w.y - v.y)));
  }
}
