// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf_static.example;

import 'dart:io';
import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

void main(List<String> args) {
  final parser = _getParser();

  int port;
  bool logging;
  bool listDirectories;

  try {
    final result = parser.parse(args);
    port = int.parse(result['port'] as String);
    logging = result['logging'] as bool;
    listDirectories = result['list-directories'] as bool;
  } on FormatException catch (e) {
    stderr
      ..writeln(e.message)
      ..writeln(parser.usage);
    // http://linux.die.net/include/sysexits.h
    // #define EX_USAGE	64	/* command line usage error */
    exit(64);
  }

  if (!FileSystemEntity.isFileSync('example/example.dart')) {
    throw StateError('Server expects to be started the '
        'root of the project.');
  }
  var pipeline = const shelf.Pipeline();

  if (logging) {
    pipeline = pipeline.addMiddleware(shelf.logRequests());
  }

  String? defaultDoc = _defaultDoc;
  if (listDirectories) {
    defaultDoc = null;
  }

  final handler = pipeline.addHandler(createStaticHandler('example/files',
      defaultDocument: defaultDoc, listDirectories: listDirectories));

  io.serve(handler, 'localhost', port).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}

ArgParser _getParser() => ArgParser()
  ..addFlag('logging', abbr: 'l', defaultsTo: true)
  ..addOption('port', abbr: 'p', defaultsTo: '8080')
  ..addFlag('list-directories',
      abbr: 'f',
      negatable: false,
      help: 'List the files in the source directory instead of serving the '
          'default document - "$_defaultDoc".');

const _defaultDoc = 'index.html';
