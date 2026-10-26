// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Converts the engine's GN build files to Bazel `BUILD.bazel` files.
///
/// Pipeline: `gn format --dump-tree=json` ([parseGnTree]) → symbolic
/// evaluation under a set of assumed argument values ([evaluateGnFile]) →
/// Starlark ([emitBuildFile]). Every construct outside the understood subset
/// is a [GnError] with a file and line.
library;

export 'src/bazel_mapping.dart';
export 'src/builders.dart';
export 'src/dependency_resolver.dart';
export 'src/felt_config.dart';
export 'src/gn_ast.dart';
export 'src/gn_eval.dart';
export 'src/manifest.dart';
export 'src/mirrored_lists.dart';
export 'src/starlark_emitter.dart';
