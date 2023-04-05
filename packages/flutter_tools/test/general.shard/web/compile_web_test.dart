// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/web/compile.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late TestUsage testUsage;
  late BufferLogger logger;
  late FlutterVersion flutterVersion;
  late FlutterProject flutterProject;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    testUsage = TestUsage();
    logger = BufferLogger.test();
    flutterVersion = FakeFlutterVersion(frameworkVersion: '1.0.0', engineRevision: '9.8.7');

    flutterProject = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    fileSystem.file('.packages').createSync();
  });

  testUsingContext('WebBuilder sets environment on success', () async {
    final TestBuildSystem buildSystem =
        TestBuildSystem.all(BuildResult(success: true), (Target target, Environment environment) {
      final WebServiceWorker webServiceWorker = target as WebServiceWorker;
      expect(webServiceWorker.isWasm, isTrue);
      expect(webServiceWorker.webRenderer, WebRendererMode.autoDetect);

      expect(environment.defines, <String, String>{
        'TargetFile': 'target',
        'HasWebPlugins': 'false',
        'cspMode': 'true',
        'SourceMaps': 'true',
        'NativeNullAssertions': 'true',
        'ServiceWorkerStrategy': 'serviceWorkerStrategy',
        'Dart2jsOptimization': 'O4',
        'Dart2jsDumpInfo': 'false',
        'Dart2jsNoFrequencyBasedMinification': 'false',
        'BuildMode': 'debug',
        'DartObfuscation': 'false',
        'TrackWidgetCreation': 'true',
        'TreeShakeIcons': 'false',
      });

      expect(environment.engineVersion, '9.8.7');
      expect(environment.generateDartPluginRegistry, isFalse);
    });

    final WebBuilder webBuilder = WebBuilder(
      logger: logger,
      buildSystem: buildSystem,
      usage: testUsage,
      flutterVersion: flutterVersion,
      fileSystem: fileSystem,
    );
    await webBuilder.buildWeb(
      flutterProject,
      'target',
      BuildInfo.debug,
      true,
      'serviceWorkerStrategy',
      true,
      true,
      true,
    );

    expect(logger.statusText, contains('Compiling target for the Web...'));
    expect(logger.errorText, isEmpty);
    // Runs ScrubGeneratedPluginRegistrant migrator.
    expect(logger.traceText, contains('generated_plugin_registrant.dart not found. Skipping.'));

    // Sends timing event.
    final TestTimingEvent timingEvent = testUsage.timings.single;
    expect(timingEvent.category, 'build');
    expect(timingEvent.variableName, 'dart2js');
  });

  testUsingContext('WebBuilder throws tool exit on failure', () async {
    final TestBuildSystem buildSystem = TestBuildSystem.all(BuildResult(
      success: false,
      exceptions: <String, ExceptionMeasurement>{
        'hello': ExceptionMeasurement(
          'hello',
          const FormatException('illegal character in input string'),
          StackTrace.current,
        ),
      },
    ));

    final WebBuilder webBuilder = WebBuilder(
      logger: logger,
      buildSystem: buildSystem,
      usage: testUsage,
      flutterVersion: flutterVersion,
      fileSystem: fileSystem,
    );
    await expectLater(
        () async => webBuilder.buildWeb(
              flutterProject,
              'target',
              BuildInfo.debug,
              true,
              'serviceWorkerStrategy',
              true,
              true,
              true,
            ),
        throwsToolExit(message: 'Failed to compile application for the Web.'));

    expect(logger.errorText, contains('Target hello failed: FormatException: illegal character in input string'));
    expect(testUsage.timings, isEmpty);
  });
}
