// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:build/build.dart';
import 'package:flutter_tools/src/build_runner/build_script.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';

void main() {
  test('FlutterWebShellBuilder correctly configures platform', () async {
    final MockBuildStep mockBuildStep = MockBuildStep();
    const FlutterWebShellBuilder builder = FlutterWebShellBuilder(
      hasPlugins: false,
      initializePlatform: true,
    );
    final AssetId inputId = AssetId('hello_world', 'lib/main.dart');
    when(mockBuildStep.inputId).thenReturn(inputId);
    when(mockBuildStep.readAsString(any)).thenAnswer((Invocation invocation) async {
      return 'void main() { }';
    });

    await builder.build(mockBuildStep);

    verify(mockBuildStep.writeAsString(any, argThat(contains('if (true)')))).called(1);
  });

  test('FlutterWebShellBuilder correctly configures does not platform', () async {
    final MockBuildStep mockBuildStep = MockBuildStep();
    const FlutterWebShellBuilder builder = FlutterWebShellBuilder(
      hasPlugins: false,
      initializePlatform: false,
    );
    final AssetId inputId = AssetId('hello_world', 'lib/main.dart');
    when(mockBuildStep.inputId).thenReturn(inputId);
    when(mockBuildStep.readAsString(any)).thenAnswer((Invocation invocation) async {
      return 'void main() { }';
    });

    await builder.build(mockBuildStep);

    verify(mockBuildStep.writeAsString(any, argThat(contains('if (false)')))).called(1);
  });

  test('FlutterWebShellBuilder correctly configures plugins', () async {
    final MockBuildStep mockBuildStep = MockBuildStep();
    const FlutterWebShellBuilder builder = FlutterWebShellBuilder(
      hasPlugins: true,
      initializePlatform: true,
    );
    final AssetId inputId = AssetId('hello_world', 'lib/main.dart');
    when(mockBuildStep.inputId).thenReturn(inputId);
    when(mockBuildStep.readAsString(any)).thenAnswer((Invocation invocation) async {
      return 'void main() { }';
    });

    await builder.build(mockBuildStep);

    verify(mockBuildStep.writeAsString(any, argThat(contains('registerPlugins(webPluginRegistry)')))).called(1);
  });

  test('FlutterWebShellBuilder correctly does not configure plugins', () async {
    final MockBuildStep mockBuildStep = MockBuildStep();
    const FlutterWebShellBuilder builder = FlutterWebShellBuilder(
      hasPlugins: false,
      initializePlatform: true,
    );
    final AssetId inputId = AssetId('hello_world', 'lib/main.dart');
    when(mockBuildStep.inputId).thenReturn(inputId);
    when(mockBuildStep.readAsString(any)).thenAnswer((Invocation invocation) async {
      return 'void main() { }';
    });

    await builder.build(mockBuildStep);

    verify(mockBuildStep.writeAsString(any, argThat(isNot(contains('registerPlugins(webPluginRegistry)'))))).called(1);
  });
}

class MockBuildStep extends Mock implements BuildStep {}
