// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:test/test.dart';

import 'fixtures/context.dart';

final context = TestContext();

void main() {
  setUpAll(() async {
    await context.setUp();
  });

  tearDownAll(() async {
    await context.tearDown();
  });

  test('can take screenshots', () async {
    final response = await context.debugConnection.vmService
        .callServiceExtension('ext.dwds.screenshot');
    expect(response.json['data'], isNotNull);
  });
}
