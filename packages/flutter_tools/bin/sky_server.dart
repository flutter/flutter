// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:shelf_static/shelf_static.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf/shelf.dart';

const String usage = 'Usage: sky_server PORT';

main(List<String> argv) async {
  if (argv.length != 1) {
    print(usage);
    return;
  }

  int port;
  try {
    port = int.parse(argv[0]);
  } catch(e) {
    print(usage);
    return;
  }

  Handler handler = createStaticHandler(Directory.current.path,
      serveFilesOutsidePath: true);

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
