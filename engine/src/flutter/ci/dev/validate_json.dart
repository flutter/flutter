// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:io' show File;
import 'dart:io' as io_internals show exit;

final bool hasColor = stdout.supportsAnsiEscapes;
final String bold = hasColor ? '\x1B[1m' : ''; // used for shard titles
final String red = hasColor ? '\x1B[31m' : ''; // used for errors
final String reset = hasColor ? '\x1B[0m' : '';
final String reverse = hasColor ? '\x1B[7m' : ''; // used for clocks

/// Validates if the input builders JSON file has valid contents.
///
/// Examples:
/// dart validate_json.dart /path/to/json/file
Future<void> main(List<String> args) async {
  final String jsonString = await File(args[0]).readAsString();
  Map<String, dynamic> decodedJson;
  final List<String> messages = <String>[];
  try {
    decodedJson = json.decode(jsonString) as Map<String, dynamic>;
    final List<dynamic> builders = decodedJson['builders'] as List<dynamic>;
    if (builders == null) {
      messages.add('${bold}Json format is violated: no "builders" exists. Please follow: $reset');
      messages.add('''
      {
        "builders":[
          {
            "name":"xxx",
            "repo":"engine"
          }, {
            "name":"xxx",
            "repo":"engine"
          }
        ]
      }''');
      exitWithError(messages);
    }
  } on ExitException catch (error) {
    error.apply();
  }
  print('$clock ${bold}Analysis successful for ${args[0]}.$reset');
}

class ExitException implements Exception {
  ExitException(this.exitCode);

  final int exitCode;

  void apply() {
    io_internals.exit(exitCode);
  }
}

void exitWithError(List<String> messages) {
  final String redLine = '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset';
  print(redLine);
  messages.forEach(print);
  print(redLine);
  exit(1);
}

String get clock {
  final DateTime now = DateTime.now();
  return '$reverse▌'
      '${now.hour.toString().padLeft(2, "0")}:'
      '${now.minute.toString().padLeft(2, "0")}:'
      '${now.second.toString().padLeft(2, "0")}'
      '▐$reset';
}


