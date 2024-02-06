// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/dds.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/tools/scene_importer.dart';
import 'package:flutter_tools/src/build_system/tools/shader_compiler.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/device_port_forwarder.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/resident_devtools_handler.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/run_cold.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_vm_services.dart';
import '../../src/fakes.dart';
import '../../src/testbed.dart';
import 'fake_native_assets_build_runner.dart';

final vm_service.Event fakeUnpausedEvent = vm_service.Event(
  kind: vm_service.EventKind.kResume,
  timestamp: 0
);

final vm_service.Event fakePausedEvent = vm_service.Event(
  kind: vm_service.EventKind.kPauseException,
  timestamp: 0
);

final vm_service.Isolate fakeUnpausedIsolate = vm_service.Isolate(
  id: '1',
  pauseEvent: fakeUnpausedEvent,
  breakpoints: <vm_service.Breakpoint>[],
  extensionRPCs: <String>[],
  libraries: <vm_service.LibraryRef>[
    vm_service.LibraryRef(
      id: '1',
      uri: 'file:///hello_world/main.dart',
      name: '',
    ),
  ],
  livePorts: 0,
  name: 'test',
  number: '1',
  pauseOnExit: false,
  runnable: true,
  startTime: 0,
  isSystemIsolate: false,
  isolateFlags: <vm_service.IsolateFlag>[],
);

final vm_service.Isolate fakePausedIsolate = vm_service.Isolate(
  id: '1',
  pauseEvent: fakePausedEvent,
  breakpoints: <vm_service.Breakpoint>[
    vm_service.Breakpoint(
      breakpointNumber: 123,
      id: 'test-breakpoint',
      location: vm_service.SourceLocation(
        tokenPos: 0,
        script: vm_service.ScriptRef(id: 'test-script', uri: 'foo.dart'),
      ),
      enabled: true,
      resolved: true,
    ),
  ],
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

final vm_service.VM fakeVM = vm_service.VM(
  isolates: <vm_service.IsolateRef>[fakeUnpausedIsolate],
  pid: 1,
  hostCPU: '',
  isolateGroups: <vm_service.IsolateGroupRef>[],
  targetCPU: '',
  startTime: 0,
  name: 'dart',
  architectureBits: 64,
  operatingSystem: '',
  version: '',
  systemIsolateGroups: <vm_service.IsolateGroupRef>[],
  systemIsolates: <vm_service.IsolateRef>[],
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

const FakeVmServiceRequest setAssetBundlePath = FakeVmServiceRequest(
  method: '_flutter.setAssetBundlePath',
  args: <String, Object>{
    'viewId': 'a',
    'assetDirectory': 'build/flutter_assets',
    'isolateId': '1',
  }
);

const FakeVmServiceRequest evict = FakeVmServiceRequest(
  method: 'ext.flutter.evict',
  args: <String, Object>{
    'value': 'asset',
    'isolateId': '1',
  }
);

const FakeVmServiceRequest evictShader = FakeVmServiceRequest(
  method: 'ext.ui.window.reinitializeShader',
  args: <String, Object>{
    'assetKey': 'foo.frag',
    'isolateId': '1',
  }
);

final Uri testUri = Uri.parse('foo://bar');

void main() {
  late Testbed testbed;
  late FakeFlutterDevice flutterDevice;
  late FakeDevFS devFS;
  late ResidentRunner residentRunner;
  late FakeDevice device;
  late FakeAnalytics fakeAnalytics;
  FakeVmServiceHost? fakeVmServiceHost;

  setUp(() {
    testbed = Testbed(setup: () {
      fakeAnalytics = getInitializedFakeAnalyticsInstance(
        fs: globals.fs,
        fakeFlutterVersion: FakeFlutterVersion(),
      );

      globals.fs.file('.packages')
        .writeAsStringSync('\n');
      globals.fs.file(globals.fs.path.join('build', 'app.dill'))
        ..createSync(recursive: true)
        ..writeAsStringSync('ABC');
      residentRunner = HotRunner(
        <FlutterDevice>[
          flutterDevice,
        ],
        stayResident: false,
        debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
        target: 'main.dart',
        devtoolsHandler: createNoOpHandler,
        analytics: fakeAnalytics,
      );
    });
    device = FakeDevice();
    devFS = FakeDevFS();
    flutterDevice = FakeFlutterDevice()
      ..testUri = testUri
      ..vmServiceHost = (() => fakeVmServiceHost)
      ..device = device
      .._devFS = devFS;
  });

  testUsingContext(
      'use the nativeAssetsYamlFile when provided',
      () => testbed.run(() async {
        final FakeDevice device = FakeDevice(
          targetPlatform: TargetPlatform.darwin,
          sdkNameAndVersion: 'Macos',
        );
        final FakeResidentCompiler residentCompiler = FakeResidentCompiler();
        final FakeFlutterDevice flutterDevice = FakeFlutterDevice()
          ..testUri = testUri
          ..vmServiceHost = (() => fakeVmServiceHost)
          ..device = device
          .._devFS = devFS
          ..targetPlatform = TargetPlatform.darwin
          ..generator = residentCompiler;

        fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
          listViews,
          listViews,
        ]);
        globals.fs
            .file(globals.fs.path.join('lib', 'main.dart'))
            .createSync(recursive: true);
        final FakeNativeAssetsBuildRunner buildRunner = FakeNativeAssetsBuildRunner();
        residentRunner = HotRunner(
          <FlutterDevice>[
            flutterDevice,
          ],
          stayResident: false,
          debuggingOptions: DebuggingOptions.enabled(const BuildInfo(
            BuildMode.debug,
            '',
            treeShakeIcons: false,
            trackWidgetCreation: true,
          )),
          target: 'main.dart',
          devtoolsHandler: createNoOpHandler,
          nativeAssetsBuilder: FakeHotRunnerNativeAssetsBuilder(buildRunner),
          analytics: fakeAnalytics,
          nativeAssetsYamlFile: 'foo.yaml',
        );

        final int? result = await residentRunner.run();
        expect(result, 0);

        expect(buildRunner.buildInvocations, 0);
        expect(buildRunner.dryRunInvocations, 0);
        expect(buildRunner.hasPackageConfigInvocations, 0);
        expect(buildRunner.packagesWithNativeAssetsInvocations, 0);

        expect(residentCompiler.recompileCalled, true);
        expect(residentCompiler.receivedNativeAssetsYaml, globals.fs.path.toUri('foo.yaml'));
      }),
      overrides: <Type, Generator>{
        ProcessManager: () => FakeProcessManager.any(),
        FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: true, isMacOSEnabled: true),
      });
}

class FakeFlutterDevice extends Fake implements FlutterDevice {
  FakeVmServiceHost? Function()? vmServiceHost;
  Uri? testUri;
  UpdateFSReport report = UpdateFSReport(
    success: true,
    invalidatedSourcesCount: 1,
  );
  Exception? reportError;
  Exception? runColdError;
  int runHotCode = 0;
  int runColdCode = 0;

  @override
  ResidentCompiler? generator;

  @override
  DevelopmentShaderCompiler get developmentShaderCompiler => const FakeShaderCompiler();

  @override
  TargetPlatform targetPlatform = TargetPlatform.android;

  @override
  Stream<Uri?> get vmServiceUris => Stream<Uri?>.value(testUri);

  @override
  FlutterVmService? get vmService => vmServiceHost?.call()?.vmService;

  DevFS? _devFS;

  @override
  DevFS? get devFS => _devFS;

  @override
  set devFS(DevFS? value) { }

  @override
  Device? device;

  @override
  Future<void> stopEchoingDeviceLog() async { }

  @override
  Future<void> initLogReader() async { }

  @override
  Future<Uri> setupDevFS(String fsName, Directory rootDirectory) async {
    return testUri!;
  }

  @override
  Future<int> runHot({required HotRunner hotRunner, String? route}) async {
    return runHotCode;
  }

  @override
  Future<int> runCold({required ColdRunner coldRunner, String? route}) async {
    if (runColdError != null) {
      throw runColdError!;
    }
    return runColdCode;
  }

  @override
  Future<void> connect({
    ReloadSources? reloadSources,
    Restart? restart,
    CompileExpression? compileExpression,
    GetSkSLMethod? getSkSLMethod,
    FlutterProject? flutterProject,
    PrintStructuredErrorLogMethod? printStructuredErrorLogMethod,
    int? hostVmServicePort,
    int? ddsPort,
    bool disableServiceAuthCodes = false,
    bool enableDds = true,
    bool cacheStartupProfile = false,
    required bool allowExistingDdsInstance,
    bool ipv6 = false,
  }) async { }

  @override
  Future<UpdateFSReport> updateDevFS({
    required Uri mainUri,
    String? target,
    AssetBundle? bundle,
    DateTime? firstBuildTime,
    bool bundleFirstUpload = false,
    bool bundleDirty = false,
    bool fullRestart = false,
    String? projectRootPath,
    required String pathToReload,
    required String dillOutputPath,
    required List<Uri> invalidatedFiles,
    required PackageConfig packageConfig,
  }) async {
    if (reportError != null) {
      throw reportError!;
    }
    return report;
  }

  @override
  Future<void> updateReloadStatus(bool wasReloadSuccessful) async { }
}

class FakeResidentCompiler extends Fake implements ResidentCompiler {
  CompilerOutput? nextOutput;
  bool didSuppressErrors = false;
  Uri? receivedNativeAssetsYaml;
  bool recompileCalled = false;

  @override
  Future<CompilerOutput?> recompile(
    Uri mainUri,
    List<Uri>? invalidatedFiles, {
    required String outputPath,
    required PackageConfig packageConfig,
    String? projectRootPath,
    required FileSystem fs,
    bool suppressErrors = false,
    bool checkDartPluginRegistry = false,
    File? dartPluginRegistrant,
    Uri? nativeAssetsYaml,
  }) async {
    recompileCalled = true;
    receivedNativeAssetsYaml = nativeAssetsYaml;
    didSuppressErrors = suppressErrors;
    return nextOutput ?? const CompilerOutput('foo.dill', 0, <Uri>[]);
  }

  @override
  void accept() { }

  @override
  void reset() { }
}

class FakeDevice extends Fake implements Device {
  FakeDevice({
    String sdkNameAndVersion = 'Android',
    TargetPlatform targetPlatform = TargetPlatform.android_arm,
    bool isLocalEmulator = false,
    this.supportsHotRestart = true,
    this.supportsScreenshot = true,
    this.supportsFlutterExit = true,
  }) : _isLocalEmulator = isLocalEmulator,
       _targetPlatform = targetPlatform,
       _sdkNameAndVersion = sdkNameAndVersion;

  final bool _isLocalEmulator;
  final TargetPlatform _targetPlatform;
  final String _sdkNameAndVersion;

  bool disposed = false;
  bool appStopped = false;
  bool failScreenshot = false;

  @override
  bool supportsHotRestart;

  @override
  bool supportsScreenshot;

  @override
  bool supportsFlutterExit;

  @override
  PlatformType get platformType => _targetPlatform == TargetPlatform.web_javascript
    ? PlatformType.web
    : PlatformType.android;

  @override
  Future<String> get sdkNameAndVersion async => _sdkNameAndVersion;

  @override
  Future<TargetPlatform> get targetPlatform async => _targetPlatform;

  @override
  Future<bool> get isLocalEmulator async => _isLocalEmulator;

  @override
  String get name => 'FakeDevice';

  @override
  late DartDevelopmentService dds;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    appStopped = true;
    return true;
  }

  @override
  Future<void> takeScreenshot(File outputFile) async {
    if (failScreenshot) {
      throw Exception();
    }
    outputFile.writeAsBytesSync(List<int>.generate(1024, (int i) => i));
  }

  @override
  FutureOr<DeviceLogReader> getLogReader({
    ApplicationPackage? app,
    bool includePastLogs = false,
  }) => NoOpDeviceLogReader(name);

  @override
  DevicePortForwarder portForwarder = const NoOpDevicePortForwarder();
}

class FakeDevFS extends Fake implements DevFS {
  @override
  DateTime? lastCompiled = DateTime(2000);

  @override
  PackageConfig? lastPackageConfig = PackageConfig.empty;

  @override
  List<Uri> sources = <Uri>[];

  @override
  Uri baseUri = Uri();

  @override
  Future<void> destroy() async { }

  @override
  Set<String> assetPathsToEvict = <String>{};

  @override
  Set<String> shaderPathsToEvict = <String>{};

  @override
  Set<String> scenePathsToEvict = <String>{};

  @override
  bool didUpdateFontManifest = false;

  UpdateFSReport nextUpdateReport = UpdateFSReport(success: true);

  @override
  bool hasSetAssetDirectory = false;

  @override
  Future<Uri> create() async {
    return Uri();
  }

  @override
  void resetLastCompiled() {
    lastCompiled = null;
  }

  @override
  Future<UpdateFSReport> update({
    required Uri mainUri,
    required ResidentCompiler generator,
    required bool trackWidgetCreation,
    required String pathToReload,
    required List<Uri> invalidatedFiles,
    required PackageConfig packageConfig,
    required String dillOutputPath,
    required DevelopmentShaderCompiler shaderCompiler,
    DevelopmentSceneImporter? sceneImporter,
    DevFSWriter? devFSWriter,
    String? target,
    AssetBundle? bundle,
    DateTime? firstBuildTime,
    bool bundleFirstUpload = false,
    bool fullRestart = false,
    String? projectRootPath,
    File? dartPluginRegistrant,
  }) async {
    return nextUpdateReport;
  }
}

class FakeShaderCompiler implements DevelopmentShaderCompiler {
  const FakeShaderCompiler();

  @override
  void configureCompiler(TargetPlatform? platform) { }

  @override
  Future<DevFSContent> recompileShader(DevFSContent inputShader) {
    throw UnimplementedError();
  }
}
