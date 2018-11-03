// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show AsciiDecoder;

import 'package:quiver/strings.dart';

import '../globals.dart';
import 'context.dart';
import 'io.dart' as io;
import 'platform.dart';
import 'utils.dart';

final AnsiTerminal _kAnsiTerminal = AnsiTerminal();

AnsiTerminal get terminal {
  return (context == null || context[AnsiTerminal] == null)
      ? _kAnsiTerminal
      : context[AnsiTerminal];
}

enum TerminalColor {
  red,
  green,
  blue,
  cyan,
  yellow,
  magenta,
  grey,
}

final OutputPreferences _kOutputPreferences = OutputPreferences();

OutputPreferences get outputPreferences => (context == null || context[OutputPreferences] == null)
    ? _kOutputPreferences
    : context[OutputPreferences];

/// A class that contains the context settings for command text output to the
/// console.
class OutputPreferences {
  OutputPreferences({
    bool wrapText,
    int wrapColumn,
    bool showColor,
  })  : wrapText = wrapText ?? io.stdio?.hasTerminal ?? const io.Stdio().hasTerminal,
        _overrideWrapColumn = wrapColumn,
        showColor = showColor ?? platform.stdoutSupportsAnsi ?? false;

  /// If [wrapText] is true, then any text sent to the context's [Logger]
  /// instance (e.g. from the [printError] or [printStatus] functions) will be
  /// wrapped (newlines added between words) to be no longer than the
  /// [wrapColumn] specifies. Defaults to true if there is a terminal. To
  /// determine if there's a terminal, [OutputPreferences] asks the context's
  /// stdio to see, and if that's not set, it tries creating a new [io.Stdio]
  /// and asks it if there is a terminal.
  final bool wrapText;

  /// The column at which output sent to the context's [Logger] instance
  /// (e.g. from the [printError] or [printStatus] functions) will be wrapped.
  /// Ignored if [wrapText] is false. Defaults to the width of the output
  /// terminal, or to [kDefaultTerminalColumns] if not writing to a terminal.
  /// To find out if we're writing to a terminal, it tries the context's stdio,
  /// and if that's not set, it tries creating a new [io.Stdio] and asks it, if
  /// that doesn't have an idea of the terminal width, then we just use a
  /// default of 100. It will be ignored if [wrapText] is false.
  final int _overrideWrapColumn;
  int get wrapColumn {
    return  _overrideWrapColumn ?? io.stdio?.terminalColumns
      ?? const io.Stdio().terminalColumns ?? kDefaultTerminalColumns;
  }

  /// Whether or not to output ANSI color codes when writing to the output
  /// terminal. Defaults to whatever [platform.stdoutSupportsAnsi] says if
  /// writing to a terminal, and false otherwise.
  final bool showColor;

  @override
  String toString() {
    return '$runtimeType[wrapText: $wrapText, wrapColumn: $wrapColumn, showColor: $showColor]';
  }
}

class AnsiTerminal {
  static const String bold = '\u001B[1m';
  static const String resetAll = '\u001B[0m';
  static const String resetColor = '\u001B[39m';
  static const String resetBold = '\u001B[22m';
  static const String clear = '\u001B[2J\u001B[H';

  static const String red = '\u001b[31m';
  static const String green = '\u001b[32m';
  static const String blue = '\u001b[34m';
  static const String cyan = '\u001b[36m';
  static const String magenta = '\u001b[35m';
  static const String yellow = '\u001b[33m';
  static const String grey = '\u001b[1;30m';

  static const Map<TerminalColor, String> _colorMap = <TerminalColor, String>{
    TerminalColor.red: red,
    TerminalColor.green: green,
    TerminalColor.blue: blue,
    TerminalColor.cyan: cyan,
    TerminalColor.magenta: magenta,
    TerminalColor.yellow: yellow,
    TerminalColor.grey: grey,
  };

  static String colorCode(TerminalColor color) => _colorMap[color];

  bool get supportsColor => platform.stdoutSupportsAnsi ?? false;
  final RegExp _boldControls = RegExp('(${RegExp.escape(resetBold)}|${RegExp.escape(bold)})');

  String bolden(String message) {
    assert(message != null);
    if (!supportsColor || message.isEmpty)
      return message;
    final StringBuffer buffer = StringBuffer();
    for (String line in message.split('\n')) {
      // If there were bolds or resetBolds in the string before, then nuke them:
      // they're redundant. This prevents previously embedded resets from
      // stopping the boldness.
      line = line.replaceAll(_boldControls, '');
      buffer.writeln('$bold$line$resetBold');
    }
    final String result = buffer.toString();
    // avoid introducing a new newline to the emboldened text
    return (!message.endsWith('\n') && result.endsWith('\n'))
        ? result.substring(0, result.length - 1)
        : result;
  }

  String color(String message, TerminalColor color) {
    assert(message != null);
    if (!supportsColor || color == null || message.isEmpty)
      return message;
    final StringBuffer buffer = StringBuffer();
    final String colorCodes = _colorMap[color];
    for (String line in message.split('\n')) {
      // If there were resets in the string before, then keep them, but
      // restart the color right after. This prevents embedded resets from
      // stopping the colors, and allows nesting of colors.
      line = line.replaceAll(resetColor, '$resetColor$colorCodes');
      buffer.writeln('$colorCodes$line$resetColor');
    }
    final String result = buffer.toString();
    // avoid introducing a new newline to the colored text
    return (!message.endsWith('\n') && result.endsWith('\n'))
        ? result.substring(0, result.length - 1)
        : result;
  }

  String clearScreen() => supportsColor ? clear : '\n\n';

  set singleCharMode(bool value) {
    final Stream<List<int>> stdin = io.stdin;
    if (stdin is io.Stdin && stdin.hasTerminal) {
      // The order of setting lineMode and echoMode is important on Windows.
      if (value) {
        stdin.echoMode = false;
        stdin.lineMode = false;
      } else {
        stdin.lineMode = true;
        stdin.echoMode = true;
      }
    }
  }

  Stream<String> _broadcastStdInString;

  /// Return keystrokes from the console.
  ///
  /// Useful when the console is in [singleCharMode].
  Stream<String> get onCharInput {
    _broadcastStdInString ??= io.stdin.transform<String>(const AsciiDecoder(allowInvalid: true)).asBroadcastStream();
    return _broadcastStdInString;
  }

  /// Prompts the user to input a character within the accepted list. Re-prompts
  /// if entered character is not in the list.
  ///
  /// The [prompt] is the text displayed prior to waiting for user input. The
  /// [defaultChoiceIndex], if given, will be the character appearing in
  /// [acceptedCharacters] in the index given if the user presses enter without
  /// any key input. Setting [displayAcceptedCharacters] also prints the
  /// accepted keys next to the [prompt].
  ///
  /// Throws a [TimeoutException] if a `timeout` is provided and its duration
  /// expired without user input. Duration resets per key press.
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    String prompt,
    int defaultChoiceIndex,
    bool displayAcceptedCharacters = true,
    Duration timeout,
  }) async {
    assert(acceptedCharacters != null);
    assert(acceptedCharacters.isNotEmpty);
    List<String> charactersToDisplay = acceptedCharacters;
    if (defaultChoiceIndex != null) {
      assert(defaultChoiceIndex >= 0 && defaultChoiceIndex < acceptedCharacters.length);
      charactersToDisplay = List<String>.from(charactersToDisplay);
      charactersToDisplay[defaultChoiceIndex] = bolden(charactersToDisplay[defaultChoiceIndex]);
      acceptedCharacters.add('\n');
    }
    String choice;
    singleCharMode = true;
    while (isEmpty(choice) || choice.length != 1 || !acceptedCharacters.contains(choice)) {
      if (isNotEmpty(prompt)) {
        printStatus(prompt, emphasis: true, newline: false);
        if (displayAcceptedCharacters)
          printStatus(' [${charactersToDisplay.join("|")}]', newline: false);
        printStatus(': ', emphasis: true, newline: false);
      }
      Future<String> inputFuture = onCharInput.first;
      if (timeout != null)
        inputFuture = inputFuture.timeout(timeout);
      choice = await inputFuture;
      printStatus(choice);
    }
    singleCharMode = false;
    if (defaultChoiceIndex != null && choice == '\n')
      choice = acceptedCharacters[defaultChoiceIndex];
    return choice;
  }
}
