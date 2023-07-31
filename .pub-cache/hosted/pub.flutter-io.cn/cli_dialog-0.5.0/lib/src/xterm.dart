import 'dart:io';
import 'keys.dart';

/// Abstract class providing some key codes which can be statically accessed.
abstract class Keys {
  /// Arrow down. Consists of three bytes.
  /// For historical reasons, you can also use 's' instead of arrow down on Windows.
  /// It is packed into a single element list in order to not break the spread syntax.
  static final arrowDown = Platform.isWindows ? [WIN_DOWN] : [27, 91, 66];

  /// Arrows up. Consists of three bytes in Unix like systems (including MacOS).
  /// For historical reasons, you can also use 'w' insted of arrow up on Windows.
  /// It is packed into a single element list in order to not break the spread syntax.
  static final arrowUp = Platform.isWindows ? [WIN_UP] : [27, 91, 65];

  /// Enter key. Single byte.
  static final enter = Platform.isWindows ? WIN_ENTER : 10;
}

/// Abstract class providing XTerm escape sequences
abstract class XTerm {
  /// This is actually just a string but it does something
  /// so I decided to wrap it into a method
  static String blankRemaining() => '\u001b[0K';

  /// Bold output.
  static String bold(str) => '\u001b[1m' + str + reset;

  /// Gray color.
  static String gray(str) => '\u001b[38;5;246m' + str + reset;

  /// Green color.
  static String green(str) => '\u001b[32m' + str + reset;

  /// The reverse of '\n'. Goes to the beginning of the previous line.
  static String moveUp(n) => '\u001b[${n}A';

  /// Use [moveUp], concatenate your string ([str]) and then blank the remaining line.
  static String replacePreviousLine(str) => moveUp(1) + str + blankRemaining();

  /// Reset XTerm sequence. This is always applied after using some other sequence.
  static var reset = '\u001b[0m';

  /// UTF-16 char for selecting an item in [ListChooser].
  /// Formally called HEAVY RIGHT-POINTING ANGLE QUOTATION MARK ORNAMENT.
  /// On windows a simple > character is used
  /// See: https://codepoints.net/U+276F
  static String rightIndicator() =>
      Platform.isWindows ? teal('>') : teal('\u276F');

  /// Teal (=blue/green) color.
  static String teal(str) => '\u001b[38;5;6m' + str + reset;
}
