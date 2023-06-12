// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Which camera to use when picking images/videos while source is `ImageSource.camera`.
///
/// Not every device supports both of the positions.
enum CameraDevice {
  /// Use the rear camera.
  ///
  /// In most of the cases, it is the default configuration.
  rear,

  /// Use the front camera.
  ///
  /// Supported on all iPhones/iPads and some Android devices.
  front,
}
