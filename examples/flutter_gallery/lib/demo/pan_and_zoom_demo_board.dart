import 'dart:collection' show IterableMixin;
import 'dart:math';
import 'dart:ui' show Vertices;
import 'package:flutter/material.dart' hide Gradient;
import 'package:vector_math/vector_math_64.dart' show Vector3;

// An abstraction of the hex board logic
class Board extends Object with IterableMixin<BoardPoint> {
  Board({
    @required this.boardRadius,
    @required this.hexagonRadius,
    @required this.hexagonMargin,
    this.selected,
    this.boardPoints,
  })
    : assert(boardRadius > 0),
      assert(hexagonRadius > 0),
      assert(hexagonMargin >= 0) {
    // Set up the positions for the center hexagon where the entire board is
    // centered on the origin.
    // Start point of hexagon (top vertex)
    final Point<double> hexStart = Point<double>(
      0,
      -hexagonRadius,
    );
    final double hexagonRadiusPadded = hexagonRadius - hexagonMargin;
    final double centerToFlat = sqrt(3) / 2 * hexagonRadiusPadded;
    positionsForHexagonAtOrigin = <Offset>[
      Offset(hexStart.x, hexStart.y),
      Offset(hexStart.x + centerToFlat, hexStart.y + 0.5 * hexagonRadiusPadded),
      Offset(hexStart.x + centerToFlat, hexStart.y + 1.5 * hexagonRadiusPadded),
      Offset(hexStart.x + centerToFlat, hexStart.y + 1.5 * hexagonRadiusPadded),
      Offset(hexStart.x, hexStart.y + 2 * hexagonRadiusPadded),
      Offset(hexStart.x, hexStart.y + 2 * hexagonRadiusPadded),
      Offset(hexStart.x - centerToFlat, hexStart.y + 1.5 * hexagonRadiusPadded),
      Offset(hexStart.x - centerToFlat, hexStart.y + 1.5 * hexagonRadiusPadded),
      Offset(hexStart.x - centerToFlat, hexStart.y + 0.5 * hexagonRadiusPadded),
    ];

    if (boardPoints == null) {
      // Generate boardPoints for a fresh board.
      boardPoints = <BoardPoint>[];
      BoardPoint boardPoint = _getNextBoardPoint(null);
      while (boardPoint != null) {
        boardPoints.add(boardPoint);
        boardPoint = _getNextBoardPoint(boardPoint);
      }
    }
  }

  int boardRadius; // Number of hexagons from center to edge
  double hexagonRadius; // Pixel radius of a hexagon (center to vertex)
  double hexagonMargin; // Margin between hexagons
  List<Offset> positionsForHexagonAtOrigin;
  BoardPoint selected;
  List<BoardPoint> boardPoints;

  @override
  Iterator<BoardPoint> get iterator =>
    BoardIterator(boardPoints);

  // For a given q axial coordinate, get the range of possible r values
  Range _getRRangeForQ(int q) {
    int rStart;
    int rEnd;
    if (q <= 0) {
      rStart = -boardRadius - q;
      rEnd = boardRadius;
    } else if (q > 0) {
      rEnd = boardRadius - q;
      rStart = -boardRadius;
    }

    return Range(rStart, rEnd);
  }

  // Get the BoardPoint that comes after the given BoardPoint. If given null,
  // returns the origin BoardPoint. If given BoardPoint is the last, returns
  // null.
  BoardPoint _getNextBoardPoint (BoardPoint boardPoint) {
    // If before the first element
    if (boardPoint == null) {
      return BoardPoint(-boardRadius, 0);
    }

    final Range rRange = _getRRangeForQ(boardPoint.q);

    // If at or after the last element
    if (boardPoint.q >= boardRadius && boardPoint.r >= rRange.max) {
      return null;
    }

    // If wrapping from one q to the next
    if (boardPoint.r >= rRange.max) {
      return BoardPoint(boardPoint.q + 1, _getRRangeForQ(boardPoint.q + 1).min);
    }

    // Otherwise we're just incrementing r.
    return BoardPoint(boardPoint.q, boardPoint.r + 1);
  }

  // Check if the board point is actually on the board.
  bool _validateBoardPoint(BoardPoint boardPoint) {
    final BoardPoint center = BoardPoint(0, 0);
    final int distanceFromCenter = getDistance(center, boardPoint);
    return distanceFromCenter <= boardRadius;
  }

  // Get the distance between two BoardPoins.
  static int getDistance(BoardPoint a, BoardPoint b) {
    final Vector3 a3 = a.getCubeCoords();
    final Vector3 b3 = b.getCubeCoords();
    return
      ((a3.x - b3.x).abs() + (a3.y - b3.y).abs() + (a3.z - b3.z).abs()) ~/ 2;
  }

  // Return the q,r BoardPoint for a point in the scene, where the origin is in
  // the center of the board in both coordinate systems. If no BoardPoint at the
  // location, return null.
  BoardPoint pointToBoardPoint(Offset point) {
    final BoardPoint boardPoint = BoardPoint(
      ((sqrt(3) / 3 * point.dx - 1 / 3 * point.dy) / hexagonRadius).round(),
      ((2 / 3 * point.dy) / hexagonRadius).round(),
    );

    if (!_validateBoardPoint(boardPoint)) {
      return null;
    }

    return boardPoints.firstWhere((BoardPoint boardPointI) =>
      boardPointI.q == boardPoint.q && boardPointI.r == boardPoint.r,
    );
  }

  // Return a scene point for the center of a hexagon given its q,r point.
  Point<double> boardPointToPoint(BoardPoint boardPoint) {
    return Point<double>(
      sqrt(3) * hexagonRadius * boardPoint.q + sqrt(3) / 2 * hexagonRadius * boardPoint.r,
      1.5 * hexagonRadius * boardPoint.r,
    );
  }

  // Return a new board with the given BoardPoint selected.
  Board selectBoardPoint(BoardPoint boardPoint) {
    final Board nextBoard = Board(
      boardRadius: boardRadius,
      hexagonRadius: hexagonRadius,
      hexagonMargin: hexagonMargin,
      selected: boardPoint,
      boardPoints: boardPoints,
    );
    return nextBoard;
  }

  // Return a new board where boardPoint has the given color.
  Board setBoardPointColor(BoardPoint boardPoint, Color color) {
    final BoardPoint nextBoardPoint = boardPoint.setColor(color);
    final int boardPointIndex = boardPoints.indexWhere((BoardPoint boardPointI) =>
      boardPointI.q == boardPoint.q && boardPointI.r == boardPoint.r
    );
    final List<BoardPoint> nextBoardPoints = List<BoardPoint>.from(boardPoints);
    nextBoardPoints[boardPointIndex] = nextBoardPoint;
    final BoardPoint selectedBoardPoint = boardPoint == selected
      ? nextBoardPoint
      : selected;
    return Board(
      boardRadius: boardRadius,
      hexagonRadius: hexagonRadius,
      hexagonMargin: hexagonMargin,
      selected: selectedBoardPoint,
      boardPoints: nextBoardPoints,
    );
  }

  // Get Vertices that can be drawn to a Canvas for the given BoardPoint.
  Vertices getVerticesForBoardPoint(BoardPoint boardPoint, Color color) {
    final Point<double> centerOfHexZeroCenter = boardPointToPoint(boardPoint);

    final List<Offset> positions = positionsForHexagonAtOrigin.map((Offset offset) {
      return offset.translate(centerOfHexZeroCenter.x, centerOfHexZeroCenter.y);
    }).toList();

    return Vertices(
      VertexMode.triangleFan,
      positions,
      colors: List<Color>.filled(positions.length, color),
    );
  }
}

class BoardIterator extends Iterator<BoardPoint> {
  BoardIterator(this.boardPoints);

  List<BoardPoint> boardPoints;
  int currentIndex;

  @override
  BoardPoint current;

  @override
  bool moveNext() {
    if (currentIndex == null) {
      currentIndex = 0;
    } else {
      currentIndex++;
    }

    if (currentIndex >= boardPoints.length) {
      current = null;
      return false;
    }

    current = boardPoints[currentIndex];
    return true;
  }
}

// A range of q/r board coordinate values
class Range {
  Range(this.min, this.max)
    : assert(min <= max, '$min must be less than or equal to $max');

  int min;
  int max;
}

Set<Color> boardPointColors = <Color>{
  Colors.grey,
  Colors.black,
  Colors.red,
  Colors.blue,
};

// A location on the board in axial coordinates
class BoardPoint {
  BoardPoint(this.q, this.r, {
    this.color = Colors.grey,
  });

  int q;
  int r;
  Color color;

  @override
  String toString() {
    return 'BoardPoint($q, $r, $color)';
  }

  // Only compares by location
  @override
  bool operator ==(dynamic other) {
    if (other is! BoardPoint) {
      return false;
    }
    final BoardPoint boardPoint = other;
    return boardPoint.q == q && boardPoint.r == r;
  }

  @override
  int get hashCode {
    final String string = q.toString() + r.toString();
    return int.parse(string);
  }

  BoardPoint setColor(Color nextColor) {
    return BoardPoint(
      q,
      r,
      color: nextColor,
    );
  }

  // Convert from q,r axial coords to x,y,z cube coords
  Vector3 getCubeCoords() {
    return Vector3(
      q.toDouble(),
      r.toDouble(),
      (-q - r).toDouble(),
    );
  }
}
