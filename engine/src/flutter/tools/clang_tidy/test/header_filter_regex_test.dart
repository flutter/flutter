// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart' as yaml;

/// Tests that `HeaderFilterRegex` works as expected in `.clang_tidy`.
void main() {
  // Find the root of the repo.
  final engine = Engine.findWithin();

  // Find the `.clang_tidy` file and "parse" it (it's YAML).
  final yaml.YamlDocument dotClangTidy = yaml.loadYamlDocument(
    File(path.join(engine.flutterDir.path, '.clang-tidy')).readAsStringSync(),
  );

  // Find the `HeaderFilterRegex` entry.
  if (dotClangTidy.contents is! yaml.YamlMap) {
    stderr.writeln('Expected .clang-tidy to be a YAML map.');
    exit(1);
  }
  final nodes = dotClangTidy.contents as yaml.YamlMap;
  final yaml.YamlNode? headerFilterRegex = nodes.nodes['HeaderFilterRegex'];
  if (headerFilterRegex == null) {
    stderr.writeln('Expected .clang-tidy to have a HeaderFilterRegex entry.');
    exit(1);
  }

  final regexValue = RegExp(headerFilterRegex.value.toString());

  test('contains every root directory in the regex', () {
    // These are a list of directories that should _not_ be included.
    const intentionallyOmitted = <String>{
      '.dart_tool',
      '.git',
      '.gemini',
      '.github',
      '.sourcekit-lsp',
      '.vscode',
      'build_overrides',
      'buildtools',
      'prebuilts',
      'third_party',
    };

    // Find all the directories in the repo root aside from the ones above.
    final rootDirs = <String>{};
    for (final FileSystemEntity entity in engine.flutterDir.listSync()) {
      if (entity is! Directory) {
        continue;
      }
      final String name = path.basename(entity.path);
      if (intentionallyOmitted.contains(name)) {
        continue;
      }
      rootDirs.add(name);
    }

    // Create a fake file in that path, and assert that it matches the regex,
    // as GN's compile commands spell it (from the build directory) and as
    // Bazel's do (from the execution root).
    for (final rootDir in rootDirs) {
      for (final file in <String>[
        path.join('..', '..', 'flutter', rootDir, 'foo'),
        path.join('engine', 'src', 'flutter', rootDir, 'foo'),
      ]) {
        expect(
          file,
          matches(regexValue),
          reason: '$rootDir/foo should be allowed by the regex but was not ($file).',
        );
      }
    }
  });

  test("matches the engine's headers under either build system's spelling", () {
    // GN: from the build directory.
    expect('../../flutter/fml/foo.h', matches(regexValue));
    // Bazel: from the execution root.
    expect('engine/src/flutter/fml/foo.h', matches(regexValue));
    // A header included relative to the main file is spelled under the
    // checkout's absolute path and matches under neither build system (GN
    // never linted those; the Bazel alternative is anchored so that the
    // generated headers under bazel-out/ stay out).
    expect('/abs/path/engine/src/flutter/impeller/x.h', isNot(matches(regexValue)));
  });

  test('does not match third_party or generated headers', () {
    expect('../../flutter/third_party/x/y.h', isNot(matches(regexValue)));
    expect('engine/src/flutter/third_party/x/y.h', isNot(matches(regexValue)));
    // GN's generated headers are under the build directory's gen/, Bazel's
    // under bazel-out/<configuration>/bin/.
    expect('gen/flutter/fml/gen.h', isNot(matches(regexValue)));
    expect('bazel-out/k8-opt/bin/engine/src/flutter/fml/gen.h', isNot(matches(regexValue)));
  });
}
