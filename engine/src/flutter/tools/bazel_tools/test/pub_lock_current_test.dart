// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:bazel_tools/bazel_tools.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// `build_defs/dart/pub.lock.bzl` against the locks it is generated from:
/// every hosted package of the workspace's `pubspec.lock`, and of
/// lib/web_ui's, is in the generated file at the lock's version and sha256,
/// and nothing else is. The dependency graph the generator also writes
/// comes from the packages' pubspecs (a pub cache), which this test does
/// without; `gen_pub_lock.dart --check` compares the whole file. A roll of
/// pubspec.lock without a rerun of the generator is what this catches (the
/// rebase of 10-30 left dap_adapters at 1.0.1 for the tool's tests while
/// the lock had moved to 1.1.0).
void main() {
  final String repoRoot = findRepositoryRoot()!;
  final String generated = io.File(p.join(repoRoot, 'build_defs', 'dart', 'pub.lock.bzl'))
      .readAsStringSync();

  // `"<name>": struct(` with `version` and `sha256` on the next two lines at
  // one deeper indentation: PUB_HOSTED's entries and a PUB_LOCKS entry's.
  final entry = RegExp(
    r'^( +)"([^"]+)": struct\(\n\1    version = "([^"]+)",\n\1    sha256 = "([^"]+)",',
    multiLine: true,
  );

  Map<String, (String, String)> pinsOf(String section) {
    return <String, (String, String)>{
      for (final RegExpMatch m in entry.allMatches(section)) m[2]!: (m[3]!, m[4]!),
    };
  }

  String between(String text, String start, String end) {
    final int from = text.indexOf(start);
    expect(from, isNot(-1), reason: 'pub.lock.bzl has no $start');
    final int to = text.indexOf(end, from + start.length);
    expect(to, isNot(-1), reason: 'pub.lock.bzl: $start is not closed by $end');
    return text.substring(from, to);
  }

  void expectCurrent(String lockPath, Map<String, (String, String)> pins) {
    final PubLock lock = PubLock.parse(
      io.File(p.join(repoRoot, lockPath)).readAsStringSync(),
      fileName: lockPath,
    );
    final expected = <String, (String, String)>{
      for (final HostedPackage package in lock.hosted.values)
        package.name: (package.version, package.sha256),
    };
    expect(
      pins,
      expected,
      reason:
          'build_defs/dart/pub.lock.bzl is out of date with $lockPath: run '
          '`dart bin/gen_pub_lock.dart` in engine/src/flutter/tools/bazel_tools',
    );
  }

  test('PUB_HOSTED is pubspec.lock', () {
    expectCurrent('pubspec.lock', pinsOf(between(generated, 'PUB_HOSTED = {', '\n}\n')));
  });

  test("PUB_LOCKS holds lib/web_ui's pubspec.lock", () {
    final String locks = between(generated, 'PUB_LOCKS = {', '\n}\n');
    final String webUi = between(locks, '"engine/src/flutter/lib/web_ui": struct(', '\n    ),');
    expectCurrent('engine/src/flutter/lib/web_ui/pubspec.lock', pinsOf(webUi));
  });
}
