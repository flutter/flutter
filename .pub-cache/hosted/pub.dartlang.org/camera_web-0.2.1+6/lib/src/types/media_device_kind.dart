// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A kind of a media device.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/MediaDeviceInfo/kind
abstract class MediaDeviceKind {
  /// A video input media device kind.
  static const String videoInput = 'videoinput';

  /// An audio input media device kind.
  static const String audioInput = 'audioinput';

  /// An audio output media device kind.
  static const String audioOutput = 'audiooutput';
}
