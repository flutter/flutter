// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';

import '../framework/metrics_center.dart';

class UploadMetricsCommand extends Command<void> {
  UploadMetricsCommand() {
    argParser.addOption('results-file', help: 'Test results JSON to upload to Cocoon.');
    argParser.addOption('commit-time', help: 'Commit time in UNIX timestamp');
    argParser.addOption(
      'task-name',
      help: '[Flutter infrastructure] Name of the task being run on.',
    );
    argParser.addOption(
      'benchmark-tags',
      help: '[Flutter infrastructure] Benchmark tags to surface on Skia Perf',
    );
  }

  @override
  String get name => 'upload-metrics';

  @override
  String get description => '[Flutter infrastructure] Upload results data to Cocoon/Skia Perf';

  @override
  Future<void> run() async {
    final String? resultsPath = argResults!['results-file'] as String?;
    final String? commitTime = argResults!['commit-time'] as String?;
    final String? taskName = argResults!['task-name'] as String?;
    final String? benchmarkTags = argResults!['benchmark-tags'] as String?;

    // Upload metrics to skia perf from test runner when `resultsPath` is specified.
    if (resultsPath != null) {
      await uploadToSkiaPerf(resultsPath, commitTime, taskName, benchmarkTags);
      print('Successfully uploaded metrics to skia perf');
    }
  }
}
