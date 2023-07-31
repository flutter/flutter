import 'dart:io';

const ansiEraseInDisplayAll = '\x1b[2J';
const ansiResetCursorPosition = '\x1b[H';

void main() {
  stdout.write(ansiEraseInDisplayAll + ansiResetCursorPosition);
}
