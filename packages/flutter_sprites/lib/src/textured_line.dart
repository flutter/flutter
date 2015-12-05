part of flutter_sprites;

class TexturedLine extends Node {
  TexturedLine(List<Point> points, List<Color> colors, List<double> widths, [Texture texture, List<double> textureStops]) {
    painter = new TexturedLinePainter(points, colors, widths, texture, textureStops);
  }

  TexturedLinePainter painter;

  void paint(Canvas canvas) {
    painter.paint(canvas);
  }
}

class TexturedLinePainter {
  TexturedLinePainter(this._points, this.colors, this.widths, [Texture texture, this.textureStops]) {
    this.texture = texture;
  }

  List<Point> _points;

  List<Point> get points => _points;

  set points(List<Point> points) {
    _points = points;
    _calculatedTextureStops = null;
  }

  List<Color> colors;
  List<double> widths;
  Texture _texture;

  Texture get texture => _texture;

  set texture(Texture texture) {
    _texture = texture;
    if (texture == null) {
      _cachedPaint = new Paint();
    } else {
      Matrix4 matrix = new Matrix4.identity();
      ui.ImageShader shader = new ui.ImageShader(texture.image,
        ui.TileMode.repeated, ui.TileMode.repeated, matrix.storage);

      _cachedPaint = new Paint()
        ..shader = shader;
    }
  }

  List<double> textureStops;

  List<double> _calculatedTextureStops;

  List<double> get calculatedTextureStops {
    if (_calculatedTextureStops == null)
      _calculateTextureStops();
    return _calculatedTextureStops;
  }

  double _length;

  double get length {
    if (_calculatedTextureStops == null)
      _calculateTextureStops();
    return _length;
  }

  double textureStopOffset = 0.0;

  double _textureLoopLength;

  get textureLoopLength => textureLoopLength;

  set textureLoopLength(double textureLoopLength) {
    _textureLoopLength = textureLoopLength;
    _calculatedTextureStops = null;
  }

  bool removeArtifacts = true;

  ui.TransferMode transferMode = ui.TransferMode.srcOver;

  Paint _cachedPaint = new Paint();

  void paint(Canvas canvas) {
    // Check input values
    assert(_points != null);
    if (_points.length < 2) return;

    assert(_points.length == colors.length);
    assert(_points.length == widths.length);

    _cachedPaint.transferMode = transferMode;

    // Calculate normals
    List<Vector2> vectors = <Vector2>[];
    for (Point pt in _points) {
      vectors.add(new Vector2(pt.x, pt.y));
    }
    List<Vector2> miters = _computeMiterList(vectors, false);

    List<Point> vertices = <Point>[];
    List<int> indicies = <int>[];
    List<Color> verticeColors = <Color>[];
    List<Point> textureCoordinates;
    double textureTop;
    double textureBottom;
    List<double> stops;

    // Add first point
    Point lastPoint = _points[0];
    Vector2 lastMiter = miters[0];

    // Add vertices and colors
    _addVerticesForPoint(vertices, lastPoint, lastMiter, widths[0]);
    verticeColors.add(colors[0]);
    verticeColors.add(colors[0]);

    if (texture != null) {
      assert(texture.rotated == false);

      // Setup for calculating texture coordinates
      textureTop = texture.frame.top;
      textureBottom = texture.frame.bottom;
      textureCoordinates = <Point>[];

      // Use correct stops
      if (textureStops != null) {
        assert(_points.length == textureStops.length);
        stops = textureStops;
      } else {
        if (_calculatedTextureStops == null) _calculateTextureStops();
        stops = _calculatedTextureStops;
      }

      // Texture coordinate points
      double xPos = _xPosForStop(stops[0]);
      textureCoordinates.add(new Point(xPos, textureTop));
      textureCoordinates.add(new Point(xPos, textureBottom));
    }

    // Add the rest of the points
    for (int i = 1; i < _points.length; i++) {
      // Add vertices
      Point currentPoint = _points[i];
      Vector2 currentMiter = miters[i];
      _addVerticesForPoint(vertices, currentPoint, currentMiter, widths[i]);

      // Add references to the triangles
      int lastIndex0 = (i - 1) * 2;
      int lastIndex1 = (i - 1) * 2 + 1;
      int currentIndex0 = i * 2;
      int currentIndex1 = i * 2 + 1;
      indicies.addAll(<int>[lastIndex0, lastIndex1, currentIndex0]);
      indicies.addAll(<int>[lastIndex1, currentIndex1, currentIndex0]);

      // Add colors
      verticeColors.add(colors[i]);
      verticeColors.add(colors[i]);

      if (texture != null) {
        // Texture coordinate points
        double xPos = _xPosForStop(stops[i]);
        textureCoordinates.add(new Point(xPos, textureTop));
        textureCoordinates.add(new Point(xPos, textureBottom));
      }

      // Update last values
      lastPoint = currentPoint;
      lastMiter = currentMiter;
    }

    canvas.drawVertices(ui.VertexMode.triangles, vertices, textureCoordinates, verticeColors, ui.TransferMode.modulate, indicies, _cachedPaint);
  }

  double _xPosForStop(double stop) {
    if (_textureLoopLength == null) {
      return texture.frame.left + texture.frame.width * (stop - textureStopOffset);
    } else {
      return texture.frame.left + texture.frame.width * (stop - textureStopOffset * (_textureLoopLength / length)) * (length / _textureLoopLength);
    }
  }

  void _addVerticesForPoint(List<Point> vertices, Point point, Vector2 miter, double width) {
    double halfWidth = width / 2.0;

    Offset offset0 = new Offset(miter[0] * halfWidth, miter[1] * halfWidth);
    Offset offset1 = new Offset(-miter[0] * halfWidth, -miter[1] * halfWidth);

    Point vertex0 = point + offset0;
    Point vertex1 = point + offset1;

    int vertexCount = vertices.length;
    if (removeArtifacts && vertexCount >= 2) {
      Point oldVertex0 = vertices[vertexCount - 2];
      Point oldVertex1 = vertices[vertexCount - 1];

      Point intersection = GameMath.lineIntersection(oldVertex0, oldVertex1, vertex0, vertex1);
      if (intersection != null) {
        if (GameMath.distanceBetweenPoints(vertex0, intersection) < GameMath.distanceBetweenPoints(vertex1, intersection)) {
          vertex0 = oldVertex0;
        } else {
          vertex1 = oldVertex1;
        }
      }
    }

    vertices.add(vertex0);
    vertices.add(vertex1);
  }

  void _calculateTextureStops() {
    List<double> stops = <double>[];
    double length = 0.0;

    // Add first stop
    stops.add(0.0);

    // Calculate distance to each point from the first point along the line
    for (int i = 1; i < _points.length; i++) {
      Point lastPoint = _points[i - 1];
      Point currentPoint = _points[i];

      double dist = GameMath.distanceBetweenPoints(lastPoint, currentPoint);
      length += dist;
      stops.add(length);
    }

    // Normalize the values in the range [0.0, 1.0]
    for (int i = 1; i < points.length; i++) {
      stops[i] = stops[i] / length;
      new Point(512.0, 512.0);
    }

    _calculatedTextureStops = stops;
    _length = length;
  }
}

Vector2 _computeMiter(Vector2 lineA, Vector2 lineB) {
  Vector2 miter = new Vector2(- (lineA[1] + lineB[1]), lineA[0] + lineB[0]);
  miter.normalize();

  double dot = dot2(miter, new Vector2(-lineA[1], lineA[0]));
  if (dot.abs() < 0.1) {
    miter = _vectorNormal(lineA).normalize();
    return miter;
  }

  double miterLength = 1.0 / dot;
  miter = miter.scale(miterLength);

  return miter;
}

Vector2 _vectorNormal(Vector2 v) {
  return new Vector2(-v[1], v[0]);
}

Vector2 _vectorDirection(Vector2 a, Vector2 b) {
  Vector2 result = a - b;
  return result.normalize();
}

List<Vector2> _computeMiterList(List<Vector2> points, bool closed) {
  List<Vector2> out = <Vector2>[];
  Vector2 curNormal = null;

  if (closed) {
    points = new List<Vector2>.from(points);
    points.add(points[0]);
  }

  int total = points.length;
  for (int i = 1; i < total; i++) {
    Vector2 last = points[i - 1];
    Vector2 cur = points[i];
    Vector2 next = (i < total - 1) ? points[i + 1] : null;

    Vector2 lineA = _vectorDirection(cur, last);
    if (curNormal == null) {
      curNormal = _vectorNormal(lineA);
    }

    if (i == 1) {
      out.add(curNormal);
    }

    if (next == null) {
      curNormal = _vectorNormal(lineA);
      out.add(curNormal);
    } else {
      Vector2 lineB = _vectorDirection(next, cur);
      Vector2 miter = _computeMiter(lineA, lineB);
      out.add(miter);
    }
  }

  return out;
}
