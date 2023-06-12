// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'package:http/io_client.dart';
import 'package:http_client_conformance_tests/http_client_conformance_tests.dart';
import 'package:test/test.dart';

void main() {
  final client = IOClient();

  testAll(client);
}
