// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core' as core_internals show print;
import 'dart:core' hide print;
import 'dart:io' as system show exit;
import 'dart:io' hide exit;

import 'package:meta/meta.dart';

final bool hasColor = stdout.supportsAnsiEscapes;

final String bold = hasColor ? '\x1B[1m' : ''; // used for shard titles
final String red = hasColor ? '\x1B[31m' : ''; // used for errors
final String green = hasColor ? '\x1B[32m' : ''; // used for section titles, commands
final String yellow = hasColor ? '\x1B[33m' : ''; // used for skips
final String cyan = hasColor ? '\x1B[36m' : ''; // used for paths
final String reverse = hasColor ? '\x1B[7m' : ''; // used for clocks
final String reset = hasColor ? '\x1B[0m' : '';
final String redLine = '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset';

typedef PrintCallback = void Function(Object line);

// Allow print() to be overridden, for tests.
PrintCallback print = core_internals.print;

bool get hasError => _hasError;
bool _hasError = false;

Iterable<String> get errorMessages => _errorMessages;
List<String> _errorMessages = <String>[];

void foundError(List<String> messages) {
  assert(messages.isNotEmpty);
  print(redLine);
  messages.forEach(print);
  print(redLine);
  _errorMessages.addAll(messages);
  _hasError = true;
}

@visibleForTesting
void resetErrorStatus() {
  _hasError = false;
  _errorMessages.clear();
}

Never reportErrorsAndExit() {
  print(redLine);
  print('For your convenience, the error messages reported above are repeated here:');
  _errorMessages.forEach(print);
  print(redLine);
  system.exit(1);
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

void printProgress(String action, String workingDir, String command) {
  print('$clock $action: cd $cyan$workingDir$reset; $green$command$reset');
}

int _portCounter = 8080;

/// Finds the next available local port.
Future<int> findAvailablePort() async {
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
