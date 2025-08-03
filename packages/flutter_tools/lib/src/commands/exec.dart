// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import '../base/common.dart';
import '../base/process.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';

class ExecCommand extends FlutterCommand {
  ExecCommand() {
    requiresPubspecYaml();
    argParser.addFlag(
      'list',
      abbr: 'l',
      negatable: false,
      help: 'List all available scripts defined in pubspec.yaml.',
    );
  }

  @override
  String get name => 'exec';

  @override
  String get description => 'Execute scripts defined in pubspec.yaml.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  String get invocation => '${runner?.executableName} $name <script-name>';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject project = FlutterProject.current();
    final Map<String, String>? scripts = project.manifest.scripts;

    // Handle --list flag
    if (boolArg('list')) {
      if (scripts == null || scripts.isEmpty) {
        globals.printStatus('No scripts defined in pubspec.yaml');
      } else {
        globals.printStatus('Available scripts:');
        for (final MapEntry<String, String> script in scripts.entries) {
          globals.printStatus('  ${script.key}: ${script.value}');
        }
      }
      return const FlutterCommandResult(ExitStatus.success);
    }

    // Get script name from arguments
    final List<String> args = argResults?.rest ?? <String>[];
    if (args.isEmpty) {
      throwToolExit('No script name provided. Use "flutter exec --list" to see available scripts.');
    }

    final String scriptName = args.first;

    // Check if scripts are defined
    if (scripts == null || scripts.isEmpty) {
      throwToolExit('No scripts defined in pubspec.yaml');
    }

    // Check if the script exists
    final String? command = scripts[scriptName];
    if (command == null) {
      throwToolExit(
        'Script "$scriptName" not found in pubspec.yaml.\n'
        'Available scripts: ${scripts.keys.join(', ')}',
      );
    }

    // Execute the script
    globals.printStatus('Running script "$scriptName": $command');

    // Parse command to handle shell operators and quoted arguments
    final List<String> commandToRun = _parseShellCommand(command);

    // Run the command
    final processUtils = ProcessUtils(
      processManager: globals.processManager,
      logger: globals.logger,
    );

    final RunResult result = await processUtils.run(
      commandToRun,
      workingDirectory: project.directory.path,
      allowReentrantFlutter: true,
    );

    if (result.exitCode != 0) {
      if (result.stdout.isNotEmpty) {
        globals.printStatus(result.stdout);
      }
      if (result.stderr.isNotEmpty) {
        globals.printError(result.stderr);
      }
      throwToolExit('Script "$scriptName" failed with exit code ${result.exitCode}');
    }

    if (result.stdout.isNotEmpty) {
      globals.printStatus(result.stdout);
    }

    return const FlutterCommandResult(ExitStatus.success);
  }

  /// Parses a shell command string, handling quoted arguments and shell operators.
  ///
  /// For commands containing shell operators (&&, ||, |, ;) or complex quoting,
  /// delegates to the system shell. Otherwise, performs proper argument parsing
  /// that respects quoted strings.
  List<String> _parseShellCommand(String command) {
    // Check if command contains shell operators that require shell execution
    final shellOperators = <String>['&&', '||', '|', ';', '>', '<', '>>'];
    final bool hasShellOperators = shellOperators.any((String op) => command.contains(op));

    if (hasShellOperators) {
      // Delegate to system shell for complex commands
      if (io.Platform.isWindows) {
        return <String>['cmd', '/c', command];
      } else {
        return <String>['sh', '-c', command];
      }
    }

    // Parse simple commands with proper quote handling
    return _parseSimpleCommand(command);
  }

  /// Parses a simple command (no shell operators) with proper quote handling.
  List<String> _parseSimpleCommand(String command) {
    final result = <String>[];
    final currentArg = StringBuffer();
    var inSingleQuote = false;
    var inDoubleQuote = false;
    var escaped = false;

    for (var i = 0; i < command.length; i++) {
      final String char = command[i];

      if (escaped) {
        currentArg.write(char);
        escaped = false;
        continue;
      }

      if (char == r'\' && !inSingleQuote) {
        escaped = true;
        continue;
      }

      if (char == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
        continue;
      }

      if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }

      if (char == ' ' && !inSingleQuote && !inDoubleQuote) {
        if (currentArg.isNotEmpty) {
          result.add(currentArg.toString());
          currentArg.clear();
        }
        continue;
      }

      currentArg.write(char);
    }

    if (currentArg.isNotEmpty) {
      result.add(currentArg.toString());
    }

    return result;
  }
}
