// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_runner/build_runner.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('experimentalBuildEnabled', () {
    final MockPlatform mockPlatform = MockPlatform();

    setUp(() {
      experimentalBuildEnabled = null;
    });
    testUsingContext('is enabled if environment variable is enabled', () async {
      when(mockPlatform.environment).thenReturn(<String, String>{'FLUTTER_EXPERIMENTAL_BUILD': 'true'});
      expect(experimentalBuildEnabled, true);
    }, overrides: <Type, Generator>{
      Platform: () => mockPlatform,
    });

    testUsingContext('is not enabed if environment varable is not enabled', () async {
      when(mockPlatform.environment).thenReturn(<String, String>{});
      expect(experimentalBuildEnabled, false);
    }, overrides: <Type, Generator>{
      Platform: () => mockPlatform,
    });
  });
}

class MockPlatform extends Mock implements Platform {}