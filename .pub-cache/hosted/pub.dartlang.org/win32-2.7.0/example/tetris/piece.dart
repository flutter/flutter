import 'dart:math' show min, max;

class Point {
  int x;
  int y;

  @override
  String toString() => '($x, $y)';

  Point([this.x = 0, this.y = 0]);
  factory Point.clone(Point orig) => Point(orig.x, orig.y);
}

// A piece in Tetris game. This class is only used by PieceSet. Other classes
// should access Piece through PieceSet.
//
// Every piece is composed by 4 POINTs, using Cartesian coordinate system.
// That is, the most bottom left point is (0, 0), the values on x-axis
// increase to the right, and values on y-axis increase to the top.
//
// To represent a piece, it is snapped to the bottom-left corner. For example,
// when the 'I' piece stands vertically, the point array stores:
// (0,0) (0,1) (0,2) (0,3)
//
class Piece {
  // POINT array of which the piece is composed
  List<Point>? body;

  // Number of points in body
  int pointCount;

  // Make rotation faster
  int width;
  int height;

  // Piece type ID and rotation
  int id;
  int rotation;

  // Piece color in RGB
  int color;

  /// Constructs a piece
  ///
  /// id: piece type ID
  /// rotation: how many time is the piece rotated (0-3)
  /// color: piece color in RGB
  /// points: array of points of which the piece is composed. This constructor
  ///         moves these points automatically to snap the piece to
  ///         bottom-left corner (0,0)
  /// pointCount: number of points in apt
  Piece(this.id, this.rotation, this.color, List<Point> points,
      [this.pointCount = 4])
      : width = 0,
        height = 0 {
    final bottomLeft = Point.clone(points[0]);

    for (var i = 1; i < pointCount; i++) {
      bottomLeft
        ..x = min(points[i].x, bottomLeft.x)
        ..y = min(points[i].y, bottomLeft.y);
    }

    body = List<Point>.generate(pointCount, (i) => Point());
    for (var i = 0; i < pointCount; i++) {
      body![i].x = points[i].x - bottomLeft.x;
      body![i].y = points[i].y - bottomLeft.y;

      width = max(body![i].x + 1, width);
      height = max(body![i].y + 1, height);
    }
  }

  /// Gets the bottom part of points of the piece
  List<Point> get skirt {
    final points = <Point>[];

    for (var x = 0; x < width; x++) {
      for (var y = 0; y < height; y++) {
        if (isPointExists(x, y)) {
          final p = Point()
            ..x = x
            ..y = y;
          points.add(p);
          break;
        }
      }
    }
    return points;
  }

  /// Gets the left part of points of the piece
  List<Point> get leftSide {
    final points = <Point>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < height; x++) {
        if (isPointExists(x, y)) {
          final p = Point()
            ..x = x
            ..y = y;
          points.add(p);
          break;
        }
      }
    }
    return points;
  }

  /// Gets the right part of points of the piece
  List<Point> get rightSide {
    final points = <Point>[];
    for (var y = 0; y < height; y++) {
      for (var x = width - 1; x >= 0; x--) {
        if (isPointExists(x, y)) {
          final p = Point()
            ..x = x
            ..y = y;
          points.add(p);
          break;
        }
      }
    }
    return points;
  }

  /// String representation of a piece (for debugging)
  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('width = $width | ')
      ..write('height = $height | ')
      ..write('nPoints = $pointCount | ')
      ..writeln('color = ${color.toRadixString(16)}');

    for (var y = height - 1; y >= 0; y--) {
      for (var x = 0; x < width; x++) {
        if (isPointExists(x, y)) {
          buffer.write('#');
        } else {
          buffer.write(' ');
        }
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Determines if the piece has a point (x, y)
  bool isPointExists(int x, int y) {
    for (var i = 0; i < 4; i++) {
      if (body![i].x == x && body![i].y == y) {
        return true;
      }
    }
    return false;
  }
}
