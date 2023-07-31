// rawkeys.dart
//
// Diagnostic test for tracking down differences in raw key input from different
// platforms.

import 'dart:io';

import 'package:dart_console/dart_console.dart';

final console = Console();

void main() {
  console.writeLine('Purely for testing purposes.');
  console.writeLine();
  console.writeLine(
      'This method echos what stdin reads. Useful for testing unusual terminals.');
  console.writeLine("Press 'q' to return to the command prompt.");
  console.rawMode = true;

  while (true) {
    var codeUnit = 0;
    while (codeUnit <= 0) {
      codeUnit = stdin.readByteSync();
    }

    if (codeUnit < 0x20 || codeUnit == 0x7F) {
      print('${codeUnit.toRadixString(16)}\r');
    } else {
      print(
          '${codeUnit.toRadixString(16)} (${String.fromCharCode(codeUnit)})\r');
    }

    if (String.fromCharCode(codeUnit) == 'q') {
      console.rawMode = false;
      exit(0);
    }
  }
}
