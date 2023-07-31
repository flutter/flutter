// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The top-level type inference error.
class TopLevelInferenceError {
  /// The kind of the error.
  final TopLevelInferenceErrorKind kind;

  /// The [kind] specific arguments.
  final List<String> arguments;

  TopLevelInferenceError({
    required this.kind,
    required this.arguments,
  });
}

/// Enum used to indicate the kind of the error during top-level inference.
enum TopLevelInferenceErrorKind {
  none,
  dependencyCycle,
  overrideNoCombinedSuperSignature,
}
