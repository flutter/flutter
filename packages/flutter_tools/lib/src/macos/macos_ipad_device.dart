// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:vm_service/vm_service_io.dart' as vm_service_io;

import '../application_package.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../darwin/darwin.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../device_vm_service_discovery_for_attach.dart';
import '../globals.dart' as globals;
import '../ios/application_package.dart';
import '../ios/ios_workflow.dart';
import '../ios/mac.dart';
import '../ios/xcode_debug.dart';
import '../mdns_discovery.dart';
import '../project.dart';
import '../vmservice.dart';
import 'xcdevice.dart';
import 'xcode.dart';

/// Represents an ARM macOS target that can run iPad apps.
///
/// https://developer.apple.com/documentation/apple-silicon/running-your-ios-apps-on-macos
class MacOSDesignedForIPadDevice extends DesktopDevice {
  MacOSDesignedForIPadDevice({
    required super.toolContext,
    required Xcode xcode,
    required this._xcdevice,
    XcodeDebug? xcodeDebug,
    MDnsVmServiceDiscovery Function(Set<(int, String)>)? vmServiceDiscoveryFactory,
    Future<vm_service.VmService> Function(Uri)? vmServiceConnector,
  }) : _xcodeDebug =
           xcodeDebug ??
           XcodeDebug(
             logger: toolContext.logger,
             processManager: toolContext.processManager,
             xcode: xcode,
             fileSystem: toolContext.fs,
           ),
       _vmServiceDiscoveryFactory =
           vmServiceDiscoveryFactory ??
           ((Set<(int, String)> ignoredServices) => MDnsVmServiceDiscovery(
             logger: toolContext.logger,
             analytics: globals.analytics,
             platform: toolContext.platform,
             ignoredServices: ignoredServices,
           )),
       _vmServiceConnector =
           vmServiceConnector ??
           ((Uri uri) => vm_service_io.vmServiceConnectUri(
             uri.replace(scheme: 'ws', path: '${uri.path}ws').toString(),
           )),
       super('mac-designed-for-ipad', platformType: PlatformType.ios, ephemeral: false);

  final XCDevice _xcdevice;
  final XcodeDebug _xcodeDebug;
  final MDnsVmServiceDiscovery Function(Set<(int, String)>) _vmServiceDiscoveryFactory;
  final Future<vm_service.VmService> Function(Uri) _vmServiceConnector;
  final _logReader = _MacOSDesignedForIPadLogReader();

  static const _destination = 'platform=macOS,variant=Designed for iPad,arch=arm64';

  @override
  String get name => 'Mac Designed for iPad';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  // "Designed for iPad" apps are only supported on Apple Silicon Macs.
  @override
  Future<CpuArch> get cpuArch async => CpuArch.arm64;

  @override
  Future<bool> isSupported() async => toolContext.os.hostPlatform == HostPlatform.darwin_arm64;

  @override
  bool get supportsFlavors => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.ios.existsSync() &&
        toolContext.os.hostPlatform == HostPlatform.darwin_arm64;
  }

  @override
  String? executablePathForDevice(ApplicationPackage package, BuildInfo buildInfo) => null;

  @override
  VMServiceDiscoveryForAttach getVMServiceDiscoveryForAttach({
    String? appId,
    String? fuchsiaModule,
    int? filterDevicePort,
    int? expectedHostPort,
    required bool ipv6,
    required Logger logger,
  }) {
    final mdnsVMServiceDiscoveryForAttach = MdnsVMServiceDiscoveryForAttach(
      device: this,
      appId: appId,
      deviceVmservicePort: filterDevicePort,
      hostVmservicePort: expectedHostPort,
      // Do not throw on error since DelegateVMServiceDiscoveryForAttach falls
      // back to log-based protocol discovery.
      throwOnError: false,
      useDeviceIPAsHost: false,
      usesIpv6: ipv6,
    );

    return DelegateVMServiceDiscoveryForAttach(<VMServiceDiscoveryForAttach>[
      mdnsVMServiceDiscoveryForAttach,
      super.getVMServiceDiscoveryForAttach(
        appId: appId,
        fuchsiaModule: fuchsiaModule,
        filterDevicePort: filterDevicePort,
        expectedHostPort: expectedHostPort,
        ipv6: ipv6,
        logger: logger,
      ),
    ]);
  }

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs = const <String, Object>{},
    bool prebuiltApplication = false,
    String? userIdentifier,
  }) async {
    final Logger logger = toolContext.logger;
    if (package is! IOSApp) {
      throwToolExit('An iOS application is required for $name.');
    }
    if (debuggingOptions.disablePortPublication && debuggingOptions.debuggingEnabled) {
      throwToolExit('Disabling VM service publication is not supported for $name.');
    }
    final String? deviceId = await _xcdevice.getMacOSDeviceIdentifier();
    if (deviceId == null) {
      throwToolExit('Unable to find this Mac in Xcode. Run "flutter doctor" to check Xcode.');
    }
    String applicationId = package.id;
    if (!prebuiltApplication) {
      if (package is! BuildableIOSApp) {
        throwToolExit('An iOS project is required to build for $name.');
      }
      final XcodeBuildResult result = await _buildApp(
        package,
        debuggingOptions.buildInfo,
        mainPath,
      );
      applicationId =
          result.xcodeBuildExecution?.buildSettings[IosProject.kProductBundleIdKey] ??
          applicationId;
    }
    if (!toolContext.fs.directory(package.deviceBundlePath).existsSync()) {
      throwToolExit('Unable to find the iOS application at ${package.deviceBundlePath}.');
    }

    final FlutterProject project = toolContext.projectFactory.fromDirectory(
      toolContext.fs.currentDirectory,
    );
    await project.ios.ensureReadyForPlatformSpecificTooling(toolContext: toolContext);
    final XcodeDebugProject debugProject = await _xcodeDebug.createXcodeProjectWithCustomBundle(
      toolContext.fs.path.absolute(package.deviceBundlePath),
      templateRenderer: globals.templateRenderer,
      copyApplicationBundle: true,
      buildMode: debuggingOptions.buildInfo.mode,
      debuggerEnabled:
          debuggingOptions.buildInfo.isDebug ||
          (debuggingOptions.buildInfo.isProfile && (debuggingOptions.iosProfileDebugger ?? false)),
      lldbInitFile: project.ios.lldbInitFile.absolute.path,
      verboseLogging: logger.isVerbose,
    );
    final List<String> arguments = debuggingOptions
        .getIOSLaunchArguments(EnvironmentType.physical, route, platformArgs, isLocal: true)
        .where(
          (String argument) =>
              argument != '--enable-checked-mode' && argument != '--verify-entry-points',
        )
        .toList();
    logger.printStatus(
      'Flutter uses Xcode to launch $name. If prompted, allow access to control Xcode.',
    );
    var succeeded = false;
    var startupPending = true;
    toolContext.shutdownHooks.addShutdownHook(() async {
      if (startupPending) {
        await _xcodeDebug.exit();
      }
    });
    final int launchStartedAt = toolContext.systemClock.now().millisecondsSinceEpoch;
    try {
      final bool launched = await _xcodeDebug.debugApp(
        project: debugProject,
        deviceId: deviceId,
        devicePlatform: 'iphoneos',
        deviceArchitecture: 'arm64',
        launchArguments: arguments,
      );
      if (!launched) {
        return LaunchResult.failed();
      }
      if (!debuggingOptions.debuggingEnabled) {
        succeeded = true;
        return LaunchResult.succeeded();
      }
      final Uri? uri = await _discoverVMService(applicationId, debuggingOptions, launchStartedAt);
      if (uri == null) {
        return LaunchResult.failed();
      }
      succeeded = true;
      return LaunchResult.succeeded(vmServiceUri: uri);
    } finally {
      startupPending = false;
      if (!succeeded) {
        await _xcodeDebug.exit();
        if (debugProject.xcodeProject.parent.existsSync()) {
          debugProject.xcodeProject.parent.deleteSync(recursive: true);
        }
      }
    }
  }

  Future<Uri?> _discoverVMService(
    String applicationId,
    DebuggingOptions options,
    int launchStartedAt,
  ) async {
    final int? requestedPort = options.hostVmServicePort ?? options.deviceVmServicePort;
    final ignoredServices = <(int, String)>{};
    final stopwatch = Stopwatch()..start();
    const timeout = Duration(minutes: 10);
    while (stopwatch.elapsed < timeout) {
      // A new client avoids retaining a previous process's Bonjour records.
      final Uri? uri = await _vmServiceDiscoveryFactory(ignoredServices).getVMServiceUriForLaunch(
        applicationId,
        this,
        deviceName: toolContext.platform.localHostname,
        deviceVmservicePort: requestedPort == 0 ? null : requestedPort,
        hostVmservicePort: options.hostVmServicePort,
        usesIpv6: options.ipv6,
        timeout: timeout - stopwatch.elapsed,
      );
      if (uri == null) {
        return null;
      }
      vm_service.VmService? service;
      try {
        service = await _vmServiceConnector(uri);
        final vm_service.VM vm = await service.getVM();
        if (vm.startTime != null && vm.startTime! >= launchStartedAt) {
          return uri;
        }
      } on Exception {
        // The previous Xcode session can stop after its service was advertised.
      } finally {
        await service?.dispose();
      }
      final String authCode = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      if (authCode.isNotEmpty) {
        ignoredServices.add((uri.port, authCode));
      }
      toolContext.logger.printTrace('Ignoring a Dart VM service from a previous app launch.');
    }
    throwToolExit('Unable to discover the Dart VM service for the newly launched app.');
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    return _xcodeDebug.debugStarted ? _xcodeDebug.exit() : true;
  }

  @override
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier}) async {
    throwToolExit('Standalone installation is not supported for $name. Use "flutter run".');
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier}) async {
    throwToolExit('Uninstalling applications is not supported for $name.');
  }

  @override
  DeviceLogReader getLogReader({ApplicationPackage? app, bool includePastLogs = false}) =>
      _logReader;

  @override
  Future<void> dispose() async {
    _logReader.dispose();
    await super.dispose();
  }

  @override
  Future<void> buildForDevice({
    String? mainPath,
    required BuildInfo buildInfo,
    bool usingCISystem = false,
  }) async {
    final FlutterProject project = toolContext.projectFactory.fromDirectory(
      toolContext.fs.currentDirectory,
    );
    final BuildableIOSApp? app = await BuildableIOSApp.fromProject(
      project.ios,
      buildInfo,
      toolContext: toolContext,
    );
    if (app == null) {
      throwToolExit('Unable to find an iOS application to build for $name.');
    }
    await _buildApp(app, buildInfo, mainPath);
  }

  Future<XcodeBuildResult> _buildApp(
    BuildableIOSApp app,
    BuildInfo buildInfo,
    String? mainPath,
  ) async {
    final XcodeBuildResult result = await buildXcodeProject(
      app: app,
      buildInfo: buildInfo,
      targetOverride: mainPath,
      activeArch: CpuArch.arm64,
      destination: _destination,
      toolContext: toolContext,
    );
    if (!result.success) {
      await diagnoseXcodeBuildFailure(
        result,
        analytics: globals.analytics,
        fileSystem: toolContext.fs,
        logger: toolContext.logger,
        platform: FlutterDarwinPlatform.ios,
        project: app.project.parent,
        device: this,
      );
      throwToolExit('Failed to build the iOS application for $name.');
    }
    return result;
  }
}

class MacOSDesignedForIPadDevices extends PollingDeviceDiscovery {
  MacOSDesignedForIPadDevices({
    required this._iosWorkflow,
    required ToolContext super.toolContext,
    required this.xcode,
    required this.xcdevice,
  }) : super('Mac designed for iPad devices');

  final IOSWorkflow _iosWorkflow;
  final Xcode xcode;
  final XCDevice xcdevice;
  MacOSDesignedForIPadDevice? _device;

  @override
  bool get supportsPlatform => toolContext.platform.isMacOS;

  /// iOS (not desktop macOS) development is enabled, the host is an ARM Mac,
  /// and Xcode can discover devices.
  @override
  bool get canListAnything =>
      _iosWorkflow.canListDevices && toolContext.os.hostPlatform == HostPlatform.darwin_arm64;

  @override
  Future<List<Device>> pollingGetDevices({
    Duration? timeout,
    bool forWirelessDiscovery = false,
  }) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      _device ??= MacOSDesignedForIPadDevice(
        toolContext: toolContext,
        xcode: xcode,
        xcdevice: xcdevice,
      ),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['mac-designed-for-ipad'];
}

/// Receives Dart output after the VM service connects, without a remote device logger.
class _MacOSDesignedForIPadLogReader extends DeviceLogReader {
  final _lines = StreamController<String>.broadcast();
  final _subscriptions = <StreamSubscription<vm_service.Event>>[];

  @override
  String get name => 'Mac Designed for iPad';

  @override
  Stream<String> get logLines => _lines.stream;

  @override
  Future<void> provideVmService(FlutterVmService connectedVmService) async {
    for (final StreamSubscription<vm_service.Event> subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    void logEvent(vm_service.Event event) {
      final String message = processVmServiceMessage(event);
      if (message.isNotEmpty) {
        const LineSplitter().convert(message).forEach(_lines.add);
      }
    }

    _subscriptions.addAll(<StreamSubscription<vm_service.Event>>[
      connectedVmService.service.onStdoutEvent.listen(logEvent),
      connectedVmService.service.onStderrEvent.listen(logEvent),
    ]);
    for (final stream in <String>[
      'Debug',
      vm_service.EventStreams.kStdout,
      vm_service.EventStreams.kStderr,
    ]) {
      try {
        await connectedVmService.service.streamListen(stream);
      } on vm_service.RPCError catch (error) {
        if (error.code != vm_service.RPCErrorKind.kStreamAlreadySubscribed.code) {
          // The stream may already be subscribed by the resident runner.
          rethrow;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final StreamSubscription<vm_service.Event> subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }
}
