// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'builder.dart';
import 'post_process_build_step.dart';

/// A builder which runs in a special phase at the end of the build.
///
/// They are different from a normal [Builder] in several ways:
///
/// - They don't have to declare output extensions, and can output any file as
///   long as it doesn't conflict with an existing one.
/// - They can only read their primary input.
/// - They will not cause optional actions to run - they will only run on assets
///   that were built as a part of the normal build.
/// - They all run in a single phase, and thus can not see the outputs of any
///   other [PostProcessBuilder]s.
/// - Because they run in a separate phase, after other builders, none of thier
///   outputs can be consumed by [Builder]s.
///
/// Because of these restrictions, these builders should never be used to output
/// Dart files, or any other file which would should be processed by normal
/// [Builder]s.
abstract class PostProcessBuilder {
  /// The extensions this builder expects for its inputs.
  Iterable<String> get inputExtensions;

  /// Generates the outputs and deletes for [buildStep].
  FutureOr<void> build(PostProcessBuildStep buildStep);
}

typedef PostProcessBuilderFactory = PostProcessBuilder Function(BuilderOptions);
