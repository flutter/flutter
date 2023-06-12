// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'build_step.dart';

/// The basic builder class, used to build new files from existing ones.
abstract class Builder {
  /// Generates the outputs for a given [BuildStep].
  FutureOr<void> build(BuildStep buildStep);

  /// Mapping from input file extension to output file extensions.
  ///
  /// All input sources matching any key in this map will be passed as build
  /// step to this builder. Only files with the same basename and an extension
  /// from the values in this map are expected as outputs.
  ///
  /// - If an empty key exists, all inputs are considered matching.
  /// - A builder must always return the same configuration. Typically this will
  /// be `const` but may vary based on build arguments.
  /// - Most builders will use a single input extension and one or more output
  /// extensions.
  Map<String, List<String>> get buildExtensions;
}

class BuilderOptions {
  /// A configuration with no options set.
  static const empty = BuilderOptions({});

  /// A configuration with [isRoot] set to `true`, and no options set.
  static const forRoot = BuilderOptions({}, isRoot: true);

  /// The configuration to apply to a given usage of a [Builder].
  ///
  /// A `Map` parsed from json or yaml. The value types will be `String`, `num`,
  /// `bool` or `List` or `Map` of these types.
  final Map<String, dynamic> config;

  /// Whether or not this builder is running on the root package.
  final bool isRoot;

  const BuilderOptions(this.config, {this.isRoot = false});

  /// Returns a new set of options with keys from [other] overriding options in
  /// this instance.
  ///
  /// Config values are overridden at a per-key granularity. There is no value
  /// level merging. [other] may be null, in which case this instance is
  /// returned directly.
  ///
  /// The `isRoot` value will also be overridden to value from [other].
  BuilderOptions overrideWith(BuilderOptions? other) {
    if (other == null) return this;
    return BuilderOptions(
        {}
          ..addAll(config)
          ..addAll(other.config),
        isRoot: other.isRoot);
  }
}

/// Creates a [Builder] honoring the configuation in [options].
typedef BuilderFactory = Builder Function(BuilderOptions options);
