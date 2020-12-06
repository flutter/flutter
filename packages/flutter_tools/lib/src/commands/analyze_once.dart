// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../dart/analysis.dart';
import 'analyze_base.dart';

class AnalyzeOnce extends AnalyzeBase {
  AnalyzeOnce(
    ArgResults argResults,
    List<String> repoRoots,
    List<Directory> repoPackages, {
    @required FileSystem fileSystem,
    @required Logger logger,
    @required Platform platform,
    @required ProcessManager processManager,
    @required Terminal terminal,
    @required List<String> experiments,
    @required Artifacts artifacts,
    this.workingDirectory,
  }) : super(
        argResults,
        repoRoots: repoRoots,
        repoPackages: repoPackages,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
        terminal: terminal,
        experiments: experiments,
        artifacts: artifacts,
      );

  /// The working directory for testing analysis using dartanalyzer.
  final Directory workingDirectory;

  @override
  Future<void> analyze() async {
    final String currentDirectory =
        (workingDirectory ?? fileSystem.currentDirectory).path;

    // find directories from argResults.rest
    final Set<String> directories = Set<String>.of(argResults.rest
        .map<String>((String path) => fileSystem.path.canonicalize(path)));
    if (directories.isNotEmpty) {
      for (final String directory in directories) {
        final FileSystemEntityType type = fileSystem.typeSync(directory);

        if (type == FileSystemEntityType.notFound) {
          throwToolExit("'$directory' does not exist");
        } else if (type != FileSystemEntityType.directory) {
          throwToolExit("'$directory' is not a directory");
        }
      }
    }

    if (isFlutterRepo) {
      // check for conflicting dependencies
      final PackageDependencyTracker dependencies = PackageDependencyTracker();
      dependencies.checkForConflictingDependencies(repoPackages, dependencies);
      directories.addAll(repoRoots);
      if (argResults.wasParsed('current-package') && (argResults['current-package'] as bool)) {
        directories.add(currentDirectory);
      }
    } else {
      if (argResults['current-package'] as bool) {
        directories.add(currentDirectory);
      }
    }

    if (directories.isEmpty) {
      throwToolExit('Nothing to analyze.', exitCode: 0);
    }

    final Completer<void> analysisCompleter = Completer<void>();
    final List<AnalysisError> errors = <AnalysisError>[];

    final AnalysisServer server = AnalysisServer(
      sdkPath,
      directories.toList(),
      fileSystem: fileSystem,
      platform: platform,
      logger: logger,
      processManager: processManager,
      terminal: terminal,
      experiments: experiments,
    );

    Stopwatch timer;
    Status progress;
    try {
      StreamSubscription<bool> subscription;

      void handleAnalysisStatus(bool isAnalyzing) {
        if (!isAnalyzing) {
          analysisCompleter.complete();
          subscription?.cancel();
          subscription = null;
        }
      }

      subscription = server.onAnalyzing.listen((bool isAnalyzing) => handleAnalysisStatus(isAnalyzing));

      void handleAnalysisErrors(FileAnalysisErrors fileErrors) {
        fileErrors.errors.removeWhere((AnalysisError error) => error.type == 'TODO');

        errors.addAll(fileErrors.errors);
      }

      server.onErrors.listen(handleAnalysisErrors);

      await server.start();
      // Completing the future in the callback can't fail.
      unawaited(server.onExit.then<void>((int exitCode) {
        if (!analysisCompleter.isCompleted) {
          analysisCompleter.completeError('analysis server exited: $exitCode');
        }
      }));

      // collect results
      timer = Stopwatch()..start();
      final String message = directories.length > 1
          ? '${directories.length} ${directories.length == 1 ? 'directory' : 'directories'}'
          : fileSystem.path.basename(directories.first);
      progress = argResults['preamble'] as bool
          ? logger.startProgress(
            'Analyzing $message...',
            timeout: timeoutConfiguration.slowOperation,
          )
          : null;

      await analysisCompleter.future;
    } finally {
      await server.dispose();
      progress?.cancel();
      timer?.stop();
    }

    final int undocumentedMembers = AnalyzeBase.countMissingDartDocs(errors);
    if (!isDartDocs) {
      errors.removeWhere((AnalysisError error) => error.code == 'public_member_api_docs');
    }

    // emit benchmarks
    if (isBenchmarking) {
      writeBenchmark(timer, errors.length, undocumentedMembers);
    }

    // --write
    dumpErrors(errors.map<String>((AnalysisError error) => error.toLegacyString()));

    // report errors
    if (errors.isNotEmpty && (argResults['preamble'] as bool)) {
      logger.printStatus('');
    }
    errors.sort();
    for (final AnalysisError error in errors) {
      logger.printStatus(error.toString(), hangingIndent: 7);
    }

    final int errorCount = errors.length;
    final String seconds = (timer.elapsedMilliseconds / 1000.0).toStringAsFixed(1);
    final String dartDocMessage = AnalyzeBase.generateDartDocMessage(undocumentedMembers);
    final String errorsMessage = AnalyzeBase.generateErrorsMessage(
      issueCount: errorCount,
      seconds: seconds,
      undocumentedMembers: undocumentedMembers,
      dartDocMessage: dartDocMessage,
    );

    if (errorCount > 0) {
      logger.printStatus('');
      // We consider any level of error to be an error exit (we don't report different levels).
      throwToolExit(errorsMessage);
    }

    if (argResults['congratulate'] as bool) {
      logger.printStatus(errorsMessage);
    }

    if (server.didServerErrorOccur) {
      throwToolExit('Server error(s) occurred. (ran in ${seconds}s)');
    }
  }
}
