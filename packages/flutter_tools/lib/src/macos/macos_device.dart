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
import '../ios/plist_parser.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_macos.dart';
import 'macos_workflow.dart';

/// A device that represents a desktop MacOS target.
class MacOSDevice extends DesktopDevice {
  MacOSDevice({
    required super.fileSystem,
    required super.logger,
    required super.operatingSystemUtils,
    required super.processManager,
  }) : _processManager = processManager,
       _logger = logger,
       _fileSystem = fileSystem,
       _operatingSystemUtils = operatingSystemUtils,
       super('macos', platformType: PlatformType.macos, ephemeral: false);

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
  String? executablePathForDevice(ApplicationPackage package, BuildInfo buildInfo) =>
      switch (package) {
        final MacOSApp macosApp => macosApp.executable(buildInfo),
        _ => null,
      };

  /// Converts engine switches from environment variables into CLI arguments.
  ///
  /// When launching via the macOS `open` command, environment variables cannot be
  /// passed directly to the subprocess in the same manner as `ProcessManager.start`.
  /// Instead, engine switches (like `--enable-dart-profiling`) must be passed as
  /// command-line arguments following the `--args` flag.
  List<String> _computeArgs(DebuggingOptions debuggingOptions, bool traceStartup, String? route) {
    final Map<String, String> env = computeEnvironment(debuggingOptions, traceStartup, route);
    final args = <String>[];

    if (env['FLUTTER_ENGINE_SWITCHES'] case final String countStr) {
      final int count = int.tryParse(countStr) ?? 0;
      for (var i = 1; i <= count; i++) {
        if (env['FLUTTER_ENGINE_SWITCH_$i'] case final String value) {
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

    // In release mode, the VM Service is disabled and cannot be discovered via
    // `--write-service-info`. Fall back to direct binary execution to preserve
    // stdout/stderr log streaming.
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

    // Under macOS Transparency, Consent, and Control (TCC), running an application
    // binary directly from an IDE or terminal process attributes permission requests
    // (e.g. Camera, Microphone, Contacts) to the parent IDE/terminal process rather
    // than the app bundle itself. This often leads to silent permission denials or crashes.
    // Launching via `open -a <bundle> --args <args>` runs the application within its proper
    // bundle context, ensuring correct TCC attribution.
    //
    // Under macOS App Sandbox, sandboxed applications are forbidden by kernel sandbox policy
    // from writing outside their sandbox container directory (`~/Library/Containers/<bundleId>/Data/tmp/`)
    // unless granted specific user-selected file entitlements.
    //
    // Attempting to write `--write-service-info` to the system temporary directory (e.g. `/tmp` or
    // `/Volumes/Work/...`) is blocked by `sandboxd`, preventing the Dart VM from creating `vm_service_info.json`.
    //
    // To ensure the VM can write the connection file, resolve the application's bundle identifier
    // from `Info.plist` and create the temporary file inside the application's sandbox container:
    // `~/Library/Containers/<bundleId>/Data/tmp/`
    // If the bundle identifier cannot be resolved or container directory creation fails, fall back to
    // `_fileSystem.systemTempDirectory`.
    Directory tempDirectory = _fileSystem.systemTempDirectory;
    final String plistPath = _fileSystem.path.join(bundlePath, 'Contents', 'Info.plist');
    if (_fileSystem.file(plistPath).existsSync()) {
      try {
        final String? bundleId = globals.plistParser.getValueFromFile<String>(
          plistPath,
          PlistParser.kCFBundleIdentifierKey,
        );
        final String? homeDirPath = globals.fsUtils.homeDirPath;
        if (bundleId != null && bundleId.isNotEmpty && homeDirPath != null) {
          final Directory containerTmpDir = _fileSystem.directory(
            _fileSystem.path.join(homeDirPath, 'Library', 'Containers', bundleId, 'Data', 'tmp'),
          );
          containerTmpDir.createSync(recursive: true);
          tempDirectory = containerTmpDir;
        }
      } on Exception catch (e) {
        _logger.printTrace('Could not resolve or create sandbox container tmp directory: $e');
      }
    }

    final File vmServiceInfoFile = tempDirectory
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
            if (jsonDecode(content) case {'uri': final String uriStr}) {
              vmServiceUri = Uri.parse(uriStr);
              break;
            }
          }
        } on Exception catch (e) {
          _logger.printTrace('Error reading VM Service info file: $e. Retrying...');
        }
      }

      // Check if the application exited or crashed prematurely before writing the VM Service URI.
      final ProcessResult pgrepResult = await _processManager.run(<String>[
        'pgrep',
        '-f',
        executable,
      ]);
      if (pgrepResult.exitCode != 0) {
        // App is no longer running. Check one last time if the file was written before exiting.
        if (vmServiceInfoFile.existsSync()) {
          try {
            final String content = vmServiceInfoFile.readAsStringSync();
            if (content.isNotEmpty) {
              if (jsonDecode(content) case {'uri': final String uriStr}) {
                vmServiceUri = Uri.parse(uriStr);
                break;
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
    final MacOSApp macosApp = app;

    // Find the executable for the application across build modes.
    String? executable;
    for (final BuildMode mode in BuildMode.values) {
      final buildInfo = BuildInfo(
        mode,
        null,
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      if (macosApp.executable(buildInfo) case final String path
          when _fileSystem.file(path).existsSync()) {
        executable = path;
        break;
      }
    }

    if (executable == null) {
      _logger.printTrace('Could not find executable path for ${app.name} to stop.');
      return false;
    }

    // Because debug and profile applications are launched via `open`, we do not
    // have a persistent `Process` instance to kill directly. Use `pkill` to terminate
    // matching application processes.
    final ProcessResult result = await _processManager.run(<String>['pkill', '-f', executable]);
    return result.exitCode == 0;
  }
}

class MacOSDevices extends PollingDeviceDiscovery {
  MacOSDevices({
    required FileSystem fileSystem,
    required Logger logger,
    required MacOSWorkflow macOSWorkflow,
    required OperatingSystemUtils operatingSystemUtils,
    required Platform platform,
    required ProcessManager processManager,
  }) : _fileSystem = fileSystem,
       _logger = logger,
       _macOSWorkflow = macOSWorkflow,
       _operatingSystemUtils = operatingSystemUtils,
       _platform = platform,
       _processManager = processManager,
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
        fileSystem: _fileSystem,
        logger: _logger,
        operatingSystemUtils: _operatingSystemUtils,
        processManager: _processManager,
      ),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['macos'];
}
