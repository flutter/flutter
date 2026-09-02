// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../android/android_sdk.dart';
import '../artifacts.dart';
import '../base/bot_detector.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/signals.dart';
import '../base/template.dart';
import '../base/terminal.dart';
import '../base/time.dart';
import '../base/user_messages.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../custom_devices/custom_devices_config.dart';
import '../features.dart';
import '../git.dart';
import '../ios/code_signing.dart';
import '../ios/plist_parser.dart';
import '../macos/xcode.dart';
import '../persistent_tool_state.dart';
import '../pre_run_validator.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../runner/local_engine.dart';
import '../version.dart';
import 'build_aar.dart';
import 'build_apk.dart';
import 'build_appbundle.dart';
import 'build_bundle.dart';
import 'build_ios.dart';
import 'build_ios_framework.dart';
import 'build_linux.dart';
import 'build_macos.dart';
import 'build_macos_framework.dart';
import 'build_swift_package.dart';
import 'build_web.dart';
import 'build_windows.dart';
import 'darwin_add_to_app.dart';

class BuildCommand extends FlutterCommand {
  BuildCommand({
    required AndroidSdk? androidSdk,
    required Artifacts artifacts,
    required BuildSystem buildSystem,
    required Cache cache,
    required Config config,
    required FileSystem fileSystem,
    required FileSystemUtils fileSystemUtils,
    required FlutterVersion flutterVersion,
    required Logger logger,
    required OperatingSystemUtils osUtils,
    required Platform platform,
    required PlistParser plistParser,
    required ProcessManager processManager,
    required ProcessUtils processUtils,
    required TemplateRenderer templateRenderer,
    required AnsiTerminal terminal,
    required Xcode? xcode,
    FeatureFlags? featureFlags,
    super.outputPreferences,
    ToolContext? toolContext,
    super.verboseHelp,
  }) : _fallbackToolContext = _createFallbackToolContext(
         artifacts: artifacts,
         cache: cache,
         config: config,
         fileSystem: fileSystem,
         flutterVersion: flutterVersion,
         logger: logger,
         osUtils: osUtils,
         outputPreferences: outputPreferences,
         platform: platform,
         processManager: processManager,
         processUtils: processUtils,
         terminal: terminal,
       ),
       super(toolContext: toolContext) {
    Analytics effectiveAnalytics;
    try {
      effectiveAnalytics = analytics;
    } on UnsupportedError {
      effectiveAnalytics = const NoOpAnalytics();
    }
    final FeatureFlags effectiveFeatureFlags = featureFlags ?? const _DefaultFeatureFlags();
    final ToolContext effectiveToolContext = toolContext ?? _fallbackToolContext;

    _addSubcommand(
      BuildAarCommand(
        fileSystem: fileSystem,
        androidSdk: androidSdk,
        logger: logger,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(BuildApkCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildAppBundleCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(BuildIOSCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildIOSFrameworkCommand(
        logger: logger,
        buildSystem: buildSystem,
        verboseHelp: verboseHelp,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: platform,
            processUtils: processUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
      ),
    );
    _addSubcommand(
      BuildMacOSFrameworkCommand(
        logger: logger,
        buildSystem: buildSystem,
        verboseHelp: verboseHelp,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: platform,
            processUtils: processUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
      ),
    );
    _addSubcommand(
      BuildSwiftPackage(
        logger: logger,
        analytics: effectiveAnalytics,
        artifacts: artifacts,
        buildSystem: buildSystem,
        cache: cache,
        featureFlags: effectiveFeatureFlags,
        fileSystem: fileSystem,
        flutterVersion: flutterVersion,
        platform: platform,
        processManager: processManager,
        templateRenderer: templateRenderer,
        xcode: xcode,
        codesign: DarwinAddToAppCodesigning(
          logger: logger,
          xcodeCodeSigningSettings: XcodeCodeSigningSettings(
            config: config,
            logger: logger,
            platform: platform,
            processUtils: processUtils,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            terminal: terminal,
            plistParser: plistParser,
          ),
        ),
        verboseHelp: verboseHelp,
      ),
    );

    _addSubcommand(BuildIOSArchiveCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildBundleCommand(
        buildSystem: buildSystem,
        featureFlags: effectiveFeatureFlags,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildWebCommand(
        buildSystem: buildSystem,
        featureFlags: effectiveFeatureFlags,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(BuildMacosCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildLinuxCommand(logger: logger, operatingSystemUtils: osUtils, verboseHelp: verboseHelp),
    );
    _addSubcommand(
      BuildWindowsCommand(logger: logger, operatingSystemUtils: osUtils, verboseHelp: verboseHelp),
    );
  }

  final ToolContext _fallbackToolContext;

  static ToolContext _createFallbackToolContext({
    required Artifacts artifacts,
    required Cache cache,
    required Config config,
    required FileSystem fileSystem,
    required FlutterVersion flutterVersion,
    required Logger logger,
    required OperatingSystemUtils osUtils,
    required OutputPreferences? outputPreferences,
    required Platform platform,
    required ProcessManager processManager,
    required ProcessUtils processUtils,
    required AnsiTerminal terminal,
  }) {
    final OutputPreferences effectiveOutputPreferences =
        outputPreferences ?? OutputPreferences.test();

    final persistentToolState = PersistentToolState(
      fileSystem: fileSystem,
      logger: logger,
      platform: platform,
    );

    return ToolContext(
      artifacts: artifacts,
      botDetector: BotDetector(
        httpClientFactory: () => HttpClient(),
        persistentToolState: persistentToolState,
        platform: platform,
      ),
      cache: cache,
      config: config,
      customDevicesConfig: CustomDevicesConfig(
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
      ),
      flutterVersion: flutterVersion,
      fs: fileSystem,
      git: Git(currentPlatform: platform, runProcessWith: processUtils),
      localEngineLocator: LocalEngineLocator(
        fileSystem: fileSystem,
        flutterRoot: Cache.flutterRoot ?? '',
        logger: logger,
        platform: platform,
        userMessages: UserMessages(),
      ),
      logger: logger,
      os: osUtils,
      outputPreferences: effectiveOutputPreferences,
      persistentToolState: persistentToolState,
      platform: platform,
      preRunValidator: PreRunValidator(fileSystem: fileSystem),
      processInfo: ProcessInfo(fileSystem),
      processManager: processManager,
      processUtils: processUtils,
      projectFactory: FlutterProjectFactory(fileSystem: fileSystem, logger: logger),
      shutdownHooks: ShutdownHooks(),
      signals: LocalSignals.instance,
      stdio: Stdio(),
      systemClock: const SystemClock(),
      terminal: terminal,
      userMessages: UserMessages(),
    );
  }

  @override
  ToolContext get toolContext => super.toolContext ?? _fallbackToolContext;

  void _addSubcommand(BuildSubCommand command) {
    bool isSupported;
    try {
      isSupported = command.supported;
    } on UnsupportedError {
      isSupported = true;
    }
    if (isSupported) {
      addSubcommand(command);
    }
  }

  @override
  final name = 'build';

  @override
  final description = 'Build an executable app or install bundle.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

abstract class BuildSubCommand extends FlutterCommand {
  BuildSubCommand({
    required this.logger,
    required super.verboseHelp,
    super.outputPreferences,
    super.toolContext,
  }) : super() {
    requiresPubspecYaml();
    usesFatalWarningsOption(verboseHelp: verboseHelp);
  }

  @protected
  final Logger logger;

  /// Whether this command is supported and should be shown.
  bool get supported => true;
}

class _DefaultFeatureFlags extends FeatureFlags {
  const _DefaultFeatureFlags();

  @override
  bool isEnabled(Feature feature) => false;
  @override
  bool get isLinuxEnabled => false;
  @override
  bool get isMacOSEnabled => false;
  @override
  bool get isWindowsEnabled => false;
  @override
  bool get isWebEnabled => false;
  @override
  bool get isAndroidEnabled => false;
  @override
  bool get isIOSEnabled => false;
  @override
  bool get isFuchsiaEnabled => false;
  @override
  bool get areCustomDevicesEnabled => false;
  @override
  bool get isCliAnimationEnabled => false;
  @override
  bool get isNativeAssetsEnabled => false;
  @override
  bool get isDartDataAssetsEnabled => false;
  @override
  bool get isRecordUseEnabled => false;
  @override
  bool get isSwiftPackageManagerEnabled => false;
  @override
  bool get isOmitLegacyVersionFileEnabled => false;
  @override
  bool get isWindowingEnabled => false;
  @override
  bool get isAccessibilityEvaluationsEnabled => false;
  @override
  bool get isLLDBDebuggingEnabled => false;
  @override
  bool get isUISceneMigrationEnabled => false;
  @override
  bool get isRiscv64SupportEnabled => false;
  @override
  bool get isMacOSArm64OnlyEnabled => false;
  @override
  bool get isHcppEnabled => false;
  @override
  bool get isToolExtensionsEnabled => false;
}
