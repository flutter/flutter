// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'constants.dart';
import 'source.dart';

/// Abstract contract representing a build target.
///
/// Contains the metadata of the target (name, inputs, outputs, dependencies).
/// Host and extension packages extend this to add execution behaviors.
abstract class Target {
  const Target();

  /// The unique name of this target.
  String get name;

  /// The targets that this target depends on.
  List<Target> get dependencies;

  /// The input files of this target.
  List<Source> get inputs;

  /// The output files produced by this target.
  List<Source> get outputs;

  /// The depfiles associated with this target.
  List<String> get depfiles => const <String>[];

  /// The output directory pattern for this target.
  String get outputDir => kBuildDirPlaceholder;
}

/// A simple concrete implementation of [Target] to represent static metadata.
///
/// Used for declaring built-in target constants in core.
class SimpleTarget extends Target {
  const SimpleTarget({
    required this.name,
    this.dependencies = const <Target>[],
    this.depfiles = const <String>[],
    this.inputs = const <Source>[],
    this.outputDir = kBuildDirPlaceholder,
    this.outputs = const <Source>[],
  });

  @override
  final String name;

  @override
  final List<Target> dependencies;

  @override
  final List<String> depfiles;

  @override
  final List<Source> inputs;

  @override
  final String outputDir;

  @override
  final List<Source> outputs;
}
