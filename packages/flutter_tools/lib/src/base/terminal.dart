// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show ascii;

import 'package:quiver/strings.dart';

import '../globals.dart';
import 'context.dart';
import 'io.dart' as io;
import 'platform.dart';

final AnsiTerminal _kAnsiTerminal = new AnsiTerminal();

AnsiTerminal get terminal {
  return (context == null || context[AnsiTerminal] == null)
      ? _kAnsiTerminal
      : context[AnsiTerminal];
}

class AnsiTerminal {
  static const String _bold  = '\u001B[1m';
  static const String _reset = '\u001B[0m';
  static const String _clear = '\u001B[2J\u001B[H';

  static const int _EBADF = 9;
  static const int _ENXIO = 6;
  static const int _ENOTTY = 25;
  static const int _ENETRESET = 102;
  static const int _INVALID_HANDLE = 6;

  /// Setting the line mode can throw for some terminals (with "Operation not
  /// supported on socket"), but the error can be safely ignored.
  static const List<int> _lineModeIgnorableErrors = const <int>[
    _EBADF,
    _ENXIO,
    _ENOTTY,
    _ENETRESET,
    _INVALID_HANDLE,
  ];

  bool supportsColor = platform.stdoutSupportsAnsi;

  String bolden(String message) {
    if (!supportsColor)
      return message;
    final StringBuffer buffer = new StringBuffer();
    for (String line in message.split('\n'))
      buffer.writeln('$_bold$line$_reset');
    final String result = buffer.toString();
    // avoid introducing a new newline to the emboldened text
    return (!message.endsWith('\n') && result.endsWith('\n'))
        ? result.substring(0, result.length - 1)
        : result;
  }

  String clearScreen() => supportsColor ? _clear : '\n\n';

  set singleCharMode(bool value) {
    // TODO(goderbauer): instead of trying to set lineMode and then catching
    // [_ENOTTY] or [_INVALID_HANDLE], we should check beforehand if stdin is
    // connected to a terminal or not.
    // (Requires https://github.com/dart-lang/sdk/issues/29083 to be resolved.)
    final Stream<List<int>> stdin = io.stdin;
    if (stdin is io.Stdin) {
      try {
        // The order of setting lineMode and echoMode is important on Windows.
        if (value) {
          stdin.echoMode = false;
          stdin.lineMode = false;
        } else {
          stdin.lineMode = true;
          stdin.echoMode = true;
        }
      } on io.StdinException catch (error) {
        if (!_lineModeIgnorableErrors.contains(error.osError?.errorCode))
          rethrow;
      }
    }
  }

  Stream<String> _broadcastStdInString;

  /// Return keystrokes from the console.
  ///
  /// Useful when the console is in [singleCharMode].
  Stream<String> get onCharInput {
    _broadcastStdInString ??= io.stdin.transform(ascii.decoder).asBroadcastStream();
    return _broadcastStdInString;
  }

  /// Prompts the user to input a character within the accepted list.
  /// Reprompts if inputted character is not in the list.
  ///
  /// `prompt` is the text displayed prior to waiting for user input each time.
  /// `defaultChoiceIndex`, if given, will be the character in `acceptedCharacters`
  ///     in the index given if the user presses enter without any key input.
  /// `displayAcceptedCharacters` prints also the accepted keys next to the `prompt` if true.
  ///
  /// Throws a [TimeoutException] if a `timeout` is provided and its duration
  /// expired without user input. Duration resets per key press.
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    String prompt,
    int defaultChoiceIndex,
    bool displayAcceptedCharacters: true,
    Duration timeout,
  }) async {
    assert(acceptedCharacters != null);
    assert(acceptedCharacters.isNotEmpty);
    List<String> charactersToDisplay = acceptedCharacters;
    if (defaultChoiceIndex != null) {
      assert(defaultChoiceIndex >= 0 && defaultChoiceIndex < acceptedCharacters.length);
      charactersToDisplay = new List<String>.from(charactersToDisplay);
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

