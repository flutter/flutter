// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library install_test;

import 'package:mockito/mockito.dart';
import 'package:sky_tools/src/install.dart';
import 'package:test/test.dart';

import 'src/common.dart';

main() => defineTests();

defineTests() {
  group('install', () {
    test('install returns 0', () {
      MockArgResults results = new MockArgResults();
      when(results['help']).thenReturn(false);
      InstallCommandHandler handler = new InstallCommandHandler();
      handler
          .processArgResults(results)
          .then((int code) => expect(code, equals(0)));
    });
  });
}
