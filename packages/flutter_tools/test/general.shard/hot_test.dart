// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/resident_devtools_handler.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_vm_services.dart';

final vm_service.Isolate fakeUnpausedIsolate = vm_service.Isolate(
  id: '1',
  pauseEvent: vm_service.Event(
    kind: vm_service.EventKind.kResume,
    timestamp: 0
  ),
  breakpoints: <vm_service.Breakpoint>[],
  exceptionPauseMode: null,
  libraries: <vm_service.LibraryRef>[],
  livePorts: 0,
  name: 'test',
  number: '1',
  pauseOnExit: false,
  runnable: true,
  startTime: 0,
  isSystemIsolate: false,
  isolateFlags: <vm_service.IsolateFlag>[],
);

final FlutterView fakeFlutterView = FlutterView(
  id: 'a',
  uiIsolate: fakeUnpausedIsolate,
);

final FakeVmServiceRequest listViews = FakeVmServiceRequest(
  method: kListViewsMethod,
  jsonResponse: <String, Object>{
    'views': <Object>[
      fakeFlutterView.toJson(),
    ],
  },
);

void main() {
  group('validateReloadReport', () {
    testUsingContext('invalid', () async {
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{},
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
          ],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <String, dynamic>{
            'message': 'error',
          },
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': false},
          ],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': <String>['error']},
          ],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': 'error'},
            <String, dynamic>{'message': <String>['error']},
          ],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': false,
        'details': <String, dynamic>{
          'notices': <Map<String, dynamic>>[
            <String, dynamic>{'message': 'error'},
          ],
        },
      })), false);
      expect(HotRunner.validateReloadReport(vm_service.ReloadReport.parse(<String, dynamic>{
        'type': 'ReloadReport',
        'success': true,
      })), true);
    });

    testWithoutContext('ReasonForCancelling toString has a hint for specific errors', () {
      final ReasonForCancelling reasonForCancelling = ReasonForCancelling(
        message: 'Const class cannot remove fields',
      );

      expect(reasonForCancelling.toString(), contains('Try performing a hot restart instead.'));
    });
  });

  group('hotRestart', () {
    final FakeResidentCompiler residentCompiler = FakeResidentCompiler();
    final MockDevFs mockDevFs = MockDevFs();
    FileSystem fileSystem;

    when(mockDevFs.update(
      mainUri: anyNamed('mainUri'),
      target: anyNamed('target'),
      bundle: anyNamed('bundle'),
      firstBuildTime: anyNamed('firstBuildTime'),
      bundleFirstUpload: anyNamed('bundleFirstUpload'),
      generator: anyNamed('generator'),
      fullRestart: anyNamed('fullRestart'),
      dillOutputPath: anyNamed('dillOutputPath'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
      projectRootPath: anyNamed('projectRootPath'),
      pathToReload: anyNamed('pathToReload'),
      invalidatedFiles: anyNamed('invalidatedFiles'),
      packageConfig: anyNamed('packageConfig'),
    )).thenAnswer((Invocation _) => Future<UpdateFSReport>.value(
        UpdateFSReport(success: true, syncedBytes: 1000, invalidatedSourcesCount: 1)));
    when(mockDevFs.assetPathsToEvict).thenReturn(<String>{});
    when(mockDevFs.baseUri).thenReturn(Uri.file('test'));
    when(mockDevFs.sources).thenReturn(<Uri>[Uri.file('test')]);
    when(mockDevFs.lastCompiled).thenReturn(DateTime.now());

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    testUsingContext('Does not hot restart when device does not support it', () async {
      fileSystem.file('.packages')
        ..createSync(recursive: true)
        ..writeAsStringSync('\n');
      // Setup mocks
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(false);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      // Trigger hot restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)..devFS = mockDevFs,
      ];
      final OperationResult result = await HotRunner(
        devices,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
      ).restart(fullRestart: true);
      // Expect hot restart failed.
      expect(result.isOk, false);
      expect(result.message, 'hotRestart not supported');
    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true),
      Artifacts: () => Artifacts.test(),
      FileSystem: () => fileSystem,
      Platform: () => FakePlatform(operatingSystem: 'linux'),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Does not hot restart when one of many devices does not support it', () async {
      fileSystem.file('.packages')
        ..createSync(recursive: true)
        ..writeAsStringSync('\n');
      // Setup mocks
      final MockDevice mockDevice = MockDevice();
      final MockDevice mockHotDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(false);
      when(mockHotDevice.supportsHotReload).thenReturn(true);
      when(mockHotDevice.supportsHotRestart).thenReturn(true);
      // Trigger hot restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)..devFS = mockDevFs,
        FlutterDevice(mockHotDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)..devFS = mockDevFs,
      ];
      final OperationResult result = await HotRunner(
        devices,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
      ).restart(fullRestart: true);
      // Expect hot restart failed.
      expect(result.isOk, false);
      expect(result.message, 'hotRestart not supported');
    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true),
      Artifacts: () => Artifacts.test(),
      FileSystem: () => fileSystem,
      Platform: () => FakePlatform(operatingSystem: 'linux'),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('Does hot restarts when all devices support it', () async {
      final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
        listViews,
        FakeVmServiceRequest(
          method: 'getIsolate',
          args: <String, Object>{
            'isolateId': fakeUnpausedIsolate.id,
          },
          jsonResponse: fakeUnpausedIsolate.toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson()
        ),
        listViews,
        FakeVmServiceRequest(
          method: 'getIsolate',
          args: <String, Object>{
            'isolateId': fakeUnpausedIsolate.id,
          },
          jsonResponse: fakeUnpausedIsolate.toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson()
        ),
        listViews,
        listViews,
        const FakeVmServiceRequest(
          method: 'streamListen',
          args: <String, Object>{
            'streamId': 'Isolate',
          }
        ),
        const FakeVmServiceRequest(
          method: 'streamListen',
          args: <String, Object>{
            'streamId': 'Isolate',
          }
        ),
        FakeVmServiceStreamResponse(
          streamId: 'Isolate',
          event: vm_service.Event(
            timestamp: 0,
            kind: vm_service.EventKind.kIsolateRunnable,
          )
        ),
        FakeVmServiceStreamResponse(
          streamId: 'Isolate',
          event: vm_service.Event(
            timestamp: 0,
            kind: vm_service.EventKind.kIsolateRunnable,
          )
        ),
        FakeVmServiceRequest(
          method: kRunInViewMethod,
          args: <String, Object>{
            'viewId': fakeFlutterView.id,
            'mainScript': 'main.dart.dill',
            'assetDirectory': 'build/flutter_assets',
          }
        ),
        FakeVmServiceRequest(
          method: kRunInViewMethod,
          args: <String, Object>{
            'viewId': fakeFlutterView.id,
            'mainScript': 'main.dart.dill',
            'assetDirectory': 'build/flutter_assets',
          }
        ),
      ]);
      // Setup mocks
      final MockDevice mockDevice = MockDevice();
      final MockDevice mockHotDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(true);
      when(mockHotDevice.supportsHotReload).thenReturn(true);
      when(mockHotDevice.supportsHotRestart).thenReturn(true);
      // Trigger a restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)
          ..vmService = fakeVmServiceHost.vmService
          ..devFS = mockDevFs,
        FlutterDevice(mockHotDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)
          ..vmService = fakeVmServiceHost.vmService
          ..devFS = mockDevFs,
      ];
      final HotRunner hotRunner = HotRunner(
        devices,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
      );
      final OperationResult result = await hotRunner.restart(fullRestart: true);
      // Expect hot restart was successful.
      expect(hotRunner.uri, mockDevFs.baseUri);
      expect(result.isOk, true);
      expect(result.message, isNot('hotRestart not supported'));
    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true),
      Artifacts: () => Artifacts.test(),
      FileSystem: () => fileSystem,
      Platform: () => FakePlatform(operatingSystem: 'linux'),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('setup function fails', () async {
      fileSystem.file('.packages')
        ..createSync(recursive: true)
        ..writeAsStringSync('\n');
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(true);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)..devFS = MockDevFs(),
      ];
      final OperationResult result = await HotRunner(
        devices,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
      ).restart(fullRestart: true);
      expect(result.isOk, false);
      expect(result.message, 'setupHotRestart failed');
    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: false),
      Artifacts: () => Artifacts.test(),
      FileSystem: () => fileSystem,
      Platform: () => FakePlatform(operatingSystem: 'linux'),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('hot restart supported', () async {
      fileSystem.file('.packages')
        ..createSync(recursive: true)
        ..writeAsStringSync('\n');
      // Setup mocks
      final FakeVmServiceHost fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
        listViews,
        FakeVmServiceRequest(
          method: 'getIsolate',
          args: <String, Object>{
            'isolateId': fakeUnpausedIsolate.id,
          },
          jsonResponse: fakeUnpausedIsolate.toJson(),
        ),
        FakeVmServiceRequest(
          method: 'getVM',
          jsonResponse: vm_service.VM.parse(<String, Object>{}).toJson(),
        ),
        listViews,
        const FakeVmServiceRequest(
          method: 'streamListen',
          args: <String, Object>{
            'streamId': 'Isolate',
          }
        ),
        FakeVmServiceRequest(
          method: kRunInViewMethod,
          args: <String, Object>{
            'viewId': fakeFlutterView.id,
            'mainScript': 'main.dart.dill',
            'assetDirectory': 'build/flutter_assets',
          }
        ),
        FakeVmServiceStreamResponse(
          streamId: 'Isolate',
          event: vm_service.Event(
            timestamp: 0,
            kind: vm_service.EventKind.kIsolateRunnable,
          )
        ),
      ]);
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(true);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      // Trigger hot restart.
      final List<FlutterDevice> devices = <FlutterDevice>[
        FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug)
          ..vmService = fakeVmServiceHost.vmService
          ..devFS = mockDevFs,
      ];
      final HotRunner hotRunner = HotRunner(
        devices,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
      );
      final OperationResult result = await hotRunner.restart(fullRestart: true);
      // Expect hot restart successful.
      expect(hotRunner.uri, mockDevFs.baseUri);
      expect(result.isOk, true);
      expect(result.message, isNot('setupHotRestart failed'));
    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true),
      Artifacts: () => Artifacts.test(),
      FileSystem: () => fileSystem,
      Platform: () => FakePlatform(operatingSystem: 'linux'),
      ProcessManager: () => FakeProcessManager.any(),
    });

    group('shutdown hook tests', () {
      TestHotRunnerConfig shutdownTestingConfig;

      setUp(() {
        shutdownTestingConfig = TestHotRunnerConfig(
          successfulSetup: true,
        );
      });

      testUsingContext('shutdown hook called after signal', () async {
        fileSystem.file('.packages')
          ..createSync(recursive: true)
          ..writeAsStringSync('\n');
        final MockDevice mockDevice = MockDevice();
        when(mockDevice.supportsHotReload).thenReturn(true);
        when(mockDevice.supportsHotRestart).thenReturn(true);
        when(mockDevice.supportsFlutterExit).thenReturn(false);
        final List<FlutterDevice> devices = <FlutterDevice>[
          FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug),
        ];
        await HotRunner(
          devices,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
        ).cleanupAfterSignal();
        expect(shutdownTestingConfig.shutdownHookCalled, true);
      }, overrides: <Type, Generator>{
        HotRunnerConfig: () => shutdownTestingConfig,
        Artifacts: () => Artifacts.test(),
        FileSystem: () => fileSystem,
        Platform: () => FakePlatform(operatingSystem: 'linux'),
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('shutdown hook called after app stop', () async {
        fileSystem.file('.packages')
          ..createSync(recursive: true)
          ..writeAsStringSync('\n');
        final MockDevice mockDevice = MockDevice();
        when(mockDevice.supportsHotReload).thenReturn(true);
        when(mockDevice.supportsHotRestart).thenReturn(true);
        when(mockDevice.supportsFlutterExit).thenReturn(false);
        final List<FlutterDevice> devices = <FlutterDevice>[
          FlutterDevice(mockDevice, generator: residentCompiler, buildInfo: BuildInfo.debug),
        ];
        await HotRunner(
          devices,
          debuggingOptions: DebuggingOptions.disabled(BuildInfo.debug),
          target: 'main.dart',
        ).preExit();
        expect(shutdownTestingConfig.shutdownHookCalled, true);
      }, overrides: <Type, Generator>{
        HotRunnerConfig: () => shutdownTestingConfig,
        Artifacts: () => Artifacts.test(),
        FileSystem: () => fileSystem,
        Platform: () => FakePlatform(operatingSystem: 'linux'),
        ProcessManager: () => FakeProcessManager.any(),
      });
    });
  });

  group('hot attach', () {
    FileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    testUsingContext('Exits with code 2 when when HttpException is thrown '
      'during VM service connection', () async {
      fileSystem.file('.packages')
        ..createSync(recursive: true)
        ..writeAsStringSync('\n');

      final FakeResidentCompiler residentCompiler = FakeResidentCompiler();
      final MockDevice mockDevice = MockDevice();
      when(mockDevice.supportsHotReload).thenReturn(true);
      when(mockDevice.supportsHotRestart).thenReturn(false);
      when(mockDevice.targetPlatform).thenAnswer((Invocation _) async => TargetPlatform.tester);
      when(mockDevice.sdkNameAndVersion).thenAnswer((Invocation _) async => 'Android 10');

      final List<FlutterDevice> devices = <FlutterDevice>[
        TestFlutterDevice(
          device: mockDevice,
          generator: residentCompiler,
          exception: const HttpException('Connection closed before full header was received, '
              'uri = http://127.0.0.1:63394/5ZmLv8A59xY=/ws'),
        ),
      ];

      final int exitCode = await HotRunner(devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
      ).attach(
        enableDevTools: false,
      );
      expect(exitCode, 2);
    }, overrides: <Type, Generator>{
      HotRunnerConfig: () => TestHotRunnerConfig(successfulSetup: true),
      Artifacts: () => Artifacts.test(),
      FileSystem: () => fileSystem,
      Platform: () => FakePlatform(operatingSystem: 'linux'),
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('hot cleanupAtFinish()', () {
    MockFlutterDevice mockFlutterDeviceFactory(Device device) {
      final MockFlutterDevice mockFlutterDevice = MockFlutterDevice();
      when(mockFlutterDevice.stopEchoingDeviceLog()).thenAnswer((Invocation invocation) => Future<void>.value(null));
      when(mockFlutterDevice.device).thenReturn(device);
      return mockFlutterDevice;
    }

    testUsingContext('disposes each device', () async {
      final MockDevice mockDevice1 = MockDevice();
      final MockDevice mockDevice2 = MockDevice();
      final MockFlutterDevice mockFlutterDevice1 = mockFlutterDeviceFactory(mockDevice1);
      final MockFlutterDevice mockFlutterDevice2 = mockFlutterDeviceFactory(mockDevice2);

      final List<FlutterDevice> devices = <FlutterDevice>[
        mockFlutterDevice1,
        mockFlutterDevice2,
      ];

      await HotRunner(devices,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
      ).cleanupAtFinish();

      verify(mockDevice1.dispose());
      verify(mockFlutterDevice1.stopEchoingDeviceLog());
      verify(mockDevice2.dispose());
      verify(mockFlutterDevice2.stopEchoingDeviceLog());
    });
  });
}

class MockDevFs extends Mock implements DevFS {}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}

class MockFlutterDevice extends Mock implements FlutterDevice {}

class TestFlutterDevice extends FlutterDevice {
  TestFlutterDevice({
    @required Device device,
    @required this.exception,
    @required ResidentCompiler generator,
  })  : assert(exception != null),
        super(device, buildInfo: BuildInfo.debug, generator: generator);

  /// The exception to throw when the connect method is called.
  final Exception exception;

  @override
  Future<void> connect({
    ReloadSources reloadSources,
    Restart restart,
    CompileExpression compileExpression,
    GetSkSLMethod getSkSLMethod,
    PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
    bool disableServiceAuthCodes = false,
    bool disableDds = false,
    bool ipv6 = false,
    int hostVmServicePort,
    int ddsPort,
    bool allowExistingDdsInstance = false,
  }) async {
    throw exception;
  }
}

class TestHotRunnerConfig extends HotRunnerConfig {
  TestHotRunnerConfig({@required this.successfulSetup});
  bool successfulSetup;
  bool shutdownHookCalled = false;

  @override
  Future<bool> setupHotRestart() async {
    return successfulSetup;
  }

  @override
  Future<void> runPreShutdownOperations() async {
    shutdownHookCalled = true;
  }
}

class FakeResidentCompiler extends Fake implements ResidentCompiler {
  @override
  void accept() {}
}
