// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import './base.dart';

/// A PickedFile is a cross-platform, simplified File abstraction.
///
/// It wraps the bytes of a selected file, and its (platform-dependant) path.
class PickedFile extends PickedFileBase {
  /// Construct a PickedFile object, from its `bytes`.
  ///
  /// Optionally, you may pass a `path`. See caveats in [PickedFileBase.path].
  PickedFile(String path) : super(path) {
    throw UnimplementedError(
        'PickedFile is not available in your current platform.');
  }
}
