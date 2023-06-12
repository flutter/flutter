// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library wip.multiplex;

import 'dart:io' show stderr;

import 'package:args/args.dart' show ArgParser;
import 'package:logging/logging.dart'
    show hierarchicalLoggingEnabled, Level, Logger, LogRecord;
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    show ChromeConnection;

import 'multiplex_impl.dart' show Server;

void main(List<String> argv) async {
  var args = (ArgParser()
        ..addFlag('verbose', abbr: 'v', defaultsTo: false, negatable: false)
        ..addFlag('model_dom', defaultsTo: false, negatable: true)
        ..addOption('chrome_host', defaultsTo: 'localhost')
        ..addOption('chrome_port', defaultsTo: '9222')
        ..addOption('listen_port', defaultsTo: '9223'))
      .parse(argv);

  hierarchicalLoggingEnabled = true;

  if (args['verbose'] == true) {
    Logger.root.level = Level.ALL;
  } else {
    Logger.root.level = Level.WARNING;
  }

  Logger.root.onRecord.listen((LogRecord rec) {
    stderr.writeln('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  var cr = ChromeConnection(
      args['chrome_host'] as String, int.parse(args['chrome_port'] as String));
  Server(int.parse(args['listen_port'] as String), cr,
      modelDom: args['model_dom'] as bool);
}
