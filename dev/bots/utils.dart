// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:core' hide print;
import 'dart:io' as system show exit;
import 'dart:io' hide exit;
import 'dart:math' as math;

import 'package:meta/meta.dart';

const Duration _quietTimeout = Duration(minutes: 10); // how long the output should be hidden between calls to printProgress before just being verbose

// If running from LUCI set to False.
final bool isLuci =  Platform.environment['LUCI_CI'] == 'True';
final bool hasColor = stdout.supportsAnsiEscapes && !isLuci;


final String bold = hasColor ? '\x1B[1m' : ''; // shard titles
final String red = hasColor ? '\x1B[31m' : ''; // errors
final String green = hasColor ? '\x1B[32m' : ''; // section titles, commands
final String yellow = hasColor ? '\x1B[33m' : ''; // indications that a test was skipped (usually renders orange or brown)
final String cyan = hasColor ? '\x1B[36m' : ''; // paths
final String reverse = hasColor ? '\x1B[7m' : ''; // clocks
final String gray = hasColor ? '\x1B[30m' : ''; // subtle decorative items (usually renders as dark gray)
final String white = hasColor ? '\x1B[37m' : ''; // last log line (usually renders as light gray)
final String reset = hasColor ? '\x1B[0m' : '';

const int kESC = 0x1B;
const int kOpenSquareBracket = 0x5B;
const int kCSIParameterRangeStart = 0x30;
const int kCSIParameterRangeEnd = 0x3F;
const int kCSIIntermediateRangeStart = 0x20;
const int kCSIIntermediateRangeEnd = 0x2F;
const int kCSIFinalRangeStart = 0x40;
const int kCSIFinalRangeEnd = 0x7E;


String get redLine {
  if (hasColor) {
    return '$red${'━' * stdout.terminalColumns}$reset';
  }
  return '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
}

String get clock {
  final DateTime now = DateTime.now();
  return '$reverse▌'
         '${now.hour.toString().padLeft(2, "0")}:'
         '${now.minute.toString().padLeft(2, "0")}:'
         '${now.second.toString().padLeft(2, "0")}'
         '▐$reset';
}

String prettyPrintDuration(Duration duration) {
  String result = '';
  final int minutes = duration.inMinutes;
  if (minutes > 0) {
    result += '${minutes}min ';
  }
  final int seconds = duration.inSeconds - minutes * 60;
  final int milliseconds = duration.inMilliseconds - (seconds * 1000 + minutes * 60 * 1000);
  result += '$seconds.${milliseconds.toString().padLeft(3, "0")}s';
  return result;
}

typedef PrintCallback = void Function(Object? line);
typedef VoidCallback = void Function();

// Allow print() to be overridden, for tests.
//
// Files that import this library should not import `print` from dart:core
// and should not use dart:io's `stdout` or `stderr`.
//
// By default this hides log lines between `printProgress` calls unless a
// timeout expires or anything calls `foundError`.
//
// Also used to implement `--verbose` in test.dart.
PrintCallback print = _printQuietly;

// Called by foundError and used to implement `--abort-on-error` in test.dart.
VoidCallback? onError;

bool get hasError => _hasError;
bool _hasError = false;

List<List<String>> _errorMessages = <List<String>>[];

final List<String> _pendingLogs = <String>[];
Timer? _hideTimer; // When this is null, the output is verbose.

void foundError(List<String> messages) {
  assert(messages.isNotEmpty);
  // Make the error message easy to notice in the logs by
  // wrapping it in a red box.
  final int width = math.max(15, (hasColor ? stdout.terminalColumns : 80) - 1);
  print('$red╔═╡${bold}ERROR$reset$red╞═${"═" * (width - 9)}');
  for (final String message in messages.expand((String line) => line.split('\n'))) {
    print('$red║$reset $message');
  }
  print('$red╚${"═" * width}');
  // Normally, "print" actually prints to the log. To make the errors visible,
  // and to include useful context, print the entire log up to this point, and
  // clear it. Subsequent messages will continue to not be logged until there is
  // another error.
  _pendingLogs.forEach(_printLoudly);
  _pendingLogs.clear();
  _errorMessages.add(messages);
  _hasError = true;
  if (onError != null) {
    onError!();
  }
}

@visibleForTesting
void resetErrorStatus() {
  _hasError = false;
  _errorMessages.clear();
  _pendingLogs.clear();
  _hideTimer?.cancel();
  _hideTimer = null;
}

Never reportSuccessAndExit(String message) {
  _hideTimer?.cancel();
  _hideTimer = null;
  print('$clock $message$reset');
  system.exit(0);
}

Never reportErrorsAndExit(String message) {
  _hideTimer?.cancel();
  _hideTimer = null;
  print('$clock $message$reset');
  print(redLine);
  print('${red}For your convenience, the error messages reported above are repeated here:$reset');
  final bool printSeparators = _errorMessages.any((List<String> messages) => messages.length > 1);
  if (printSeparators) {
    print('  🙙  🙛  ');
  }
  for (int index = 0; index < _errorMessages.length * 2 - 1; index += 1) {
    if (index.isEven) {
      _errorMessages[index ~/ 2].forEach(print);
    } else if (printSeparators) {
      print('  🙙  🙛  ');
    }
  }
  print(redLine);
  system.exit(1);
}

void printProgress(String message) {
  _pendingLogs.clear();
  _hideTimer?.cancel();
  _hideTimer = null;
  print('$clock $message$reset');
  if (hasColor) {
    // This sets up a timer to switch to verbose mode when the tests take too long,
    // so that if a test hangs we can see the logs.
    // (This is only supported with a color terminal. When the terminal doesn't
    // support colors, the scripts just print everything verbosely, that way in
    // CI there's nothing hidden.)
    _hideTimer = Timer(_quietTimeout, () {
      _hideTimer = null;
      _pendingLogs.forEach(_printLoudly);
      _pendingLogs.clear();
    });
  }
}

final Pattern _lineBreak = RegExp(r'[\r\n]');

void _printQuietly(Object? message) {
  // The point of this function is to avoid printing its output unless the timer
  // has gone off in which case the function assumes verbose mode is active and
  // prints everything. To show that progress is still happening though, rather
  // than showing nothing at all, it instead shows the last line of output and
  // keeps overwriting it. To do this in color mode, carefully measures the line
  // of text ignoring color codes, which is what the parser below does.
  if (_hideTimer != null) {
    _pendingLogs.add(message.toString());
    String line = '$message'.trimRight();
    final int start = line.lastIndexOf(_lineBreak) + 1;
    int index = start;
    int length = 0;
    while (index < line.length && length < stdout.terminalColumns) {
      if (line.codeUnitAt(index) == kESC) { // 0x1B
        index += 1;
        if (index < line.length && line.codeUnitAt(index) == kOpenSquareBracket) { // 0x5B, [
          // That was the start of a CSI sequence.
          index += 1;
          while (index < line.length && line.codeUnitAt(index) >= kCSIParameterRangeStart
                                     && line.codeUnitAt(index) <= kCSIParameterRangeEnd) { // 0x30..0x3F
            index += 1; // ...parameter bytes...
          }
          while (index < line.length && line.codeUnitAt(index) >= kCSIIntermediateRangeStart
                                     && line.codeUnitAt(index) <= kCSIIntermediateRangeEnd) { // 0x20..0x2F
            index += 1; // ...intermediate bytes...
          }
          if (index < line.length && line.codeUnitAt(index) >= kCSIFinalRangeStart
                                  && line.codeUnitAt(index) <= kCSIFinalRangeEnd) { // 0x40..0x7E
            index += 1; // ...final byte.
          }
        }
      } else {
        index += 1;
        length += 1;
      }
    }
    line = line.substring(start, index);
    if (line.isNotEmpty) {
      stdout.write('\r\x1B[2K$white$line$reset');
    }
  } else {
    _printLoudly('$message');
  }
}

void _printLoudly(String message) {
  if (hasColor) {
    // Overwrite the last line written by _printQuietly.
    stdout.writeln('\r\x1B[2K$reset${message.trimRight()}');
  } else {
    stdout.writeln(message);
  }
}

// THE FOLLOWING CODE IS A VIOLATION OF OUR STYLE GUIDE
// BECAUSE IT INTRODUCES A VERY FLAKY RACE CONDITION
// https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo#never-check-if-a-port-is-available-before-using-it-never-add-timeouts-and-other-race-conditions
// DO NOT USE THE FOLLOWING FUNCTIONS
// DO NOT WRITE CODE LIKE THE FOLLOWING FUNCTIONS
// https://github.com/flutter/flutter/issues/109474

int _portCounter = 8080;

/// Finds the next available local port.
Future<int> findAvailablePortAndPossiblyCauseFlakyTests() async {
  while (!await _isPortAvailable(_portCounter)) {
    _portCounter += 1;
  }
  return _portCounter++;
}

Future<bool> _isPortAvailable(int port) async {
  try {
    final RawSocket socket = await RawSocket.connect('localhost', port);
    socket.shutdown(SocketDirection.both);
    await socket.close();
    return false;
  } on SocketException {
    return true;
  }
}
