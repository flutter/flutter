// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Lists testing/run_tests.py keeps that a generated BUILD.bazel repeats.
///
/// `run_tests.py --type impeller-vulkan-sync-validation` runs a hand-picked
/// subset of impeller_unittests (its `VULKAN_SYNC_VALIDATION_TESTS`) with
/// the Vulkan validation layers' synchronization validation on. The Bazel
/// test of the same run is a variant of the suite in impeller's BUILD.bazel
/// (flutter_display_test_variant), whose gtest filter the converter reads
/// from the script when it generates the file -- so the list lives in one
/// place, and `gn_to_bazel --check` reports a BUILD file behind it.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'gn_ast.dart';

/// The script, relative to the source tree's root (engine/src).
const String runTestsScript = 'flutter/testing/run_tests.py';

/// The Python list run_tests.py names [name] (`NAME = [ ... ]` at the top
/// level: one quoted string per line, `#` comments between), in order.
/// Throws a [FormatException] when the script has no such list.
List<String> runTestsStringList(String source, String name) {
  final List<String> lines = source.split('\n');
  final int start = lines.indexWhere((String line) => line.startsWith('$name = ['));
  if (start < 0) {
    throw FormatException('$runTestsScript: no top-level `$name = [` list');
  }
  final entries = <String>[];
  final entry = RegExp(r'''^\s*'([^']*)',?\s*(#.*)?$''');
  for (final String line in lines.skip(start + 1)) {
    if (line.trim() == ']') {
      return entries;
    }
    final String stripped = line.trim();
    if (stripped.isEmpty || stripped.startsWith('#')) {
      continue;
    }
    final RegExpMatch? match = entry.firstMatch(line);
    if (match == null) {
      throw FormatException(
        '$runTestsScript: `$name` has an entry that is not a string: `$stripped`',
      );
    }
    entries.add(match.group(1)!);
  }
  throw FormatException('$runTestsScript: `$name = [` is not closed');
}

/// The tests of run_tests.py's `VULKAN_SYNC_VALIDATION_TESTS`.
List<String> vulkanSyncValidationTests(String source) =>
    runTestsStringList(source, 'VULKAN_SYNC_VALIDATION_TESTS');

/// Impeller's appendix: the suite's Vulkan synchronization validation run,
/// `run_tests.py --type impeller-vulkan-sync-validation` as a Bazel test
/// (run_impeller_vulkan_sync_validation_tests: impeller_unittests under the
/// display and the validation environment, the hand-picked tests, the
/// binary's `--enable_vulkan_sync_validation` switch).
String impellerAppendix(GnSourceTree tree) {
  final String source = File(p.join(tree.root, runTestsScript)).readAsStringSync();
  final List<String> tests = vulkanSyncValidationTests(source);
  final buffer = StringBuffer()
    ..writeln('load("//build_defs/testing:testing.bzl", "flutter_display_test_variant")')
    ..writeln()
    ..writeln('# run_tests.py --type impeller-vulkan-sync-validation: the hand-picked tests')
    ..writeln("# of its VULKAN_SYNC_VALIDATION_TESTS (the converter reads the script's list;")
    ..writeln('# tools/gn_to_bazel/lib/src/run_tests_lists.dart) with the Vulkan validation')
    ..writeln("# layers' synchronization validation on, under the display and the validation")
    ..writeln('# environment, as the suite above runs.')
    ..writeln('flutter_display_test_variant(')
    ..writeln('    name = "impeller_vulkan_sync_validation_unittests",')
    ..writeln('    size = "large",')
    ..writeln('    args = [')
    ..writeln('        "--gtest_filter=${tests.join(':')}",')
    ..writeln('        "--",')
    ..writeln('        "--enable_vulkan_sync_validation",')
    ..writeln('    ],')
    ..writeln('    data = [":gpu_test_backends"],')
    ..writeln('    target_compatible_with = select({')
    ..writeln('        "//engine/src/flutter/testing:unittests_enabled": [],')
    ..writeln('        "//conditions:default": ["@platforms//:incompatible"],')
    ..writeln('    }),')
    ..writeln('    test = ":impeller_unittests",')
    ..writeln(')');
  return buffer.toString();
}
