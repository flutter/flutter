// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
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
       _operatingSystemUtils = operatingSystemUtils,
       super('macos', platformType: PlatformType.macos, ephemeral: false);

  final ProcessManager _processManager;
  final Logger _logger;
  final OperatingSystemUtils _operatingSystemUtils;

  /// The [MacOSLogReader] instance used by this device.
  late final MacOSLogReader macosLogReader = MacOSLogReader(logger: _logger);

  @override
  DesktopLogReader createLogReader() => macosLogReader;

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
    macosLogReader.bundlePath = null;
    if (package is MacOSApp) {
      macosLogReader.bundlePath = package.applicationBundle(debuggingOptions.buildInfo);
    }
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

/// A [DesktopLogReader] for macOS devices that inspects stderr for
/// platform-specific crash signatures such as TCC privacy violations.
class MacOSLogReader extends DesktopLogReader {
  MacOSLogReader({required this.logger});

  final Logger logger;

  /// The path to the application bundle, if known.
  String? bundlePath;

  bool _detectedPrivacyCrash = false;

  /// The message printed to stderr by macOS when an application crashes due to a
  /// missing privacy usage description in its Info.plist.
  @visibleForTesting
  static const String kMacOSPrivacyCrashPattern =
      'This app has crashed because it attempted to access privacy-sensitive '
      'data without a usage description';

  /// A pattern matching the missing usage description key name in the macOS crash log.
  @visibleForTesting
  static final RegExp privacyKeyPattern = RegExp(
    r'must (?:supply|contain) an?\s+([A-Za-z0-9_]+)\s+key',
  );

  @override
  void listenToProcessOutput(Process process) {
    _detectedPrivacyCrash = false;
    super.listenToProcessOutput(process);
  }

  @override
  @visibleForTesting
  void handleStderrLine(String line) {
    if (_detectedPrivacyCrash) {
      return;
    }
    checkPrivacyCrash(line);
  }

  /// Checks if [line] contains the macOS privacy crash signature and, if so,
  /// prints an actionable diagnostic message.
  @visibleForTesting
  bool checkPrivacyCrash(String line) {
    if (!line.contains(kMacOSPrivacyCrashPattern)) {
      return false;
    }
    _detectedPrivacyCrash = true;
    _printPrivacyDiagnostic(line);
    return true;
  }

  void _printPrivacyDiagnostic(String line) {
    final RegExpMatch? match = privacyKeyPattern.firstMatch(line);
    final String? key = match?.group(1);
    final keyNotice = key != null ? ' (requiring $key)' : '';
    final keyDetail = key != null
        ? 'Even if $key is already present in macos/Runner/Info.plist, '
        : 'Even if the usage description key is already present in '
              'macos/Runner/Info.plist, ';
    final runCommand = bundlePath != null ? 'open "$bundlePath"' : 'open <path-to-app-bundle>';

    logger.printError('''

════════════════════════════════════════════════════════════════════════════════
macOS Privacy Permission Crash Detected
════════════════════════════════════════════════════════════════════════════════
The application crashed while requesting access to privacy-sensitive data$keyNotice.

When launched from an IDE (such as VS Code or Android Studio) or terminal via
"flutter run", macOS Transparency, Consent, and Control (TCC) attributes
permission requests to the parent IDE or terminal process rather than the
application bundle.

${keyDetail}macOS terminates the process if the parent process lacks the usage
description.

Workaround:
1. Open the application bundle directly once from Terminal or Finder:
   $runCommand
   (or run the project directly from Xcode)
2. Accept the permission prompt when shown.
3. Once granted for your bundle identifier, subsequent "flutter run" sessions
   from your IDE will work.

See https://github.com/flutter/flutter/issues/70374 for more details.
════════════════════════════════════════════════════════════════════════════════
''');
  }
}
