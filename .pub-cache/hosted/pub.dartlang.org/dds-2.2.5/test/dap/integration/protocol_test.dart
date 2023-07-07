// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';

import 'test_support.dart';

main() {
  group('dap protocol', () {
    test('prints a suitable error if the server receives malformed input',
        () async {
      final errorOutput = Completer<String>();
      final server = await DapTestSession.startServer(
        onError: (e) => errorOutput.complete('$e'),
      );
      addTearDown(() => server.stop());
      server.sink.add(utf8.encode('not\r\n\r\nvalid'));
      expect(
        await errorOutput.future,
        contains('No Content-Length header was supplied'),
      );
    });
    // These tests can be slow due to starting up the external server process.
  }, timeout: Timeout.none);
}
