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
  Iterator<BoardPoint> get iterator => BoardIterator(boardRadius);

  //BoardPoint _selectedBoardPoint;
  int boardRadius; // Number of hexagons from center to edge
  int hexagonRadius; // Pixel radius of a hexagon (center to vertex)

  // Return a pixel point for a q,r point
  Point<double> boardPointToPoint(BoardPoint boardPoint) {
    return Point<double>(
      sqrt(3) * hexagonRadius * boardPoint.q + sqrt(3) / 2 * hexagonRadius * boardPoint.r,
      1.5 * hexagonRadius * boardPoint.r,
    );
  }

  Path getPathForBoardPoint(BoardPoint boardPoint) {
    final Point<double> centerOfHexZeroCenter = boardPointToPoint(boardPoint);

    // Start point of hexagon (top vertex)
    final Point<double> hexStart = Point<double>(
      centerOfHexZeroCenter.x,
      centerOfHexZeroCenter.y - hexagonRadius,
    );

    final Path hexagon = Path();
    hexagon.moveTo(hexStart.x, hexStart.y);
    hexagon.lineTo(hexStart.x + sqrt(3) / 2 * hexagonRadius, hexStart.y + 0.5 * hexagonRadius);
    hexagon.lineTo(hexStart.x + sqrt(3) / 2 * hexagonRadius, hexStart.y + 1.5 * hexagonRadius);
    hexagon.lineTo(hexStart.x, hexStart.y + 2 * hexagonRadius);
    hexagon.lineTo(hexStart.x - sqrt(3) / 2 * hexagonRadius, hexStart.y + 1.5 * hexagonRadius);
    hexagon.lineTo(hexStart.x - sqrt(3) / 2 * hexagonRadius, hexStart.y + 0.5 * hexagonRadius);
    hexagon.close();
    return hexagon;
  }
}

class BoardIterator extends Iterator<BoardPoint> {
  BoardIterator(this.boardRadius)
    : assert(boardRadius > 0);

  int boardRadius;

  @override
  BoardPoint current;

  @override
  bool moveNext() {
    // If before the first element
    if (current == null) {
      current = BoardPoint(-boardRadius, 0, false);
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
      current = BoardPoint(current.q + 1, getRRangeForQ(current.q + 1).min, false);
      return true;
    }

    // Otherwise we're just incrementing r
    current = BoardPoint(current.q, current.r + 1, false);
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
  BoardPoint(this.q, this.r, this.isSelected);

  int q;
  int r;
  bool isSelected;
}
