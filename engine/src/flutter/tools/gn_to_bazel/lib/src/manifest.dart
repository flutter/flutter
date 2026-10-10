// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The GN files whose `BUILD.bazel` the converter generates, with what each
/// one needs beyond the mechanical conversion.
///
/// `dart bin/gn_to_bazel.dart` with no arguments regenerates them all;
/// `--check` verifies that the checked-in files are what the converter
/// produces, which is the presubmit.
library;

/// One generated file.
final class ConvertedFile {
  const ConvertedFile(this.gnPackage, {this.skip = const <String, String>{}, this.appendix});

  /// The GN directory (`//flutter/fml`); the input is its `BUILD.gn`.
  final String gnPackage;

  /// Targets not to convert, with the reason for each. These are the
  /// targets whose dependencies have no Bazel build yet, or which use a
  /// template the converter does not know; the list shrinks as the
  /// migration proceeds.
  final Map<String, String> skip;

  /// Starlark appended verbatim to the generated file: what the GN file has
  /// no way to express.
  final String? appendix;
}

const List<ConvertedFile> convertedFiles = <ConvertedFile>[
  ConvertedFile(
    '//flutter/fml',
    skip: <String, String>{'fml_benchmarks': 'needs //flutter/benchmarking'},
  ),
  ConvertedFile(
    '//flutter/testing',
    skip: <String, String>{
      'testing_lib': 'needs //flutter/display_list',
      'testing': 'needs testing_lib',
      'dart': 'needs //flutter/runtime',
      'skia': 'needs //flutter/skia',
      'vmservice_kernel': 'dart_snapshot_kernel template',
      'vmservice_snapshot': 'dart_snapshot_aot template',
      'fixture_test': 'needs //flutter/runtime',
      'vulkan': 'needs //flutter/vulkan',
      'test_swiftshader_utils': 'needs //flutter/third_party/swiftshader',
      'test_swangle_utils': 'needs //flutter/third_party/angle',
      'opengl': 'needs //flutter/third_party/angle',
    },
    // The fixtures macro in testing.bzl compiles this file into every
    // fixtures library, from whichever package declares one.
    appendix: '''
exports_files(["fixtures_location.cc"])
''',
  ),
];
