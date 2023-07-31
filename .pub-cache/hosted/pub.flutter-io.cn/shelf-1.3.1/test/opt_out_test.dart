// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('allows a null value to elide a header', () {
    expect(Response.ok('', headers: {'some_header': null}).headers,
        isNot(contains('some_header')));
  });
}
