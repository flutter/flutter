// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data";

import "package:charcode/ascii.dart";

/// Parses argument lists based on a [Flags] configuration.
///
/// Arguments are either literals or flags.
///
/// Flags start with `-` or `--`
/// Flags starting with `-` are single-character flags, like `-x`.
/// Single character flag names must be ASCII.
/// Flags starting with `--` are named, like `--expand`.
/// They extend to the end of the argument, or until a `=`.
///
/// Flags can have parameters.
///
/// Single-character flags can have an parameter:
/// * immediately after the charcter, `-ofilename`,
/// * with a `=` between them, `-o=filename`,
/// * or as the next argument, `-o filename`.
///
/// Named flags cannot be directly concatenated with the parameter,
/// but must be one of `--output=filename` or `--output filename`.
/// Named flags conflate non-ASCII alphanumeric characters, like `-` and `_`
/// (but not `=` which delimites a parameter value).
/// Any non-letter, non-digit character sequence is matched by any other,
/// so `--foo-bar`, `--foo_bar` and `--foo.<!>.bar` are all the same.
///
/// Flags can have *optional* parameters. A flag with an optional parameter
/// cannot have its value in the next argument, it *must* use `=` or have
/// the value immediately after a single character flag.
/// It has a default value to use if the parameter is omitted.
///
/// An unrecognized or malformed flag is reported using the [warn]
/// function. If omitted, the [warn] function defaults to printing
/// using the [print] function.
Iterable<CmdLineArg<T>> parseFlags<T>(
    Flags<T> flags, Iterable<String> arguments,
    [void Function(String warning)? warn]) sync* {
  warn ??= _printWarning;
  var args = arguments.iterator;
  while (args.moveNext()) {
    var arg = args.current;
    if (arg.startsWith("-")) {
      if (arg.startsWith("-", 1)) {
        // Named flags.
        if (arg.length == 2) {
          // Found `--`. Stop parsing flags.
          break;
        }
        var equals = arg.indexOf("=", 2);
        if (equals >= 0) {
          var name = arg.substring(2, equals);
          var value = arg.substring(equals + 1);
          var flag = flags.byName(name);
          if (flag != null) {
            if (!flag.hasParameter) {
              warn("Flag $name should not have a parameter: $arg");
              continue;
            }
            yield CmdLineArg<T>(flag.key, value);
            continue;
          }
          warn("Unknown flag: $arg");
          continue;
        }
        var name = arg.substring(2);
        var flag = flags.byName(name);
        if (flag != null) {
          var value = flag.value;
          if (flag.hasParameter &&
              !flag.hasOptionalParameter &&
              args.moveNext()) {
            value = args.current;
          }
          yield CmdLineArg<T>(flag.key, value);
          continue;
        }
        warn("Unknown flag: $arg");
        continue;
      }
      // Character flag(s).
      for (var i = 1; i < arg.length; i++) {
        var char = arg.codeUnitAt(i);
        var flag = flags.byChar(char);
        if (flag == null) {
          warn("Unknown flag: ${arg.substring(i, i + 1)}");
          continue;
        }
        var value = flag.value;
        if (arg.startsWith("=", i + 1)) {
          value = arg.substring(i + 2);
          if (!flag.hasParameter) {
            warn(
                "Flag ${arg.substring(i, i + 1)} should not have a parameter: ${arg.substring(i)}");
            break;
          }
          yield CmdLineArg<T>(flag.key, value);
          break;
        }
        if (flag.hasParameter) {
          if (i + 1 < arg.length) {
            value = arg.substring(i + 1);
          } else if (!flag.hasOptionalParameter && args.moveNext()) {
            value = args.current;
          }
          yield CmdLineArg<T>(flag.key, value);
          break;
        }
        yield CmdLineArg<T>(flag.key, value);
      }
      continue;
    }
    yield CmdLineArg<Never>(null, arg);
  }
  // Handle entries after `--`.
  while (args.moveNext()) {
    yield CmdLineArg<Never>(null, args.current);
  }
}

/// A part of the arguments list recognized as a flag or not.
///
/// If [key] is `null`, the [value] is a plain argument list entry.
/// Otherwise they key corresponds to the flag that was recognized,
/// and [value] is its parameter or default value, if any.
///
class CmdLineArg<T> {
  final T? key;
  final String? value;
  CmdLineArg(this.key, this.value);
  bool get isFlag => key != null;
}

/// A flag configuration.
///
/// Collects one or more [FlagConfig] objects and allows quick look-up
/// on character or name.
class Flags<T> {
  final List<FlagConfig<T>?> _charFlags =
      List<FlagConfig<T>?>.filled(128, null, growable: false);
  final Map<String, FlagConfig<T>> _namedFlags = {};

  void add(FlagConfig<T> flag) {
    var char = flag.flagChar;
    if (char != null) {
      _charFlags[char] = flag;
    }
    var name = flag.flagName;
    if (name != null) {
      _namedFlags[name] = flag;
    }
  }

  void addBoolFlag(T key, String flagChar, String flagName,
      [String? description]) {
    add(FlagConfig.optionalParameter(key, flagChar, flagName, "true",
        description: description, valueDescription: "true"));
    add(FlagConfig.optionalParameter(key, null, "no-" + flagName, "false"));
  }

  FlagConfig<T>? byName(String name) => _namedFlags[name];
  FlagConfig<T>? byChar(int char) =>
      0 <= char && char <= 217 ? _charFlags[char] : null;

  void writeUsage(StringSink buffer) {
    const descriptionStart = 28;
    var allFlags = [
      ...{
        for (var flag in _namedFlags.values)
          if (!flag.flagName!.startsWith("no-") || flag.value != "false") flag,
        for (var flag in _charFlags)
          if (flag != null && flag.flagName == null) flag
      }
    ]..sort(_flagOrder);
    for (var flag in allFlags) {
      var name = flag.flagName;
      var char = flag.flagChar;
      var parameter = flag.valueDescription ?? "VALUE";
      var description = flag.description;
      var lineLength = 0;
      if (char != null) {
        buffer
          ..write("  -")
          ..writeCharCode(char);
        lineLength = 4;
        if (name != null) {
          buffer..write(", --")..write(name);
          lineLength = name.length + 8;
        }
      } else if (name != null) {
        buffer..write("      --")..write(name);
        lineLength = name.length + 8;
      } else {
        continue;
      }
      if (flag.hasParameter) {
        var end = "";
        if (flag.hasOptionalParameter) {
          buffer.write("[=");
          lineLength += 2;
          end = "]";
        } else {
          buffer.write("=");
          lineLength += 1;
        }
        buffer.write(parameter);
        lineLength += parameter.length;
        buffer.write(end);
        lineLength += end.length;
      }
      if (description != null) {
        if (lineLength < descriptionStart) {
          do {
            buffer.write(" ");
            lineLength += 1;
          } while (lineLength < descriptionStart);
        } else {
          buffer.write(" ");
          lineLength += 1;
        }
        var indent = "                              "; // 30 spaces.
        _writeSplitDescription(buffer, description, lineLength, 80, indent);
      } else {
        buffer.writeln();
      }
    }
  }

  void _writeSplitDescription(StringSink output, String description, int indent,
      int maxLength, String newLineIndent) {
    var index = 0;
    var end = index + (maxLength - indent);
    end:
    while (end < description.length) {
      line:
      while (description.codeUnitAt(end) != $space) {
        end--;
        if (end == index) {
          end = index + (maxLength - indent) + 1;
          while (end < description.length) {
            if (description.codeUnitAt(end) == $space) {
              break line;
            }
            end++;
          }
          break end;
        }
      }
      output.writeln(description.substring(index, end));
      index = end + 1;
      output.write(newLineIndent);
      indent = newLineIndent.length;
      end = index + (maxLength - indent);
    }
    if (index < description.length) {
      output.writeln(description.substring(index));
    }
  }

  static int _flagOrder(FlagConfig a, FlagConfig b) {
    var aName = a.flagName;
    var bName = b.flagName;
    if (aName != null) {
      if (bName != null) return aName.compareTo(bName);
      return aName.codeUnitAt(0) < b.flagChar! ? -1 : 1;
    }
    if (bName != null) {
      return a.flagChar! < bName.codeUnitAt(0) ? -1 : 1;
    }
    return a.flagChar! - b.flagChar!;
  }
}

/// Configuration of a single flag.
class FlagConfig<T> {
  /// The user designated key linked to this flag.
  final T key;

  /// ASCII character code for the single-character flag.
  ///
  /// Must be a digit or letter. Does distinguish case.
  final int? flagChar;

  /// Flag name.
  ///
  /// Canonicalized to lower-case letters, digits and single `-` characters.
  final String? flagName;

  /// Whether the flag expects a parameter.
  ///
  /// A flag expecting a parameter which is not optional ([hasOptionalParameter])
  /// will require a value in the argument list to be well-formed.
  final bool hasParameter;

  /// Whether the parameter is optional.
  ///
  /// An optional parameter can be omitted.
  final bool hasOptionalParameter;

  /// A name for the parameter, if there is a parameter.
  ///
  /// Traditionally an all-upper-case name.
  final String? valueDescription;

  /// The value associated with the flag.
  ///
  /// A flag without parameters can have a value configured, which allows the same
  /// [key] to be used for different flags.
  ///
  /// A flag with an optional parameter will have a default value, which may be
  /// null.
  final String? value;

  /// Description for documentation purposes.
  final String? description;

  FlagConfig._(
      this.key,
      String? flagChar,
      String? flagName,
      this.hasParameter,
      this.hasOptionalParameter,
      this.value,
      this.description,
      this.valueDescription)
      : flagChar = _checkFlagChar(flagChar),
        flagName = canonicalizeName(flagName);
  FlagConfig(T key, String? flagChar, String? flagName,
      {String? value, String? description, String valueDescription = "VALUE"})
      : this._(key, flagChar, flagName, false, false, value, description,
            valueDescription);
  FlagConfig.requiredParameter(T key, String? flagChar, String? flagName,
      {String? description, String valueDescription = "VALUE"})
      : this._(key, flagChar, flagName, true, false, null, description,
            valueDescription);
  FlagConfig.optionalParameter(
      T key, String? flagChar, String? flagName, String defaultValue,
      {String? description, String valueDescription = "VALUE"})
      : this._(key, flagChar, flagName, true, true, defaultValue, description,
            valueDescription);

  static int? _checkFlagChar(String? flagChar) {
    if (flagChar == null) return null;
    if (flagChar.length == 1) {
      var char = flagChar.codeUnitAt(0);
      if (char ^ 0x30 <= 9) return char;
      var lc = char | 0x20;
      if (lc >= 0x61 && lc <= 0x7b) return char;
    }
    throw ArgumentError.value(flagChar, "flagChar",
        "Must be a single ASCII digit or letter character");
  }
}

/// Converts names to canonical form.
///
/// Canonical form consists of only *lower case ASCII letters*,
/// *decimal digits* and single *dash* characters (`-`) separating letter/digit
/// sequences.
///
/// All upper-case letters are made lower-case.
/// If the input-name contains sequences of non-letter, non-digit characters,
/// each sequence is replaced by a single `-`.
/// Leading and trailing `-`s are then ignored
/// if the result contains anything other than `-`.
String? canonicalizeName(String? name) {
  if (name == null) return name;
  const $dash = 0x2d;
  var wasDash = false;
  var i = 0;
  var upperCase = 0x20;
  while (i < name.length) {
    var char = name.codeUnitAt(i++);
    var lcChar = char | 0x20;
    if (char ^ 0x30 <= 9 || lcChar >= 0x61 && lcChar <= 0x7b) {
      wasDash = false;
      upperCase &= char;
      continue;
    }
    if (char == $dash && !wasDash) {
      wasDash = true;
      continue;
    }

    var bytes = Uint8List(name.length);
    var j = 0;
    for (; j < i - 1; j++) {
      bytes[j] = name.codeUnitAt(j) | 0x20;
    }

    // Convert all letters to lower-case, all non letter/digits to a single `-`.
    outer:
    do {
      if (!wasDash) {
        bytes[j++] = $dash;
        wasDash = true;
      }
      while (i < name.length) {
        char = name.codeUnitAt(i++);
        var lcChar = char | 0x20;
        if (char ^ 0x30 <= 9 || lcChar >= 0x61 && lcChar <= 0x7b) {
          bytes[j++] = lcChar;
          wasDash = false;
          continue;
        }
        if (char == $dash && !wasDash) {
          bytes[j++] = char;
          wasDash = true;
          continue;
        }
        continue outer;
      }
      break;
    } while (true);
    var start = 0;
    var end = j;
    if (end > start + 1) {
      // Omit leading/trailing dashes.
      if (bytes[start] == $dash) start++;
      if (bytes[end - 1] == $dash) end--;
    }
    return String.fromCharCodes(Uint8List.sublistView(bytes, start, end));
  }
  return upperCase == 0 ? name.toLowerCase() : name;
}

void _printWarning(String message) {
  print(message);
}
