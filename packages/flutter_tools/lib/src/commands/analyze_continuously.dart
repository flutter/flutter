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
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../dart/analysis.dart';
import 'analyze_base.dart';

class AnalyzeContinuously extends AnalyzeBase {
  AnalyzeContinuously(
    ArgResults argResults,
    List<String> repoRoots,
    List<Directory> repoPackages, {
    @required FileSystem fileSystem,
    @required Logger logger,
    @required Terminal terminal,
    @required Platform platform,
    @required ProcessManager processManager,
    @required List<String> experiments,
    @required Artifacts artifacts,
  }) : super(
        argResults,
        repoPackages: repoPackages,
        repoRoots: repoRoots,
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        terminal: terminal,
        processManager: processManager,
        experiments: experiments,
        artifacts: artifacts,
      );

  String analysisTarget;
  bool firstAnalysis = true;
  Set<String> analyzedPaths = <String>{};
  Map<String, List<AnalysisError>> analysisErrors = <String, List<AnalysisError>>{};
  Stopwatch analysisTimer;
  int lastErrorCount = 0;
  Status analysisStatus;

  @override
  Future<void> analyze() async {
    List<String> directories;

    if (isFlutterRepo) {
      final PackageDependencyTracker dependencies = PackageDependencyTracker();
      dependencies.checkForConflictingDependencies(repoPackages, dependencies);

      directories = repoRoots;
      analysisTarget = 'Flutter repository';

      logger.printTrace('Analyzing Flutter repository:');
      for (final String projectPath in repoRoots) {
        logger.printTrace('  ${fileSystem.path.relative(projectPath)}');
      }
    } else {
      directories = <String>[fileSystem.currentDirectory.path];
      analysisTarget = fileSystem.currentDirectory.path;
    }

    final AnalysisServer server = AnalysisServer(
      sdkPath,
      directories,
      fileSystem: fileSystem,
      logger: logger,
      platform: platform,
      processManager: processManager,
      terminal: terminal,
      experiments: experiments,
    );
    server.onAnalyzing.listen((bool isAnalyzing) => _handleAnalysisStatus(server, isAnalyzing));
    server.onErrors.listen(_handleAnalysisErrors);

    await server.start();
    final int exitCode = await server.onExit;

    final String message = 'Analysis server exited with code $exitCode.';
    if (exitCode != 0) {
      throwToolExit(message, exitCode: exitCode);
    }
    logger.printStatus(message);

    if (server.didServerErrorOccur) {
      throwToolExit('Server error(s) occurred.');
    }
  }

  void _handleAnalysisStatus(AnalysisServer server, bool isAnalyzing) {
    if (isAnalyzing) {
      analysisStatus?.cancel();
      if (!firstAnalysis) {
        logger.printStatus('\n');
      }
      analysisStatus = logger.startProgress('Analyzing $analysisTarget...', timeout: timeoutConfiguration.slowOperation);
      analyzedPaths.clear();
      analysisTimer = Stopwatch()..start();
    } else {
      analysisStatus?.stop();
      analysisStatus = null;
      analysisTimer.stop();

      logger.printStatus(terminal.clearScreen(), newline: false);

      // Remove errors for deleted files, sort, and print errors.
      final List<AnalysisError> errors = <AnalysisError>[];
      for (final String path in analysisErrors.keys.toList()) {
        if (fileSystem.isFileSync(path)) {
          errors.addAll(analysisErrors[path]);
        } else {
          analysisErrors.remove(path);
        }
      }

      int issueCount = errors.length;

      // count missing dartdocs
      final int undocumentedMembers = AnalyzeBase.countMissingDartDocs(errors);
      if (!isDartDocs) {
        errors.removeWhere((AnalysisError error) => error.code == 'public_member_api_docs');
        issueCount -= undocumentedMembers;
      }

      errors.sort();

      for (final AnalysisError error in errors) {
        logger.printStatus(error.toString());
        if (error.code != null) {
          logger.printTrace('error code: ${error.code}');
        }
      }

      dumpErrors(errors.map<String>((AnalysisError error) => error.toLegacyString()));

      final int issueDiff = issueCount - lastErrorCount;
      lastErrorCount = issueCount;
      final String seconds = (analysisTimer.elapsedMilliseconds / 1000.0).toStringAsFixed(2);
      final String dartDocMessage = AnalyzeBase.generateDartDocMessage(undocumentedMembers);
      final String errorsMessage = AnalyzeBase.generateErrorsMessage(
        issueCount: issueCount,
        issueDiff: issueDiff,
        files: analyzedPaths.length,
        seconds: seconds,
        undocumentedMembers: undocumentedMembers,
        dartDocMessage: dartDocMessage,
      );

      logger.printStatus(errorsMessage);

      if (firstAnalysis && isBenchmarking) {
        writeBenchmark(analysisTimer, issueCount, undocumentedMembers);
        server.dispose().whenComplete(() { exit(issueCount > 0 ? 1 : 0); });
      }

      firstAnalysis = false;
    }
  }

  void _handleAnalysisErrors(FileAnalysisErrors fileErrors) {
    fileErrors.errors.removeWhere((AnalysisError error) => error.type == 'TODO');

    analyzedPaths.add(fileErrors.file);
    analysisErrors[fileErrors.file] = fileErrors.errors;
  }
}
