// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:args/args.dart';

import 'gen_deps_command.dart' show findRepositoryRoot;
import 'hermeticity_check.dart';

/// Runs `bazel aquery` for a target pattern and scans the resulting action
/// graph for references to the host (see `hermeticity_check.dart`).
final class CheckHermeticityCommand {
  CheckHermeticityCommand._({
    required this.repoRoot,
    required this.bazel,
    required this.pattern,
    required this.bazelArguments,
    required this.input,
    required this.policy,
    required this.verbose,
    required io.IOSink stdout,
    required io.IOSink stderr,
  }) : _stdout = stdout,
       _stderr = stderr;

  /// Parses [arguments] and creates the command.
  ///
  /// Prints usage and returns `null` when `--help` is requested or the
  /// arguments are invalid.
  static CheckHermeticityCommand? fromCommandLine(
    List<String> arguments, {
    io.IOSink? stdout,
    io.IOSink? stderr,
    String? workingDirectory,
  }) {
    final io.IOSink out = stdout ?? io.stdout;
    final io.IOSink err = stderr ?? io.stderr;
    final ArgResults results;
    try {
      results = argParser.parse(arguments);
    } on FormatException catch (e) {
      err
        ..writeln(e.message)
        ..writeln()
        ..writeln(usage);
      return null;
    }
    if (results.flag('help')) {
      out.writeln(usage);
      return null;
    }
    final String? input = results.option('input');
    String? repoRoot;
    if (input == null) {
      final String? repoRootArgument = results.option('repo-root');
      repoRoot = repoRootArgument ?? findRepositoryRoot(workingDirectory);
      if (repoRoot == null) {
        err.writeln(
          'Could not find the repository root (the directory containing DEPS) '
          'from the current directory; pass --repo-root.',
        );
        return null;
      }
    }
    return CheckHermeticityCommand._(
      repoRoot: repoRoot,
      bazel: results.option('bazel')!,
      pattern: results.option('pattern')!,
      bazelArguments: results.rest,
      input: input,
      policy: HermeticityPolicy(
        allowedAbsolutePaths: <String>[
          ...defaultAllowedAbsolutePaths,
          ...results.multiOption('allow'),
        ],
      ),
      verbose: results.flag('verbose'),
      stdout: out,
      stderr: err,
    );
  }

  /// The command-line options.
  static final ArgParser argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this help.')
    ..addOption(
      'pattern',
      defaultsTo: 'deps(//...)',
      help: 'The aquery expression selecting the actions to scan.',
      valueHelp: 'expression',
    )
    ..addOption(
      'bazel',
      defaultsTo: 'bazelisk',
      help: 'The Bazel executable to run from the repository root.',
      valueHelp: 'path',
    )
    ..addOption(
      'input',
      help:
          'Scan a saved `bazel aquery --output=jsonproto --include_param_files` '
          'document instead of running Bazel.',
      valueHelp: 'file',
    )
    ..addMultiOption(
      'allow',
      help:
          'An absolute path (or prefix) actions may mention, in addition to '
          '${defaultAllowedAbsolutePaths.join(', ')}.',
      valueHelp: 'path',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Print the number of actions scanned per mnemonic.',
    )
    ..addOption(
      'repo-root',
      help:
          'The repository root (the directory containing DEPS). Defaults to '
          'the checkout the current directory is in.',
      valueHelp: 'path',
    );

  /// Usage text.
  static String get usage =>
      'Usage: dart bin/check_hermeticity.dart [options] [-- <bazel options>]\n'
      '\n'
      'Fails if any action in the Bazel action graph mentions an absolute\n'
      'path outside the execution root, sets an unexpected environment\n'
      'variable, or (for C/C++ actions) runs a compiler other than the\n'
      "hermetic toolchains'. Options after `--` are passed to `bazel aquery`\n"
      '(for example `-- -c opt`).\n'
      '\n'
      '${argParser.usage}';

  /// The repository root Bazel runs in; `null` when scanning [input].
  final String? repoRoot;

  /// The Bazel executable.
  final String bazel;

  /// The aquery expression.
  final String pattern;

  /// Extra options for `bazel aquery` (configuration flags, typically).
  final List<String> bazelArguments;

  /// A saved aquery document to scan instead of running Bazel.
  final String? input;

  /// The rules to scan against.
  final HermeticityPolicy policy;

  /// Whether to print the per-mnemonic action counts.
  final bool verbose;

  final io.IOSink _stdout;
  final io.IOSink _stderr;

  /// Runs the command and returns the process exit code.
  Future<int> run() async {
    final String document;
    final String? inputPath = input;
    if (inputPath != null) {
      final file = io.File(inputPath);
      if (!file.existsSync()) {
        _stderr.writeln('No such file: $inputPath');
        return 1;
      }
      document = await file.readAsString();
    } else {
      final String? queried = await _runAquery();
      if (queried == null) {
        return 1;
      }
      document = queried;
    }

    final Object? decoded;
    try {
      decoded = json.decode(document);
    } on FormatException catch (e) {
      _stderr.writeln('Could not parse the action graph as JSON: ${e.message}');
      return 1;
    }
    if (decoded is! Map<String, Object?>) {
      _stderr.writeln('Could not parse the action graph: expected a JSON object.');
      return 1;
    }

    final HermeticityReport report = scanActionGraph(decoded, policy: policy);
    if (verbose) {
      final List<String> mnemonics = report.actionsByMnemonic.keys.toList()..sort();
      for (final mnemonic in mnemonics) {
        _stdout.writeln('${report.actionsByMnemonic[mnemonic]!.toString().padLeft(7)}  $mnemonic');
      }
    }
    final scanned = 'Scanned ${report.actionCount} actions of ${report.targetCount} targets';
    if (report.isHermetic) {
      _stdout.writeln('$scanned: no reference to the host found.');
      return 0;
    }
    _stderr.writeln('$scanned: ${report.violations.length} reference(s) to the host:');
    for (final HermeticityViolation violation in report.violations) {
      _stderr.writeln('  $violation');
    }
    return 1;
  }

  Future<String?> _runAquery() async {
    final arguments = <String>[
      'aquery',
      '--output=jsonproto',
      '--include_param_files',
      ...bazelArguments,
      pattern,
    ];
    if (verbose) {
      _stdout.writeln('Running: $bazel ${arguments.join(' ')} (in $repoRoot)');
    }
    final io.ProcessResult result;
    try {
      result = await io.Process.run(
        bazel,
        arguments,
        workingDirectory: repoRoot,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
    } on io.ProcessException catch (e) {
      _stderr.writeln('Could not run $bazel: ${e.message}');
      return null;
    }
    if (result.exitCode != 0) {
      _stderr
        ..writeln('$bazel aquery failed with exit code ${result.exitCode}:')
        ..write(result.stderr);
      return null;
    }
    return result.stdout as String;
  }
}
