// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:io' as io;

import 'package:args/command_runner.dart';

import 'build.dart';
import 'clean.dart';
import 'create_simulator.dart';
import 'licenses.dart';
import 'exceptions.dart';
import 'test_runner.dart';
import 'utils.dart';

CommandRunner runner = CommandRunner<bool>(
  'felt',
  'Command-line utility for building and testing Flutter web engine.',
)
  ..addCommand(CleanCommand())
  ..addCommand(CreateSimulatorCommand())
  ..addCommand(LicensesCommand())
  ..addCommand(TestCommand())
  ..addCommand(BuildCommand());

void main(List<String> args) async {
  if (args.isEmpty) {
    // The felt tool was invoked with no arguments. Print usage.
    runner.printUsage();
    io.exit(64); // Exit code 64 indicates a usage error.
  }

  _listenToShutdownSignals();

  int exitCode = -1;
  try {
    final bool result = (await runner.run(args)) as bool;
    if (result == false) {
      print('Sub-command returned false: `${args.join(' ')}`');
      exitCode = 1;
    }
  } on UsageException catch (e) {
    print(e);
    exitCode = 64; // Exit code 64 indicates a usage error.
  } on ToolException catch (e) {
    io.stderr.writeln(e.message);
    exitCode = 1;
  } on ProcessException catch (e) {
    io.stderr.writeln('description: ${e.description}'
        'executable: ${e.executable} '
        'arguments: ${e.arguments} '
        'exit code: ${e.exitCode}');
    exitCode = e.exitCode;
  } catch (e) {
    rethrow;
  } finally {
    await cleanup();
    // The exit code is changed by one of the branches.
    if (exitCode != -1) {
      io.exit(exitCode);
    }
  }

  // Sometimes the Dart VM refuses to quit.
  io.exit(io.exitCode);
}

void _listenToShutdownSignals() async {
  io.ProcessSignal.sigint.watch().listen((_) async {
    print('Received SIGINT. Shutting down.');
    await cleanup();
    io.exit(1);
  });

  // SIGTERM signals are not generated under Windows.
  // See https://docs.microsoft.com/en-us/previous-versions/xdkz3x12(v%3Dvs.140)
  if (!io.Platform.isWindows) {
    io.ProcessSignal.sigterm.watch().listen((_) async {
      await cleanup();
      print('Received SIGTERM. Shutting down.');
      io.exit(1);
    });
  }
}
