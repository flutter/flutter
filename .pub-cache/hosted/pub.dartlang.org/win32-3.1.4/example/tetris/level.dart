import 'dart:math' show max;

import 'package:win32/win32.dart';

import 'drawengine.dart';
import 'piece.dart';
import 'pieceset.dart';

class Level {
  late List<List<int>> board; // The canvas / drawing board
  late DrawEngine de; // Does graphic rendering
  PieceSet pieceSet = PieceSet(); // Piece generator
  Piece? current; // Current dropping piece
  Piece? next; // Next piece

  int width; // Level width (in cells)
  int height; // Level height
  late int posX; // X coordinate of dropping piece (Cartesian system)
  int? posY; // Y coordinate of dropping piece
  int speed; // Drop a cell every _speed_ millisecs
  int lastTime; // Last time updated
  late int currentTime; // Current update time
  int score; // Player's score

  // de: used to draw the level
  // width & height: level size in cells
  Level(this.de, [this.width = 10, this.height = 20])
      : lastTime = 0,
        speed = 500,
        score = -1 {
    board =
        List.generate(width, (i) => List.generate(height, (i) => RGB(0, 0, 0)));
    next = pieceSet.randomPiece;
  }

  // Draws the level
  void drawBoard() {
    for (var i = 0; i < width; i++) {
      for (var j = 0; j < height; j++) {
        de.drawBlock(i, j, board[i][j]);
      }
    }
  }

  // Updates the level based on the current speed
  void timerUpdate() {
    // If the time isn't up, don't drop nor update
    currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - lastTime < speed) return;

    // Time's up, drop
    // If the piece hits the bottom, check if player gets score, drop the next
    // piece, increase speed, redraw info
    // If player gets score, increase more speed
    if (current == null || !move(0, -1)) {
      final lines = clearRows();
      speed = max(speed - 2 * lines, 100);
      score += 1 + lines * lines * 5;
      dropRandomPiece();
      drawScore();
      drawSpeed();
      drawNextPiece();
    }

    lastTime = DateTime.now().millisecondsSinceEpoch;
  }

  bool place(int x, int? y, Piece piece) {
    // Out of boundary or the position has been filled
    if (x + piece.width > width || isCovered(piece, x, y)) {
      return false;
    }

    posX = x;
    posY = y;

    final apt = piece.body;
    final color = piece.color;

    for (var i = 0; i < 4; i++) {
      if (y! + apt![i].y > height - 1) continue;
      board[x + apt[i].x][y + apt[i].y] = color;
    }
    return true;
  }

  // Rotates the dropping piece, returns true if successful
  bool rotate() {
    final tmp = current;

    // Move the piece if it needs some space to rotate
    final disX = max(posX + current!.height - width, 0);

    // Go to next rotation state (0-3)
    final rotation = (current!.rotation + 1) % PieceSet.numRotations;

    clear(current!);
    current = pieceSet.getPiece(current!.id, rotation);

    // Rotate successfully
    if (place(posX - disX, posY, current!)) {
      return true;
    }

    // If the piece cannot rotate due to insufficient space, undo it
    current = tmp;
    place(posX, posY, current!);
    return false;
  }

  // Moves the dropping piece, returns true if successful
  // cxDistance is horizontal movement, positive value is right
  // cyDistance is vertical movement, positive value is up (normally it's
  // negaive)
  bool move(int cxDistance, int cyDistance) {
    if (posX + cxDistance < 0 ||
        posY! + cyDistance < 0 ||
        posX + current!.width + cxDistance > width) {
      return false;
    }
    if (cxDistance < 0 && isHitLeft()) {
      return false;
    }
    if (cxDistance > 0 && isHitRight()) {
      return false;
    }
    if (cyDistance < 0 && isHitBottom()) {
      return false;
    }
    clear(current!);
    return place(posX + cxDistance, posY! + cyDistance, current!);
  }

  void clear(Piece piece) {
    final apt = piece.body;
    int x, y;
    for (var i = 0; i < 4; i++) {
      x = posX + apt![i].x;
      y = posY! + apt[i].y;

      if (x > width - 1 || y > height - 1) {
        continue;
      }
      board[posX + apt[i].x][posY! + apt[i].y] = RGB(0, 0, 0);
    }
  }

  void dropRandomPiece() {
    current = next;
    next = pieceSet.randomPiece;
    place(3, height - 1, current!);
  }

  bool isHitBottom() {
    final apt = current!.skirt;
    int x, y;
    for (var i = 0; i < apt.length; i++) {
      x = posX + apt[i].x;
      y = posY! + apt[i].y;
      if (y < height && (y == 0 || board[x][y - 1] != RGB(0, 0, 0))) {
        return true;
      }
    }
    return false;
  }

  bool isHitLeft() {
    final apt = current!.leftSide;
    int x, y;
    for (var i = 0; i < apt.length; i++) {
      x = posX + apt[i].x;
      y = posY! + apt[i].y;
      if (y > height - 1) {
        continue;
      }
      if (x == 0 || board[x - 1][y] != RGB(0, 0, 0)) {
        return true;
      }
    }
    return false;
  }

  bool isHitRight() {
    final apt = current!.rightSide;
    int x, y;
    for (var i = 0; i < apt.length; i++) {
      x = posX + apt[i].x;
      y = posY! + apt[i].y;
      if (y > height - 1) {
        continue;
      }
      if (x == width - 1 || board[x + 1][y] != RGB(0, 0, 0)) {
        return true;
      }
    }
    return false;
  }

  bool isCovered(Piece piece, int x, int? y) {
    final apt = piece.body;
    int tmpX, tmpY;
    for (var i = 0; i < 4; i++) {
      tmpX = apt![i].x + x;
      tmpY = apt[i].y + y!;
      if (tmpX > width - 1 || tmpY > height - 1) {
        continue;
      }
      if (board[tmpX][tmpY] != RGB(0, 0, 0)) {
        return true;
      }
    }
    return false;
  }

  int clearRows() {
    late bool isComplete;
    var rows = 0;

    for (var i = 0; i < height; i++) {
      for (var j = 0; j < width; j++) {
        if (board[j][i] == RGB(0, 0, 0)) {
          isComplete = false;
          break;
        }
        // The row is full
        if (j == width - 1) isComplete = true;
      }
      // If the row is full, clear it (fill with black)
      if (isComplete) {
        for (var j = 0; j < width; j++) {
          board[j][i] = RGB(0, 0, 0);
        }

        // Move rows down
        for (var k = i; k < height - 1; k++) {
          for (var m = 0; m < width; m++) {
            board[m][k] = board[m][k + 1];
          }
        }
        i = -1;
        rows++;
      }
    }
    return rows;
  }

  bool isGameOver() {
    // Exclude the current piece
    if (current != null) {
      clear(current!);
    }

    // If there's a piece on the top, game over
    for (var i = 0; i < width; i++) {
      if (board[i][height - 1] != 0) {
        if (current != null) place(posX, posY, current!);
        return true;
      }
    }

    // Put the current piece back
    if (current != null) place(posX, posY, current!);
    return false;
  }

  // Draw different kinds of info
  void drawSpeed() {
    de.drawSpeed((500 - speed) ~/ 2, width + 1, 12);
  }

  void drawScore() {
    de.drawScore(score, width + 1, 13);
  }

  void drawNextPiece() {
    de.drawNextPiece(next!, width + 1, 14);
  }
}
