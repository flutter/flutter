// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:bazel_tools/bazel_tools.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Parses the repository's real `DEPS` file and checks the invariants the
/// generated Bazel files rely on.
void main() {
  final String repoRoot = findRepositoryRoot()!;
  final depsFile = io.File(p.join(repoRoot, 'DEPS'));

  late final DepsFile deps;

  setUpAll(() {
    deps = DepsFile.parse(depsFile.readAsStringSync(), fileName: depsFile.path);
  });

  test('parses without using anything outside the gclient subset', () {
    expect(deps.deps.length, greaterThan(50));
    expect(deps.gitDeps.length, greaterThan(20));
    expect(deps.cipdDeps.length, greaterThan(10));
    expect(deps.hooks, isNotEmpty);
    expect(deps.gclientGnArgsFile, isNotNull);
  });

  test('every dependency path is a normalized relative path', () {
    for (final Dep dep in deps.deps) {
      expect(p.posix.isRelative(dep.path), isTrue, reason: dep.path);
      expect(p.posix.normalize(dep.path), dep.path, reason: dep.path);
      expect(dep.path, isNot(contains('..')));
    }
  });

  test('every git dependency is pinned and fully substituted', () {
    final placeholder = RegExp(r'\{[A-Za-z_]+\}');
    for (final GitDep dep in deps.gitDeps) {
      expect(dep.revision, isNotNull, reason: dep.path);
      expect(dep.url, isNot(matches(placeholder)), reason: dep.path);
      expect(dep.revision, isNot(matches(placeholder)), reason: dep.path);
      expect(dep.url, startsWith('https://'), reason: dep.path);
    }
  });

  test('every cipd package is substituted except for CIPD templates', () {
    // `${platform}` is expanded by CIPD, not gclient.
    final gclientPlaceholder = RegExp(r'(?<!\$)\{[A-Za-z_]+\}');
    for (final CipdDep dep in deps.cipdDeps) {
      expect(dep.packages, isNotEmpty, reason: dep.path);
      for (final CipdPackage package in dep.packages) {
        expect(package.package, isNot(matches(gclientPlaceholder)), reason: dep.path);
        expect(package.version, isNot(matches(gclientPlaceholder)), reason: dep.path);
      }
    }
  });

  test('the GN args gclient writes are declared in vars', () {
    for (final String arg in deps.gclientGnArgs) {
      expect(deps.vars, contains(arg));
    }
  });

  test('the generated files are up to date', () async {
    final GenDepsCommand command = GenDepsCommand.fromCommandLine(<String>[
      '--check',
      '--repo-root=$repoRoot',
    ])!;
    expect(
      await command.run(),
      0,
      reason: 'Run `dart $generatorLabel` from the repository root and commit the result.',
    );
  });
}
