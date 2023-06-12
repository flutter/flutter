// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:logging/logging.dart';

import 'package:build_runner/src/build_script_generate/bootstrap.dart';
import 'package:build_runner/src/entrypoint/options.dart';
import 'package:build_runner/src/entrypoint/runner.dart';
import 'package:build_runner/src/logging/std_io_logging.dart';

import 'src/commands/clean.dart';
import 'src/commands/generate_build_script.dart';

Future<void> main(List<String> args) async {
  // Use the actual command runner to parse the args and immediately print the
  // usage information if there is no command provided or the help command was
  // explicitly invoked.
  var commandRunner =
      BuildCommandRunner([], await PackageGraph.forThisPackage());
  var localCommands = [CleanCommand(), GenerateBuildScript()];
  var localCommandNames = localCommands.map((c) => c.name).toSet();
  for (var command in localCommands) {
    commandRunner.addCommand(command);
    // This flag is added to each command individually and not the top level.
    command.argParser.addFlag(verboseOption,
        abbr: 'v',
        defaultsTo: false,
        negatable: false,
        help: 'Enables verbose logging.');
  }

  ArgResults parsedArgs;
  try {
    parsedArgs = commandRunner.parse(args);
  } on UsageException catch (e) {
    print(red.wrap(e.message));
    print('');
    print(e.usage);
    exitCode = ExitCode.usage.code;
    return;
  }

  var commandName = parsedArgs.command?.name;

  if (parsedArgs.rest.isNotEmpty) {
    print(
        yellow.wrap('Could not find a command named "${parsedArgs.rest[0]}".'));
    print('');
    print(commandRunner.usageWithoutDescription);
    exitCode = ExitCode.usage.code;
    return;
  }

  if (commandName == 'help' ||
      parsedArgs.wasParsed('help') ||
      (parsedArgs.command?.wasParsed('help') ?? false)) {
    await commandRunner.runCommand(parsedArgs);
    return;
  }

  if (commandName == null) {
    commandRunner.printUsage();
    exitCode = ExitCode.usage.code;
    return;
  }

  StreamSubscription logListener;
  if (commandName == 'daemon') {
    // Simple logs only in daemon mode. These get converted into info or
    // severe logs by the client.
    logListener = Logger.root.onRecord.listen((record) {
      if (record.level >= Level.SEVERE) {
        var buffer = StringBuffer(record.message);
        if (record.error != null) buffer.writeln(record.error);
        if (record.stackTrace != null) buffer.writeln(record.stackTrace);
        stderr.writeln(buffer);
      } else {
        stdout.writeln(record.message);
      }
    });
  } else {
    var verbose = parsedArgs.command['verbose'] as bool ?? false;
    if (verbose) Logger.root.level = Level.ALL;
    logListener =
        Logger.root.onRecord.listen(stdIOLogListener(verbose: verbose));
  }
  if (localCommandNames.contains(commandName)) {
    exitCode = await commandRunner.runCommand(parsedArgs);
  } else {
    while ((exitCode = await generateAndRun(args)) == ExitCode.tempFail.code) {}
  }
  await logListener?.cancel();
}
