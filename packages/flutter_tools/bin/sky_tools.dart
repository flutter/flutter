// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:sky_tools/src/common.dart';
import 'package:sky_tools/src/init.dart';

void main(List<String> args) {
  Map<String, CommandHandler> handlers = {};

  ArgParser parser = new ArgParser();
  parser.addSeparator('options:');
  parser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Display this help message.');
  parser.addSeparator('commands:');

  CommandHandler handler = new InitCommandHandler();
  parser.addCommand(handler.name, handler.parser);
  handlers[handler.name] = handler;

  ArgResults results = parser.parse(args);

  if (results['help']) {
    _printUsage(parser, handlers);
  } else if (results.command != null) {
    handlers[results.command.name].processArgResults(results.command);
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
