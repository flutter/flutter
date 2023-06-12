import 'dart:math' show Random;

import 'package:win32/win32.dart';

import 'piece.dart';

// PieceSet generates 7 types of pieces. Each piece has 4 rotations, so there
// are 7 x 4 = 28 configurations in total.
//
// All 28 configurations are kept in memory after you new PieceSet(). To get
// get piece, use the `getPiece()` method or the `randomPiece` property.
class PieceSet {
  static const numRotations = 4;
  static const numPieces = 7;

  final rng = Random();

  List<List<Piece?>> pieces =
      List.generate(numPieces, (i) => List<Piece?>.filled(numRotations, null));

  PieceSet() {
    List<Point> tetrimino;

    // 0, I piece, red
    tetrimino = <Point>[Point(0, 0), Point(0, 1), Point(0, 2), Point(0, 3)];
    pieces[0][0] = Piece(0, 0, RGB(255, 0, 0), tetrimino);

    // 1, L piece, orange
    tetrimino = <Point>[Point(0, 0), Point(1, 0), Point(0, 1), Point(0, 2)];
    pieces[1][0] = Piece(1, 0, RGB(230, 130, 24), tetrimino);

    // 2, counter-L piece, yellow
    tetrimino = <Point>[Point(0, 0), Point(1, 0), Point(1, 1), Point(1, 2)];
    pieces[2][0] = Piece(2, 0, RGB(255, 255, 0), tetrimino);

    // 3, S piece, green
    tetrimino = <Point>[Point(0, 0), Point(1, 0), Point(1, 1), Point(2, 1)];
    pieces[3][0] = Piece(3, 0, RGB(120, 200, 80), tetrimino);

    // 4, Z piece, blue
    tetrimino = <Point>[Point(1, 0), Point(2, 0), Point(0, 1), Point(1, 1)];
    pieces[4][0] = Piece(4, 0, RGB(100, 180, 255), tetrimino);

    // 5, Square piece, dark blue
    tetrimino = <Point>[Point(0, 0), Point(1, 0), Point(0, 1), Point(1, 1)];
    pieces[5][0] = Piece(5, 0, RGB(20, 100, 200), tetrimino);

    // 6, T piece, purple
    tetrimino = <Point>[Point(0, 0), Point(1, 0), Point(2, 0), Point(1, 1)];
    pieces[6][0] = Piece(6, 0, RGB(220, 180, 255), tetrimino);

    // Create piece rotations
    rotateAll();
  }

  Piece? getPiece(int id, int rotation) {
    if (id >= numPieces || id < 0 || rotation >= numRotations || rotation < 0) {
      return null;
    }
    return pieces[id][rotation];
  }

  Piece? get randomPiece =>
      getPiece(rng.nextInt(numPieces), rng.nextInt(numRotations));

  void rotateAll() {
    for (var i = 0; i < numPieces; i++) {
      // clone the original piece
      var clone = pieces[i][0]!.body!.map((e) => e).toList();

      for (var j = 1; j < numRotations; j++) {
        clone = rotate(clone);
        if (pieces[i][j] != null) {
          pieces[i].removeAt(j);
        }
        pieces[i][j] = Piece(i, j, pieces[i][0]!.color, clone);
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
