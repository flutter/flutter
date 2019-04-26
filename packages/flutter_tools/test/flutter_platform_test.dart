// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/test/flutter_platform.dart';

import 'package:mockito/mockito.dart';
import 'package:test_core/backend.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('FlutterPlatform', () {
    testUsingContext('ensureConfiguration throws an error if an explicitObservatoryPort is specified and more than one test file', () async {
      final FlutterPlatform flutterPlatfrom = FlutterPlatform(shellPath: '/', explicitObservatoryPort: 1234);
      flutterPlatfrom.loadChannel('test1.dart', MockPlatform());
      expect(() => flutterPlatfrom.loadChannel('test2.dart', MockPlatform()), throwsA(isA<ToolExit>()));
    });

    testUsingContext('ensureConfiguration throws an error if a precompiled entrypoint is specified and more that one test file', () {
      final FlutterPlatform flutterPlatfrom = FlutterPlatform(shellPath: '/', precompiledDillPath: 'example.dill');
      flutterPlatfrom.loadChannel('test1.dart', MockPlatform());
      expect(() => flutterPlatfrom.loadChannel('test2.dart', MockPlatform()), throwsA(isA<ToolExit>()));
    });
  });
}

class MockPlatform extends Mock implements SuitePlatform {}
