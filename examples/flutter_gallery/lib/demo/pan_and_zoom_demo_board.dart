import 'dart:collection' show IterableMixin;
import 'dart:math';
import 'package:flutter/material.dart' hide Gradient;

// An abstraction of the hex board logic
class Board extends Object with IterableMixin<BoardPoint> {
  Board({
    @required this.boardRadius,
    @required this.hexagonRadius,
  })
    : assert(boardRadius > 0),
      assert(hexagonRadius > 0);

  @override
  Iterator<BoardPoint> get iterator => BoardIterator(boardRadius, selected);

  BoardPoint selected;
  int boardRadius; // Number of hexagons from center to edge
  double hexagonRadius; // Pixel radius of a hexagon (center to vertex)

  BoardPoint pointToBoardPoint(Offset point) {
    return BoardPoint(
      ((sqrt(3) / 3 * point.dx - 1 / 3 * point.dy) / hexagonRadius).round(),
      ((2 / 3 * point.dy) / hexagonRadius).round(),
    );
  }

  // Return a pixel point for a q,r point
  Point<double> boardPointToPoint(BoardPoint boardPoint) {
    return Point<double>(
      sqrt(3) * hexagonRadius * boardPoint.q + sqrt(3) / 2 * hexagonRadius * boardPoint.r,
      1.5 * hexagonRadius * boardPoint.r,
    );
  }

  Path getPathForBoardPoint(BoardPoint boardPoint) {
    final Point<double> centerOfHexZeroCenter = boardPointToPoint(boardPoint);

    // Start point of hexagon (top vertex).
    // Give one pixel of padding between hexagons.
    final Point<double> hexStart = Point<double>(
      centerOfHexZeroCenter.x + 1,
      centerOfHexZeroCenter.y - hexagonRadius + 1,
    );

    final double hexagonRadiusPadded = hexagonRadius - 1;

    final Path hexagon = Path();
    hexagon.moveTo(hexStart.x, hexStart.y);
    hexagon.lineTo(hexStart.x + sqrt(3) / 2 * hexagonRadiusPadded, hexStart.y + 0.5 * hexagonRadiusPadded);
    hexagon.lineTo(hexStart.x + sqrt(3) / 2 * hexagonRadiusPadded, hexStart.y + 1.5 * hexagonRadiusPadded);
    hexagon.lineTo(hexStart.x, hexStart.y + 2 * hexagonRadiusPadded);
    hexagon.lineTo(hexStart.x - sqrt(3) / 2 * hexagonRadiusPadded, hexStart.y + 1.5 * hexagonRadiusPadded);
    hexagon.lineTo(hexStart.x - sqrt(3) / 2 * hexagonRadiusPadded, hexStart.y + 0.5 * hexagonRadiusPadded);
    hexagon.close();
    return hexagon;
  }

  Board selectBoardPoint(BoardPoint boardPoint) {
    final Board nextBoard = Board(
      boardRadius: boardRadius,
      hexagonRadius: hexagonRadius,
    );
    nextBoard.selected = boardPoint;
    return nextBoard;
  }
}

class BoardIterator extends Iterator<BoardPoint> {
  BoardIterator(this.boardRadius, this.selected)
    : assert(boardRadius > 0);

  int boardRadius;
  BoardPoint selected;

  @override
  BoardPoint current;

  @override
  bool moveNext() {
    // If before the first element
    if (current == null) {
      current = BoardPoint(-boardRadius, 0);
      return true;
    }

    final Range rRange = getRRangeForQ(current.q);

    // If at or after the last element
    if (current.q >= boardRadius && current.r >= rRange.max) {
      current = null;
      return false;
    }

    // If wrapping from one q to the next
    if (current.r >= rRange.max) {
      current = BoardPoint(current.q + 1, getRRangeForQ(current.q + 1).min);
      return true;
    }

    // Otherwise we're just incrementing r
    current = BoardPoint(current.q, current.r + 1);
    return true;
  }

  // For a given q axial coordinate, get the range of possible r values
  Range getRRangeForQ(int q) {
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
}

// A range of q/r board coordinate values
class Range {
  Range(this.min, this.max)
    : assert(min <= max, '$min must be less than or equal to $max');

  int min;
  int max;
}

// A location on the board in axial coordinates
class BoardPoint {
  BoardPoint(this.q, this.r);

  int q;
  int r;

  @override
  String toString() {
    return 'BoardPoint(${q.toString()}, ${r.toString()})';
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! BoardPoint) {
      return false;
    }
    BoardPoint boardPoint = other;
    return boardPoint.q == q && boardPoint.r == r;
  }

  @override
  int get hashCode {
    final String string = q.toString() + r.toString();
    return int.parse(string);
  }
}
