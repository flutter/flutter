// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:ui/src/engine.dart';

/// Holds the decoding result for a single frame of an animated image processed
/// by a native backend (CanvasKit or Skwasm).
///
/// This is a backend-agnostic equivalent of [ui.FrameInfo], containing a
/// [BackendImage] representing the GPU texture or Skia image, and the [duration]
/// for which this frame should be displayed.
class BackendFrameInfo {
  BackendFrameInfo({required this.duration, required this.image});

  /// The duration this frame should be shown.
  final Duration duration;

  /// The underlying backend-specific representation of the image frame.
  final BackendImage image;
}

/// An abstract contract defining the interface for a backend-specific, multi-frame
/// animated image decoder (e.g., CkAnimatedImage for CanvasKit and
/// SkwasmAnimatedImageDecoder for Skwasm).
///
/// The shared frontend (`EngineCodec`) is responsible for high-level codec state,
/// while the concrete backends act as frame extractors that implement this contract.
abstract class BackendAnimatedImage {
  /// The total number of frames in the animated image.
  int get frameCount;

  /// The number of times this animation should repeat.
  ///
  /// A value of -1 indicates infinite repetition, while 0 indicates the animation
  /// should play once (no repetitions).
  int get repetitionCount;

  /// Decodes and returns the next frame of the animation.
  ///
  /// When called, the implementation should extract the current frame, prepare
  /// the decoder to advance to the next frame, and return a [BackendFrameInfo]
  /// containing the frame's image and duration.
  Future<BackendFrameInfo> getNextFrame();

  /// Releases all native resources associated with the animated decoder.
  void dispose();
}
