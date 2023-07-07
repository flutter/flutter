// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

/// Some hopefully real-world representative platform-independent paths.
const genericPaths = [
  '.',
  '..',
  'out/ReleaseIA32/packages',
  'lib',
  'lib/src/',
  'lib/src/style/url.dart',
  'test/./not/.././normalized',
  'benchmark/really/long/path/with/many/components.dart',
];

/// Some platform-specific paths.
final platformPaths = {
  p.Style.posix: [
    '/',
    '/home/user/dart/sdk/lib/indexed_db/dart2js/indexed_db_dart2js.dart',
  ],
  p.Style.url: [
    'https://example.server.org/443643002/path?top=yes#fragment',
  ],
  p.Style.windows: [
    r'C:\User\me\',
    r'\\server\share\my\folders\some\file.data',
  ],
};

/// The command line arguments passed to this script.
late final List<String> arguments;

void main(List<String> args) {
  arguments = args;

  for (var style in [p.Style.posix, p.Style.url, p.Style.windows]) {
    final context = p.Context(style: style);
    final files = <String>[...genericPaths, ...platformPaths[style]!];

    void benchmark(String name, void Function(String) function) {
      runBenchmark('${style.name}-$name', 100000, () {
        for (var file in files) {
          function(file);
        }
      });
    }

    void benchmarkPairs(String name, void Function(String, String) function) {
      runBenchmark('${style.name}-$name', 1000, () {
        for (var file1 in files) {
          for (var file2 in files) {
            function(file1, file2);
          }
        }
      });
    }

    benchmark('absolute', context.absolute);
    benchmark('basename', context.basename);
    benchmark('basenameWithoutExtension', context.basenameWithoutExtension);
    benchmark('dirname', context.dirname);
    benchmark('extension', context.extension);
    benchmark('rootPrefix', context.rootPrefix);
    benchmark('isAbsolute', context.isAbsolute);
    benchmark('isRelative', context.isRelative);
    benchmark('isRootRelative', context.isRootRelative);
    benchmark('normalize', context.normalize);
    benchmark('relative', context.relative);
    benchmarkPairs('relative from', (String file, String from) {
      try {
        context.relative(file, from: from);
      } on p.PathException {
        // Do nothing.
      }
    });
    benchmark('toUri', context.toUri);
    benchmark('prettyUri', context.prettyUri);
    benchmarkPairs('isWithin', context.isWithin);
  }

  runBenchmark('current', 100000, () => p.current);
}

void runBenchmark(String name, int count, void Function() function) {
  // If names are passed on the command-line, they select which benchmarks are
  // run.
  if (arguments.isNotEmpty && !arguments.contains(name)) return;

  // Warmup.
  for (var i = 0; i < 10000; i++) {
    function();
  }

  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < count; i++) {
    function();
  }

  final rate =
      (count / stopwatch.elapsedMicroseconds).toStringAsFixed(5).padLeft(9);
  print('${name.padLeft(32)}: $rate iter/us (${stopwatch.elapsed})');
}
