// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io show Directory, File, Platform, stderr;

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

// Path to root of the flutter/engine repository containing this script.
final String _engineRoot = path.dirname(path.dirname(path.dirname(path.dirname(path.fromUri(io.Platform.script)))));

/// A class for organizing the options to the Engine linter, and the files
/// that it operates on.
class Options {
  /// Builds an instance of [Options] from the arguments.
  Options({
    required this.buildCommandsPath,
    this.help = false,
    this.verbose = false,
    this.checksArg = '',
    this.lintAll = false,
    this.fix = false,
    this.errorMessage,
    StringSink? errSink,
  }) : checks = checksArg.isNotEmpty ? '--checks=$checksArg' : null,
       _errSink = errSink ?? io.stderr;

  factory Options._error(
    String message, {
    StringSink? errSink,
  }) {
    return Options(
      errorMessage: message,
      buildCommandsPath: io.File('none'),
      errSink: errSink,
    );
  }

  factory Options._help({
    StringSink? errSink,
  }) {
    return Options(
      help: true,
      buildCommandsPath: io.File('none'),
      errSink: errSink,
    );
  }

  /// Builds an [Options] instance with an [ArgResults] instance.
  factory Options._fromArgResults(
    ArgResults options, {
    required io.File buildCommandsPath,
    StringSink? errSink,
  }) {
    return Options(
      help: options['help'] as bool,
      verbose: options['verbose'] as bool,
      buildCommandsPath: buildCommandsPath,
      checksArg: options.wasParsed('checks') ? options['checks'] as String : '',
      lintAll: io.Platform.environment['FLUTTER_LINT_ALL'] != null ||
               options['lint-all'] as bool,
      fix: options['fix'] as bool,
      errSink: errSink,
    );
  }

  /// Builds an instance of [Options] from the given `arguments`.
  factory Options.fromCommandLine(
    List<String> arguments, {
    StringSink? errSink,
  }) {
    final ArgResults argResults = _argParser.parse(arguments);

    String? buildCommandsPath = argResults['compile-commands'] as String?;
    // path/to/engine/src/out/variant/compile_commands.json
    buildCommandsPath ??= path.join(
      argResults['src-dir'] as String,
      'out',
      argResults['target-variant'] as String,
      'compile_commands.json',
    );
    final io.File buildCommands = io.File(buildCommandsPath);
    final String? message = _checkArguments(argResults, buildCommands);
    if (message != null) {
      return Options._error(message, errSink: errSink);
    }
    if (argResults['help'] as bool) {
      return Options._help(errSink: errSink);
    }
    return Options._fromArgResults(
      argResults,
      buildCommandsPath: buildCommands,
      errSink: errSink,
    );
  }

  static final ArgParser _argParser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Print help.',
      negatable: false,
    )
    ..addFlag(
      'lint-all',
      help: 'lint all of the sources, regardless of FLUTTER_NOLINT.',
      defaultsTo: false,
    )
    ..addFlag(
      'fix',
      help: 'Apply suggested fixes.',
      defaultsTo: false,
    )
    ..addFlag(
      'verbose',
      help: 'Print verbose output.',
      defaultsTo: false,
    )
    ..addOption(
      'compile-commands',
      help: 'Use the given path as the source of compile_commands.json. This '
            'file is created by running "tools/gn". Cannot be used with --target-variant '
            'or --src-dir.',
    )
    ..addOption(
      'target-variant',
      aliases: <String>['variant'],
      help: 'The engine variant directory containing compile_commands.json '
            'created by running "tools/gn". Cannot be used with --compile-commands.',
      valueHelp: 'host_debug|android_debug_unopt|ios_debug|ios_debug_sim_unopt',
      defaultsTo: 'host_debug',
    )
    ..addOption(
      'src-dir',
      help: 'Path to the engine src directory. Cannot be used with --compile-commands.',
      valueHelp: 'path/to/engine/src',
      defaultsTo: path.dirname(_engineRoot),
    )
    ..addOption(
      'checks',
      help: 'Perform the given checks on the code. Defaults to the empty '
            'string, indicating all checks should be performed.',
      defaultsTo: '',
    );

  /// Whether to print a help message and exit.
  final bool help;

  /// Whether to run with verbose output.
  final bool verbose;

  /// The location of the compile_commands.json file.
  final io.File buildCommandsPath;

  /// The root of the flutter/engine repository.
  final io.Directory repoPath = io.Directory(_engineRoot);

  /// Arguments to plumb through to clang-tidy formatted as a command line
  /// argument.
  final String checksArg;

  /// Check arguments to plumb through to clang-tidy.
  final String? checks;

  /// Whether all files should be linted.
  final bool lintAll;

  /// Whether checks should apply available fix-ups to the working copy.
  final bool fix;

  /// If there was a problem with the command line arguments, this string
  /// contains the error message.
  final String? errorMessage;

  final StringSink _errSink;

  /// Print command usage with an additional message.
  void printUsage({String? message}) {
    if (message != null) {
      _errSink.writeln(message);
    }
    _errSink.writeln(
      'Usage: bin/main.dart [--help] [--lint-all] [--fix] [--verbose] [--diff-branch] [--target-variant variant] [--src-dir path/to/engine/src]',
    );
    _errSink.writeln(_argParser.usage);
  }

  /// Command line argument validation.
  static String? _checkArguments(ArgResults argResults, io.File buildCommandsPath) {
    if (argResults.wasParsed('help')) {
      return null;
    }

    final bool compileCommandsParsed = argResults.wasParsed('compile-commands');
    if (compileCommandsParsed && argResults.wasParsed('target-variant')) {
      return 'ERROR: --compile-commands option cannot be used with --target-variant.';
    }

    if (compileCommandsParsed && argResults.wasParsed('src-dir')) {
      return 'ERROR: --compile-commands option cannot be used with --src-dir.';
    }

    if (!buildCommandsPath.existsSync()) {
      return "ERROR: Build commands path ${buildCommandsPath.absolute.path} doesn't exist.";
    }

    return null;
  }
}
