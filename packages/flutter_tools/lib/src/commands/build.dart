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
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/net.dart';
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
    required Terminal terminal,
    required Xcode? xcode,
    Analytics? analytics,
    FeatureFlags? featureFlags,
    OutputPreferences? outputPreferences,
    PreRunValidator? preRunValidator,
    ToolContext? toolContext,
    bool verboseHelp = false,
  }) : super(
         outputPreferences: outputPreferences,
         toolContext: toolContext,
         verboseHelp: verboseHelp,
       ) {
    final Analytics effectiveAnalytics =
        analytics ?? (context.get<Analytics>() ?? const NoOpAnalytics());
    final FeatureFlags effectiveFeatureFlags =
        featureFlags ?? (context.get<FeatureFlags>() ?? const _DefaultFeatureFlags());
    final effectivePlatform = platform;
    final PersistentToolState persistentToolState =
        context.get<PersistentToolState>() ??
        PersistentToolState.test(
          directory: fileSystem.directory(
            fileSystem.path.join(fileSystem.systemTempDirectory.path, '.tmp_state'),
          )..createSync(recursive: true),
          logger: logger,
        );

    final OutputPreferences effectiveOutputPreferences =
        outputPreferences ?? (context.get<OutputPreferences>() ?? OutputPreferences.test());
    final ToolContext effectiveToolContext =
        toolContext ??
        (_fallbackToolContext = ToolContext(
          artifacts: artifacts,
          botDetector: BotDetector(
            httpClientFactory: context.get<HttpClientFactory>() ?? () => HttpClient(),
            persistentToolState: persistentToolState,
            platform: effectivePlatform,
          ),
          cache: cache,
          config: config,
          customDevicesConfig: CustomDevicesConfig(
            fileSystem: fileSystem,
            logger: logger,
            platform: effectivePlatform,
          ),
          flutterVersion: flutterVersion,
          fs: fileSystem,
          git: Git(currentPlatform: effectivePlatform, runProcessWith: processUtils),
          localEngineLocator: LocalEngineLocator(
            fileSystem: fileSystem,
            flutterRoot: Cache.flutterRoot ?? '',
            logger: logger,
            platform: effectivePlatform,
            userMessages: context.get<UserMessages>() ?? UserMessages(),
          ),
          logger: logger,
          os: osUtils,
          outputPreferences: effectiveOutputPreferences,
          persistentToolState: persistentToolState,
          platform: effectivePlatform,
          preRunValidator:
              preRunValidator ??
              (context.get<PreRunValidator>() ??
                  (!fileSystem
                          .directory(
                            fileSystem.path.join(
                              Cache.flutterRoot ?? '',
                              'packages',
                              'flutter_tools',
                            ),
                          )
                          .existsSync()
                      ? _NoopPreRunValidator()
                      : PreRunValidator(fileSystem: fileSystem))),
          processInfo: ProcessInfo(fileSystem),
          processManager: processManager,
          processUtils: processUtils,
          projectFactory: FlutterProjectFactory(fileSystem: fileSystem, logger: logger),
          shutdownHooks: ShutdownHooks(),
          signals: LocalSignals.instance,
          stdio: context.get<Stdio>() ?? Stdio(),
          systemClock: const SystemClock(),
          terminal: terminal is AnsiTerminal
              ? terminal
              : AnsiTerminal(stdio: context.get<Stdio>() ?? Stdio(), platform: effectivePlatform),
          userMessages: context.get<UserMessages>() ?? UserMessages(),
        ));

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
    _addSubcommand(BuildBundleCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildWebCommand(fileSystem: fileSystem, logger: logger, verboseHelp: verboseHelp),
    );
    _addSubcommand(BuildMacosCommand(logger: logger, verboseHelp: verboseHelp));
    _addSubcommand(
      BuildLinuxCommand(
        analytics: effectiveAnalytics,
        buildSystem: buildSystem,
        featureFlags: effectiveFeatureFlags,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
    _addSubcommand(
      BuildWindowsCommand(
        analytics: effectiveAnalytics,
        buildSystem: buildSystem,
        featureFlags: effectiveFeatureFlags,
        toolContext: effectiveToolContext,
        verboseHelp: verboseHelp,
      ),
    );
  }

  void _addSubcommand(BuildSubCommand command) {
    if (command.supported) {
      addSubcommand(command);
    }
  }

  ToolContext? _fallbackToolContext;

  @override
  ToolContext? get toolContext => super.toolContext ?? _fallbackToolContext;

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
    Analytics? analytics,
    super.outputPreferences,
    super.toolContext,
  }) {
    _analytics = analytics;
    requiresPubspecYaml();
    usesFatalWarningsOption(verboseHelp: verboseHelp);
  }

  @protected
  final Logger logger;

  Analytics? _analytics;

  @override
  Analytics get analytics => _analytics ?? super.analytics;

  /// Whether this command is supported and should be shown.
  bool get supported => true;
}

class _NoopPreRunValidator implements PreRunValidator {
  @override
  void validate() {}
}

class _DefaultFeatureFlags implements FeatureFlags {
  const _DefaultFeatureFlags();

  @override
  bool get isLinuxEnabled => true;

  @override
  bool get isWindowsEnabled => true;

  @override
  bool get isHcppEnabled => false;

  @override
  bool get isToolExtensionsEnabled => false;

  @override
  Object? noSuchMethod(Invocation invocation) => false;
}
