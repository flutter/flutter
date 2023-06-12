// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The possible flash modes that can be set for a camera
enum FlashMode {
  /// Do not use the flash when taking a picture.
  off,

  /// Let the device decide whether to flash the camera when taking a picture.
  auto,

  /// Always use the flash when taking a picture.
  always,

  /// Turns on the flash light and keeps it on until switched off.
  torch,
}
