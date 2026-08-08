// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'runner.dart' as runner;
import 'src/base/io.dart';
import 'src/base/logger.dart';
import 'src/base/platform.dart';
import 'src/base/process.dart';
import 'src/base/terminal.dart';
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
import 'src/features.dart';
import 'src/isolated/mustache_template.dart';
import 'src/project_validator.dart';
import 'src/runner/flutter_command.dart';

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

  final bool doctor =
      (args.isNotEmpty && args.first == 'doctor') ||
      (args.length == 2 && verbose && args.last == 'doctor');
  final bool help =
      args.contains('-h') ||
      args.contains('--help') ||
      (args.isNotEmpty && args.first == 'help') ||
      (args.length == 1 && verbose);
  final bool muteCommandLogging = (help || doctor) && !veryVerbose;
  final bool verboseHelp = help && verbose;
  final bool daemon = args.contains('daemon');
  final bool widgetPreviews = args.contains(WidgetPreviewCommand.kWidgetPreview);
  final bool runMachine = args.contains('--machine');

  final shutdownHooks = ShutdownHooks();
  const Platform platform = LocalPlatform();
  final stdio = Stdio();
  final terminal = AnsiTerminal(
    stdio: stdio,
    platform: platform,
    now: DateTime.now(),
    defaultCliAnimationEnabled: false,
    shutdownHooks: shutdownHooks,
  );
  final outputPreferences = OutputPreferences(
    wrapText: stdio.hasTerminal,
    showColor: platform.stdoutSupportsAnsi,
    stdio: stdio,
  );
  final loggerFactory = LoggerFactory(
    outputPreferences: outputPreferences,
    terminal: terminal,
    stdio: stdio,
  );
  final Logger logger = loggerFactory.createLogger(
    daemon: daemon,
    machine: runMachine,
    verbose: verbose && !muteCommandLogging,
    prefixedErrors: prefixedErrors,
    windows: platform.isWindows,
    widgetPreviews: widgetPreviews,
  );

  await runner.run(
    args,
    (ToolDependencies toolDependencies) => generateCommands(
      toolDependencies: toolDependencies,
      verbose: verbose,
      verboseHelp: verboseHelp,
    ),
    logger: logger,
    outputPreferences: outputPreferences,
    platform: platform,
    stdio: stdio,
    terminal: terminal,
    verbose: verbose,
    muteCommandLogging: muteCommandLogging,
    verboseHelp: verboseHelp,
    shutdownHooks: shutdownHooks,
  );
}

List<FlutterCommand> generateCommands({
  required ToolDependencies toolDependencies,
  required bool verbose,
  required bool verboseHelp,
}) => <FlutterCommand>[
  AnalyzeCommand(
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
    toolContext: toolDependencies.toolContext,
    verboseHelp: verboseHelp,
  ),
  AssembleCommand(
    buildSystem: toolDependencies.buildSystem,
    toolContext: toolDependencies.toolContext,
    analytics: toolDependencies.analytics,
    verboseHelp: verboseHelp,
  ),
  AttachCommand(toolContext: toolDependencies.toolContext, verboseHelp: verboseHelp),
  BuildCommand(
    androidContext: toolDependencies.androidContext,
    androidSdk: toolDependencies.androidContext.androidSdk,
    appleContext: toolDependencies.appleContext,
    artifacts: toolDependencies.toolContext.artifacts,
    buildSystem: toolDependencies.buildSystem,
    cache: toolDependencies.toolContext.cache,
    config: toolDependencies.toolContext.config,
    fileSystem: toolDependencies.toolContext.fs,
    fileSystemUtils: toolDependencies.toolContext.fileSystemUtils,
    flutterVersion: toolDependencies.toolContext.flutterVersion,
    logger: toolDependencies.toolContext.logger,
    osUtils: toolDependencies.toolContext.os,
    platform: toolDependencies.toolContext.platform,
    plistParser: toolDependencies.appleContext.plistParser,
    processManager: toolDependencies.toolContext.processManager,
    processUtils: toolDependencies.toolContext.processUtils,
    templateRenderer: const MustacheTemplateRenderer(),
    terminal: toolDependencies.toolContext.terminal,
    toolContext: toolDependencies.toolContext,
    verboseHelp: verboseHelp,
    xcode: toolDependencies.appleContext.xcode,
  ),
  ChannelCommand(verboseHelp: verboseHelp, toolContext: toolDependencies.toolContext),
  CleanCommand(
    verbose: verbose,
    toolContext: toolDependencies.toolContext,
    xcode: toolDependencies.appleContext.xcode,
    xcodeProjectInterpreter: toolDependencies.appleContext.xcodeProjectInterpreter,
  ),
  ConfigCommand(
    verboseHelp: verboseHelp,
    androidContext: toolDependencies.androidContext,
    toolContext: toolDependencies.toolContext,
    analytics: toolDependencies.analytics,
    featureFlags: featureFlags,
  ),
  CustomDevicesCommand(featureFlags: featureFlags, toolContext: toolDependencies.toolContext),
  CreateCommand(
    toolContext: toolDependencies.toolContext,
    verboseHelp: verboseHelp,
    java: toolDependencies.androidContext.java,
    plistParser: toolDependencies.appleContext.plistParser,
  ),
  DaemonCommand(toolContext: toolDependencies.toolContext, hidden: !verboseHelp),
  DebugAdapterCommand(toolContext: toolDependencies.toolContext, verboseHelp: verboseHelp),
  DevicesCommand(toolContext: toolDependencies.toolContext, verboseHelp: verboseHelp),
  DoctorCommand(verbose: verbose, toolContext: toolDependencies.toolContext),
  DowngradeCommand(toolContext: toolDependencies.toolContext, verboseHelp: verboseHelp),
  DriveCommand(toolContext: toolDependencies.toolContext, verboseHelp: verboseHelp),
  EmulatorsCommand(toolContext: toolDependencies.toolContext),
  GenerateCommand(toolContext: toolDependencies.toolContext),
  GenerateLocalizationsCommand(toolContext: toolDependencies.toolContext),
  InstallCommand(toolContext: toolDependencies.toolContext, verboseHelp: verboseHelp),
  LogsCommand(toolContext: toolDependencies.toolContext),
  PackagesCommand(toolContext: toolDependencies.toolContext),
  PrecacheCommand(
    verboseHelp: verboseHelp,
    cache: toolDependencies.toolContext.cache,
    logger: toolDependencies.toolContext.logger,
    platform: toolDependencies.toolContext.platform,
    featureFlags: featureFlags,
  ),
  RunCommand(
    toolContext: toolDependencies.toolContext,
    appleContext: toolDependencies.appleContext,
    buildSystem: toolDependencies.buildSystem,
    buildTargets: toolDependencies.buildTargets,
    verboseHelp: verboseHelp,
  ),
  ScreenshotCommand(toolContext: toolDependencies.toolContext),
  ShellCompletionCommand(toolContext: toolDependencies.toolContext),
  TestCommand(
    toolContext: toolDependencies.toolContext,
    verboseHelp: verboseHelp,
    verbose: verbose,
    nativeAssetsBuilder: toolDependencies.toolContext.nativeAssetsBuilder,
  ),
  WidgetPreviewCommand(toolContext: toolDependencies.toolContext, verboseHelp: verboseHelp),
  UpgradeCommand(toolContext: toolDependencies.toolContext, verboseHelp: verboseHelp),
  SymbolizeCommand(toolContext: toolDependencies.toolContext),
  // Development-only commands. These are always hidden,
  IdeConfigCommand(toolContext: toolDependencies.toolContext),
  UpdatePackagesCommand(toolContext: toolDependencies.toolContext, verboseHelp: verboseHelp),
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
      return WidgetPreviewMachineAwareLogger(
        logger,
        machine: machine,
        verbose: verbose,
        stdio: _stdio,
      );
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
