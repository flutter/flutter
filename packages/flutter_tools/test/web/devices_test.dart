// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(WebDevice, () {
    final MockWebCompiler mockWebCompiler = MockWebCompiler();
    final MockChromeLauncher mockChromeLauncher = MockChromeLauncher();
    final MockPlatform mockPlatform = MockPlatform();
    FlutterProject flutterProject;

    setUp(() async {
      flutterProject = await FlutterProject.fromPath(fs.path.join(getFlutterRoot(), 'dev', 'integration_tests', 'web'));
      when(mockWebCompiler.compile(
        target: anyNamed('target'),
        minify: anyNamed('minify'),
        enabledAssertions: anyNamed('enabledAssertions'),
      )).thenAnswer((Invocation invocation) async => 0);
      when(mockChromeLauncher.launch(any)).thenAnswer((Invocation invocation) async {});
    });

    testUsingContext('can build and connect to chrome', () async {
      final WebDevice device = WebDevice();
      await device.startApp(WebApplicationPackage(flutterProject));
    }, overrides: <Type, Generator>{
      ChromeLauncher: () => mockChromeLauncher,
      WebCompiler: () => mockWebCompiler,
      Platform: () => mockPlatform,
    });
  });
}

class MockChromeLauncher extends Mock implements ChromeLauncher {}
class MockWebCompiler extends Mock implements WebCompiler {}
class MockPlatform extends Mock implements Platform {}

