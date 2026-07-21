// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Represents an image managed by a specific graphics backend.
abstract class BackendImage {
  /// Disposes resources held by the backend image.
  void dispose();

  /// Returns whether this backend image is a clone of the [other] backend image.
  bool isCloneOf(BackendImage other);
}
