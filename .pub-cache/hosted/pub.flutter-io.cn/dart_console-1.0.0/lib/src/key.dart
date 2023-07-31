// key.dart
//
// Representation of keyboard input and control characters.

/// Non-printable characters that can be entered from the keyboard.
enum ControlCharacter {
  none,

  ctrlA,
  ctrlB,
  ctrlC, // Break
  ctrlD, // End of File
  ctrlE,
  ctrlF,
  ctrlG, // Bell
  ctrlH, // Backspace
  tab,
  ctrlJ,
  ctrlK,
  ctrlL,
  enter,
  ctrlN,
  ctrlO,
  ctrlP,
  ctrlQ,
  ctrlR,
  ctrlS,
  ctrlT,
  ctrlU,
  ctrlV,
  ctrlW,
  ctrlX,
  ctrlY,
  ctrlZ, // Suspend

  arrowLeft,
  arrowRight,
  arrowUp,
  arrowDown,
  pageUp,
  pageDown,
  wordLeft,
  wordRight,

  home,
  end,
  escape,
  delete,
  backspace,
  wordBackspace,

  F1,
  F2,
  F3,
  F4,

  unknown
}

/// A representation of a keystroke.
class Key {
  bool isControl = false;
  String char = '';
  ControlCharacter controlChar = ControlCharacter.unknown;

  Key.printable(this.char) : assert(char.length == 1) {
    controlChar = ControlCharacter.none;
  }

  Key.control(this.controlChar) {
    char = '';
    isControl = true;
  }

  @override
  String toString() => isControl ? controlChar.toString() : char.toString();
}
