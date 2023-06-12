// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_proxy/shelf_proxy.dart';

Future<void> main() async {
  final server = await shelf_io.serve(
    proxyHandler('https://dart.dev'),
    'localhost',
    8080,
  );

  print('Proxying at http://${server.address.host}:${server.port}');
}
