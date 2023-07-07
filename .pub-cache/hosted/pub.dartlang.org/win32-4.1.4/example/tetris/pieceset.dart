import 'dart:math' as math show Random;

import 'package:win32/win32.dart';

import 'piece.dart';

class Colors {
  static int red = RGB(255, 0, 0);
  static int orange = RGB(230, 130, 24);
  static int yellow = RGB(255, 255, 0);
  static int green = RGB(120, 200, 80);
  static int blue = RGB(100, 180, 255);
  static int indigo = RGB(20, 100, 200);
  static int violet = RGB(220, 180, 255);
}

// PieceSet generates 7 types of pieces. Each piece has 4 rotations, so there
// are 7 x 4 = 28 configurations in total.
//
// All 28 configurations are kept in memory after you new PieceSet(). To get
// get piece, use the `getPiece()` method or the `randomPiece` property.
class PieceSet {
  static const numRotations = 4;
  static const numPieces = 7;

  final rng = math.Random();

  final List<List<Piece>> pieces = List.generate(numPieces, (i) => <Piece>[]);

  PieceSet() {
    List<Point> tetrimino;

    // 0, I piece, red
    tetrimino = <Point>[Point(0, 0), Point(0, 1), Point(0, 2), Point(0, 3)];
    pieces[0].add(Piece(0, 0, Colors.red, tetrimino));

    // 1, L piece, orange
    tetrimino = <Point>[Point(0, 0), Point(1, 0), Point(0, 1), Point(0, 2)];
    pieces[1].add(Piece(1, 0, Colors.orange, tetrimino));

    // 2, counter-L piece, yellow
    tetrimino = <Point>[Point(0, 0), Point(1, 0), Point(1, 1), Point(1, 2)];
    pieces[2].add(Piece(2, 0, Colors.yellow, tetrimino));

    // 3, S piece, green
    tetrimino = <Point>[Point(0, 0), Point(1, 0), Point(1, 1), Point(2, 1)];
    pieces[3].add(Piece(3, 0, Colors.green, tetrimino));

    // 4, Z piece, blue
    tetrimino = <Point>[Point(1, 0), Point(2, 0), Point(0, 1), Point(1, 1)];
    pieces[4].add(Piece(4, 0, Colors.blue, tetrimino));

    // 5, Square piece, indigo
    tetrimino = <Point>[Point(0, 0), Point(1, 0), Point(0, 1), Point(1, 1)];
    pieces[5].add(Piece(5, 0, Colors.indigo, tetrimino));

    // 6, T piece, violet
    tetrimino = <Point>[Point(0, 0), Point(1, 0), Point(2, 0), Point(1, 1)];
    pieces[6].add(Piece(6, 0, Colors.violet, tetrimino));

    // Create piece rotations
    rotateAll();
  }

  Piece getPiece(int id, int rotation) {
    if (id >= numPieces || id < 0) throw ArgumentError(id);
    if (rotation >= numRotations || rotation < 0) {
      throw ArgumentError.value(rotation);
    }

    return pieces[id][rotation];
  }

  Piece get randomPiece =>
      getPiece(rng.nextInt(numPieces), rng.nextInt(numRotations));

  void rotateAll() {
    for (var i = 0; i < numPieces; i++) {
      // clone the original piece
      var clone = pieces[i].first.body.map((e) => e).toList();

      for (var j = 1; j < numRotations; j++) {
        clone = rotate(clone);
        pieces[i].add(Piece(i, j, pieces[i][0].color, clone));
      }
    }
  }

  List<Point> rotate(List<Point> apt, [int numPoints = 4]) {
    final rotated = <Point>[];

    // X' = -Y
    // Y' = X
    for (var i = 0; i < numPoints; i++) {
      final pt = Point()
        ..x = -apt[i].y
        ..y = apt[i].x;
      rotated.add(pt);
    }
    return rotated;
  }
}
