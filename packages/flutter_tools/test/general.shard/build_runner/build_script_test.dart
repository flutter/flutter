// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:build/build.dart';
import 'package:flutter_tools/src/build_runner/build_script.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';

void main() {
  MockBuildStep mockBuildStep;
  AssetId inputId;

  setUp(() {
    mockBuildStep = MockBuildStep();
    inputId = AssetId('hello_world', 'lib/main.dart');
    when(mockBuildStep.inputId).thenReturn(inputId);
    when(mockBuildStep.readAsString(any)).thenAnswer((Invocation invocation) async {
      return 'void main() { }';
    });

  });

  test('FlutterWebShellBuilder correctly configures platform', () async {
    const FlutterWebShellBuilder builder = FlutterWebShellBuilder(
      hasPlugins: false,
      initializePlatform: true,
    );

    await builder.build(mockBuildStep);

    verify(mockBuildStep.writeAsString(any, argThat(contains('if (true) '
        '{\n    await ui.webOnlyInitializePlatform')))).called(1);
  });

  test('FlutterWebShellBuilder correctly configures does not platform', () async {
    const FlutterWebShellBuilder builder = FlutterWebShellBuilder(
      hasPlugins: false,
      initializePlatform: false,
    );

    await builder.build(mockBuildStep);

    verify(mockBuildStep.writeAsString(any, argThat(contains('if (false) '
        '{\n    await ui.webOnlyInitializePlatform')))).called(1);
  });

  test('FlutterWebShellBuilder correctly configures plugins', () async {
    const FlutterWebShellBuilder builder = FlutterWebShellBuilder(
      hasPlugins: true,
      initializePlatform: true,
    );

    await builder.build(mockBuildStep);

    verify(mockBuildStep.writeAsString(any,
        argThat(contains('registerPlugins(webPluginRegistry)')))).called(1);
  });

  test('FlutterWebShellBuilder correctly does not configure plugins', () async {
    const FlutterWebShellBuilder builder = FlutterWebShellBuilder(
      hasPlugins: false,
      initializePlatform: true,
    );

    await builder.build(mockBuildStep);

    verify(mockBuildStep.writeAsString(any,
        argThat(isNot(contains('registerPlugins(webPluginRegistry)'))))).called(1);
  });
}

class MockBuildStep extends Mock implements BuildStep {}
