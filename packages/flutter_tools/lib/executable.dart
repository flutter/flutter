// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';
import 'package:meta/meta.dart';

import 'runner.dart' as runner;
import 'src/base/context.dart';
import 'src/base/io.dart';
import 'src/base/logger.dart';
import 'src/base/platform.dart';
import 'src/base/template.dart';
import 'src/base/terminal.dart';
import 'src/base/user_messages.dart';
import 'src/build_system/build_targets.dart';
import 'src/build_system/targets/hook_runner_native.dart' show FlutterHookRunnerNative;
import 'src/cache.dart';
import 'src/commands/analyze.dart';
import 'src/commands/assemble.dart';
import 'src/commands/attach.dart';
import 'src/commands/build.dart';
import 'src/commands/channel.dart';
import 'src/commands/clean.dart';
import 'src/commands/config.dart';
import 'src/commands/create.dart';
import 'src/commands/custom_devices.dart';
import 'src/commands/daemon.dart';
import 'src/commands/debug_adapter.dart';
import 'src/commands/devices.dart';
import 'src/commands/doctor.dart';
import 'src/commands/downgrade.dart';
import 'src/commands/drive.dart';
import 'src/commands/emulators.dart';
import 'src/commands/generate.dart';
import 'src/commands/generate_localizations.dart';
import 'src/commands/ide_config.dart';
import 'src/commands/install.dart';
import 'src/commands/logs.dart';
import 'src/commands/packages.dart';
import 'src/commands/precache.dart';
import 'src/commands/run.dart';
import 'src/commands/screenshot.dart';
import 'src/commands/shell_completion.dart';
import 'src/commands/symbolize.dart';
import 'src/commands/test.dart';
import 'src/commands/update_packages.dart';
import 'src/commands/upgrade.dart';
import 'src/commands/widget_preview.dart';
import 'src/context/tool_dependencies.dart';
import 'src/devtools_launcher.dart';
import 'src/experimental/extension_discovery.dart';
import 'src/experimental/extension_manager.dart';
import 'src/features.dart';
import 'src/globals.dart' as globals;
// Files in `isolated` are intentionally excluded from google3 tooling.
import 'src/hook_runner.dart' show FlutterHookRunner;
import 'src/isolated/build_targets.dart';
import 'src/isolated/mustache_template.dart';
import 'src/isolated/native_assets/test/native_assets.dart';
import 'src/isolated/resident_web_runner.dart';
import 'src/native_assets.dart';
import 'src/pre_run_validator.dart';
import 'src/project_validator.dart';
import 'src/resident_runner.dart';
import 'src/runner/flutter_command.dart';
import 'src/runner/flutter_command_runner.dart';
import 'src/web/web_runner.dart';

/// Main entry point for commands.
///
/// This function is intended to be used from the `flutter` command line tool.
Future<void> main(List<String> args) async {
  final bool veryVerbose = args.contains('-vv');
  final bool verbose = args.contains('-v') || args.contains('--verbose') || veryVerbose;
  final bool prefixedErrors = args.contains('--prefixed-errors');
  // Support universal help idioms.
  final int powershellHelpIndex = args.indexOf('-?');
  if (powershellHelpIndex != -1) {
    args[powershellHelpIndex] = '-h';
  }
  final int slashQuestionHelpIndex = args.indexOf('/?');
  if (slashQuestionHelpIndex != -1) {
    args[slashQuestionHelpIndex] = '-h';
  }

  final String? commandName = findCommandName(args);
  final doctor = commandName == 'doctor';
  final bool help =
      args.contains('-h') ||
      args.contains('--help') ||
      commandName == 'help' ||
      (args.length == 1 && verbose);
  final bool muteCommandLogging = (help || doctor) && !veryVerbose;
  final bool verboseHelp = help && verbose;
  final daemon = commandName == 'daemon';
  final widgetPreviews = commandName == WidgetPreviewCommand.kWidgetPreview;
  final bool runMachine = args.contains('--machine');

  // Cache.flutterRoot must be set early because other features use it (e.g.
  // enginePath's initializer uses it). This can only work with the real
  // instances of the platform or filesystem, so just use those.
  Cache.flutterRoot = Cache.defaultFlutterRoot(
    platform: const LocalPlatform(),
    fileSystem: globals.localFileSystem,
    userMessages: UserMessages(),
  );

  await runner.run(
    args,
    (ToolDependencies toolDependencies) {
      final manager = ExtensionManager(
        hostPlatform: globals.os.hostPlatform,
        logger: globals.logger,
        entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
        featureFlags: featureFlags,
      );
      return generateCommands(
        toolDependencies: toolDependencies,
        verboseHelp: verboseHelp,
        verbose: verbose,
        extensionManager: manager,
      );
    },
    verbose: verbose,
    muteCommandLogging: muteCommandLogging,
    verboseHelp: verboseHelp,
    overrides: <Type, Generator>{
      FlutterHookRunner: () => FlutterHookRunnerNative(),
      // The web runner is not supported in google3 because it depends
      // on dwds.
      WebRunnerFactory: () => DwdsWebRunnerFactory(),
      // The mustache dependency is different in google3
      TemplateRenderer: () => const MustacheTemplateRenderer(),
      // The devtools launcher is not supported in google3 because it depends on
      // devtools source code.
      DevtoolsLauncher: () => DevtoolsServerLauncher(
        processManager: globals.processManager,
        artifacts: globals.artifacts!,
        logger: globals.logger,
        botDetector: globals.botDetector,
      ),
      BuildTargets: () => const BuildTargetsImpl(),
      Logger: () {
        final loggerFactory = LoggerFactory(
          outputPreferences: globals.outputPreferences,
          terminal: globals.terminal,
          stdio: globals.stdio,
        );
        return loggerFactory.createLogger(
          daemon: daemon,
          machine: runMachine,
          verbose: verbose && !muteCommandLogging,
          prefixedErrors: prefixedErrors,
          windows: globals.platform.isWindows,
          widgetPreviews: widgetPreviews,
        );
      },
      AnsiTerminal: () {
        return AnsiTerminal(
          stdio: globals.stdio,
          platform: globals.platform,
          now: DateTime.now(),
          // So that we don't animate anything before calling applyFeatureFlags, default
          // the animations to disabled in real apps.
          defaultCliAnimationEnabled: false,
          shutdownHooks: globals.shutdownHooks,
        );
        // runner.run calls "terminal.applyFeatureFlags()"
      },
      PreRunValidator: () => PreRunValidator(fileSystem: globals.fs),
      TestCompilerNativeAssetsBuilder: () => const TestCompilerNativeAssetsBuilderImpl(),
    },
    shutdownHooks: globals.shutdownHooks,
  );
}

/// The name of the command in [args], or null if there isn't one.
///
/// Global options can come before the command, so it can't be found by
/// position. A throwaway parser walks past them instead: trailing options are
/// disabled, so parsing stops at the command and leaves it at the head of
/// [ArgResults.rest]. `help` is the exception, since the command runner
/// registers it on the parser itself and so reports it as a parsed command.
@visibleForTesting
String? findCommandName(List<String> args) {
  final ArgResults results;
  try {
    results = FlutterCommandRunner().argParser.parse(args);
  } on ArgParserException {
    // The real parser will complain about these later.
    return null;
  }
  return results.command?.name ?? results.rest.firstOrNull;
}

List<FlutterCommand> generateCommands({
  required ToolDependencies toolDependencies,
  required bool verbose,
  required bool verboseHelp,
  ExtensionManager? extensionManager,
}) => <FlutterCommand>[
  AnalyzeCommand(
    verboseHelp: verboseHelp,
    fileSystem: toolDependencies.toolContext.fs,
    platform: toolDependencies.toolContext.platform,
    processManager: toolDependencies.toolContext.processManager,
    logger: toolDependencies.toolContext.logger,
    terminal: toolDependencies.toolContext.terminal,
    artifacts: toolDependencies.toolContext.artifacts,
    // new ProjectValidators should be added here for the --suggestions to run
    allProjectValidators: <ProjectValidator>[
      GeneralInfoProjectValidator(),
      VariableDumpMachineProjectValidator(
        logger: toolDependencies.toolContext.logger,
        fileSystem: toolDependencies.toolContext.fs,
        platform: toolDependencies.toolContext.platform,
        git: toolDependencies.toolContext.git,
      ),
    ],
    suppressAnalytics: !toolDependencies.analytics.okToSend,
  ),
  AssembleCommand(verboseHelp: verboseHelp, buildSystem: toolDependencies.buildSystem),
  AttachCommand(
    verboseHelp: verboseHelp,
    stdio: toolDependencies.toolContext.stdio,
    logger: toolDependencies.toolContext.logger,
    terminal: toolDependencies.toolContext.terminal,
    signals: toolDependencies.toolContext.signals,
    platform: toolDependencies.toolContext.platform,
    processInfo: ProcessInfo(toolDependencies.toolContext.fs),
    fileSystem: toolDependencies.toolContext.fs,
  ),
  BuildCommand(
    fileSystem: toolDependencies.toolContext.fs,
    buildSystem: toolDependencies.buildSystem,
    osUtils: toolDependencies.toolContext.os,
    verboseHelp: verboseHelp,
    androidSdk: toolDependencies.androidContext.androidSdk,
    logger: toolDependencies.toolContext.logger,
    config: toolDependencies.toolContext.config,
    platform: toolDependencies.toolContext.platform,
    fileSystemUtils: toolDependencies.toolContext.fileSystemUtils,
    terminal: toolDependencies.toolContext.terminal,
    plistParser: toolDependencies.appleContext.plistParser,
    processUtils: toolDependencies.toolContext.processUtils,
    processManager: toolDependencies.toolContext.processManager,
    templateRenderer: const MustacheTemplateRenderer(),
    xcode: toolDependencies.appleContext.xcode,
    artifacts: toolDependencies.toolContext.artifacts,
    cache: toolDependencies.toolContext.cache,
    flutterVersion: toolDependencies.toolContext.flutterVersion,
  ),
  ChannelCommand(verboseHelp: verboseHelp),
  CleanCommand(verbose: verbose),
  ConfigCommand(verboseHelp: verboseHelp),
  CustomDevicesCommand(
    customDevicesConfig: toolDependencies.toolContext.customDevicesConfig,
    operatingSystemUtils: toolDependencies.toolContext.os,
    terminal: toolDependencies.toolContext.terminal,
    platform: toolDependencies.toolContext.platform,
    featureFlags: featureFlags,
    processManager: toolDependencies.toolContext.processManager,
    fileSystem: toolDependencies.toolContext.fs,
    logger: toolDependencies.toolContext.logger,
  ),
  CreateCommand(verboseHelp: verboseHelp),
  DaemonCommand(hidden: !verboseHelp),
  DebugAdapterCommand(verboseHelp: verboseHelp),
  DevicesCommand(verboseHelp: verboseHelp),
  DoctorCommand(verbose: verbose, extensionManager: extensionManager),
  DowngradeCommand(verboseHelp: verboseHelp, logger: toolDependencies.toolContext.logger),
  DriveCommand(
    verboseHelp: verboseHelp,
    fileSystem: toolDependencies.toolContext.fs,
    logger: toolDependencies.toolContext.logger,
    platform: toolDependencies.toolContext.platform,
    terminal: toolDependencies.toolContext.terminal,
    outputPreferences: toolDependencies.toolContext.outputPreferences,
    signals: toolDependencies.toolContext.signals,
  ),
  EmulatorsCommand(),
  GenerateCommand(),
  GenerateLocalizationsCommand(
    fileSystem: toolDependencies.toolContext.fs,
    logger: toolDependencies.toolContext.logger,
    artifacts: toolDependencies.toolContext.artifacts,
    processManager: toolDependencies.toolContext.processManager,
  ),
  InstallCommand(verboseHelp: verboseHelp),
  LogsCommand(sigint: ProcessSignal.sigint, sigterm: ProcessSignal.sigterm),
  PackagesCommand(),
  PrecacheCommand(
    verboseHelp: verboseHelp,
    cache: toolDependencies.toolContext.cache,
    logger: toolDependencies.toolContext.logger,
    platform: toolDependencies.toolContext.platform,
    featureFlags: featureFlags,
  ),
  RunCommand(verboseHelp: verboseHelp),
  ScreenshotCommand(fs: toolDependencies.toolContext.fs),
  ShellCompletionCommand(),
  TestCommand(
    verboseHelp: verboseHelp,
    verbose: verbose,
    nativeAssetsBuilder: toolDependencies.toolContext.nativeAssetsBuilder,
  ),
  WidgetPreviewCommand(
    verboseHelp: verboseHelp,
    logger: toolDependencies.toolContext.logger,
    fs: toolDependencies.toolContext.fs,
    projectFactory: toolDependencies.toolContext.projectFactory,
    cache: toolDependencies.toolContext.cache,
    platform: toolDependencies.toolContext.platform,
    shutdownHooks: toolDependencies.toolContext.shutdownHooks,
    os: toolDependencies.toolContext.os,
    processManager: toolDependencies.toolContext.processManager,
    artifacts: toolDependencies.toolContext.artifacts,
    terminal: toolDependencies.toolContext.terminal,
  ),
  UpgradeCommand(verboseHelp: verboseHelp),
  SymbolizeCommand(
    stdio: toolDependencies.toolContext.stdio,
    fileSystem: toolDependencies.toolContext.fs,
  ),
  // Development-only commands. These are always hidden,
  IdeConfigCommand(),
  UpdatePackagesCommand(verboseHelp: verboseHelp),
];

/// An abstraction for instantiation of the correct logger type.
///
/// Our logger class hierarchy and runtime requirements are overly complicated.
class LoggerFactory {
  LoggerFactory({
    required Terminal terminal,
    required Stdio stdio,
    required OutputPreferences outputPreferences,
    StopwatchFactory stopwatchFactory = const StopwatchFactory(),
  }) : _terminal = terminal,
       _stdio = stdio,
       _stopwatchFactory = stopwatchFactory,
       _outputPreferences = outputPreferences;

  final Terminal _terminal;
  final Stdio _stdio;
  final StopwatchFactory _stopwatchFactory;
  final OutputPreferences _outputPreferences;

  /// Create the appropriate logger for the current platform and configuration.
  Logger createLogger({
    required bool verbose,
    required bool prefixedErrors,
    required bool machine,
    required bool daemon,
    required bool windows,
    required bool widgetPreviews,
  }) {
    Logger logger;
    if (windows) {
      logger = WindowsStdoutLogger(
        terminal: _terminal,
        stdio: _stdio,
        outputPreferences: _outputPreferences,
        stopwatchFactory: _stopwatchFactory,
      );
    } else {
      logger = StdoutLogger(
        terminal: _terminal,
        stdio: _stdio,
        outputPreferences: _outputPreferences,
        stopwatchFactory: _stopwatchFactory,
      );
    }
    if (verbose) {
      logger = VerboseLogger(logger, stopwatchFactory: _stopwatchFactory);
    }
    if (prefixedErrors) {
      logger = PrefixedErrorLogger(logger);
    }
    if (widgetPreviews) {
      return WidgetPreviewMachineAwareLogger(logger, machine: machine, verbose: verbose);
    }
    if (daemon) {
      return NotifyingLogger(verbose: verbose, parent: logger);
    }
    if (machine) {
      return MachineOutputLogger(parent: logger);
    }
    return logger;
  }
}
