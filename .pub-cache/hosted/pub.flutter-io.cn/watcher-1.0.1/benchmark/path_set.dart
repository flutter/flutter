// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Benchmarks for the PathSet class.
library watcher.benchmark.path_set;

import 'dart:io';
import 'dart:math' as math;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:path/path.dart' as p;

import 'package:watcher/src/path_set.dart';

final String root = Platform.isWindows ? r'C:\root' : '/root';

/// Base class for benchmarks on [PathSet].
abstract class PathSetBenchmark extends BenchmarkBase {
  PathSetBenchmark(String method) : super('PathSet.$method');

  final PathSet pathSet = PathSet(root);

  /// Use a fixed [math.Random] with a constant seed to ensure the tests are
  /// deterministic.
  final math.Random random = math.Random(1234);

  /// Walks over a virtual directory [depth] levels deep invoking [callback]
  /// for each "file".
  ///
  /// Each virtual directory contains ten entries: either subdirectories or
  /// files.
  void walkTree(int depth, void Function(String) callback) {
    void recurse(String path, remainingDepth) {
      for (var i = 0; i < 10; i++) {
        var padded = i.toString().padLeft(2, '0');
        if (remainingDepth == 0) {
          callback(p.join(path, 'file_$padded.txt'));
        } else {
          var subdir = p.join(path, 'subdirectory_$padded');
          recurse(subdir, remainingDepth - 1);
        }
      }
    }

    recurse(root, depth);
  }
}

class AddBenchmark extends PathSetBenchmark {
  AddBenchmark() : super('add()');

  final List<String> paths = [];

  @override
  void setup() {
    // Make a bunch of paths in about the same order we expect to get them from
    // Directory.list().
    walkTree(3, paths.add);
  }

  @override
  void run() {
    for (var path in paths) {
      pathSet.add(path);
    }
  }
}

class ContainsBenchmark extends PathSetBenchmark {
  ContainsBenchmark() : super('contains()');

  final List<String> paths = [];

  @override
  void setup() {
    // Add a bunch of paths to the set.
    walkTree(3, (path) {
      pathSet.add(path);
      paths.add(path);
    });

    // Add some non-existent paths to test the false case.
    for (var i = 0; i < 100; i++) {
      paths.addAll([
        '/nope',
        '/root/nope',
        '/root/subdirectory_04/nope',
        '/root/subdirectory_04/subdirectory_04/nope',
        '/root/subdirectory_04/subdirectory_04/subdirectory_04/nope',
        '/root/subdirectory_04/subdirectory_04/subdirectory_04/nope/file_04.txt',
      ]);
    }
  }

  @override
  void run() {
    var contained = 0;
    for (var path in paths) {
      if (pathSet.contains(path)) contained++;
    }

    if (contained != 10000) throw 'Wrong result: $contained';
  }
}

class PathsBenchmark extends PathSetBenchmark {
  PathsBenchmark() : super('toSet()');

  @override
  void setup() {
    walkTree(3, pathSet.add);
  }

  @override
  void run() {
    var count = 0;
    for (var _ in pathSet.paths) {
      count++;
    }

    if (count != 10000) throw 'Wrong result: $count';
  }
}

class RemoveBenchmark extends PathSetBenchmark {
  RemoveBenchmark() : super('remove()');

  final List<String> paths = [];

  @override
  void setup() {
    // Make a bunch of paths. Do this here so that we don't spend benchmarked
    // time synthesizing paths.
    walkTree(3, (path) {
      pathSet.add(path);
      paths.add(path);
    });

    // Shuffle the paths so that we delete them in a random order that
    // hopefully mimics real-world file system usage. Do the shuffling here so
    // that we don't spend benchmarked time shuffling.
    paths.shuffle(random);
  }

  @override
  void run() {
    for (var path in paths) {
      pathSet.remove(path);
    }
  }
}

void main() {
  AddBenchmark().report();
  ContainsBenchmark().report();
  PathsBenchmark().report();
  RemoveBenchmark().report();
}
