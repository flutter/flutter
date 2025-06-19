// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_devtools_handler.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/context.dart';
import 'hot_shared.dart';

void main() {
  testWithoutContext('defaultReloadSourcesHelper() handles empty DeviceReloadReports)', () {
    defaultReloadSourcesHelper(
      _FakeHotRunner(),
      <FlutterDevice?>[_FakeFlutterDevice()],
      false,
      const <String, dynamic>{},
      'android',
      'flutter-sdk',
      false,
      'test-reason',
      const NoOpAnalytics(),
    );
  });

  testUsingContext('defaultReloadSourcesHelper() reloads each isolate group once)', () async {
    final _FakeVmService fakeService = _FakeVmService();
    final _FakeFlutterDevice fakeDevice = _FakeFlutterDevice(
      vmService: _FakeFlutterVmService(service: fakeService),
    );

    fakeService._vm._isolates.addAll(<_FakeIsolateRef>[
      _FakeIsolateRef(isolateGroupId: 'Group A', id: 'Isolate A.1'),
      _FakeIsolateRef(isolateGroupId: 'Group B', id: 'Isolate B.1'),
      _FakeIsolateRef(isolateGroupId: 'Group B', id: 'Isolate B.2'),
    ]);

    await defaultReloadSourcesHelper(
      _FakeHotRunner(),
      <FlutterDevice?>[fakeDevice],
      false,
      <String, dynamic>{},
      'android',
      'flutter-sdk',
      false,
      'test-reason',
      const NoOpAnalytics(),
    );

    expect(fakeService._reloadedIsolates.length, equals(2));
    expect(fakeService._reloadedIsolates, contains('Isolate A.1'));
    expect(
      fakeService._reloadedIsolates,
      predicate((List<String> ids) {
        return ids.contains('Isolate B.1') || ids.contains('Isolate B.2');
      }),
    );
  });

  group('signal handling', () {
    late _FakeHotCompatibleFlutterDevice flutterDevice;
    late MemoryFileSystem fileSystem;

    setUp(() {
      flutterDevice = _FakeHotCompatibleFlutterDevice(FakeDevice());
      fileSystem = MemoryFileSystem.test();
    });

    testUsingContext(
      'kills the test device',
      () async {
        final HotRunner runner = HotRunner(
          <FlutterDevice>[flutterDevice],
          target: 'main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          analytics: _FakeAnalytics(),
          devtoolsHandler: createNoOpHandler,
        );

        await runner.run();
        await runner.cleanupAfterSignal();
        expect(flutterDevice.wasExited, true);
        expect((flutterDevice.device.dds as FakeDartDevelopmentService).wasShutdown, true);
        expect((runner.residentDevtoolsHandler! as NoOpDevtoolsHandler).wasShutdown, true);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: FakeProcessManager.empty,
      },
    );

    testUsingContext(
      'kill with a detach keeps the test device running',
      () async {
        final HotRunner runner = HotRunner(
          <FlutterDevice>[flutterDevice],
          target: 'main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          analytics: _FakeAnalytics(),
        );

        await runner.run();
        await runner.detach();
        await runner.cleanupAfterSignal();
        expect(flutterDevice.wasExited, false);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: FakeProcessManager.empty,
      },
    );

    testUsingContext(
      'kill on an attached device keeps the test device running',
      () async {
        final HotRunner runner = HotRunner(
          <FlutterDevice>[flutterDevice],
          target: 'main.dart',
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          analytics: _FakeAnalytics(),
        );

        await runner.attach();
        await runner.cleanupAfterSignal();
        expect(flutterDevice.wasExited, false);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: FakeProcessManager.empty,
      },
    );
  });
}

class _FakeAnalytics extends Fake implements Analytics {
  @override
  void send(Event event) {}
}

class _FakeHotRunner extends Fake implements HotRunner {
  @override
  void addBenchmarkData(String name, int value) {}
}

class _FakeDevFS extends Fake implements DevFS {
  @override
  final Uri? baseUri = Uri();

  @override
  Future<void> destroy() async {}

  @override
  void resetLastCompiled() {}
}

class _FakeFlutterDevice extends Fake implements FlutterDevice {
  _FakeFlutterDevice({FlutterVmService? vmService})
    : vmService = vmService ?? _FakeFlutterVmService();

  @override
  final DevFS? devFS = _FakeDevFS();

  @override
  final FlutterVmService? vmService;

  @override
  Future<void> updateReloadStatus(bool wasReloadSuccessful) async {}
}

class _FakeHotCompatibleFlutterDevice extends Fake implements FlutterDevice {
  _FakeHotCompatibleFlutterDevice(this.device);

  @override
  final Device device;

  @override
  DevFS? devFS = _FakeDevFS();

  @override
  ResidentCompiler? get generator => null;

  @override
  Future<int> runHot({required HotRunner hotRunner, String? route}) async {
    return 0;
  }

  @override
  Future<void> stopEchoingDeviceLog() async {}

  @override
  Future<void> exitApps({Duration timeoutDelay = const Duration(seconds: 10)}) async {
    wasExited = true;
  }

  bool wasExited = false;
}

class _FakeFlutterVmService extends Fake implements FlutterVmService {
  _FakeFlutterVmService({vm_service.VmService? service}) : service = service ?? _FakeVmService();
  @override
  final vm_service.VmService service;
}

class _FakeVmService extends Fake implements vm_service.VmService {
  final _FakeVm _vm = _FakeVm();
  final List<String> _reloadedIsolates = <String>[];

  @override
  Future<_FakeVm> getVM() async => _vm;

  @override
  Future<vm_service.ReloadReport> reloadSources(
    String isolateId, {
    bool? force,
    bool? pause,
    String? rootLibUri,
    String? packagesUri,
  }) async {
    _reloadedIsolates.add(isolateId);
    return vm_service.ReloadReport.parse(<String, Object?>{
      'success': true,
      'details': <String, Object?>{},
    })!;
  }
}

class _FakeVm extends Fake implements vm_service.VM {
  final List<vm_service.IsolateRef> _isolates = <vm_service.IsolateRef>[];

  @override
  List<vm_service.IsolateRef>? get isolates => _isolates;
}

class _FakeIsolateRef extends Fake implements vm_service.IsolateRef {
  _FakeIsolateRef({this.isolateGroupId, this.id});
  @override
  String? isolateGroupId;
  @override
  String? id;
}
