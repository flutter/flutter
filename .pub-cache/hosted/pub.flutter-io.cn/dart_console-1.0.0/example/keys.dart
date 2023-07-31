import 'dart:io';

import 'package:dart_console/dart_console.dart';

final console = Console();

void main() {
  console.writeLine(
      'This sample demonstrates keyboard input. Press any key including control keys');
  console.writeLine(
      'such as arrow keys, page up/down, home, end etc. to see it echoed to the');
  console.writeLine('screen. Press Ctrl+Q to end the sample.');
  var key = console.readKey();

  while (true) {
    if (key.isControl && key.controlChar == ControlCharacter.ctrlQ) {
      console.clearScreen();
      console.resetCursorPosition();
      console.rawMode = false;
      exit(0);
    } else {
      print(key);
    }
    key = console.readKey();
  }
}
