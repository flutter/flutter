// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/template.dart';
import '../build_info.dart';
import '../context/apple_context.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../desktop_device.dart';
import '../device.dart';
import '../features.dart';
import '../project.dart';
import 'application_package.dart';
import 'build_macos.dart';
import 'macos_workflow.dart';

/// A device that represents a desktop MacOS target.
class MacOSDevice extends DesktopDevice {
  MacOSDevice({
    required this._analytics,
    required this._appleContext,
    required this._featureFlags,
    required this._templateRenderer,
    required super.toolContext,
  }) : super('macos', platformType: PlatformType.macos, ephemeral: false);

  /// The process exit code when terminated by `SIGABRT` (`-SIGABRT`).
  @visibleForTesting
  static const int kSigabrtExitCode = -6;

  /// The message logged by macOS when an application crashes due to a
  /// missing privacy usage description in its `Info.plist`.
  @visibleForTesting
  static const String kMacOSPrivacyCrashPattern =
      'This app has crashed because it attempted to access privacy-sensitive '
      'data without a usage description';

  /// A pattern matching the missing usage description key name in the macOS crash log.
  static final RegExp _privacyKeyPattern = RegExp(
    r'must (?:supply|contain) an?\s+([A-Za-z0-9_]+)\s+key',
  );

  static const _kLogCommand = '/usr/bin/log';
  static const _kLogShowSubcommand = 'show';
  static const _kLogLastFlag = '--last';
  static const _kLogLookbackDuration = '30s';
  static const _kLogStyleFlag = '--style';
  static const _kLogStyleNdjson = 'ndjson';
  static const _kLogPredicateFlag = '--predicate';
  static const _kLogQueryTimeout = Duration(seconds: 5);
  static const _kEventMessageKey = 'eventMessage';
  static const _kProcessIdKey = 'processID';

  final Analytics _analytics;
  final AppleContext _appleContext;
  final FeatureFlags _featureFlags;
  final TemplateRenderer _templateRenderer;

  @override
  Future<bool> isSupported() async => true;

  @override
  String get name => 'macOS';

  @override
  bool get supportsFlavors => true;

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.darwin;

  @override
  Future<CpuArch> get cpuArch async => toolContext.os.hostPlatform.cpuArch;

  @override
  Future<String> get targetPlatformDisplayName async {
    if (toolContext.os.hostPlatform == HostPlatform.darwin_arm64) {
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
    final ToolContext(:FileSystem fs, :Logger logger, :FlutterProjectFactory projectFactory) =
        toolContext;
    await buildMacOS(
      analytics: _analytics,
      appleContext: _appleContext,
      buildInfo: buildInfo,
      featureFlags: _featureFlags,
      flutterProject: projectFactory.fromDirectory(fs.currentDirectory),
      targetOverride: mainPath,
      templateRenderer: _templateRenderer,
      toolContext: toolContext,
      usingCISystem: usingCISystem,
      verboseLogging: logger.isVerbose,
    );
  }

  @override
  String? executablePathForDevice(covariant MacOSApp package, BuildInfo buildInfo) {
    return package.executable(buildInfo);
  }

  @override
  void onAttached(covariant MacOSApp package, BuildInfo buildInfo, Process process) {
    final ToolContext(:Logger logger, :ProcessManager processManager) = toolContext;
    // Bring app to foreground. Ideally this would be done post-launch rather
    // than post-attach, since this won't run for release builds, but there's
    // no general-purpose way of knowing when a process is far enough along in
    // the launch process for 'open' to foreground it.
    final String? applicationBundle = package.applicationBundle(buildInfo);
    if (applicationBundle == null) {
      logger.printError('Failed to foreground app; application bundle not found');
      return;
    }
    processManager.run(<String>['open', applicationBundle]).then((ProcessResult result) {
      if (result.exitCode != 0) {
        logger.printError('Failed to foreground app; open returned ${result.exitCode}');
      }
    });
  }

  @override
  Future<void> onProcessExited(Process process, int exitCode) async {
    if (exitCode != kSigabrtExitCode) {
      return;
    }
    final String? crashMessage = await _querySystemLogsForPrivacyCrash(process.pid);
    if (crashMessage != null) {
      _printPrivacyDiagnostic(crashMessage);
    }
  }

  Future<String?> _querySystemLogsForPrivacyCrash(int pid) async {
    final ProcessManager processManager = toolContext.processManager;
    if (!processManager.canRun(_kLogCommand)) {
      return null;
    }
    final ProcessResult result;
    try {
      result = await processManager
          .run(<String>[
            _kLogCommand,
            _kLogShowSubcommand,
            _kLogLastFlag,
            _kLogLookbackDuration,
            _kLogStyleFlag,
            _kLogStyleNdjson,
            _kLogPredicateFlag,
            '$_kProcessIdKey == $pid AND $_kEventMessageKey CONTAINS "$kMacOSPrivacyCrashPattern"',
          ])
          .timeout(_kLogQueryTimeout);
    } on ProcessException {
      return null;
    } on TimeoutException {
      return null;
    }
    if (result case ProcessResult(exitCode: 0, :final String stdout)) {
      for (final String line in LineSplitter.split(stdout)) {
        final Object? decoded;
        try {
          decoded = jsonDecode(line);
        } on FormatException {
          continue;
        }
        if (decoded
            case <String, Object?>{
              _kProcessIdKey: final int processId,
              _kEventMessageKey: final String eventMessage,
            }
            when processId == pid && eventMessage.contains(kMacOSPrivacyCrashPattern)) {
          return eventMessage;
        }
      }
    }
    return null;
  }

  void _printPrivacyDiagnostic(String line) {
    final String? key = _privacyKeyPattern.firstMatch(line)?.group(1);
    final keyNotice = key != null ? ' (requiring $key)' : '';
    final keyDetail = key != null
        ? 'Even if $key is already present in macos/Runner/Info.plist, '
        : 'Even if the usage description key is already present in '
              'macos/Runner/Info.plist, ';
    final String requiredKeyDescription = key ?? 'the required usage description key';

    toolContext.logger.printError('''

════════════════════════════════════════════════════════════════════════════════
macOS Privacy Permission Crash Detected
════════════════════════════════════════════════════════════════════════════════
The application crashed while requesting access to protected resources$keyNotice.

When launched from an IDE (such as VS Code or Android Studio) or custom terminal
via "flutter run", protected resource requests are made to the parent IDE or
terminal process rather than the application bundle.

${keyDetail}macOS terminates the process if the parent process lacks the usage
description.

Workaround:
1. Ensure $requiredKeyDescription is present in macos/Runner/Info.plist.
2. Run the project directly from Xcode, or 'flutter run' using the default macOS Terminal app.

See https://github.com/flutter/flutter/issues/70374 for more details.
════════════════════════════════════════════════════════════════════════════════
''');
  }
}

class MacOSDevices extends PollingDeviceDiscovery {
  MacOSDevices({
    required this._analytics,
    required this._appleContext,
    required this._featureFlags,
    required this._macOSWorkflow,
    required this._templateRenderer,
    required ToolContext super.toolContext,
  }) : super('macOS devices');

  final Analytics _analytics;
  final AppleContext _appleContext;
  final FeatureFlags _featureFlags;
  final MacOSWorkflow _macOSWorkflow;
  final TemplateRenderer _templateRenderer;

  @override
  bool get supportsPlatform => toolContext.platform.isMacOS;

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
        analytics: _analytics,
        appleContext: _appleContext,
        featureFlags: _featureFlags,
        templateRenderer: _templateRenderer,
        toolContext: toolContext,
      ),
    ];
  }

  @override
  Future<List<String>> getDiagnostics() async => const <String>[];

  @override
  List<String> get wellKnownIds => const <String>['macos'];
}
