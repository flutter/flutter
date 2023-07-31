// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
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

  test('_flutter.listViews', () async {
    final serviceMethod = '_flutter.listViews';
    final service = context.debugConnection.vmService;
    final vm = await service.getVM();
    final isolates = vm.isolates;

    final expected = <String, Object>{
      'views': <Object>[
        for (var isolate in isolates)
          <String, Object>{
            'id': isolate.id,
            'isolate': isolate.toJson(),
          }
      ],
    };

    final result = await service.callServiceExtension(serviceMethod, args: {});

    expect(result.json, expected);
  });
}
