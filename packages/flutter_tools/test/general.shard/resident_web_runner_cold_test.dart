// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dwds/dwds.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/build_runner/resident_web_runner.dart';
import 'package:flutter_tools/src/build_runner/web_fs.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:vm_service/vm_service.dart';

import '../src/common.dart';
import '../src/testbed.dart';

void main() {
  Testbed testbed;
  MockFlutterWebFs mockWebFs;
  ResidentWebRunner residentWebRunner;

  setUp(() {
    mockWebFs = MockFlutterWebFs();
    final MockWebDevice mockWebDevice = MockWebDevice();
    testbed = Testbed(
      setup: () {
        residentWebRunner = ResidentWebRunner(
          mockWebDevice,
          flutterProject: FlutterProject.current(),
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
          ipv6: true,
        );
      },
      overrides: <Type, Generator>{
      WebFsFactory: () => ({
        @required String target,
        @required FlutterProject flutterProject,
        @required BuildInfo buildInfo,
        @required bool skipDwds,
        @required String hostname,
        @required String port,
      }) async {
        return mockWebFs;
      },
    });
  });

   void _setupMocks() {
    fs.file('pubspec.yaml').createSync();
    fs.file(fs.path.join('lib', 'main.dart')).createSync(recursive: true);
    fs.file(fs.path.join('web', 'index.html')).createSync(recursive: true);
    when(mockWebFs.runAndDebug()).thenThrow(StateError('debugging not supported'));
  }

  test('Can successfully run and connect without vmservice', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

    expect(debugConnectionInfo.wsUri, null);
  }));

  test('Can full restart after attaching', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
     unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockWebFs.recompile()).thenAnswer((Invocation _) async {
      return true;
    });
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 0);
  }));

  test('Fails on compilation errors in hot restart', () => testbed.run(() async {
    _setupMocks();
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
     unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    when(mockWebFs.recompile()).thenAnswer((Invocation _) async {
      return false;
    });
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 1);
    expect(result.message, contains('Failed to recompile application.'));
  }));

}


class MockWebDevice extends Mock implements Device {}
class MockBuildDaemonCreator extends Mock implements BuildDaemonCreator {}
class MockFlutterWebFs extends Mock implements WebFs {}
class MockDebugConnection extends Mock implements DebugConnection {}
class MockVmService extends Mock implements VmService {}
