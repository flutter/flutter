import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dart_console/dart_console.dart';

final console = Console();
final random = Random();

final int rows = console.windowHeight;
final int cols = console.windowWidth;
final int size = rows * cols;

final temp = List<bool>.filled(size, false, growable: false);
final data =
    List<bool>.generate(size, (i) => random.nextBool(), growable: false);

final buffer = StringBuffer();

bool done = false;

final neighbors = [
  [-1, -1],
  [0, -1],
  [1, -1],
  [-1, 0],
  [1, 0],
  [-1, 1],
  [0, 1],
  [1, 1],
];

void draw() {
  console.setBackgroundColor(ConsoleColor.black);
  console.setForegroundColor(ConsoleColor.blue);
  console.clearScreen();

  buffer.clear();

  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      final index = row * rows + col;
      buffer.write(data[index] ? '#' : ' ');
    }
    buffer.write(console.newLine);
  }

  console.write(buffer.toString());
}

int numLiveNeighbors(int row, int col) {
  var sum = 0;
  for (var i = 0; i < 8; i++) {
    final x = col + neighbors[i][0];
    if (x < 0 || x >= cols) continue;
    final y = row + neighbors[i][1];
    if (y < 0 || y >= rows) continue;
    sum += data[y * rows + x] ? 1 : 0;
  }
  return sum;
}

/*
 * 1. Any live cell with fewer than two live neighbors dies, as if caused
 *    by underpopulation.
 * 2. Any live cell with two or three live neighbors lives on to the next
 *    generation.
 * 3. Any live cell with more than three live neighbors dies, as if by
 *    overpopulation.
 * 4. Any dead cell with exactly three live neighbors becomes a live cell, as
 *    if by reproduction.
 */
void update() {
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      final n = numLiveNeighbors(row, col);
      final index = row * rows + col;
      final v = data[index];
      temp[index] = (v == true && (n == 2 || n == 3)) || (v == false && n == 3);
    }
  }
  data.setAll(0, temp);
}

void input() {
  final key = console.readKey();
  if (key.isControl) {
    switch (key.controlChar) {
      case ControlCharacter.escape:
        done = true;
        break;
      default:
    }
  }
}

void resetConsole() {
  console.clearScreen();
  console.resetCursorPosition();
  console.resetColorAttributes();
  console.rawMode = false;
}

void crash(String message) {
  resetConsole();
  console.write(message);
  exit(1);
}

void quit() {
  resetConsole();
  exit(0);
}

void main(List<String> arguments) {
  try {
    console.rawMode = false;
    console.hideCursor();

    Timer.periodic(const Duration(milliseconds: 200), (t) {
      draw();
      update();
      //input(); // TODO: need async input
      if (done) quit();
    });
  } catch (exception) {
    crash(exception.toString());
    rethrow;
  }
}
