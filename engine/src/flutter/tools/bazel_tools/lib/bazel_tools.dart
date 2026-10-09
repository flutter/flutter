// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Tooling that keeps the Bazel workspace in sync with the rest of the
/// repository (`DEPS`, GN build configurations, ...).
library;

export 'src/check_hermeticity_command.dart';
export 'src/deps_file.dart';
export 'src/deps_outputs.dart';
export 'src/gen_deps_command.dart';
export 'src/hermeticity_check.dart';
