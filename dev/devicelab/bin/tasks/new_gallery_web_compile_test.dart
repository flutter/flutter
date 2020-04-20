// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

import 'package:flutter_devicelab/tasks/perf_tests.dart' show WebCompileTest;

Future<void> main() async {
  await task(const NewGalleryWebCompileTest().run);
}

/// Measures the time to compile the New Flutter Gallery to JavaScript
/// and the size of the compiled code.
class NewGalleryWebCompileTest {
  const NewGalleryWebCompileTest();

  String get metricKeyPrefix => 'new_gallery';

  /// Runs the test.
  Future<TaskResult> run() async {
    await gitClone(path: 'temp', repo: 'https://github.com/flutter/gallery.git');

    final Map<String, Object> metrics = <String, Object>{};

    final Stopwatch watch = Stopwatch();

    await inDirectory<TaskResult>('temp/gallery', () async {
      await flutter('doctor');
      await flutter('packages', options: <String>['get']);

      watch.start();

      await evalFlutter('build', options: <String>[
        'web',
        '-v',
        '--release',
        '--no-pub',
      ], environment: <String, String>{
        'FLUTTER_WEB': 'true',
      });

      watch.stop();

      const String js = 'temp/gallery/build/web/main.dart.js';
      await _measureSize(metricKeyPrefix, js, metrics);

      metrics['${metricKeyPrefix}_dart2js_millis'] = watch.elapsedMilliseconds;

      return null;
    });

    rmTree(Directory('temp'));

    return TaskResult.success(metrics, benchmarkScoreKeys: metrics.keys.toList());
  }

  static Future<void> _measureSize(String metric, String js, Map<String, Object> metrics) async {
    final ProcessResult result = await Process.run('du', <String>['-k', js]);
    await Process.run('gzip',<String>['-k', '9', js]);
    final ProcessResult resultGzip = await Process.run('du', <String>['-k', js + '.gz']);
    metrics['${metric}_dart2js_size'] = _parseDu(result.stdout as String);
    metrics['${metric}_dart2js_size_gzip'] = _parseDu(resultGzip.stdout as String);
  }

  static int _parseDu(String source) {
    return int.parse(source.split(RegExp(r'\s+')).first.trim());
  }
}
