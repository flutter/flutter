// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io"; // For writing directly to file.

import "package:charcode/ascii.dart";

import "src/uflags.dart";

/// Generates Dart constant declarations for character codes.
///
/// Usage:
/// ```text
///   charcode (character-range | rename | flags)*
/// ```
///
/// ## Character ranges
///
/// A `character-range` is either
/// * a single charater,
/// * an escaped character `\n`, `\r`, `\t`, `\xHH`, `\uHHHH` or `\DD*`,
///   where `H` is a hexadecimal digit and `D` is a decimal digit.
/// * two characters separated by `-` or the `\d`, `\w` or `\s` escapes, or
/// * a sequence of character ranges.
/// Examples include `a`, `a-z`, or `abe-gz`.
/// Accepts `\n`, `\r`, `\t`, `\`, `\-`, `\xHH` and `\uHHHHHH` escapes.
///
/// A (re)name declaration is a single or escaped character, a `=` and an
/// identifier name, optionally followed by a `:` and a description
/// Example: `x=cross:"A cross product."`.
/// The naming names or renames the character and adds or changes
/// the associated description.
/// It will not add the character to the output.
/// Following occurrences of the character will use the new name.
/// Example: `y y=why x-z` will generate `$y` for the character
/// code of "y", then `$x`, `$why` and `$z` as well.
///
/// ## Flags
///
/// `-o` followed by a file name makes output be written to that file
/// instead of to stdout.
///
/// `-f` followed by a file name will read declarations from that file
/// as well as from the command line. Each line in the file is handled
/// like a command line argument (not including flags.)
/// Intended for importing a set of name declarations.
/// The line is not split on spaces, so it allows comments with spaces
/// like:
/// ```text
/// x=cross:The cross character.
/// ```
///
/// `-p` followed by zero more characters makes those characters be
/// used as prefix for later generated names. The default is the `$`
/// character. If setting an empty prefix, names starting with digits
/// will still use the previously configured prefix character since
/// identifiers cannot start with a digit.
///
/// `-h` includes declarations for HTML entity names.
///
/// `--` disables flags in the following command line arguments.
void main(List<String> args, [StringSink? output]) {
  output ??= stdout;
  String? outputFile;
  var declarations = CharcodeBuilder();
  addAscii(declarations);

  var flags = Flags<String>()
    ..add(FlagConfig("?", null, "help",
        description: "Display this usage information"))
    ..add(FlagConfig.optionalParameter("p", "p", "prefix", "",
        description: "Sets prefix for later generated constants.",
        valueDescription: "PREFIX"))
    ..add(FlagConfig.requiredParameter("o", "o", "output",
        description: "Write generated code to file instead of stdout",
        valueDescription: "FILE"))
    ..add(FlagConfig.requiredParameter("f", "f", "input",
        description:
            "Read instructions from file. Each line of the file is treated as a non-flag command line entry.",
        valueDescription: "FILE"))
    ..add(FlagConfig("h", "h", "html",
        description: "Include HTML entity names in predefined names"));

  for (var arg in parseFlags(flags, args, stderr.writeln)) {
    var key = arg.key;
    if (!arg.isFlag) {
      // Not a flag, value is command line argument.
      declarations.parse(arg.value!);
    } else {
      switch (key) {
        case "p":
          var prefix = arg.value!;
          if (prefix.isNotEmpty &&
              (!_isIdentifierPart(prefix) || !_startsWithNonDigit(prefix))) {
            warn("Invalid prefix, must be valid identifier: $prefix");
            continue;
          }
          declarations.prefix = prefix;
          break;
        case "o":
          if (arg.value != null) {
            outputFile = arg.value;
          } else {
            warn("No file name after `-o` option");
          }
          break;
        case "f":
          var inputFile = arg.value;
          if (inputFile != null) {
            var input = File(inputFile).readAsLinesSync();
            for (var line in input) {
              line = line.trimRight();
              if (line.isNotEmpty) declarations.parse(line);
            }
          } else {
            warn("No file name after `-f` option");
          }
          break;
        case "h":
          addHtmlEntities(declarations);
          break;
        case "?":
          var buffer = StringBuffer(usageString);

          flags.writeUsage(buffer);
          output.write(buffer);
          if (output is IOSink) output.flush();
          return;
      }
    }
  }

  if (outputFile == null) {
    declarations.writeTo(output);
  } else {
    var file = File(outputFile).openWrite();
    declarations.writeTo(file);
    file.close();
  }
}

/// Emits warning message.
void warn(String warning) {
  stderr.writeln(warning);
}

/// A single declaration to be written to the output.
class Entry implements Comparable<Entry> {
  /// The code point.
  final int charCode;

  /// The non-prefixed name to be given
  final String name;

  /// The prefix to put before the name.
  ///
  /// The prefix may be empty, but it won't be if
  /// the name be used as an identifier by itself
  /// (which means it starts with a digit).
  final String prefix;

  /// Any documentation to add to the declaration.
  final String? comment;

  Entry(this.charCode, this.name, this.prefix, this.comment);

  /// Emits a declaration to [output].
  ///
  /// The constant declaration declares the identifier [prefix]+[name]
  /// to have the value [codePoint].
  void writeTo(StringSink output) {
    var hex = charCode.toRadixString(16).padLeft(2, "0");
    if (comment != null) {
      output.writeln("/// $comment");
    }
    output.writeln("const int $prefix$name = 0x$hex;");
  }

  /// Orders entries by [charCode] first, then by prefixed and name.
  @override
  int compareTo(Entry other) {
    var delta = charCode - other.charCode;
    if (delta == 0) {
      delta = prefix.compareTo(other.prefix);
      if (delta == 0) {
        delta = name.compareTo(other.name);
      }
    }
    return delta;
  }
}

/// A name and optional description currently assigned to a code point.
class CharacterDeclaration {
  /// The unprefixed name to use for the code point.
  final String name;

  /// An optional description.
  final String? description;
  CharacterDeclaration(this.name, this.description);
}

/// Character code declaration builder.
///
/// Remembers names and descriptions assigned to code points,
/// and accumulates requestes for declarations for a number
/// of those.
/// Allows the prefix to be changed between declaration
/// requests.
class CharcodeBuilder {
  /// Prefix used for all characters being added.
  String _prefix = r"$";

  /// Reserve prefix used for digits when [_prefix] is empty.
  String _reservePrefix = r"$";

  final Map<int, CharacterDeclaration> _declarations = {};

  final Set<String> _entryNames = {};

  final List<Entry> _entries = [];

  void parse(String arg) {
    var scanner = CharScanner(arg);
    var allowRename = true;
    while (true) {
      var start = scanner.index;

      var char = scanner.next();
      if (char < 0) break;
      if (char == $backslash) {
        var escape = interpretCharEscape(scanner);
        if (escape >= 0) {
          char = escape;
        } else if (interpretRangeEscape(scanner)) {
          allowRename = false;
          continue;
        }
      }
      var peek = scanner.peek;
      if (allowRename && peek == $equal) {
        // A rename.
        scanner.skip();
        var newName = scanner.rest;
        var description = _declarations[char]?.description;
        var colon = newName.indexOf(":");
        if (colon >= 0) {
          description = newName.substring(colon + 1);
          newName = newName.substring(0, colon);
        }
        if (newName.isEmpty || !_isIdentifierPart(newName)) {
          warn("Invalid name: $arg");
        }
        rename(char, newName, description);
        break;
      }
      allowRename = false;
      if (peek != $minus) {
        addChar(char);
      } else {
        var afterChar = scanner.index;
        scanner.skip();
        var secondChar = scanner.next();
        if (secondChar < 0) {
          // Trailing `-`.
          addChar(char);
          addChar(peek);
          continue;
        }
        if (secondChar == $backslash) {
          var escape = interpretCharEscape(scanner);
          if (escape >= 0) secondChar = escape;
        }
        if (char <= secondChar) {
          addCharRange(char, secondChar);
        } else {
          warn(
              "Invalid range, end before start: ${scanner.input.substring(start, scanner.index)}");
          addChar(char);
          scanner.index = afterChar;
        }
      }
    }
  }

  /// Recognize single-character escapes.
  ///
  /// - `\n`: Line feed
  /// - `\r`: Carriage return
  /// - `\t`: Tab
  /// - `\x..`: Hex escape, up to two digits.
  /// - `\u......`: Hex escape, up to six digits.
  /// - `\[0-9]+`: Decimal escape.
  /// - `\-` and `\\`: Identity escapes.
  static int interpretCharEscape(CharScanner scanner) {
    if (scanner.hasNext) {
      var char = scanner.next();
      if (char == $n) return $lf;
      if (char == $r) return $cr;
      if (char == $t) return $tab;
      if (char == $u) return scanner.hex(6);
      if (char == $x) return scanner.hex(2);
      if (char == $backslash) return char;
      if (char == $minus) return char;
      if (_isDigit(char)) return scanner.dec(char);
      scanner.index--;
    }
    return -1;
  }

  /// Renames `charCode` to `name` in following declarations.
  ///
  /// Returns whether the name is valid as an identifier.
  /// If it is not valid, no change is made.
  bool rename(int charCode, String name, [String? description]) {
    if (!_isIdentifierPart(name)) return false;
    _declarations[charCode] = CharacterDeclaration(name, description);
    return true;
  }

  /// Adds a single character to the output.
  bool addChar(int charCode) {
    var declaration = _declarations[charCode];
    if (declaration == null) return false;
    var prefix = _prefix;
    if (!_startsWithNonDigit(declaration.name)) prefix = _reservePrefix;
    var name = prefix + declaration.name;
    if (_entryNames.contains(name)) {
      warn("Existing declaration with name \"$name\" for character "
          "'${String.fromCharCode(charCode)}' "
          "(U+${charCode.toRadixString(16).toUpperCase().padLeft(4, "0")})");
      return false;
    }
    _entries.add(
        Entry(charCode, declaration.name, prefix, declaration.description));
    _entryNames.add(name);
    return true;
  }

  /// Adds a range of characters, both ends inclusive.
  ///
  /// If a character in the range has no name, nothing is emitted fo rit.
  void addCharRange(int start, int end) {
    for (var charCode = start; charCode <= end; charCode++) {
      addChar(charCode); // Ignore return value.
    }
  }

  /// The current prefix used to prefix declarations.
  ///
  /// May be emtpy, otherwise needs to be a valid identifier.
  String get prefix => _prefix;
  set prefix(String prefix) {
    if (!_isIdentifierPart(prefix) ||
        (prefix.isNotEmpty && !_startsWithNonDigit(prefix))) {
      throw ArgumentError.value(prefix, "Not a valid identifier start");
    }
    _prefix = prefix;
    if (prefix.isNotEmpty) {
      _reservePrefix = prefix;
    }
  }

  /// Emit all the accumulated declarations on [output].
  void writeTo(StringSink output) {
    _entries.sort((a, b) => a.charCode - b.charCode);
    var separator = "";
    for (var entry in _entries) {
      output.write(separator);
      entry.writeTo(output);
      separator = "\n";
    }
  }

  bool interpretRangeEscape(CharScanner scanner) {
    if (!scanner.hasNext) return false;
    var char = scanner.peek;
    if (char == $d) {
      addCharRange($0, $9);
    } else if (char == $s) {
      addChar($space);
      addChar($tab);
      addChar($cr);
      addChar($lf);
    } else if (char == $w) {
      addCharRange($0, $9);
      addCharRange($A, $Z);
      addCharRange($a, $z);
      addChar($_);
      addChar($$);
    } else {
      return false;
    }
    scanner.skip();
    return true;
  }
}

/// Whether the string starts with a non-digit.
///
/// Only used on strings that have passed [_isIdentifierPart],
/// and if those start with a non-digit, the string is a valid identifier.
bool _startsWithNonDigit(String string) =>
    string.isNotEmpty && (string.codeUnitAt(0) ^ $0) > 9;

/// Whether [string] contains only characters that can be in an identifier.
bool _isIdentifierPart(String string) {
  for (var i = 0; i < string.length; i++) {
    var char = string.codeUnitAt(i);
    if (char ^ $0 <= 9) continue;
    var lowerCaseChar = char | 0x20;
    if (lowerCaseChar >= $a && lowerCaseChar <= $z) continue;
    if (char == $$ || char == $_) continue;
    return false;
  }
  return true;
}

class CharScanner {
  final String input;
  int index = 0;
  CharScanner(this.input);
  // The next character of input.
  int get peek => index < input.length ? input.codeUnitAt(index) : -1;

  bool get hasNext => index < input.length;

  void skip() {
    if (index >= input.length) throw StateError("Nothing to skip");
    index++;
  }

  String get rest => input.substring(index);

  int next() => index < input.length ? input.codeUnitAt(index++) : -1;

  /// Parses a hex number with at most [maxDigits] digits.
  int hex(int maxDigits) {
    var result = 0;
    while (maxDigits > 0 && index < input.length) {
      var char = input.codeUnitAt(index);
      var hexValue = _hexValue(char);
      if (hexValue < 0) break;
      result = result * 16 + hexValue;
      maxDigits--;
      index++;
    }
    return result;
  }

  /// Parses a decimal number with the first digit already read.
  int dec(int firstDigit) {
    var result = firstDigit ^ 0x30;
    while (index < input.length) {
      var char = input.codeUnitAt(index);
      var digit = char ^ 0x30;
      if (digit > 9) break;
      result = result * 10 + digit;
      index++;
    }
    return result;
  }

  static int _hexValue(int char) {
    var digit = char ^ 0x30;
    if (digit <= 9) return digit;
    var lc = (char | 0x20);
    if (lc >= 0x61 && lc <= 0x66) return lc - (0x61 - 10);
    return -1;
  }
}

bool _isDigit(int char) => (char ^ 0x30) <= 9;

void addAscii(CharcodeBuilder descriptions) {
  // ASCII character comments and default names.
  descriptions
    // Control characters
    ..rename(0x00, "nul", '"Null character" control character.')
    ..rename(0x01, "soh", '"Start of Header" control character.')
    ..rename(0x02, "stx", '"Start of Text" control character.')
    ..rename(0x03, "etx", '"End of Text" control character.')
    ..rename(0x04, "eot", '"End of Transmission" control character.')
    ..rename(0x05, "enq", '"Enquiry" control character.')
    ..rename(0x06, "ack", '"Acknowledgment" control character.')
    ..rename(0x07, "bel", '"Bell" control character.')
    ..rename(0x08, "bs", '"Backspace" control character.')
    ..rename(0x09, "tab", '"Horizontal Tab" control character, common name.')
    ..rename(0x0A, "lf", '"Line feed" control character.')
    ..rename(0x0B, "vt", '"Vertical Tab" control character.')
    ..rename(0x0C, "ff", '"Form feed" control character.')
    ..rename(0x0D, "cr", '"Carriage return" control character.')
    ..rename(0x0E, "so", '"Shift Out" control character.')
    ..rename(0x0F, "si", '"Shift In" control character.')
    ..rename(0x10, "dle", '"Data Link Escape" control character.')
    ..rename(0x11, "dc1", '"Device Control 1" control character (oft. XON).')
    ..rename(0x12, "dc2", '"Device Control 2" control character.')
    ..rename(0x13, "dc3", '"Device Control 3" control character (oft. XOFF).')
    ..rename(0x14, "dc4", '"Device Control 4" control character.')
    ..rename(0x15, "nak", '"Negative Acknowledgment" control character.')
    ..rename(0x16, "syn", '"Synchronous idle" control character.')
    ..rename(0x17, "etb", '"End of Transmission Block" control character.')
    ..rename(0x18, "can", '"Cancel" control character.')
    ..rename(0x19, "em", '"End of Medium" control character.')
    ..rename(0x1A, "sub", '"Substitute" control character.')
    ..rename(0x1B, "esc", '"Escape" control character.')
    ..rename(0x1C, "fs", '"File Separator" control character.')
    ..rename(0x1D, "gs", '"Group Separator" control character.')
    ..rename(0x1E, "rs", '"Record Separator" control character.')
    ..rename(0x1F, "us", '"Unit Separator" control character.')
    // Visible characters.
    ..rename(0x20, "space", 'Space character.')
    ..rename(0x21, "exclamation", 'Character `!`.')
    ..rename(0x22, "quot", 'Character `"`, short name.')
    ..rename(0x23, "hash", 'Character `#`.')
    ..rename(0x24, "\$", 'Character `\$`.')
    ..rename(0x25, "percent", 'Character `%`.')
    ..rename(0x26, "amp", 'Character `&`, short name.')
    ..rename(0x27, "apos", 'Character "\'".')
    ..rename(0x28, "lparen", 'Character `(`.')
    ..rename(0x29, "rparen", 'Character `)`.')
    ..rename(0x2A, "asterisk", 'Character `*`.')
    ..rename(0x2B, "plus", 'Character `+`.')
    ..rename(0x2C, "comma", 'Character `,`.')
    ..rename(0x2D, "minus", 'Character `-`.')
    ..rename(0x2E, "dot", 'Character `.`.')
    ..rename(0x2F, "slash", 'Character `/`.')
    ..rename(0x30, "0", 'Character `0`.')
    ..rename(0x31, "1", 'Character `1`.')
    ..rename(0x32, "2", 'Character `2`.')
    ..rename(0x33, "3", 'Character `3`.')
    ..rename(0x34, "4", 'Character `4`.')
    ..rename(0x35, "5", 'Character `5`.')
    ..rename(0x36, "6", 'Character `6`.')
    ..rename(0x37, "7", 'Character `7`.')
    ..rename(0x38, "8", 'Character `8`.')
    ..rename(0x39, "9", 'Character `9`.')
    ..rename(0x3A, "colon", 'Character `:`.')
    ..rename(0x3B, "semicolon", 'Character `;`.')
    ..rename(0x3C, "lt", 'Character `<`.')
    ..rename(0x3D, "equal", 'Character `<`.')
    ..rename(0x3E, "gt", 'Character `>`.')
    ..rename(0x3F, "question", 'Character `?`.')
    ..rename(0x40, "at", 'Character `@`.')
    ..rename(0x41, "A", 'Character `A`.')
    ..rename(0x42, "B", 'Character `B`.')
    ..rename(0x43, "C", 'Character `C`.')
    ..rename(0x44, "D", 'Character `D`.')
    ..rename(0x45, "E", 'Character `E`.')
    ..rename(0x46, "F", 'Character `F`.')
    ..rename(0x47, "G", 'Character `G`.')
    ..rename(0x48, "H", 'Character `H`.')
    ..rename(0x49, "I", 'Character `I`.')
    ..rename(0x4A, "J", 'Character `J`.')
    ..rename(0x4B, "K", 'Character `K`.')
    ..rename(0x4C, "L", 'Character `L`.')
    ..rename(0x4D, "M", 'Character `M`.')
    ..rename(0x4E, "N", 'Character `N`.')
    ..rename(0x4F, "O", 'Character `O`.')
    ..rename(0x50, "P", 'Character `P`.')
    ..rename(0x51, "Q", 'Character `Q`.')
    ..rename(0x52, "R", 'Character `R`.')
    ..rename(0x53, "S", 'Character `S`.')
    ..rename(0x54, "T", 'Character `T`.')
    ..rename(0x55, "U", 'Character `U`.')
    ..rename(0x56, "V", 'Character `V`.')
    ..rename(0x57, "W", 'Character `W`.')
    ..rename(0x58, "X", 'Character `X`.')
    ..rename(0x59, "Y", 'Character `Y`.')
    ..rename(0x5A, "Z", 'Character `Z`.')
    ..rename(0x5B, "lbracket", 'Character `[`.')
    ..rename(0x5C, "backslash", r'Character `\`.')
    ..rename(0x5D, "rbracket", 'Character `]`.')
    ..rename(0x5E, "caret", 'Character `^`.')
    ..rename(0x5F, "_", 'Character `_`.')
    ..rename(0x60, "backquote", 'Character `` ` ``.')
    ..rename(0x61, "a", 'Character `a`.')
    ..rename(0x62, "b", 'Character `b`.')
    ..rename(0x63, "c", 'Character `c`.')
    ..rename(0x64, "d", 'Character `d`.')
    ..rename(0x65, "e", 'Character `e`.')
    ..rename(0x66, "f", 'Character `f`.')
    ..rename(0x67, "g", 'Character `g`.')
    ..rename(0x68, "h", 'Character `h`.')
    ..rename(0x69, "i", 'Character `i`.')
    ..rename(0x6A, "j", 'Character `j`.')
    ..rename(0x6B, "k", 'Character `k`.')
    ..rename(0x6C, "l", 'Character `l`.')
    ..rename(0x6D, "m", 'Character `m`.')
    ..rename(0x6E, "n", 'Character `n`.')
    ..rename(0x6F, "o", 'Character `o`.')
    ..rename(0x70, "p", 'Character `p`.')
    ..rename(0x71, "q", 'Character `q`.')
    ..rename(0x72, "r", 'Character `r`.')
    ..rename(0x73, "s", 'Character `s`.')
    ..rename(0x74, "t", 'Character `t`.')
    ..rename(0x75, "u", 'Character `u`.')
    ..rename(0x76, "v", 'Character `v`.')
    ..rename(0x77, "w", 'Character `w`.')
    ..rename(0x78, "x", 'Character `x`.')
    ..rename(0x79, "y", 'Character `y`.')
    ..rename(0x7A, "z", 'Character `z`.')
    ..rename(0x7B, "lbrace", 'Character `{`.')
    ..rename(0x7C, "bar", 'Character `|`.')
    ..rename(0x7D, "rbrace", 'Character `}`.')
    ..rename(0x7E, "tilde", 'Character `~`.')
    // Control character
    ..rename(0x7F, "del", '"Delete" control character.');
}

void addHtmlEntities(CharcodeBuilder descriptions) {
  descriptions
    ..rename(0x22, "quot", "Character '\"', short name.")
    ..rename(0x27, "apos", "Character \"'\".")
    ..rename(0x3C, "lt", "Character '<'.")
    ..rename(0x3E, "gt", "Character '>'.")
    ..rename(0x00A0, "nbsp", "no-break space (non-breaking space)")
    ..rename(0x00A1, "iexcl", "inverted exclamation mark ('¡')")
    ..rename(0x00A2, "cent", "cent sign ('¢')")
    ..rename(0x00A3, "pound", "pound sign ('£')")
    ..rename(0x00A4, "curren", "currency sign ('¤')")
    ..rename(0x00A5, "yen", "yen sign (yuan sign) ('¥')")
    ..rename(0x00A6, "brvbar", "broken bar (broken vertical bar) ('¦')")
    ..rename(0x00A7, "sect", "section sign ('§')")
    ..rename(
        0x00A8, "uml", "diaeresis (spacing diaeresis); see Germanic umlaut ('¨')")
    ..rename(0x00A9, "copy", "copyright symbol ('©')")
    ..rename(0x00AA, "ordf", "feminine ordinal indicator ('ª')")
    ..rename(0x00AB, "laquo",
        "left-pointing double angle quotation mark (left pointing guillemet) ('«')")
    ..rename(0x00AC, "not", "not sign ('¬')")
    ..rename(0x00AD, "shy", "soft hyphen (discretionary hyphen)")
    ..rename(
        0x00AE, "reg", "registered sign (registered trademark symbol) ('®')")
    ..rename(
        0x00AF, "macr", "macron (spacing macron, overline, APL overbar) ('¯')")
    ..rename(0x00B0, "deg", "degree symbol ('°')")
    ..rename(0x00B1, "plusmn", "plus-minus sign (plus-or-minus sign) ('±')")
    ..rename(
        0x00B2, "sup2", "superscript two (superscript digit two, squared) ('²')")
    ..rename(0x00B3, "sup3",
        "superscript three (superscript digit three, cubed) ('³')")
    ..rename(0x00B4, "acute", "acute accent (spacing acute) ('´')")
    ..rename(0x00B5, "micro", "micro sign ('µ')")
    ..rename(0x00B6, "para", "pilcrow sign (paragraph sign) ('¶')")
    ..rename(
        0x00B7, "middot", "middle dot (Georgian comma, Greek middle dot) ('·')")
    ..rename(0x00B8, "cedil", "cedilla (spacing cedilla) ('¸')")
    ..rename(0x00B9, "sup1", "superscript one (superscript digit one) ('¹')")
    ..rename(0x00BA, "ordm", "masculine ordinal indicator ('º')")
    ..rename(0x00BB, "raquo",
        "right-pointing double angle quotation mark (right pointing guillemet) ('»')")
    ..rename(0x00BC, "frac14",
        "vulgar fraction one quarter (fraction one quarter) ('¼')")
    ..rename(
        0x00BD, "frac12", "vulgar fraction one half (fraction one half) ('½')")
    ..rename(0x00BE, "frac34",
        "vulgar fraction three quarters (fraction three quarters) ('¾')")
    ..rename(
        0x00BF, "iquest", "inverted question mark (turned question mark) ('¿')")
    ..rename(0x00C0, "Agrave",
        "Latin capital letter A with grave accent (Latin capital letter A grave) ('À')")
    ..rename(0x00C1, "Aacute", "Latin capital letter A with acute accent ('Á')")
    ..rename(0x00C2, "Acirc", "Latin capital letter A with circumflex ('Â')")
    ..rename(0x00C3, "Atilde", "Latin capital letter A with tilde ('Ã')")
    ..rename(0x00C4, "Auml", "Latin capital letter A with diaeresis ('Ä')")
    ..rename(0x00C5, "Aring",
        "Latin capital letter A with ring above (Latin capital letter A ring) ('Å')")
    ..rename(0x00C6, "AElig",
        "Latin capital letter AE (Latin capital ligature AE) ('Æ')")
    ..rename(0x00C7, "Ccedil", "Latin capital letter C with cedilla ('Ç')")
    ..rename(0x00C8, "Egrave", "Latin capital letter E with grave accent ('È')")
    ..rename(0x00C9, "Eacute", "Latin capital letter E with acute accent ('É')")
    ..rename(0x00CA, "Ecirc", "Latin capital letter E with circumflex ('Ê')")
    ..rename(0x00CB, "Euml", "Latin capital letter E with diaeresis ('Ë')")
    ..rename(0x00CC, "Igrave", "Latin capital letter I with grave accent ('Ì')")
    ..rename(0x00CD, "Iacute", "Latin capital letter I with acute accent ('Í')")
    ..rename(0x00CE, "Icirc", "Latin capital letter I with circumflex ('Î')")
    ..rename(0x00CF, "Iuml", "Latin capital letter I with diaeresis ('Ï')")
    ..rename(0x00D0, "ETH", "Latin capital letter Eth ('Ð')")
    ..rename(0x00D1, "Ntilde", "Latin capital letter N with tilde ('Ñ')")
    ..rename(0x00D2, "Ograve", "Latin capital letter O with grave accent ('Ò')")
    ..rename(0x00D3, "Oacute", "Latin capital letter O with acute accent ('Ó')")
    ..rename(0x00D4, "Ocirc", "Latin capital letter O with circumflex ('Ô')")
    ..rename(0x00D5, "Otilde", "Latin capital letter O with tilde ('Õ')")
    ..rename(0x00D6, "Ouml", "Latin capital letter O with diaeresis ('Ö')")
    ..rename(0x00D7, "times", "multiplication sign ('×')")
    ..rename(0x00D8, "Oslash",
        "Latin capital letter O with stroke (Latin capital letter O slash) ('Ø')")
    ..rename(0x00D9, "Ugrave", "Latin capital letter U with grave accent ('Ù')")
    ..rename(0x00DA, "Uacute", "Latin capital letter U with acute accent ('Ú')")
    ..rename(0x00DB, "Ucirc", "Latin capital letter U with circumflex ('Û')")
    ..rename(0x00DC, "Uuml", "Latin capital letter U with diaeresis ('Ü')")
    ..rename(0x00DD, "Yacute", "Latin capital letter Y with acute accent ('Ý')")
    ..rename(0x00DE, "THORN", "Latin capital letter THORN ('Þ')")
    ..rename(0x00DF, "szlig",
        "Latin small letter sharp s (ess-zed); see German Eszett ('ß')")
    ..rename(0x00E0, "agrave", "Latin small letter a with grave accent ('à')")
    ..rename(0x00E1, "aacute", "Latin small letter a with acute accent ('á')")
    ..rename(0x00E2, "acirc", "Latin small letter a with circumflex ('â')")
    ..rename(0x00E3, "atilde", "Latin small letter a with tilde ('ã')")
    ..rename(0x00E4, "auml", "Latin small letter a with diaeresis ('ä')")
    ..rename(0x00E5, "aring", "Latin small letter a with ring above ('å')")
    ..rename(
        0x00E6, "aelig", "Latin small letter ae (Latin small ligature ae) ('æ')")
    ..rename(0x00E7, "ccedil", "Latin small letter c with cedilla ('ç')")
    ..rename(0x00E8, "egrave", "Latin small letter e with grave accent ('è')")
    ..rename(0x00E9, "eacute", "Latin small letter e with acute accent ('é')")
    ..rename(0x00EA, "ecirc", "Latin small letter e with circumflex ('ê')")
    ..rename(0x00EB, "euml", "Latin small letter e with diaeresis ('ë')")
    ..rename(0x00EC, "igrave", "Latin small letter i with grave accent ('ì')")
    ..rename(0x00ED, "iacute", "Latin small letter i with acute accent ('í')")
    ..rename(0x00EE, "icirc", "Latin small letter i with circumflex ('î')")
    ..rename(0x00EF, "iuml", "Latin small letter i with diaeresis ('ï')")
    ..rename(0x00F0, "eth", "Latin small letter eth ('ð')")
    ..rename(0x00F1, "ntilde", "Latin small letter n with tilde ('ñ')")
    ..rename(0x00F2, "ograve", "Latin small letter o with grave accent ('ò')")
    ..rename(0x00F3, "oacute", "Latin small letter o with acute accent ('ó')")
    ..rename(0x00F4, "ocirc", "Latin small letter o with circumflex ('ô')")
    ..rename(0x00F5, "otilde", "Latin small letter o with tilde ('õ')")
    ..rename(0x00F6, "ouml", "Latin small letter o with diaeresis ('ö')")
    ..rename(0x00F7, "divide", "division sign (obelus) ('÷')")
    ..rename(0x00F8, "oslash",
        "Latin small letter o with stroke (Latin small letter o slash) ('ø')")
    ..rename(0x00F9, "ugrave", "Latin small letter u with grave accent ('ù')")
    ..rename(0x00FA, "uacute", "Latin small letter u with acute accent ('ú')")
    ..rename(0x00FB, "ucirc", "Latin small letter u with circumflex ('û')")
    ..rename(0x00FC, "uuml", "Latin small letter u with diaeresis ('ü')")
    ..rename(0x00FD, "yacute", "Latin small letter y with acute accent ('ý')")
    ..rename(0x00FE, "thorn", "Latin small letter thorn ('þ')")
    ..rename(0x00FF, "yuml", "Latin small letter y with diaeresis ('ÿ')")
    ..rename(0x0152, "OElig", "Latin capital ligature oe ('Œ')")
    ..rename(0x0153, "oelig", "Latin small ligature oe ('œ')")
    ..rename(0x0160, "Scaron", "Latin capital letter s with caron ('Š')")
    ..rename(0x0161, "scaron", "Latin small letter s with caron ('š')")
    ..rename(0x0178, "Yuml", "Latin capital letter y with diaeresis ('Ÿ')")
    ..rename(0x0192, "fnof",
        "Latin small letter f with hook (function, florin) ('ƒ')")
    ..rename(0x02C6, "circ", "modifier letter circumflex accent ('ˆ')")
    ..rename(0x02DC, "tilde", "small tilde ('˜')")
    ..rename(0x0391, "Alpha", "Greek capital letter Alpha ('Α')")
    ..rename(0x0392, "Beta", "Greek capital letter Beta ('Β')")
    ..rename(0x0393, "Gamma", "Greek capital letter Gamma ('Γ')")
    ..rename(0x0394, "Delta", "Greek capital letter Delta ('Δ')")
    ..rename(0x0395, "Epsilon", "Greek capital letter Epsilon ('Ε')")
    ..rename(0x0396, "Zeta", "Greek capital letter Zeta ('Ζ')")
    ..rename(0x0397, "Eta", "Greek capital letter Eta ('Η')")
    ..rename(0x0398, "Theta", "Greek capital letter Theta ('Θ')")
    ..rename(0x0399, "Iota", "Greek capital letter Iota ('Ι')")
    ..rename(0x039A, "Kappa", "Greek capital letter Kappa ('Κ')")
    ..rename(0x039B, "Lambda", "Greek capital letter Lambda ('Λ')")
    ..rename(0x039C, "Mu", "Greek capital letter Mu ('Μ')")
    ..rename(0x039D, "Nu", "Greek capital letter Nu ('Ν')")
    ..rename(0x039E, "Xi", "Greek capital letter Xi ('Ξ')")
    ..rename(0x039F, "Omicron", "Greek capital letter Omicron ('Ο')")
    ..rename(0x03A0, "Pi", "Greek capital letter Pi ('Π')")
    ..rename(0x03A1, "Rho", "Greek capital letter Rho ('Ρ')")
    ..rename(0x03A3, "Sigma", "Greek capital letter Sigma ('Σ')")
    ..rename(0x03A4, "Tau", "Greek capital letter Tau ('Τ')")
    ..rename(0x03A5, "Upsilon", "Greek capital letter Upsilon ('Υ')")
    ..rename(0x03A6, "Phi", "Greek capital letter Phi ('Φ')")
    ..rename(0x03A7, "Chi", "Greek capital letter Chi ('Χ')")
    ..rename(0x03A8, "Psi", "Greek capital letter Psi ('Ψ')")
    ..rename(0x03A9, "Omega", "Greek capital letter Omega ('Ω')")
    ..rename(0x03B1, "alpha", "Greek small letter alpha ('α')")
    ..rename(0x03B2, "beta", "Greek small letter beta ('β')")
    ..rename(0x03B3, "gamma", "Greek small letter gamma ('γ')")
    ..rename(0x03B4, "delta", "Greek small letter delta ('δ')")
    ..rename(0x03B5, "epsilon", "Greek small letter epsilon ('ε')")
    ..rename(0x03B6, "zeta", "Greek small letter zeta ('ζ')")
    ..rename(0x03B7, "eta", "Greek small letter eta ('η')")
    ..rename(0x03B8, "theta", "Greek small letter theta ('θ')")
    ..rename(0x03B9, "iota", "Greek small letter iota ('ι')")
    ..rename(0x03BA, "kappa", "Greek small letter kappa ('κ')")
    ..rename(0x03BB, "lambda", "Greek small letter lambda ('λ')")
    ..rename(0x03BC, "mu", "Greek small letter mu ('μ')")
    ..rename(0x03BD, "nu", "Greek small letter nu ('ν')")
    ..rename(0x03BE, "xi", "Greek small letter xi ('ξ')")
    ..rename(0x03BF, "omicron", "Greek small letter omicron ('ο')")
    ..rename(0x03C0, "pi", "Greek small letter pi ('π')")
    ..rename(0x03C1, "rho", "Greek small letter rho ('ρ')")
    ..rename(0x03C2, "sigmaf", "Greek small letter final sigma ('ς')")
    ..rename(0x03C3, "sigma", "Greek small letter sigma ('σ')")
    ..rename(0x03C4, "tau", "Greek small letter tau ('τ')")
    ..rename(0x03C5, "upsilon", "Greek small letter upsilon ('υ')")
    ..rename(0x03C6, "phi", "Greek small letter phi ('φ')")
    ..rename(0x03C7, "chi", "Greek small letter chi ('χ')")
    ..rename(0x03C8, "psi", "Greek small letter psi ('ψ')")
    ..rename(0x03C9, "omega", "Greek small letter omega ('ω')")
    ..rename(0x03D1, "thetasym", "Greek theta symbol ('ϑ')")
    ..rename(0x03D2, "upsih", "Greek Upsilon with hook symbol ('ϒ')")
    ..rename(0x03D6, "piv", "Greek pi symbol ('ϖ')")
    ..rename(0x2002, "ensp", "en space")
    ..rename(0x2003, "emsp", "em space")
    ..rename(0x2009, "thinsp", "thin space")
    ..rename(0x200C, "zwnj", "zero-width non-joiner")
    ..rename(0x200D, "zwj", "zero-width joiner")
    ..rename(0x200E, "lrm", "left-to-right mark")
    ..rename(0x200F, "rlm", "right-to-left mark")
    ..rename(0x2013, "ndash", "en dash ('–')")
    ..rename(0x2014, "mdash", "em dash ('—')")
    ..rename(0x2018, "lsquo", "left single quotation mark ('‘')")
    ..rename(0x2019, "rsquo", "right single quotation mark ('’')")
    ..rename(0x201A, "sbquo", "single low-9 quotation mark ('‚')")
    ..rename(0x201C, "ldquo", "left double quotation mark ('“')")
    ..rename(0x201D, "rdquo", "right double quotation mark ('”')")
    ..rename(0x201E, "bdquo", "double low-9 quotation mark ('„')")
    ..rename(0x2020, "dagger", "dagger, obelisk ('†')")
    ..rename(0x2021, "Dagger", "double dagger, double obelisk ('‡')")
    ..rename(0x2022, "bull", "bullet (black small circle) ('•')")
    ..rename(0x2026, "hellip", "horizontal ellipsis (three dot leader) ('…')")
    ..rename(0x2030, "permil", "per mille sign ('‰')")
    ..rename(0x2032, "prime", "prime (minutes, feet) ('′')")
    ..rename(0x2033, "Prime", "double prime (seconds, inches) ('″')")
    ..rename(
        0x2039, "lsaquo", "single left-pointing angle quotation mark ('‹')")
    ..rename(0x203A, "rsaquo", "single right-pointing angle quotation mark ('›')")
    ..rename(0x203E, "oline", "overline (spacing overscore) ('‾')")
    ..rename(0x2044, "frasl", "fraction slash (solidus) ('⁄')")
    ..rename(0x20AC, "euro", "euro sign ('€')")
    ..rename(0x2111, "image", "black-letter capital I (imaginary part) ('ℑ')")
    ..rename(0x2118, "weierp", "script capital P (power set, Weierstrass p) ('℘')")
    ..rename(0x211C, "real", "black-letter capital R (real part symbol) ('ℜ')")
    ..rename(0x2122, "trade", "trademark symbol ('™')")
    ..rename(0x2135, "alefsym", "alef symbol (first transfinite cardinal) ('ℵ')")
    ..rename(0x2190, "larr", "leftwards arrow ('←')")
    ..rename(0x2191, "uarr", "upwards arrow ('↑')")
    ..rename(0x2192, "rarr", "rightwards arrow ('→')")
    ..rename(0x2193, "darr", "downwards arrow ('↓')")
    ..rename(0x2194, "harr", "left right arrow ('↔')")
    ..rename(0x21B5, "crarr", "downwards arrow with corner leftwards (carriage return) ('↵')")
    ..rename(0x21D0, "lArr", "leftwards double arrow ('⇐')")
    ..rename(0x21D1, "uArr", "upwards double arrow ('⇑')")
    ..rename(0x21D2, "rArr", "rightwards double arrow ('⇒')")
    ..rename(0x21D3, "dArr", "downwards double arrow ('⇓')")
    ..rename(0x21D4, "hArr", "left right double arrow ('⇔')")
    ..rename(0x2200, "forall", "for all ('∀')")
    ..rename(0x2202, "part", "partial differential ('∂')")
    ..rename(0x2203, "exist", "there exists ('∃')")
    ..rename(0x2205, "empty", "empty set (null set); see also U+8960, ⌀ ('∅')")
    ..rename(0x2207, "nabla", "del or nabla (vector differential operator) ('∇')")
    ..rename(0x2208, "isin", "element of ('∈')")
    ..rename(0x2209, "notin", "not an element of ('∉')")
    ..rename(0x220B, "ni", "contains as member ('∋')")
    ..rename(0x220F, "prod", "n-ary product (product sign) ('∏')")
    ..rename(0x2211, "sum", "n-ary summation ('∑')")
    ..rename(0x2212, "minus", "minus sign ('−')")
    ..rename(0x2217, "lowast", "asterisk operator ('∗')")
    ..rename(0x221A, "radic", "square root (radical sign) ('√')")
    ..rename(0x221D, "prop", "proportional to ('∝')")
    ..rename(0x221E, "infin", "infinity ('∞')")
    ..rename(0x2220, "ang", "angle ('∠')")
    ..rename(0x2227, "and", "logical and (wedge) ('∧')")
    ..rename(0x2228, "or", "logical or (vee) ('∨')")
    ..rename(0x2229, "cap", "intersection (cap) ('∩')")
    ..rename(0x222A, "cup", "union (cup) ('∪')")
    ..rename(0x222B, "int", "integral ('∫')")
    ..rename(0x2234, "there4", "therefore sign ('∴')")
    ..rename(0x223C, "sim", "tilde operator (varies with, similar to) ('∼')")
    ..rename(0x2245, "cong", "congruent to ('≅')")
    ..rename(0x2248, "asymp", "almost equal to (asymptotic to) ('≈')")
    ..rename(0x2260, "ne", "not equal to ('≠')")
    ..rename(0x2261, "equiv", "identical to; sometimes used for 'equivalent to' ('≡')")
    ..rename(0x2264, "le", "less-than or equal to ('≤')")
    ..rename(0x2265, "ge", "greater-than or equal to ('≥')")
    ..rename(0x2282, "sub", "subset of ('⊂')")
    ..rename(0x2283, "sup", "superset of ('⊃')")
    ..rename(0x2284, "nsub", "not a subset of ('⊄')")
    ..rename(0x2286, "sube", "subset of or equal to ('⊆')")
    ..rename(0x2287, "supe", "superset of or equal to ('⊇')")
    ..rename(0x2295, "oplus", "circled plus (direct sum) ('⊕')")
    ..rename(0x2297, "otimes", "circled times (vector product) ('⊗')")
    ..rename(0x22A5, "perp", "up tack (orthogonal to, perpendicular) ('⊥')")
    ..rename(0x22C5, "sdot", "dot operator ('⋅')")
    ..rename(0x22EE, "vellip", "vertical ellipsis ('⋮')")
    ..rename(0x2308, "lceil", "left ceiling (APL upstile) ('⌈')")
    ..rename(0x2309, "rceil", "right ceiling ('⌉')")
    ..rename(0x230A, "lfloor", "left floor (APL downstile) ('⌊')")
    ..rename(0x230B, "rfloor", "right floor ('⌋')")
    ..rename(0x2329, "lang", "left-pointing angle bracket (bra) ('〈')")
    ..rename(0x232A, "rang", "right-pointing angle bracket (ket) ('〉')")
    ..rename(0x25CA, "loz", "lozenge ('◊')")
    ..rename(0x2660, "spades", "black spade suit ('♠')")
    ..rename(0x2663, "clubs", "black club suit (shamrock) ('♣')")
    ..rename(0x2665, "hearts", "black heart suit (valentine) ('♥')")
    ..rename(0x2666, "diams", "black diamond suit ('♦')");
}

/// Usage string printed if the `--help` or `-?` flags are passed.
///
/// Flag definitions are appended after the text.
const String usageString = r"""
Usage:
  charcode [-h] [-oFILE] (<character-range> | <rename> | -pPREFIX | -fFILE)*

  Emits constant declarations for the characaters specified by character ranges.
  The constants use the pre-defined names and descriptions for ASCII characters.

  A <character-range> is either
   - a literal character,
   - an escaped character `\n`, `\r`, `\t`, `\xHH`, `\uHHHH` or `\DD*`,
       where `H` is a hexadecimal digit and `D` is a decimal digit.
   - two such characters separated by `-`,
   - The `\d` (`0-9`), `\w` (`a-zA-Z0-9$_`) or `\s` (`\x20\t\r\n`) escapes, or
   - A sequence of character ranges.
  Examples: `a`, `a-z`, `\da-fA-F`, `\x00-\uFFFF`.

  A <rename> declaration is a single or escaped character, a `=` and an
  identifier name, optionally followed by a `:` and a description
  Example:  x=cross:\"a cross product.\"
  The declaration names or renames the character, and adds or changes
  the associated description, but will not emit the character to the output.
  Following occurrences of the character in character ranges
  will use the new name.
  Example: `charcode y y=why x-z` will generate `$y` for the character
    code of "y", then `$x`, `$why` and `$z` as well.

""";
