// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:dds/dds.dart' as dds;
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config_types.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../application_package.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../device.dart';
import '../sksl_writer.dart';
import '../vmservice.dart';
import 'web_driver_service.dart';

class FlutterDriverFactory {
  FlutterDriverFactory({
    @required ApplicationPackageFactory applicationPackageFactory,
    @required Logger logger,
    @required ProcessUtils processUtils,
    @required String dartSdkPath,
  }) : _applicationPackageFactory = applicationPackageFactory,
       _logger = logger,
       _processUtils = processUtils,
       _dartSdkPath = dartSdkPath;

  final ApplicationPackageFactory _applicationPackageFactory;
  final Logger _logger;
  final ProcessUtils _processUtils;
  final String _dartSdkPath;

  /// Create a driver service for running `flutter drive`.
  DriverService createDriverService(bool web) {
    if (web) {
      return WebDriverService(
        processUtils: _processUtils,
        dartSdkPath: _dartSdkPath,
      );
    }
    return FlutterDriverService(
      logger: _logger,
      processUtils: _processUtils,
      dartSdkPath: _dartSdkPath,
      applicationPackageFactory: _applicationPackageFactory,
    );
  }
}

/// An interface for the `flutter driver` integration test operations.
abstract class DriverService {
  /// Install and launch the application for the provided [device].
  Future<void> start(
    BuildInfo buildInfo,
    Device device,
    DebuggingOptions debuggingOptions,
    bool ipv6, {
    File applicationBinary,
    String route,
    String userIdentifier,
    String mainPath,
    Map<String, Object> platformArgs = const <String, Object>{},
  });

  /// If --use-existing-app is provided, configured the correct VM Service URI.
  Future<void> reuseApplication(
    Uri vmServiceUri,
    Device device,
    DebuggingOptions debuggingOptions,
    bool ipv6,
  );

  /// Start the test file with the provided [arguments] and [environment], returning
  /// the test process exit code.
  Future<int> startTest(
    String testFile,
    List<String> arguments,
    Map<String, String> environment,
    PackageConfig packageConfig, {
    bool headless,
    String chromeBinary,
    String browserName,
    bool androidEmulator,
    int driverPort,
    List<String> browserDimension,
  });

  /// Stop the running application and uninstall it from the device.
  ///
  /// If [writeSkslOnExit] is non-null, will connect to the VM Service
  /// and write SkSL to the file. This is only supported on mobile and
  /// desktop devices.
  Future<void> stop({
    File writeSkslOnExit,
    String userIdentifier,
  });
}

/// An implementation of the driver service that connects to mobile and desktop
/// applications.
class FlutterDriverService extends DriverService {
  FlutterDriverService({
    @required ApplicationPackageFactory applicationPackageFactory,
    @required Logger logger,
    @required ProcessUtils processUtils,
    @required String dartSdkPath,
    @visibleForTesting VMServiceConnector vmServiceConnector = connectToVmService,
  }) : _applicationPackageFactory = applicationPackageFactory,
       _logger = logger,
       _processUtils = processUtils,
       _dartSdkPath = dartSdkPath,
       _vmServiceConnector = vmServiceConnector;

  static const int _kLaunchAttempts = 3;

  final ApplicationPackageFactory _applicationPackageFactory;
  final Logger _logger;
  final ProcessUtils _processUtils;
  final String _dartSdkPath;
  final VMServiceConnector _vmServiceConnector;

  Device _device;
  ApplicationPackage _applicationPackage;
  String _vmServiceUri;
  FlutterVmService _vmService;

  @override
  Future<void> start(
    BuildInfo buildInfo,
    Device device,
    DebuggingOptions debuggingOptions,
    bool ipv6, {
    File applicationBinary,
    String route,
    String userIdentifier,
    Map<String, Object> platformArgs = const <String, Object>{},
    String mainPath,
  }) async {
    if (buildInfo.isRelease) {
      throwToolExit(
        'Flutter Driver (non-web) does not support running in release mode.\n'
        '\n'
        'Use --profile mode for testing application performance.\n'
        'Use --debug (default) mode for testing correctness (with assertions).'
      );
    }
    _device = device;
    final TargetPlatform targetPlatform = await device.targetPlatform;
    _applicationPackage = await _applicationPackageFactory.getPackageForPlatform(
      targetPlatform,
      buildInfo: buildInfo,
      applicationBinary: applicationBinary,
    );
    int attempt = 0;
    LaunchResult result;
    bool prebuiltApplication = applicationBinary != null;
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
      if (result != null && result.started) {
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
    return reuseApplication(
      result.observatoryUri,
      device,
      debuggingOptions,
      ipv6,
    );
  }

  @override
  Future<void> reuseApplication(
    Uri vmServiceUri,
    Device device,
    DebuggingOptions debuggingOptions,
    bool ipv6,
  ) async {
    Uri uri;
    if (vmServiceUri.scheme == 'ws') {
      uri = vmServiceUri.replace(scheme: 'http', path: vmServiceUri.path.replaceFirst('ws/', ''));
    } else {
      uri = vmServiceUri;
    }
    _vmServiceUri = uri.toString();
    _device = device;
    try {
      await device.dds.startDartDevelopmentService(
        uri,
        debuggingOptions.ddsPort,
        ipv6,
        debuggingOptions.disableServiceAuthCodes,
        logger: _logger,
      );
      _vmServiceUri = device.dds.uri.toString();
    } on dds.DartDevelopmentServiceException {
      // If there's another flutter_tools instance still connected to the target
      // application, DDS will already be running remotely and this call will fail.
      // This can be ignored to continue to use the existing remote DDS instance.
    }
    _vmService = await _vmServiceConnector(uri, device: _device);
    final DeviceLogReader logReader = await device.getLogReader(app: _applicationPackage);
    logReader.logLines.listen(_logger.printStatus);

    final vm_service.VM vm = await _vmService.service.getVM();
    logReader.appPid = vm.pid;
  }

  @override
  Future<int> startTest(
    String testFile,
    List<String> arguments,
    Map<String, String> environment,
    PackageConfig packageConfig, {
    bool headless,
    String chromeBinary,
    String browserName,
    bool androidEmulator,
    int driverPort,
    List<String> browserDimension,
  }) async {
    return _processUtils.stream(<String>[
      _dartSdkPath,
      ...<String>[...arguments, testFile, '-rexpanded'],
    ], environment: <String, String>{
      'VM_SERVICE_URL': _vmServiceUri,
      ...environment,
    });
  }

  @override
  Future<void> stop({
    File writeSkslOnExit,
    String userIdentifier,
  }) async {
    if (writeSkslOnExit != null) {
      final FlutterView flutterView = (await _vmService.getFlutterViews()).first;
      final Map<String, Object> result = await _vmService.getSkSLs(
        viewId: flutterView.id
      );
      await sharedSkSlWriter(_device, result, outputFile: writeSkslOnExit, logger: _logger);
    }
    // If the application package is available, stop and uninstall.
    if (_applicationPackage != null) {
      if (!await _device.stopApp(_applicationPackage, userIdentifier: userIdentifier)) {
        _logger.printError('Failed to stop app');
      }
      if (!await _device.uninstallApp(_applicationPackage, userIdentifier: userIdentifier)) {
        _logger.printError('Failed to uninstall app');
      }
    } else if (_device.supportsFlutterExit) {
      // Otherwise use the VM Service URI to stop the app as a best effort approach.
      final vm_service.VM vm = await _vmService.service.getVM();
      final vm_service.IsolateRef isolateRef = vm.isolates
        .firstWhere((vm_service.IsolateRef element) {
          return !element.isSystemIsolate;
        }, orElse: () => null);
      unawaited(_vmService.flutterExit(isolateId: isolateRef.id));
    } else {
      _logger.printTrace('No application package for $_device, leaving app running');
    }
    await _device.dispose();
  }
}
