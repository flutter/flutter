// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config_types.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../application_package.dart';
import '../base/common.dart';
import '../base/dds.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/build_targets.dart';
import '../context/tool_context.dart';
import '../device.dart';
import '../resident_runner.dart';
import '../vmservice.dart';
import 'web_driver_service.dart';

class FlutterDriverFactory {
  FlutterDriverFactory({
    required this._analytics,
    required this._applicationPackageFactory,
    required this._buildSystem,
    required this._buildTargets,
    required this._dartSdkPath,
    required this._devtoolsLauncher,
    required this._toolContext,
  });

  final Analytics _analytics;
  final ApplicationPackageFactory _applicationPackageFactory;
  final BuildSystem _buildSystem;
  final BuildTargets _buildTargets;
  final String _dartSdkPath;
  final DevtoolsLauncher _devtoolsLauncher;
  final ToolContext _toolContext;

  /// Create a driver service for running `flutter drive`.
  DriverService createDriverService(bool web) {
    if (web) {
      return WebDriverService(
        analytics: _analytics,
        buildSystem: _buildSystem,
        buildTargets: _buildTargets,
        dartSdkPath: _dartSdkPath,
        toolContext: _toolContext,
      );
    }
    final ToolContext(:Logger logger, :Platform platform, :ProcessUtils processUtils) =
        _toolContext;
    return FlutterDriverService(
      applicationPackageFactory: _applicationPackageFactory,
      dartSdkPath: _dartSdkPath,
      devtoolsLauncher: _devtoolsLauncher,
      logger: logger,
      platform: platform,
      processUtils: processUtils,
    );
  }
}

/// Immutable specification consolidating test execution and browser parameters
/// for [DriverService.startTest].
@immutable
class DriveTestSpecification {
  const DriveTestSpecification({
    required this.packageConfig,
    this.arguments = const <String>[],
    this.headless,
    this.chromeBinary,
    this.browserName,
    this.androidEmulator,
    this.driverPort,
    this.webBrowserFlags = const <String>[],
    this.browserDimension,
    this.profileMemory,
  });

  static final _browserDimensionDelimiter = RegExp('[,x@]');

  /// Splits a raw `--browser-dimension` value (`width x height[@dpr]`) into tokens.
  static List<String>? parseBrowserDimension(String? raw) => raw?.split(_browserDimensionDelimiter);

  final List<String> arguments;
  final PackageConfig packageConfig;
  final bool? headless;
  final String? chromeBinary;
  final String? browserName;
  final bool? androidEmulator;
  final int? driverPort;
  final List<String> webBrowserFlags;
  final List<String>? browserDimension;
  final String? profileMemory;
}

/// An interface for the `flutter driver` integration test operations.
abstract class DriverService {
  /// Install and launch the application for the provided [device].
  Future<void> start(
    BuildInfo buildInfo,
    Device device,
    DebuggingOptions debuggingOptions, {
    File? applicationBinary,
    String? route,
    String? userIdentifier,
    String? mainPath,
    Map<String, Object> platformArgs = const <String, Object>{},
    Map<String, String> webDefines = const <String, String>{},
  });

  /// If --use-existing-app is provided, configured the correct VM Service URI.
  Future<void> reuseApplication(Uri vmServiceUri, Device device, DebuggingOptions debuggingOptions);

  /// Start the test file with the provided [spec] and current environment,
  /// returning the test process exit code.
  ///
  /// If [DriveTestSpecification.profileMemory] is provided, it will be treated
  /// as a file path to write a devtools memory profile.
  Future<int> startTest(String testFile, DriveTestSpecification spec);

  /// Stop the running application and uninstall it from the device.
  Future<void> stop({String? userIdentifier});
}

/// An implementation of the driver service that connects to mobile and desktop
/// applications.
class FlutterDriverService extends DriverService {
  FlutterDriverService({
    required this._applicationPackageFactory,
    required this._dartSdkPath,
    required this._devtoolsLauncher,
    required this._logger,
    required this._platform,
    required this._processUtils,
    @visibleForTesting this._logFlushDelay = const Duration(milliseconds: 500),
    @visibleForTesting this._vmServiceConnector = connectToVmService,
  });

  static const _kLaunchAttempts = 3;

  final ApplicationPackageFactory _applicationPackageFactory;
  final Logger _logger;
  final Platform _platform;
  final ProcessUtils _processUtils;
  final String _dartSdkPath;
  final VMServiceConnector _vmServiceConnector;
  final DevtoolsLauncher _devtoolsLauncher;
  final Duration _logFlushDelay;

  Device? _device;
  ApplicationPackage? _applicationPackage;
  late String _vmServiceUri;
  late FlutterVmService _vmService;

  @override
  Future<void> start(
    BuildInfo buildInfo,
    Device device,
    DebuggingOptions debuggingOptions, {
    File? applicationBinary,
    String? route,
    String? userIdentifier,
    Map<String, Object> platformArgs = const <String, Object>{},
    String? mainPath,
    Map<String, String> webDefines = const <String, String>{},
  }) async {
    if (buildInfo.isRelease) {
      throwToolExit(
        'Flutter Driver (non-web) does not support running in release mode.\n'
        '\n'
        'Use --profile mode for testing application performance.\n'
        'Use --debug (default) mode for testing correctness (with assertions).',
      );
    }
    _device = device;
    final TargetPlatform targetPlatform = await device.targetPlatform;
    _applicationPackage = await _applicationPackageFactory.getPackageForPlatform(
      targetPlatform,
      buildInfo: buildInfo,
      applicationBinary: applicationBinary,
    );
    var attempt = 0;
    LaunchResult? result;
    var prebuiltApplication = applicationBinary != null;
    while (attempt < _kLaunchAttempts) {
      result = await device.startApp(
        _applicationPackage,
        mainPath: mainPath,
        route: route,
        debuggingOptions: debuggingOptions,
        platformArgs: platformArgs,
        userIdentifier: userIdentifier,
        prebuiltApplication: prebuiltApplication,
      );
      if (result.started) {
        break;
      }
      // On attempts past 1, assume the application is built correctly and re-use it.
      attempt += 1;
      prebuiltApplication = true;
      _logger.printError('Application failed to start on attempt: $attempt');
    }
    if (result == null || !result.started) {
      throwToolExit('Application failed to start. Will not run test. Quitting.', exitCode: 1);
    }
    return reuseApplication(result.vmServiceUri!, device, debuggingOptions);
  }

  @override
  Future<void> reuseApplication(
    Uri vmServiceUri,
    Device device,
    DebuggingOptions debuggingOptions,
  ) async {
    Uri uri;
    if (vmServiceUri.scheme == 'ws') {
      final List<String> segments = vmServiceUri.pathSegments.toList();
      segments.remove('ws');
      uri = vmServiceUri.replace(scheme: 'http', path: segments.join('/'));
    } else {
      uri = vmServiceUri;
    }
    _vmServiceUri = uri.toString();
    _device = device;

    final DeviceLogReader logReader = await device.getLogReader(app: _applicationPackage);
    logReader.logLines.listen(_logger.printStatus);

    try {
      if (debuggingOptions.enableDds) {
        try {
          await device.dds.startDartDevelopmentServiceFromDebuggingOptions(
            uri,
            appName:
                'Kind: Flutter - Device: ${device.displayName} - '
                'Package: ${_applicationPackage?.name}',
            debuggingOptions: debuggingOptions,
          );
          _vmServiceUri = device.dds.uri.toString();
        } on DartDevelopmentServiceException {
          // If there's another flutter_tools instance still connected to the target
          // application, DDS will already be running remotely and this call will fail.
          // This can be ignored to continue to use the existing remote DDS instance.
        }
      }
      _vmService = await _vmServiceConnector(uri, device: _device, logger: _logger);
      await logReader.provideVmService(_vmService);
    } catch (error) {
      // Allow time for buffered/async log messages (e.g. engine crash logs) to arrive and flush.
      await Future<void>.delayed(_logFlushDelay);
      rethrow;
    }
  }

  @override
  Future<int> startTest(String testFile, DriveTestSpecification spec) async {
    final String? profileMemory = spec.profileMemory;
    if (profileMemory != null) {
      unawaited(
        _devtoolsLauncher.launch(
          Uri.parse(_vmServiceUri),
          additionalArguments: <String>['--record-memory-profile=$profileMemory'],
        ),
      );
      // When profiling memory the original launch future will never complete.
      await _devtoolsLauncher.processStart;
    }
    try {
      final int result = await _processUtils.stream(
        <String>[_dartSdkPath, ...spec.arguments, testFile],
        environment: <String, String>{..._platform.environment, 'VM_SERVICE_URL': _vmServiceUri},
      );
      return result;
    } finally {
      if (profileMemory != null) {
        await _devtoolsLauncher.close();
      }
    }
  }

  @override
  Future<void> stop({String? userIdentifier}) async {
    // If the application package is available, stop and uninstall.
    final ApplicationPackage? package = _applicationPackage;
    if (package != null) {
      if (!await _device!.stopApp(package, userIdentifier: userIdentifier)) {
        _logger.printError('Failed to stop app');
      }
      if (!await _device!.uninstallApp(package, userIdentifier: userIdentifier)) {
        _logger.printError('Failed to uninstall app');
      }
    } else if (_device!.supportsFlutterExit) {
      // Otherwise use the VM Service URI to stop the app as a best effort approach.
      final vm_service.VM vm = await _vmService.service.getVM();
      final vm_service.IsolateRef isolateRef = vm.isolates!.firstWhere((
        vm_service.IsolateRef element,
      ) {
        return !element.isSystemIsolate!;
      });
      unawaited(_vmService.flutterExit(isolateId: isolateRef.id!));
    } else {
      _logger.printTrace('No application package for $_device, leaving app running');
    }
    await _device!.dispose();
  }
}
