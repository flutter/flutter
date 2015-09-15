// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:sky_tools/src/common.dart';
import 'package:sky_tools/src/init.dart';
import 'package:sky_tools/src/install.dart';

void main(List<String> args) {
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.message}');
  });

  Map<String, CommandHandler> handlers = {};

  ArgParser parser = new ArgParser();
  parser.addSeparator('options:');
  parser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Display this help message.');
  parser.addFlag('verbose',
      abbr: 'v',
      negatable: false,
      help: 'Noisy logging, including all shell commands executed.');
  parser.addSeparator('commands:');

  for (CommandHandler handler in [
    new InitCommandHandler(),
    new InstallCommandHandler()
  ]) {
    parser.addCommand(handler.name, handler.parser);
    handlers[handler.name] = handler;
  }

  ArgResults results;

  try {
    results = parser.parse(args);
  } catch (e) {
    _printUsage(parser, handlers, e is FormatException ? e.message : '${e}');
    exit(1);
  }

  if (results['verbose']) {
    Logger.root.level = Level.INFO;
  }

  if (results['help']) {
    _printUsage(parser, handlers);
  } else if (results.command != null) {
    handlers[results.command.name]
        .processArgResults(results.command)
        .then((int code) => exit(code))
        .catchError((e, stack) {
      print('Error running ' + results.command.name + ': $e');
      print(stack);
      exit(2);
    });
  } else {
    _printUsage(parser, handlers, 'No command specified.');
    exit(1);
  }
}

void _printUsage(ArgParser parser, Map<String, CommandHandler> handlers,
    [String message]) {
  if (message != null) {
    print('${message}\n');
  }
  print('usage: sky_tools <command> [arguments]');
  print('');
  print(parser.usage);
  handlers.forEach((String command, CommandHandler handler) {
    print('  ${command.padRight(10)} ${handler.description}');
  });
}
