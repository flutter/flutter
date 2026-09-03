// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:process/process.dart';

import '../application_package.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../convert.dart';
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
    required super.processManager,
    required super.logger,
    required super.fileSystem,
    required super.operatingSystemUtils,
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
  String? executablePathForDevice(covariant MacOSApp package, BuildInfo buildInfo) {
    return package.executable(buildInfo);
  }

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
    required DebuggingOptions debuggingOptions,
    String? mainPath,
    Map<String, dynamic> platformArgs = const <String, dynamic>{},
    bool prebuiltApplication = false,
    String? route,
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
        debuggingOptions: debuggingOptions,
        mainPath: mainPath,
        platformArgs: platformArgs,
        prebuiltApplication: prebuiltApplication,
        route: route,
        userIdentifier: userIdentifier,
      );
    }

    // Under macOS Transparency, Consent, and Control (TCC), running an application
    // binary directly from an IDE or terminal process attributes permission requests
    // (e.g. Camera, Microphone, Contacts) to the parent IDE/terminal process rather
    // than the app bundle itself. This often leads to silent permission denials or crashes.
    // Launching via `open -n -a <bundle> --args <args>` runs the application within its proper
    // bundle context, ensuring correct TCC attribution and preventing reusing existing instances.
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
      '-n',
      '-a',
      bundlePath,
      if (args.isNotEmpty) ...<String>['--args', ...args],
    ];

    Uri? vmServiceUri;
    try {
      _logger.printTrace('Launching: ${openCommand.join(' ')}');
      final ProcessResult result = await _processManager.run(openCommand);
      if (result.exitCode != 0) {
        _logger.printError('Failed to launch app via open: ${result.stderr}');
        return LaunchResult.failed();
      }

      final stopwatch = Stopwatch()..start();
      final timeout = (await globals.isRunningOnBot)
          ? const Duration(minutes: 5)
          : const Duration(seconds: 30);

      _logger.printTrace('Waiting for VM Service info file at ${vmServiceInfoFile.path}');
      while (stopwatch.elapsed < timeout) {
        if (_readVmServiceUri(vmServiceInfoFile) case final Uri uri) {
          vmServiceUri = uri;
          break;
        }

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Check if the application exited or crashed prematurely before writing the VM Service URI.
        final ProcessResult pgrepResult = await _processManager.run(<String>[
          'pgrep',
          '-f',
          RegExp.escape(executable),
        ]);
        if (pgrepResult.exitCode != 0) {
          // App is no longer running. Check one last time if the file was written before exiting.
          if (_readVmServiceUri(vmServiceInfoFile) case final Uri uri) {
            vmServiceUri = uri;
            break;
          }
          _logger.printError('Application exited before VM Service connected.');
          break;
        }
      }
    } finally {
      try {
        vmServiceInfoFile.parent.deleteSync(recursive: true);
      } on Exception catch (e) {
        _logger.printTrace('Failed to delete temp directory: $e');
      }
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

  Uri? _readVmServiceUri(File file) {
    if (file.existsSync()) {
      try {
        final String content = file.readAsStringSync();
        if (content.isNotEmpty) {
          if (jsonDecode(content) case {'uri': final String uriStr}) {
            return Uri.tryParse(uriStr);
          }
        }
      } on Exception catch (e) {
        _logger.printTrace('Error reading VM Service info file: $e. Retrying...');
      }
    }
    return null;
  }

  @override
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier}) async {
    if (app is! MacOSApp) {
      return false;
    }
    final MacOSApp macosApp = app;

    // Stop any app process tracked by DesktopDevice.
    final bool superStopped = await super.stopApp(app, userIdentifier: userIdentifier);

    // Find the executable for the application across build modes.
    String? executable;
    for (final BuildMode mode in BuildMode.values) {
      final buildInfo = BuildInfo(
        mode,
        null,
        packageConfigPath: '.dart_tool/package_config.json',
        treeShakeIcons: false,
      );
      if (macosApp.executable(buildInfo) case final String path
          when _fileSystem.file(path).existsSync()) {
        executable = path;
        break;
      }
    }

    if (executable == null) {
      _logger.printTrace('Could not find executable path for ${app.name} to stop.');
      return superStopped;
    }

    // Because debug and profile applications are launched via `open`, we do not
    // have a persistent `Process` instance to kill directly. Use `pkill` to terminate
    // matching application processes.
    final ProcessResult result = await _processManager.run(<String>[
      'pkill',
      '-f',
      RegExp.escape(executable),
    ]);
    // pkill returns 0 on success (processes matched and killed) or 1 if no matching processes were found.
    return result.exitCode == 0 || result.exitCode == 1;
  }

  @override
  void onAttached(covariant MacOSApp package, BuildInfo buildInfo, Process process) {
    // Bring app to foreground. Ideally this would be done post-launch rather
    // than post-attach, since this won't run for release builds, but there's
    // no general-purpose way of knowing when a process is far enough along in
    // the launch process for 'open' to foreground it.
    final String? applicationBundle = package.applicationBundle(buildInfo);
    if (applicationBundle == null) {
      _logger.printError('Failed to foreground app; application bundle not found');
      return;
    }
    _processManager.run(<String>['open', applicationBundle]).then((ProcessResult result) {
      if (result.exitCode != 0) {
        _logger.printError('Failed to foreground app; open returned ${result.exitCode}');
      }
    });
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
