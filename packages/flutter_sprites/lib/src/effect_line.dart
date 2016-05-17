// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_sprites;

/// Used by [EffectLine] to determine how the width of the line is calculated.
enum EffectLineWidthMode {

  /// Linear interpolation between minWidth at the start and maxWidth at the
  /// end of the line.
  linear,

  /// Creates a barrel shaped line, with minWidth at the end points of the line
  /// and maxWidth at the middle.
  barrel,
}

/// Used by [EffectLine] to determine how the texture of the line is animated.
enum EffectLineAnimationMode {

  /// The texture of the line isn't animated.
  none,

  /// The texture of the line is scrolling.
  scroll,

  /// The texture of the line is set to a random position at every frame. This
  /// mode is useful for creating flashing or electricity styled effects.
  random,
}

/// The EffectLine class is using the [TexturedLine] class to draw animated
/// lines. These can be used to draw things such as smoke trails, electricity
/// effects, or other animated types of lines.
class EffectLine extends Node {

  /// Creates a new EffectLine with the specified parameters. Only the
  /// [texture] parameter is required, all other parameters are optional.
  EffectLine({
    this.texture: null,
    this.transferMode: TransferMode.dstOver,
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
        const Color(0xffffffff),
        const Color(0xffffffff)
      );
    }

    _offset = scrollStart;

    _painter = new TexturedLinePainter(points, _colors, _widths, texture);
    _painter.textureLoopLength = textureLoopLength;
  }

  /// The texture used to draw the line.
  final Texture texture;

  /// The transfer mode used to draw the line, default is
  /// [TransferMode.dstOver].
  final TransferMode transferMode;

  /// Mode used to calculate the width of the line.
  final EffectLineWidthMode widthMode;

  /// The width of the line at its thinnest point.
  final double minWidth;

  /// The width of the line at its thickest point.
  final double maxWidth;

  /// The speed at which the line is growing, defined in points per second.
  final double widthGrowthSpeed;

  /// The mode used to animate the texture of the line.
  final EffectLineAnimationMode animationMode;

  /// The speed of which the texture of the line is scrolling. This property
  /// is only used if the [animationMode] is set to
  /// [EffectLineAnimationMode.scroll].
  final double scrollSpeed;

  /// Color gradient used to draw the line, from start to finish.
  ColorSequence get colorSequence => _colorSequence;

  ColorSequence _colorSequence;

  /// List of points that make up the line. Typically, you will only want to
  /// set this at the beginning. Then use [addPoint] to add additional points
  /// to the line.
  List<Point> get points => _points;

  set points(List<Point> points) {
    _points = points;
    _pointAges = <double>[];
    for (int i = 0; i < _points.length; i++) {
      _pointAges.add(0.0);
    }
  }

  List<Point> _points;

  List<double> _pointAges;
  List<Color> _colors;
  List<double> _widths;

  /// The time it takes for an added point to fade out. It's total life time is
  /// [fadeDuration] + [fadeAfterDelay].
  final double fadeDuration;

  /// The time it takes until an added point starts to fade out.
  final double fadeAfterDelay;

  /// The length, in points, that the texture is stretched to. If the
  /// textureLoopLength is shorter than the line, the texture will be looped.
  final double textureLoopLength;

  /// True if the line should be simplified by removing points that are close
  /// to other points. This makes drawing faster, but can result in a slight
  /// jittering effect when points are added.
  final bool simplify;

  TexturedLinePainter _painter;
  double _offset = 0.0;

  @override
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

  @override
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

  /// Adds a new point to the line.
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
