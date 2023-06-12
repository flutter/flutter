import 'dart:html';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

// Side note: To maintain readability, this example was not formatted using dart_fmt.

void main() {
  const konamiKeyCodes = <int>[
    KeyCode.UP,
    KeyCode.UP,
    KeyCode.DOWN,
    KeyCode.DOWN,
    KeyCode.LEFT,
    KeyCode.RIGHT,
    KeyCode.LEFT,
    KeyCode.RIGHT,
    KeyCode.B,
    KeyCode.A
  ];

  final result = querySelector('#result')!;

  document.onKeyUp
      // Use map() to get the keyCode
      .map((event) => event.keyCode)
      // Use bufferCount() to remember the last 10 keyCodes
      .bufferCount(10, 1)
      // Use where() to check for matching values
      .where((lastTenKeyCodes) =>
          const IterableEquality<int>().equals(lastTenKeyCodes, konamiKeyCodes))
      // Use listen() to display the result
      .listen((_) => result.innerHtml = 'KONAMI!');
}
