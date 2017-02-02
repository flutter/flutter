// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:process/process.dart';
import 'package:stack_trace/stack_trace.dart';

import 'src/base/common.dart';
import 'src/base/config.dart';
import 'src/base/context.dart';
import 'src/base/file_system.dart';
import 'src/base/io.dart';
import 'src/base/logger.dart';
import 'src/base/os.dart';
import 'src/base/platform.dart';
import 'src/base/process.dart';
import 'src/base/utils.dart';
import 'src/cache.dart';
import 'src/commands/analyze.dart';
import 'src/commands/build.dart';
import 'src/commands/channel.dart';
import 'src/commands/config.dart';
import 'src/commands/create.dart';
import 'src/commands/daemon.dart';
import 'src/commands/devices.dart';
import 'src/commands/doctor.dart';
import 'src/commands/drive.dart';
import 'src/commands/format.dart';
import 'src/commands/install.dart';
import 'src/commands/logs.dart';
import 'src/commands/packages.dart';
import 'src/commands/precache.dart';
import 'src/commands/run.dart';
import 'src/commands/screenshot.dart';
import 'src/commands/stop.dart';
import 'src/commands/test.dart';
import 'src/commands/trace.dart';
import 'src/commands/update_packages.dart';
import 'src/commands/upgrade.dart';
import 'src/devfs.dart';
import 'src/device.dart';
import 'src/doctor.dart';
import 'src/globals.dart';
import 'src/ios/mac.dart';
import 'src/ios/simulators.dart';
import 'src/run_hot.dart';
import 'src/runner/flutter_command_runner.dart';
import 'src/toolchain.dart';
import 'src/usage.dart';


/// Main entry point for commands.
///
/// This function is intended to be used from the `flutter` command line tool.
Future<Null> main(List<String> args) async {
  bool verbose = args.contains('-v') || args.contains('--verbose');
  bool help = args.contains('-h') || args.contains('--help') ||
      (args.isNotEmpty && args.first == 'help') || (args.length == 1 && verbose);
  bool verboseHelp = help && verbose;

  if (verboseHelp) {
    // Remove the verbose option; for help, users don't need to see verbose logs.
    args = new List<String>.from(args);
    args.removeWhere((String option) => option == '-v' || option == '--verbose');
  }

  FlutterCommandRunner runner = new FlutterCommandRunner(verboseHelp: verboseHelp)
    ..addCommand(new AnalyzeCommand(verboseHelp: verboseHelp))
    ..addCommand(new BuildCommand(verboseHelp: verboseHelp))
    ..addCommand(new ChannelCommand())
    ..addCommand(new ConfigCommand())
    ..addCommand(new CreateCommand())
    ..addCommand(new DaemonCommand(hidden: !verboseHelp))
    ..addCommand(new DevicesCommand())
    ..addCommand(new DoctorCommand())
    ..addCommand(new DriveCommand())
    ..addCommand(new FormatCommand())
    ..addCommand(new InstallCommand())
    ..addCommand(new LogsCommand())
    ..addCommand(new PackagesCommand())
    ..addCommand(new PrecacheCommand())
    ..addCommand(new RunCommand(verboseHelp: verboseHelp))
    ..addCommand(new ScreenshotCommand())
    ..addCommand(new StopCommand())
    ..addCommand(new TestCommand())
    ..addCommand(new TraceCommand())
    ..addCommand(new UpdatePackagesCommand(hidden: !verboseHelp))
    ..addCommand(new UpgradeCommand());

  // Construct a context.
  AppContext _executableContext = new AppContext();

  // Make the context current.
  await _executableContext.runInZone(() {
    // Initialize the context with some defaults.
    // NOTE: Similar lists also exist in `bin/fuchsia_builder.dart` and
    // `test/src/context.dart`. If you update this list of defaults, look
    // in those locations as well to see if you need a similar update there.

    // Seed these context entries first since others depend on them
    context.putIfAbsent(Platform, () => new LocalPlatform());
    context.putIfAbsent(FileSystem, () => new LocalFileSystem());
    context.putIfAbsent(ProcessManager, () => new LocalProcessManager());
    context.putIfAbsent(Logger, () => new StdoutLogger());

    // Order-independent context entries
    context.putIfAbsent(DeviceManager, () => new DeviceManager());
    context.putIfAbsent(DevFSConfig, () => new DevFSConfig());
    context.putIfAbsent(Doctor, () => new Doctor());
    context.putIfAbsent(HotRunnerConfig, () => new HotRunnerConfig());
    context.putIfAbsent(Cache, () => new Cache());
    context.putIfAbsent(ToolConfiguration, () => new ToolConfiguration());
    context.putIfAbsent(Config, () => new Config());
    context.putIfAbsent(OperatingSystemUtils, () => new OperatingSystemUtils());
    context.putIfAbsent(Xcode, () => new Xcode());
    context.putIfAbsent(IOSSimulatorUtils, () => new IOSSimulatorUtils());
    context.putIfAbsent(SimControl, () => new SimControl());
    context.putIfAbsent(Usage, () => new Usage());

    return Chain.capture<Future<Null>>(() async {
      await runner.run(args);
      _exit(0);
    }, onError: (dynamic error, Chain chain) {
      if (error is UsageException) {
        stderr.writeln(error.message);
        stderr.writeln();
        stderr.writeln(
            "Run 'flutter -h' (or 'flutter <command> -h') for available "
                "flutter commands and options."
        );
        // Argument error exit code.
        _exit(64);
      } else if (error is ToolExit) {
        if (error.message != null)
          stderr.writeln(error.message);
        if (verbose) {
          stderr.writeln();
          stderr.writeln(chain.terse.toString());
          stderr.writeln();
        }
        _exit(error.exitCode ?? 1);
      } else if (error is ProcessExit) {
        // We've caught an exit code.
        _exit(error.exitCode);
      } else {
        // We've crashed; emit a log report.
        stderr.writeln();

        flutterUsage.sendException(error, chain);

        if (isRunningOnBot) {
          // Print the stack trace on the bots - don't write a crash report.
          stderr.writeln('$error');
          stderr.writeln(chain.terse.toString());
          _exit(1);
        } else {
          if (error is String)
            stderr.writeln('Oops; flutter has exited unexpectedly: "$error".');
          else
            stderr.writeln('Oops; flutter has exited unexpectedly.');

          _createCrashReport(args, error, chain).then<Null>((File file) {
            stderr.writeln(
                'Crash report written to ${file.path};\n'
                    'please let us know at https://github.com/flutter/flutter/issues.'
            );
            _exit(1);
          });
        }
      }
    });
  });
}

Future<File> _createCrashReport(List<String> args, dynamic error, Chain chain) async {
  File crashFile = getUniqueFile(fs.currentDirectory, 'flutter', 'log');

  StringBuffer buffer = new StringBuffer();

  buffer.writeln('Flutter crash report; please file at https://github.com/flutter/flutter/issues.\n');

  buffer.writeln('## command\n');
  buffer.writeln('flutter ${args.join(' ')}\n');

  buffer.writeln('## exception\n');
  buffer.writeln('$error\n');
  buffer.writeln('```\n${chain.terse}```\n');

  buffer.writeln('## flutter doctor\n');
  buffer.writeln('```\n${await _doctorText()}```');

  try {
    crashFile.writeAsStringSync(buffer.toString());
  } on FileSystemException catch (_) {
    // Fallback to the system temporary directory.
    crashFile = getUniqueFile(fs.systemTempDirectory, 'flutter', 'log');
    try {
      crashFile.writeAsStringSync(buffer.toString());
    } on FileSystemException catch (e) {
      printError('Could not write crash report to disk: $e');
      printError(buffer.toString());
    }
  }

  return crashFile;
}

Future<String> _doctorText() async {
  try {
    BufferLogger logger = new BufferLogger();
    AppContext appContext = new AppContext();

    appContext.setVariable(Logger, logger);

    await appContext.runInZone(() => doctor.diagnose());

    return logger.statusText;
  } catch (error, trace) {
    return 'encountered exception: $error\n\n${trace.toString().trim()}\n';
  }
}

Future<Null> _exit(int code) async {
  if (flutterUsage.isFirstRun)
    flutterUsage.printUsage();

  // Send any last analytics calls that are in progress without overly delaying
  // the tool's exit (we wait a maximum of 250ms).
  if (flutterUsage.enabled) {
    Stopwatch stopwatch = new Stopwatch()..start();
    await flutterUsage.ensureAnalyticsSent();
    printTrace('ensureAnalyticsSent: ${stopwatch.elapsedMilliseconds}ms');
  }

  // Run shutdown hooks before flushing logs
  await runShutdownHooks();

  // Give the task / timer queue one cycle through before we hard exit.
  Timer.run(() {
    printTrace('exiting with code $code');
    exit(code);
  });
}
