// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show LineSplitter, jsonDecode;
import 'dart:io' as io show File, stderr, stdout;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:process_runner/process_runner.dart';

import 'src/command.dart';
import 'src/git_repo.dart';
import 'src/options.dart';

const String _linterOutputHeader = '''
┌──────────────────────────┐
│ Engine Clang Tidy Linter │
└──────────────────────────┘
The following errors have been reported by the Engine Clang Tidy Linter.  For
more information on addressing these issues please see:
https://github.com/flutter/flutter/wiki/Engine-Clang-Tidy-Linter
''';

class _ComputeJobsResult {
  _ComputeJobsResult(this.jobs, this.sawMalformed);

  final List<WorkerJob> jobs;
  final bool sawMalformed;
}

enum _SetStatus {
  Intersection,
  Difference,
}

class _SetStatusCommand {
  _SetStatusCommand(this.setStatus, this.command);
  final _SetStatus setStatus;
  final Command command;
}

/// A class that runs clang-tidy on all or only the changed files in a git
/// repo.
class ClangTidy {
  /// Given the path to the build commands for a repo and its root, builds
  /// an instance of [ClangTidy].
  ///
  /// `buildCommandsPath` is the path to the build_commands.json file.
  /// `repoPath` is the path to the Engine repo.
  /// `checksArg` are specific checks for clang-tidy to do.
  /// `lintAll` when true indicates that all files should be linted.
  /// `outSink` when provided is the destination for normal log messages, which
  /// will otherwise go to stdout.
  /// `errSink` when provided is the destination for error messages, which
  /// will otherwise go to stderr.
  ClangTidy({
    required io.File buildCommandsPath,
    String checksArg = '',
    bool lintAll = false,
    bool lintHead = false,
    bool fix = false,
    StringSink? outSink,
    StringSink? errSink,
  }) :
    options = Options(
      buildCommandsPath: buildCommandsPath,
      checksArg: checksArg,
      lintAll: lintAll,
      lintHead: lintHead,
      fix: fix,
      errSink: errSink,
    ),
    _outSink = outSink ?? io.stdout,
    _errSink = errSink ?? io.stderr;

  /// Builds an instance of [ClangTidy] from a command line.
  ClangTidy.fromCommandLine(
    List<String> args, {
    StringSink? outSink,
    StringSink? errSink,
  }) :
    options = Options.fromCommandLine(args, errSink: errSink),
    _outSink = outSink ?? io.stdout,
    _errSink = errSink ?? io.stderr;

  /// The [Options] that specify how this [ClangTidy] operates.
  final Options options;
  final StringSink _outSink;
  final StringSink _errSink;

  /// Runs clang-tidy on the repo as specified by the [Options].
  Future<int> run() async {
    if (options.help) {
      options.printUsage();
      return 0;
    }

    if (options.errorMessage != null) {
      options.printUsage(message: options.errorMessage);
      return 1;
    }

    _outSink.writeln(_linterOutputHeader);

    final List<io.File> filesOfInterest = await computeFilesOfInterest();

    if (options.verbose) {
      _outSink.writeln('Checking lint in repo at ${options.repoPath.path}.');
      if (options.checksArg.isNotEmpty) {
        _outSink.writeln('Checking for specific checks: ${options.checks}.');
      }
      final int changedFilesCount = filesOfInterest.length;
      if (options.lintAll) {
        _outSink.writeln('Checking all $changedFilesCount files the repo dir.');
      } else {
        _outSink.writeln(
          'Dectected $changedFilesCount files that have changed',
        );
      }
    }

    final List<Object?> buildCommandsData = jsonDecode(
      options.buildCommandsPath.readAsStringSync(),
    ) as List<Object?>;
    final List<List<Object?>> shardBuildCommandsData = options
        .shardCommandsPaths
        .map((io.File file) =>
            jsonDecode(file.readAsStringSync()) as List<Object?>)
        .toList();
    final List<Command> changedFileBuildCommands = await getLintCommandsForFiles(
      buildCommandsData,
      filesOfInterest,
      shardBuildCommandsData,
      options.shardId,
    );

    if (changedFileBuildCommands.isEmpty) {
      _outSink.writeln(
        'No changed files that have build commands associated with them were '
        'found.',
      );
      return 0;
    }

    if (options.verbose) {
      _outSink.writeln(
        'Found ${changedFileBuildCommands.length} files that have build '
        'commands associated with them and can be lint checked.',
      );
    }

    final _ComputeJobsResult computeJobsResult = await _computeJobs(
      changedFileBuildCommands,
      options,
    );
    final int computeResult = computeJobsResult.sawMalformed ? 1 : 0;
    final List<WorkerJob> jobs = computeJobsResult.jobs;

    final int runResult = await _runJobs(jobs);
    _outSink.writeln('\n');
    if (computeResult + runResult == 0) {
      _outSink.writeln('No lint problems found.');
    } else {
      _errSink.writeln('Lint problems found.');
    }

    return computeResult + runResult > 0 ? 1 : 0;
  }

  /// The files with local modifications or all the files if `lintAll` was
  /// specified.
  @visibleForTesting
  Future<List<io.File>> computeFilesOfInterest() async {
    if (options.lintAll) {
      return options.repoPath
        .listSync(recursive: true)
        .whereType<io.File>()
        .toList();
    }

    final GitRepo repo = GitRepo(
      options.repoPath,
      verbose: options.verbose,
    );
    if (options.lintHead) {
      return repo.changedFilesAtHead;
    }
    return repo.changedFiles;
  }

  /// Returns f(n) = value(n * [shardCount] + [id]).
  Iterable<T> _takeShard<T>(Iterable<T> values, int id, int shardCount) sync* {
    int count = 0;
    for (final T val in values) {
      if (count % shardCount == id) {
        yield val;
      }
      count++;
    }
  }

  /// This returns a `_SetStatusCommand` for each [Command] in [items].
  /// `Intersection` if the Command shows up in [items] and its filePath in all
  /// [filePathSets], otherwise `Difference`.
  Iterable<_SetStatusCommand> _calcIntersection(
      Iterable<Command> items, Iterable<Set<String>> filePathSets) sync* {
    bool allSetsContain(Command command) {
      for (final Set<String> filePathSet in filePathSets) {
        if (!filePathSet.contains(command.filePath)) {
          return false;
        }
      }
      return true;
    }
    for (final Command command in items) {
      if (allSetsContain(command)) {
        yield _SetStatusCommand(_SetStatus.Intersection, command);
      } else {
        yield _SetStatusCommand(_SetStatus.Difference, command);
      }
    }
  }

  /// Given a build commands json file's contents in [buildCommandsData], and
  /// the [files] with local changes, compute the lint commands to run.  If
  /// build commands are supplied in [sharedBuildCommandsData] the intersection
  /// of those build commands will be calculated and distributed across
  /// instances via the [shardId].
  @visibleForTesting
  Future<List<Command>> getLintCommandsForFiles(
    List<Object?> buildCommandsData,
    List<io.File> files,
    List<List<Object?>> sharedBuildCommandsData,
    int? shardId,
  ) {
    final List<Command> totalCommands = <Command>[];
    if (sharedBuildCommandsData.isNotEmpty) {
      final List<Command> buildCommands = <Command>[
        for (Object? data in buildCommandsData)
          Command.fromMap((data as Map<String, Object?>?)!)
      ];
      final List<Set<String>> shardFilePaths = <Set<String>>[
        for (List<Object?> list in sharedBuildCommandsData)
          <String>{
            for (Object? data in list)
              Command.fromMap((data as Map<String, Object?>?)!).filePath
          }
      ];
      final Iterable<_SetStatusCommand> intersectionResults =
          _calcIntersection(buildCommands, shardFilePaths);
      for (final _SetStatusCommand result in intersectionResults) {
        if (result.setStatus == _SetStatus.Difference) {
          totalCommands.add(result.command);
        }
      }
      final List<Command> intersection = <Command>[
        for (_SetStatusCommand result in intersectionResults)
          if (result.setStatus == _SetStatus.Intersection) result.command
      ];
      // Make sure to sort results so the sharding scheme is guaranteed to work
      // since we are not sure if there is a defined order in the json file.
      intersection
          .sort((Command x, Command y) => x.filePath.compareTo(y.filePath));
      totalCommands.addAll(
          _takeShard(intersection, shardId!, 1 + sharedBuildCommandsData.length));
    } else {
      totalCommands.addAll(<Command>[
        for (Object? data in buildCommandsData)
          Command.fromMap((data as Map<String, Object?>?)!)
      ]);
    }
    return () async {
      final List<Command> result = <Command>[];
      for (final Command command in totalCommands) {
        final LintAction lintAction = await command.lintAction;
        // Short-circuit the expensive containsAny call for the many third_party files.
        if (lintAction != LintAction.skipThirdParty &&
            command.containsAny(files)) {
          result.add(command);
        }
      }
      return result;
    }();
  }

  Future<_ComputeJobsResult> _computeJobs(
    List<Command> commands,
    Options options,
  ) async {
    bool sawMalformed = false;
    final List<WorkerJob> jobs = <WorkerJob>[];
    for (final Command command in commands) {
      final String relativePath = path.relative(
        command.filePath,
        from: options.repoPath.parent.path,
      );
      final LintAction action = await command.lintAction;
      switch (action) {
        case LintAction.skipNoLint:
          _outSink.writeln('🔷 ignoring $relativePath (FLUTTER_NOLINT)');
        case LintAction.failMalformedNoLint:
          _errSink.writeln('❌ malformed opt-out $relativePath');
          _errSink.writeln(
            '   Required format: // FLUTTER_NOLINT: $issueUrlPrefix/ISSUE_ID',
          );
          sawMalformed = true;
        case LintAction.lint:
          _outSink.writeln('🔶 linting $relativePath');
          jobs.add(command.createLintJob(options));
        case LintAction.skipThirdParty:
          _outSink.writeln('🔷 ignoring $relativePath (third_party)');
        case LintAction.skipMissing:
          _outSink.writeln('🔷 ignoring $relativePath (missing)');
      }
    }
    return _ComputeJobsResult(jobs, sawMalformed);
  }

  static Iterable<String> _trimGenerator(String output) sync* {
    const LineSplitter splitter = LineSplitter();
    final List<String> lines = splitter.convert(output);
    bool isPrintingError = false;
    for (final String line in lines) {
      if (line.contains(': error:') || line.contains(': warning:')) {
        isPrintingError = true;
        yield line;
      } else if (line == ':') {
          isPrintingError = false;
      } else if (isPrintingError) {
        yield line;
      }
    }
  }

  /// Visible for testing.
  /// Function for trimming raw clang-tidy output.
  @visibleForTesting
  static String trimOutput(String output) => _trimGenerator(output).join('\n');

  Future<int> _runJobs(List<WorkerJob> jobs) async {
    int result = 0;
    final ProcessPool pool = ProcessPool();
    await for (final WorkerJob job in pool.startWorkers(jobs)) {
      if (job.result.exitCode == 0) {
        continue;
      }
      _errSink.writeln('❌ Failures for ${job.name}:');
      if (!job.printOutput) {
        final Exception? exception = job.exception;
        if (exception != null) {
          _errSink.writeln(trimOutput(exception.toString()));
        } else {
          _errSink.writeln(trimOutput(job.result.stdout));
        }
      }
      result = 1;
    }
    return result;
  }
}
