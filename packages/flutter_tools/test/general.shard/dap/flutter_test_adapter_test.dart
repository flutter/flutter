// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dap_adapters/dap_adapters.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/debug_adapters/flutter_adapter_args.dart';
import 'package:flutter_tools/src/globals.dart' as globals show platform;
import 'package:test/fake.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart' as vm;

import 'mocks.dart';

void main() {
  // Use the real platform as a base so that Windows bots test paths.
  final platform = FakePlatform.fromPlatform(globals.platform);
  final FileSystemStyle fsStyle = platform.isWindows
      ? FileSystemStyle.windows
      : FileSystemStyle.posix;

  group('flutter test adapter', () {
    final expectedFlutterExecutable = platform.isWindows
        ? r'C:\fake\flutter\bin\flutter.bat'
        : '/fake/flutter/bin/flutter';

    setUpAll(() {
      Cache.flutterRoot = platform.isWindows ? r'C:\fake\flutter' : '/fake/flutter';
    });

    test('includes toolArgs', () async {
      final adapter = FakeFlutterTestDebugAdapter(
        fileSystem: MemoryFileSystem.test(style: fsStyle),
        platform: platform,
      );
      final responseCompleter = Completer<void>();
      final request = FakeRequest();
      final args = FlutterLaunchRequestArguments(
        cwd: '.',
        program: 'foo.dart',
        toolArgs: <String>['tool_arg'],
        noDebug: true,
      );

      await adapter.configurationDoneRequest(request, null, () {});
      await adapter.launchRequest(request, args, responseCompleter.complete);
      await responseCompleter.future;

      expect(adapter.executable, equals(expectedFlutterExecutable));
      expect(adapter.processArgs, contains('tool_arg'));
    });

    test('includes env variables', () async {
      final adapter = FakeFlutterTestDebugAdapter(
        fileSystem: MemoryFileSystem.test(style: fsStyle),
        platform: platform,
      );
      final responseCompleter = Completer<void>();
      final request = FakeRequest();
      final args = FlutterLaunchRequestArguments(
        cwd: '.',
        program: 'foo.dart',
        env: <String, String>{'MY_TEST_ENV': 'MY_TEST_VALUE'},
      );

      await adapter.configurationDoneRequest(request, null, () {});
      await adapter.launchRequest(request, args, responseCompleter.complete);
      await responseCompleter.future;

      expect(adapter.env!['MY_TEST_ENV'], 'MY_TEST_VALUE');
    });

    group('includes customTool', () {
      test('with no args replaced', () async {
        final adapter = FakeFlutterTestDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final responseCompleter = Completer<void>();
        final request = FakeRequest();
        final args = FlutterLaunchRequestArguments(
          cwd: '.',
          program: 'foo.dart',
          customTool: '/custom/flutter',
          noDebug: true,
        );

        await adapter.configurationDoneRequest(request, null, () {});
        await adapter.launchRequest(request, args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.executable, equals('/custom/flutter'));
        // args should be in-tact
        expect(adapter.processArgs, contains('--machine'));
      });

      test('with all args replaced', () async {
        final adapter = FakeFlutterTestDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final responseCompleter = Completer<void>();
        final request = FakeRequest();
        final args = FlutterLaunchRequestArguments(
          cwd: '.',
          program: 'foo.dart',
          customTool: '/custom/flutter',
          customToolReplacesArgs: 9999, // replaces all built-in args
          noDebug: true,
          toolArgs: <String>['tool_args'], // should still be in args
        );

        await adapter.configurationDoneRequest(request, null, () {});
        await adapter.launchRequest(request, args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.executable, equals('/custom/flutter'));
        // normal built-in args are replaced by customToolReplacesArgs, but
        // user-provided toolArgs are not.
        expect(adapter.processArgs, isNot(contains('--machine')));
        expect(adapter.processArgs, contains('tool_args'));
      });
    });

    test('surfaces clean error when process terminates before debugger initialized', () async {
      final debuggerCompleter = Completer<void>();
      final adapter = FakeFlutterTestDebugAdapter(
        fileSystem: MemoryFileSystem.test(style: fsStyle),
        platform: platform,
        customDebuggerInitialized: debuggerCompleter.future,
      );
      final responseCompleter = Completer<void>();
      final request = FakeRequest();
      final args = FlutterLaunchRequestArguments(cwd: '.', program: 'foo.dart', noDebug: false);

      await adapter.configurationDoneRequest(request, null, () {});
      final Future<void> launchFuture = adapter.launchRequest(
        request,
        args,
        responseCompleter.complete,
      );
      await pumpEventQueue();

      expect(adapter.waitingForDebugger, isTrue);

      adapter.handleExitCode(255);

      expect(
        launchFuture,
        throwsA(
          isA<DebugAdapterException>().having(
            (DebugAdapterException e) => e.message,
            'message',
            'Session terminated before debugger initialized: (255)',
          ),
        ),
      );
    });

    test('times out with diagnostic error when debugger initialization hangs', () async {
      final debuggerCompleter = Completer<void>();
      final adapter = FakeFlutterTestDebugAdapter(
        fileSystem: MemoryFileSystem.test(style: fsStyle),
        platform: platform,
        customDebuggerInitialized: debuggerCompleter.future,
        debuggerInitializationTimeout: const Duration(milliseconds: 10),
      );
      final responseCompleter = Completer<void>();
      final request = FakeRequest();
      final args = FlutterLaunchRequestArguments(cwd: '.', program: 'foo.dart', noDebug: false);

      await adapter.configurationDoneRequest(request, null, () {});
      await expectLater(
        adapter.launchRequest(request, args, responseCompleter.complete),
        throwsA(
          isA<DebugAdapterException>().having(
            (DebugAdapterException e) => e.message,
            'message',
            contains(
              'Timed out after 0s waiting for debugger to initialize '
              '(waiting for test.startedProcess event from flutter test).',
            ),
          ),
        ),
      );
      expect(adapter.waitingForDebugger, isFalse);
    });

    test('debuggerConnected waits for isolates to become runnable and reach PauseStart', () async {
      var getIsolateCount = 0;
      final fakeVmService = _FakeVmService(
        onGetVM: () async => vm.VM(
          isolates: <vm.IsolateRef>[
            vm.IsolateRef(id: 'isolates/1', name: 'main', number: '1', isSystemIsolate: false),
          ],
        ),
        onGetIsolate: (String isolateId) async {
          getIsolateCount++;
          if (getIsolateCount == 1) {
            return vm.Isolate(
              id: isolateId,
              name: 'main',
              number: '1',
              runnable: false,
              pauseEvent: vm.Event(kind: vm.EventKind.kNone, timestamp: 0),
            );
          }
          if (getIsolateCount == 2) {
            return vm.Isolate(
              id: isolateId,
              name: 'main',
              number: '1',
              runnable: true,
              pauseEvent: vm.Event(kind: vm.EventKind.kNone, timestamp: 1),
            );
          }
          return vm.Isolate(
            id: isolateId,
            name: 'main',
            number: '1',
            runnable: true,
            pauseEvent: vm.Event(kind: vm.EventKind.kPauseStart, timestamp: 2),
          );
        },
      );

      final adapter = FakeFlutterTestDebugAdapter(
        fileSystem: MemoryFileSystem.test(style: fsStyle),
        platform: platform,
      );
      adapter.vmService = fakeVmService;

      final responseCompleter = Completer<void>();
      final request = FakeRequest();
      final args = FlutterLaunchRequestArguments(cwd: '.', program: 'foo.dart', noDebug: false);
      await adapter.configurationDoneRequest(request, null, () {});
      await adapter.launchRequest(request, args, responseCompleter.complete);
      await responseCompleter.future;

      final vmInfo = vm.VM(isolates: <vm.IsolateRef>[]);
      await adapter.debuggerConnected(vmInfo);

      expect(getIsolateCount, 3);
      expect(vmInfo.isolates?.single.id, 'isolates/1');
    });

    test('ensureIsolatesResumedFromPauseStart sends explicit resume when isolate remains at PauseStart', () async {
      final resumedIsolates = <String>[];
      final isolate = vm.Isolate(
        id: 'isolates/1',
        name: 'main',
        number: '1',
        runnable: true,
        pauseEvent: vm.Event(kind: vm.EventKind.kPauseStart, timestamp: 2),
        libraries: <vm.LibraryRef>[],
      );
      final fakeVmService = _FakeVmService(
        onGetVM: () async => vm.VM(
          isolates: <vm.IsolateRef>[
            vm.IsolateRef(id: 'isolates/1', name: 'main', number: '1', isSystemIsolate: false),
          ],
        ),
        onGetIsolate: (String isolateId) async => isolate,
        onResume: (String isolateId) async {
          resumedIsolates.add(isolateId);
          return vm.Success();
        },
      );

      final adapter = FakeFlutterTestDebugAdapter(
        fileSystem: MemoryFileSystem.test(style: fsStyle),
        platform: platform,
      );
      adapter.vmService = fakeVmService;

      final responseCompleter = Completer<void>();
      final request = FakeRequest();
      final args = FlutterLaunchRequestArguments(cwd: '.', program: 'foo.dart', noDebug: false);
      await adapter.configurationDoneRequest(request, null, () {});

      (await adapter.isolateManager.registerIsolate(
        isolate,
        vm.EventKind.kIsolateRunnable,
      )).startupHandled = true;

      await adapter.launchRequest(request, args, responseCompleter.complete);
      await responseCompleter.future;

      expect(resumedIsolates, <String>['isolates/1']);
    });
  });
}

class _FakeVmService extends Fake implements vm.VmService {
  _FakeVmService({required this.onGetVM, required this.onGetIsolate, this.onResume});

  final Future<vm.VM> Function() onGetVM;
  final Future<vm.Isolate> Function(String isolateId) onGetIsolate;
  final Future<vm.Success> Function(String isolateId)? onResume;

  @override
  Future<vm.VM> getVM() => onGetVM();

  @override
  Future<vm.Isolate> getIsolate(String isolateId) => onGetIsolate(isolateId);

  @override
  Future<vm.Success> setLibraryDebuggable(
    String isolateId,
    String libraryId,
    bool isDebuggable,
  ) async => vm.Success();

  @override
  Future<vm.Success> setExceptionPauseMode(
    String isolateId,
    /*ExceptionPauseMode*/ String mode,
  ) async => vm.Success();

  @override
  Future<vm.Success> resume(String isolateId, {String? step, int? frameIndex}) =>
      onResume!(isolateId);
}
