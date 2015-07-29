// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf/shelf.dart';

void printUsage(parser) {
  print('Usage: sky_server [-v] PORT');
  print(parser.usage);
}

main(List<String> argv) async {
  ArgParser parser = new ArgParser();
  parser.addFlag('help', abbr: 'h', negatable: false,
                 help: 'Display this help message.');
  parser.addFlag('verbose', abbr: 'v', negatable: false,
                 help: 'Log requests to stdout.');

  ArgResults args = parser.parse(argv);

  if (args['help'] || args.rest.length != 1) {
    printUsage(parser);
    return;
  }

  int port;
  try {
    port = int.parse(args.rest[0]);
  } catch(e) {
    printUsage(parser);
    return;
  }

  Handler handler = createStaticHandler(Directory.current.path,
      serveFilesOutsidePath: true);

  if (args['verbose'])
    handler = const Pipeline().addMiddleware(logRequests()).addHandler(handler);

  HttpServer server;
  try {
    server = await io.serve(handler, InternetAddress.LOOPBACK_IP_V4, port);
  } catch(e) {
    print(e);
    return;
  }

  server.defaultResponseHeaders
    ..removeAll('x-content-type-options')
    ..removeAll('x-frame-options')
    ..removeAll('x-xss-protection')
    ..add('cache-control', 'no-cache');
}
