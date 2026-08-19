// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';

import 'package:process/process.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../project.dart';
import 'application_package.dart';
import 'build_macos.dart';
import 'macos_workflow.dart';

/// A device that represents a desktop MacOS target.
class MacOSDevice extends DesktopDevice {
  MacOSDevice({
    required ProcessManager processManager,
    required Logger logger,
    required FileSystem fileSystem,
    required OperatingSystemUtils operatingSystemUtils,
  }) : _processManager = processManager,
       _logger = logger,
       _fileSystem = fileSystem,
       _operatingSystemUtils = operatingSystemUtils,
       super(
         'macos',
         platformType: PlatformType.macos,
         ephemeral: false,
         processManager: processManager,
         logger: logger,
         fileSystem: fileSystem,
         operatingSystemUtils: operatingSystemUtils,
       );

  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;
  final OperatingSystemUtils _operatingSystemUtils;

  @override
  Future<bool> isSupported() async => true;

  @override
  String get name => 'macOS';

  @override
  bool get supportsFlavors => true;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.darwin;

  @override
  Future<CpuArch> get cpuArch async => CpuArch.fromHostPlatform(_operatingSystemUtils.hostPlatform);

  @override
  Future<String> get targetPlatformDisplayName async {
    if (_operatingSystemUtils.hostPlatform == HostPlatform.darwin_arm64) {
      return 'darwin-arm64';
    }
    return 'darwin-x64';
  }

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.macos.existsSync();
  }

  @override
  Future<void> buildForDevice({
    required BuildInfo buildInfo,
    String? mainPath,
    bool usingCISystem = false,
  }) async {
    await buildMacOS(
      flutterProject: FlutterProject.current(),
      buildInfo: buildInfo,
      targetOverride: mainPath,
      verboseLogging: _logger.isVerbose,
      usingCISystem: usingCISystem,
    );
  }

  @override
  String? executablePathForDevice(ApplicationPackage package, BuildInfo buildInfo) {
    if (package is! MacOSApp) {
      return null;
    }
    return package.executable(buildInfo);
  }

  List<String> _computeArgs(DebuggingOptions debuggingOptions, bool traceStartup, String? route) {
    final Map<String, String> env = computeEnvironment(debuggingOptions, traceStartup, route);
    final args = <String>[];

    final String? countStr = env['FLUTTER_ENGINE_SWITCHES'];
    if (countStr != null) {
      final int count = int.tryParse(countStr) ?? 0;
      for (var i = 1; i <= count; i++) {
        final String? value = env['FLUTTER_ENGINE_SWITCH_$i'];
        if (value != null) {
          args.add('--$value');
        }
      }
    }
    return args;
  }

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs = const <String, dynamic>{},
    bool prebuiltApplication = false,
    String? userIdentifier,
  }) async {
    if (package is! MacOSApp) {
      _logger.printError('Expected MacOSApp package, got ${package.runtimeType}');
      return LaunchResult.failed();
    }
    final MacOSApp macosPackage = package;
    if (!prebuiltApplication) {
      await buildForDevice(
        buildInfo: debuggingOptions.buildInfo,
        mainPath: mainPath,
        usingCISystem: debuggingOptions.usingCISystem,
      );
    }

    final BuildInfo buildInfo = debuggingOptions.buildInfo;
    final String? bundlePath = macosPackage.applicationBundle(buildInfo);
    if (bundlePath == null) {
      _logger.printError('Unable to find application bundle');
      return LaunchResult.failed();
    }

    final String? executable = macosPackage.executable(buildInfo);
    if (executable == null) {
      _logger.printError('Unable to find executable to run');
      return LaunchResult.failed();
    }

    if (buildInfo.isRelease) {
      return super.startApp(
        package,
        mainPath: mainPath,
        route: route,
        debuggingOptions: debuggingOptions,
        platformArgs: platformArgs,
        prebuiltApplication: prebuiltApplication,
        userIdentifier: userIdentifier,
      );
    }

    final File vmServiceInfoFile = _fileSystem.systemTempDirectory
        .createTempSync('flutter_tools_macos_device.')
        .childFile('vm_service_info.json');

    final List<String> args = _computeArgs(
      debuggingOptions,
      platformArgs['trace-startup'] as bool? ?? false,
      route,
    );
    args.add('--write-service-info=${vmServiceInfoFile.path}');
    if (debuggingOptions.dartEntrypointArgs.isNotEmpty) {
      args.addAll(debuggingOptions.dartEntrypointArgs);
    }

    final openCommand = <String>[
      'open',
      '-a',
      bundlePath,
      if (args.isNotEmpty) ...<String>['--args', ...args],
    ];

    _logger.printTrace('Launching: ${openCommand.join(' ')}');
    final ProcessResult result = await _processManager.run(openCommand);
    if (result.exitCode != 0) {
      _logger.printError('Failed to launch app via open: ${result.stderr}');
      try {
        vmServiceInfoFile.parent.deleteSync(recursive: true);
      } on Exception catch (_) {}
      return LaunchResult.failed();
    }

    Uri? vmServiceUri;
    final DateTime start = clock.now();
    final timeout = (await globals.isRunningOnBot)
        ? const Duration(minutes: 5)
        : const Duration(seconds: 30);

    _logger.printTrace('Waiting for VM Service info file at ${vmServiceInfoFile.path}');
    while (clock.now().difference(start) < timeout) {
      if (vmServiceInfoFile.existsSync()) {
        try {
          final String content = vmServiceInfoFile.readAsStringSync();
          if (content.isNotEmpty) {
            final Object? decoded = jsonDecode(content);
            if (decoded is Map<String, dynamic>) {
              final uriStr = decoded['uri'] as String?;
              if (uriStr != null) {
                vmServiceUri = Uri.parse(uriStr);
                break;
              }
            }
          }
        } on Exception catch (e) {
          _logger.printTrace('Error reading VM Service info file: $e. Retrying...');
        }
      }

      final ProcessResult pgrepResult = await _processManager.run(<String>[
        'pgrep',
        '-f',
        executable,
      ]);
      if (pgrepResult.exitCode != 0) {
        if (vmServiceInfoFile.existsSync()) {
          try {
            final String content = vmServiceInfoFile.readAsStringSync();
            if (content.isNotEmpty) {
              final Object? decoded = jsonDecode(content);
              if (decoded is Map<String, dynamic>) {
                final uriStr = decoded['uri'] as String?;
                if (uriStr != null) {
                  vmServiceUri = Uri.parse(uriStr);
                  break;
                }
              }
            }
          } on Exception catch (_) {}
        }
        _logger.printError('Application exited before VM Service connected.');
        break;
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    try {
      vmServiceInfoFile.parent.deleteSync(recursive: true);
    } on Exception catch (e) {
      _logger.printTrace('Failed to delete temp directory: $e');
    }

    if (vmServiceUri == null) {
      if (await globals.isRunningOnBot) {
        final sandboxingMessage = debuggingOptions.usingCISystem
            ? 'Ensure sandboxing is disabled by checking the set CODE_SIGN_ENTITLEMENTS.'
            : 'Consider codesigning your app or disabling sandboxing. Flutter will attempt to disable sandboxing if the `--ci` flag is provided.';
        _logger.printError(
          'The Dart VM Service was not discovered after 5 minutes. '
          'If the app has sandboxing enabled and is not codesigned or codesigning changed, '
          'this may be caused by a system prompt asking for access. $sandboxingMessage\n'
          'See https://developer.apple.com/documentation/security/app_sandbox/accessing_files_from_the_macos_app_sandbox '
          'for more information.',
        );
      }
      _logger.printError('Failed to connect to VM Service. Timeout or app crashed.');
      return LaunchResult.failed();
    }

    return LaunchResult.succeeded(vmServiceUri: vmServiceUri);
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    if (app is! MacOSApp) {
      return false;
    }

    String? executable;
    for (final BuildMode mode in BuildMode.values) {
      final buildInfo = BuildInfo(
        mode,
        null,
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      final String? path = app.executable(buildInfo);
      if (path != null && _fileSystem.file(path).existsSync()) {
        executable = path;
        break;
      }
    }

    if (executable == null) {
      _logger.printTrace('Could not find executable path for ${app.name} to stop.');
      return false;
    }

    final ProcessResult result = await _processManager.run(<String>['pkill', '-f', executable]);
    return result.exitCode == 0;
  }
}

class MacOSDevices extends PollingDeviceDiscovery {
  MacOSDevices({
    required Platform platform,
    required MacOSWorkflow macOSWorkflow,
    required ProcessManager processManager,
    required Logger logger,
    required FileSystem fileSystem,
    required OperatingSystemUtils operatingSystemUtils,
  }) : _logger = logger,
       _platform = platform,
       _macOSWorkflow = macOSWorkflow,
       _processManager = processManager,
       _fileSystem = fileSystem,
       _operatingSystemUtils = operatingSystemUtils,
       super('macOS devices');

  final MacOSWorkflow _macOSWorkflow;
  final Platform _platform;
  final ProcessManager _processManager;
  final Logger _logger;
  final FileSystem _fileSystem;
  final OperatingSystemUtils _operatingSystemUtils;

  @override
  bool get supportsPlatform => _platform.isMacOS;

  @override
  bool get canListAnything => _macOSWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices({
    Duration? timeout,
    bool forWirelessDiscovery = false,
  }) async {
    if (!canListAnything) {
      return const <Device>[];
    }
    return <Device>[
      MacOSDevice(
        processManager: _processManager,
        logger: _logger,
        fileSystem: _fileSystem,
        operatingSystemUtils: _operatingSystemUtils,
      ),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['macos'];
}
