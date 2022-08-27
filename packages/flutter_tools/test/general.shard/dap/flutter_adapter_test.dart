// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dds/dap.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/debug_adapters/flutter_adapter_args.dart';
import 'package:flutter_tools/src/globals.dart' as globals show platform;
import 'package:test/fake.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'mocks.dart';

void main() {
  // Use the real platform as a base so that Windows bots test paths.
  final FakePlatform platform = FakePlatform.fromPlatform(globals.platform);
  final FileSystemStyle fsStyle = platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix;

  group('flutter adapter', () {
    final String expectedFlutterExecutable = platform.isWindows
        ? r'C:\fake\flutter\bin\flutter.bat'
        : '/fake/flutter/bin/flutter';

    setUpAll(() {
      Cache.flutterRoot = platform.isWindows
          ? r'C:\fake\flutter'
          : '/fake/flutter';
    });

    group('launchRequest', () {
      test('runs "flutter run" with --machine', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, containsAllInOrder(<String>['run', '--machine']));
      });

      test('includes env variables', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          env: <String, String>{
            'MY_TEST_ENV': 'MY_TEST_VALUE',
          },
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.env!['MY_TEST_ENV'], 'MY_TEST_VALUE');
      });

      test('does not record the VMs PID for terminating', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        // Trigger a fake debuggerConnected with a pid that we expect the
        // adapter _not_ to record, because it may be on another device.
        await adapter.debuggerConnected(_FakeVm(pid: 123));

        // Ensure the VM's pid was not recorded.
        expect(adapter.pidsToTerminate, isNot(contains(123)));
      });

      test('calls "app.stop" on terminateRequest', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> launchCompleter = Completer<void>();
        await adapter.launchRequest(MockRequest(), args, launchCompleter.complete);
        await launchCompleter.future;

        final Completer<void> terminateCompleter = Completer<void>();
        await adapter.terminateRequest(MockRequest(), TerminateArguments(restart: false), terminateCompleter.complete);
        await terminateCompleter.future;

        expect(adapter.flutterRequests, contains('app.stop'));
      });

      test('does not call "app.stop" on terminateRequest if app was not started', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
          simulateAppStarted: false,
        );

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> launchCompleter = Completer<void>();
        await adapter.launchRequest(MockRequest(), args, launchCompleter.complete);
        await launchCompleter.future;

        final Completer<void> terminateCompleter = Completer<void>();
        await adapter.terminateRequest(MockRequest(), TerminateArguments(restart: false), terminateCompleter.complete);
        await terminateCompleter.future;

        expect(adapter.flutterRequests, isNot(contains('app.stop')));
      });
    });

    group('attachRequest', () {
      test('runs "flutter attach" with --machine', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterAttachRequestArguments args = FlutterAttachRequestArguments(
          cwd: '/project',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.attachRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, containsAllInOrder(<String>['attach', '--machine']));
      });

      test('does not record the VMs PID for terminating', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterAttachRequestArguments args = FlutterAttachRequestArguments(
          cwd: '/project',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.attachRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        // Trigger a fake debuggerConnected with a pid that we expect the
        // adapter _not_ to record, because it may be on another device.
        await adapter.debuggerConnected(_FakeVm(pid: 123));

        // Ensure the VM's pid was not recorded.
        expect(adapter.pidsToTerminate, isNot(contains(123)));
      });

      test('calls "app.detach" on terminateRequest', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );

        final FlutterAttachRequestArguments args = FlutterAttachRequestArguments(
          cwd: '/project',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> attachCompleter = Completer<void>();
        await adapter.attachRequest(MockRequest(), args, attachCompleter.complete);
        await attachCompleter.future;

        final Completer<void> terminateCompleter = Completer<void>();
        await adapter.terminateRequest(MockRequest(), TerminateArguments(restart: false), terminateCompleter.complete);
        await terminateCompleter.future;

        expect(adapter.flutterRequests, contains('app.detach'));
      });
    });

    group('--start-paused', () {
      test('is passed for debug mode', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, contains('--start-paused'));
      });

      test('is not passed for noDebug mode', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          noDebug: true,
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, isNot(contains('--start-paused')));
      });

      test('is not passed if toolArgs contains --profile', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          toolArgs: <String>['--profile'],
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, isNot(contains('--start-paused')));
      });

      test('is not passed if toolArgs contains --release', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          toolArgs: <String>['--release'],
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, isNot(contains('--start-paused')));
      });
    });

    test('includes toolArgs', () async {
      final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
        fileSystem: MemoryFileSystem.test(style: fsStyle),
        platform: platform,
      );
      final Completer<void> responseCompleter = Completer<void>();

      final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
        cwd: '/project',
        program: 'foo.dart',
        toolArgs: <String>['tool_arg'],
        noDebug: true,
      );

      await adapter.configurationDoneRequest(MockRequest(), null, () {});
      await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
      await responseCompleter.future;

      expect(adapter.executable, equals(expectedFlutterExecutable));
      expect(adapter.processArgs, contains('tool_arg'));
    });

    group('includes customTool', () {
      test('with no args replaced', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          customTool: '/custom/flutter',
          noDebug: true,
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> responseCompleter = Completer<void>();
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.executable, equals('/custom/flutter'));
        // args should be in-tact
        expect(adapter.processArgs, contains('--machine'));
      });

      test('with all args replaced', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          customTool: '/custom/flutter',
          customToolReplacesArgs: 9999, // replaces all built-in args
          noDebug: true,
          toolArgs: <String>['tool_args'], // should still be in args
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> responseCompleter = Completer<void>();
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.executable, equals('/custom/flutter'));
        // normal built-in args are replaced by customToolReplacesArgs, but
        // user-provided toolArgs are not.
        expect(adapter.processArgs, isNot(contains('--machine')));
        expect(adapter.processArgs, contains('tool_args'));
      });
    });
  });
}

class _FakeVm extends Fake implements VM {
  _FakeVm({this.pid = 1});

  @override
  final int pid;
}
