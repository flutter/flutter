// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/framework.dart';
import '../framework/utils.dart';

/// Run each benchmark this many times and compute average.
const int _kRunsPerBenchmark = 3;

/// Runs a benchmark once and reports the result as a lower-is-better numeric
/// value.
typedef Future<double> _Benchmark();

/// Path to the generated "mega gallery" app.
Directory get _megaGalleryDirectory => dir(path.join(Directory.systemTemp.path, 'mega_gallery'));

Future<TaskResult> analyzerBenchmarkTask() async {
  await inDirectory(flutterDirectory, () async {
    rmTree(_megaGalleryDirectory);
    mkdirs(_megaGalleryDirectory);
    await dart(<String>['dev/tools/mega_gallery.dart', '--out=${_megaGalleryDirectory.path}']);
  });

  final Map<String, dynamic> data = <String, dynamic>{
    'flutter_repo_batch': await _run(new _FlutterRepoBenchmark()),
    'flutter_repo_watch': await _run(new _FlutterRepoBenchmark(watch: true)),
    'mega_gallery_batch': await _run(new _MegaGalleryBenchmark()),
    'mega_gallery_watch': await _run(new _MegaGalleryBenchmark(watch: true)),
  };

  return new TaskResult.success(data, benchmarkScoreKeys: data.keys.toList());
}

/// Times how long it takes to analyze the Flutter repository.
class _FlutterRepoBenchmark {
  _FlutterRepoBenchmark({ this.watch = false });

  final bool watch;

  Future<double> call() async {
    section('Analyze Flutter repo ${watch ? 'with watcher' : ''}');
    final Stopwatch stopwatch = new Stopwatch();
    await inDirectory(flutterDirectory, () async {
      final List<String> options = <String>[
        '--flutter-repo',
        '--benchmark',
      ];

      if (watch)
        options.add('--watch');

      stopwatch.start();
      await flutter('analyze', options: options);
      stopwatch.stop();
    });
    return stopwatch.elapsedMilliseconds / 1000;
  }
}

/// Times how long it takes to analyze the generated "mega_gallery" app.
class _MegaGalleryBenchmark {
  _MegaGalleryBenchmark({ this.watch = false });

  final bool watch;

  Future<double> call() async {
    section('Analyze mega gallery ${watch ? 'with watcher' : ''}');
    final Stopwatch stopwatch = new Stopwatch();
    await inDirectory(_megaGalleryDirectory, () async {
      final List<String> options = <String>[
        '--benchmark',
      ];

      if (watch)
        options.add('--watch');

      stopwatch.start();
      await flutter('analyze', options: options);
      stopwatch.stop();
    });
    return stopwatch.elapsedMilliseconds / 1000;
  }
}

/// Runs a [benchmark] several times and reports the average result.
Future<double> _run(_Benchmark benchmark) async {
  double total = 0.0;
  for (int i = 0; i < _kRunsPerBenchmark; i++) {
    // Delete cached analysis results.
    rmTree(dir('${Platform.environment['HOME']}/.dartServer'));

    total += await benchmark();
  }
  final double average = total / _kRunsPerBenchmark;
  return average;
}
