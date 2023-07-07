// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This is thrown when the plugin reports an error.
class CameraException implements Exception {
  /// Creates a new camera exception with the given error code and description.
  CameraException(this.code, this.description);

  /// Error code.
  // TODO(bparrishMines): Document possible error codes.
  // https://github.com/flutter/flutter/issues/69298
  String code;

  /// Textual description of the error.
  String? description;

  @override
  String toString() => 'CameraException($code, $description)';
}
