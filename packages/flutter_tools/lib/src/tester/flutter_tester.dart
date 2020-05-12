// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../application_package.dart';
import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../protocol_discovery.dart';
import '../version.dart';

class FlutterTesterApp extends ApplicationPackage {
  factory FlutterTesterApp.fromCurrentDirectory() {
    return FlutterTesterApp._(globals.fs.currentDirectory);
  }

  FlutterTesterApp._(Directory directory)
    : _directory = directory,
      super(id: directory.path);

  final Directory _directory;

  @override
  String get name => _directory.basename;

  @override
  File get packagesFile => _directory.childFile('.packages');
}

// TODO(scheglov): This device does not currently work with full restarts.
class FlutterTesterDevice extends Device {
  FlutterTesterDevice(String deviceId) : super(
      deviceId,
      platformType: null,
      category: null,
      ephemeral: false,
  );

  Process _process;
  final DevicePortForwarder _portForwarder = _NoopPortForwarder();

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String> get emulatorId async => null;

  @override
  String get name => 'Flutter test device';

  @override
  DevicePortForwarder get portForwarder => _portForwarder;

  @override
  Future<String> get sdkNameAndVersion async {
    final FlutterVersion flutterVersion = globals.flutterVersion;
    return 'Flutter ${flutterVersion.frameworkRevisionShort}';
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.tester;

  @override
  void clearLogs() { }

  final _FlutterTesterDeviceLogReader _logReader =
      _FlutterTesterDeviceLogReader();

  @override
  DeviceLogReader getLogReader({
    ApplicationPackage app,
    bool includePastLogs = false,
  }) {
    return _logReader;
  }

  @override
  Future<bool> installApp(ApplicationPackage app) async => true;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  bool isSupported() => true;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    @required String mainPath,
    String route,
    @required DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
  }) async {
    final BuildInfo buildInfo = debuggingOptions.buildInfo;

    if (!buildInfo.isDebug) {
      globals.printError('This device only supports debug mode.');
      return LaunchResult.failed();
    }

    final String shellPath = globals.artifacts.getArtifactPath(Artifact.flutterTester);
    if (!globals.fs.isFileSync(shellPath)) {
      throwToolExit('Cannot find Flutter shell at $shellPath');
    }

    final List<String> command = <String>[
      shellPath,
      '--run-forever',
      '--non-interactive',
      '--enable-dart-profiling',
      '--packages=$globalPackagesPath',
    ];
    if (debuggingOptions.debuggingEnabled) {
      if (debuggingOptions.startPaused) {
        command.add('--start-paused');
      }
      if (debuggingOptions.disableServiceAuthCodes) {
        command.add('--disable-service-auth-codes');
      }
      if (debuggingOptions.hasObservatoryPort) {
        command.add('--observatory-port=${debuggingOptions.hostVmServicePort}');
      }
    }

    // Build assets and perform initial compilation.
    final String assetDirPath = getAssetBuildDirectory();
    final String applicationKernelFilePath = getKernelPathForTransformerOptions(
      globals.fs.path.join(getBuildDirectory(), 'flutter-tester-app.dill'),
      trackWidgetCreation: buildInfo.trackWidgetCreation,
    );
    await BundleBuilder().build(
      buildInfo: buildInfo,
      mainPath: mainPath,
      assetDirPath: assetDirPath,
      applicationKernelFilePath: applicationKernelFilePath,
      precompiledSnapshot: false,
      trackWidgetCreation: buildInfo.trackWidgetCreation,
      platform: getTargetPlatformForName(getNameForHostPlatform(getCurrentHostPlatform())),
      treeShakeIcons: buildInfo.treeShakeIcons,
    );
    command.add('--flutter-assets-dir=$assetDirPath');

    command.add(applicationKernelFilePath);

    ProtocolDiscovery observatoryDiscovery;
    try {
      globals.printTrace(command.join(' '));

      _isRunning = true;
      _process = await globals.processManager.start(command,
        environment: <String, String>{
          'FLUTTER_TEST': 'true',
        },
      );
      // Setting a bool can't fail in the callback.
      unawaited(_process.exitCode.then<void>((_) => _isRunning = false));
      _process.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
          _logReader.addLine(line);
        });
      _process.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
          _logReader.addLine(line);
        });

      if (!debuggingOptions.debuggingEnabled) {
        return LaunchResult.succeeded();
      }

      observatoryDiscovery = ProtocolDiscovery.observatory(
        getLogReader(),
        hostPort: debuggingOptions.hostVmServicePort,
        devicePort: debuggingOptions.deviceVmServicePort,
        ipv6: ipv6,
      );

      final Uri observatoryUri = await observatoryDiscovery.uri;
      if (observatoryUri != null) {
        return LaunchResult.succeeded(observatoryUri: observatoryUri);
      }
      globals.printError(
        'Failed to launch $package: '
        'The log reader failed unexpectedly.',
      );
    } on Exception catch (error) {
      globals.printError('Failed to launch $package: $error');
    } finally {
      await observatoryDiscovery?.cancel();
    }
    return LaunchResult.failed();
  }

  @override
  Future<bool> stopApp(ApplicationPackage app) async {
    _process?.kill();
    _process = null;
    return true;
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app) async => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  Future<void> dispose() async {
    _logReader?.dispose();
    await _portForwarder?.dispose();
  }
}

class FlutterTesterDevices extends PollingDeviceDiscovery {
  FlutterTesterDevices() : super('Flutter tester');

  static const String kTesterDeviceId = 'flutter-tester';

  static bool showFlutterTesterDevice = false;

  final FlutterTesterDevice _testerDevice =
      FlutterTesterDevice(kTesterDeviceId);

  @override
  bool get canListAnything => true;

  @override
  bool get supportsPlatform => true;

  @override
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    return showFlutterTesterDevice ? <Device>[_testerDevice] : <Device>[];
  }
}

class _FlutterTesterDeviceLogReader extends DeviceLogReader {
  final StreamController<String> _logLinesController =
      StreamController<String>.broadcast();

  @override
  int get appPid => 0;

  @override
  Stream<String> get logLines => _logLinesController.stream;

  @override
  String get name => 'flutter tester log reader';

  void addLine(String line) => _logLinesController.add(line);

  @override
  void dispose() {}
}

/// A fake port forwarder that doesn't do anything. Used by flutter tester
/// where the VM is running on the same machine and does not need ports forwarding.
class _NoopPortForwarder extends DevicePortForwarder {
  @override
  Future<int> forward(int devicePort, { int hostPort }) {
    if (hostPort != null && hostPort != devicePort) {
      throw 'Forwarding to a different port is not supported by flutter tester';
    }
    return Future<int>.value(devicePort);
  }

  @override
  List<ForwardedPort> get forwardedPorts => <ForwardedPort>[];

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async { }

  @override
  Future<void> dispose() async { }
}
