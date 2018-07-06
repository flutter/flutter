// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../dart/analysis.dart';
import '../dart/sdk.dart' as sdk;
import '../globals.dart';
import 'analyze_base.dart';

class AnalyzeContinuously extends AnalyzeBase {
  AnalyzeContinuously(ArgResults argResults, this.repoRoots, this.repoPackages, {
    this.previewDart2 = false,
  }) : super(argResults);

  final List<String> repoRoots;
  final List<Directory> repoPackages;
  final bool previewDart2;

  String analysisTarget;
  bool firstAnalysis = true;
  Set<String> analyzedPaths = new Set<String>();
  Map<String, List<AnalysisError>> analysisErrors = <String, List<AnalysisError>>{};
  Stopwatch analysisTimer;
  int lastErrorCount = 0;
  Status analysisStatus;

  @override
  Future<Null> analyze() async {
    List<String> directories;

    if (argResults['dartdocs'])
      throwToolExit('The --dartdocs option is currently not supported when using --watch.');

    if (argResults['flutter-repo']) {
      final PackageDependencyTracker dependencies = new PackageDependencyTracker();
      dependencies.checkForConflictingDependencies(repoPackages, dependencies);

      directories = repoRoots;
      analysisTarget = 'Flutter repository';

      printTrace('Analyzing Flutter repository:');
      for (String projectPath in repoRoots) {
        printTrace('  ${fs.path.relative(projectPath)}');
      }
    } else {
      directories = <String>[fs.currentDirectory.path];
      analysisTarget = fs.currentDirectory.path;
    }

    final String sdkPath = argResults['dart-sdk'] ?? sdk.dartSdkPath;

    final AnalysisServer server = new AnalysisServer(sdkPath, directories, previewDart2: previewDart2);
    server.onAnalyzing.listen((bool isAnalyzing) => _handleAnalysisStatus(server, isAnalyzing));
    server.onErrors.listen(_handleAnalysisErrors);

    Cache.releaseLockEarly();

    await server.start();
    final int exitCode = await server.onExit;

    final String message = 'Analysis server exited with code $exitCode.';
    if (exitCode != 0)
      throwToolExit(message, exitCode: exitCode);
    printStatus(message);
  }

  void _handleAnalysisStatus(AnalysisServer server, bool isAnalyzing) {
    if (isAnalyzing) {
      analysisStatus?.cancel();
      if (!firstAnalysis)
        printStatus('\n');
      analysisStatus = logger.startProgress('Analyzing $analysisTarget...');
      analyzedPaths.clear();
      analysisTimer = new Stopwatch()..start();
    } else {
      analysisStatus?.stop();
      analysisTimer.stop();

      logger.printStatus(terminal.clearScreen(), newline: false);

      // Remove errors for deleted files, sort, and print errors.
      final List<AnalysisError> errors = <AnalysisError>[];
      for (String path in analysisErrors.keys.toList()) {
        if (fs.isFileSync(path)) {
          errors.addAll(analysisErrors[path]);
        } else {
          analysisErrors.remove(path);
        }
      }

      errors.sort();

      for (AnalysisError error in errors) {
        printStatus(error.toString());
        if (error.code != null)
          printTrace('error code: ${error.code}');
      }

      dumpErrors(errors.map<String>((AnalysisError error) => error.toLegacyString()));

      // Print an analysis summary.
      String errorsMessage;

      int issueCount = errors.length;
      final int issueDiff = issueCount - lastErrorCount;
      lastErrorCount = issueCount;

      final int undocumentedCount = errors.where((AnalysisError issue) {
        return issue.code == 'public_member_api_docs';
      }).length;

      if (firstAnalysis)
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found';
      else if (issueDiff > 0)
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found ($issueDiff new)';
      else if (issueDiff < 0)
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found (${-issueDiff} fixed)';
      else if (issueCount != 0)
        errorsMessage = '$issueCount ${pluralize('issue', issueCount)} found';
      else
        errorsMessage = 'no issues found';

      final String files = '${analyzedPaths.length} ${pluralize('file', analyzedPaths.length)}';
      final String seconds = (analysisTimer.elapsedMilliseconds / 1000.0).toStringAsFixed(2);
      printStatus('$errorsMessage • analyzed $files in $seconds seconds');

      if (firstAnalysis && isBenchmarking) {
        // We don't want to return a failing exit code based on missing documentation.
        issueCount -= undocumentedCount;

        writeBenchmark(analysisTimer, issueCount, undocumentedCount);
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
