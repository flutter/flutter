// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:clang_tidy/clang_tidy.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// The command that implements the pre-push githook
class PrePushCommand extends Command<bool> {
  @override
  final String name = 'pre-push';

  @override
  final String description = 'Checks to run before a "git push"';

  @override
  Future<bool> run() async {
    final Stopwatch sw = Stopwatch()..start();
    final bool verbose = globalResults!['verbose']! as bool;
    final bool enableClangTidy = globalResults!['enable-clang-tidy']! as bool;
    final String flutterRoot = globalResults!['flutter']! as String;

    if (!enableClangTidy) {
      print(
        'The clang-tidy check was explicitly disabled. To enable clear '
        'the environment variable PRE_PUSH_CLANG_TIDY or set it to true.');
    }

    final List<bool> checkResults = <bool>[
      await _runFormatter(flutterRoot, verbose),
      if (enableClangTidy)
        await _runClangTidy(flutterRoot, verbose),
    ];
    sw.stop();
    io.stdout.writeln('pre-push checks finished in ${sw.elapsed}');
    return !checkResults.contains(false);
  }

  /// Different `host_xxx` targets are built depending on the host platform.
  @visibleForTesting
  static const List<String> supportedHostTargets = <String>[
    'host_debug_unopt_arm64',
    'host_debug_arm64',
    'host_debug_unopt',
    'host_debug',
  ];

  Future<bool> _runClangTidy(String flutterRoot, bool verbose) async {
    io.stdout.writeln('Starting clang-tidy checks.');
    final Stopwatch sw = Stopwatch()..start();

    // First ensure that out/host_{{flags}}/compile_commands.json exists by running
    // //flutter/tools/gn. See _checkForHostTargets above for supported targets.
    final io.File? compileCommands = findMostRelevantCompileCommands(flutterRoot, verbose: verbose);
    if (compileCommands == null) {
      io.stderr.writeln(
        'clang-tidy requires a fully built host directory, such as: '
        '${supportedHostTargets.join(', ')}.'
      );
      return false;
    }

    // Because we are using a heuristic to pick a host build directory, we
    // should print some debug information explaining which directory we picked.
    io.stdout.writeln('Using compile_commands.json from ${compileCommands.parent.path}');

    final StringBuffer outBuffer = StringBuffer();
    final StringBuffer errBuffer = StringBuffer();
    final ClangTidy clangTidy = ClangTidy(
      buildCommandsPath: compileCommands,
      configPath: io.File(path.join(flutterRoot, '.clang-tidy-for-githooks')),
      excludeSlowChecks: true,
      outSink: outBuffer,
      errSink: errBuffer,
    );
    final int clangTidyResult = await clangTidy.run();
    sw.stop();
    io.stdout.writeln('clang-tidy checks finished in ${sw.elapsed}');
    if (clangTidyResult != 0) {
      io.stderr.write(errBuffer);
      return false;
    }
    return true;
  }

  /// Returns the most recent `compile_commands.json` for the given root.
  ///
  /// For example, if the following builds exist with the following timestamps:
  ///
  /// ```txt
  /// <filename>                                       <last modified>
  /// out/host_debug_unopt_arm64/compile_commands.json 1/1/2023
  /// out/host_debug_arm64/compile_commands.json       1/2/2023
  /// out/host_debug_unopt/compile_commands.json       1/3/2023
  /// out/host_debug/compile_commands.json             1/4/2023
  /// ```
  ///
  /// ... then the returned file will be `out/host_debug/compile_commands.json`.
  @visibleForTesting
  static io.File? findMostRelevantCompileCommands(String flutterRoot, {required bool verbose}) {
    final String engineRoot = path.normalize(path.join(flutterRoot, '../'));

    // Create a list of all the compile_commands.json files that exist,
    // including their last modified time.
    final List<(io.File, DateTime)> compileCommandsFiles = supportedHostTargets
      .map((String target) => io.File(path.join(engineRoot, 'out', target, 'compile_commands.json')))
      .where((io.File file) => file.existsSync())
      .map((io.File file) => (file, file.lastModifiedSync()))
      .toList();

    // Sort the list by last modified time, most recent first.
    compileCommandsFiles.sort(((io.File, DateTime) a, (io.File, DateTime) b) => b.$2.compareTo(a.$2));

    // If there are more than one entry, and we're in verbose mode, explain.
    if (verbose && compileCommandsFiles.length > 1) {
      io.stdout.writeln('Found multiple compile_commands.json files. Using the most recent one.');
      for (final (io.File file, DateTime lastModified) in compileCommandsFiles) {
        io.stdout.writeln('  ${file.path} (last modified: $lastModified)');
      }
    }

    // Return the first file in the list, or null if the list is empty.
    return compileCommandsFiles.firstOrNull?.$1;
  }

  Future<bool> _runFormatter(String flutterRoot, bool verbose) async {
    io.stdout.writeln('Starting formatting checks.');
    final Stopwatch sw = Stopwatch()..start();
    final String ext = io.Platform.isWindows ? '.bat' : '.sh';
    final bool result = await _runCheck(
      flutterRoot,
      path.join(flutterRoot, 'ci', 'format$ext'),
      <String>[],
      'Formatting check',
      verbose: verbose,
    );
    sw.stop();
    io.stdout.writeln('formatting checks finished in ${sw.elapsed}');
    return result;
  }

  Future<bool> _runCheck(
    String flutterRoot,
    String scriptPath,
    List<String> scriptArgs,
    String checkName, {
    bool verbose = false,
  }) async {
    if (verbose) {
      io.stdout.writeln('Starting "$checkName": $scriptPath');
    }
    final io.ProcessResult result = await io.Process.run(
      scriptPath,
      scriptArgs,
      workingDirectory: flutterRoot,
    );
    if (result.exitCode != 0) {
      final StringBuffer message = StringBuffer();
      message.writeln('Check "$checkName" failed.');
      message.writeln('command: $scriptPath ${scriptArgs.join(" ")}');
      message.writeln('working directory: $flutterRoot');
      message.writeln('exit code: ${result.exitCode}');
      message.writeln('stdout:');
      message.writeln(result.stdout);
      message.writeln('stderr:');
      message.writeln(result.stderr);
      io.stderr.write(message.toString());
      return false;
    }
    if (verbose) {
      io.stdout.writeln('Check "$checkName" finished successfully.');
    }
    return true;
  }
}
