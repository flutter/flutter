// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import 'canvas.dart';
import 'image.dart';

/// The backend side of a recorded picture: a thin wrapper around the native
/// picture object of a specific renderer.
///
/// A [BackendPicture] is owned by `EnginePicture`, the `ui.Picture`
/// implementation shared by all renderers, which handles reference counting,
/// disposal checks, argument validation, and image retention.
/// Implementations only translate calls into native operations.
abstract class BackendPicture {
  /// A conservative bounding box of all the drawing operations in this
  /// picture.
  ui.Rect get cullRect;

  /// The approximate number of bytes used by this picture.
  int get approximateBytesUsed;

  /// Whether [toImageSync] returns an image that is rendered lazily the first
  /// time it is drawn, rather than one whose pixels are read back eagerly.
  ///
  /// Deferred images still reference the image sources recorded into this
  /// picture, so those sources must stay open for as long as the derived
  /// image is alive.
  bool get toImageSyncIsDeferred;

  /// Rasterizes this picture into a [width] by [height] image.
  ///
  /// The caller has already checked that [width] and [height] are positive.
  BackendImage toImageSync(int width, int height, ui.TargetPixelFormat targetFormat);

  /// Releases the native picture object.
  void dispose();
}

/// The backend side of a picture recorder: a thin wrapper around the native
/// picture recorder of a specific renderer.
///
/// A [BackendPictureRecorder] is owned by `EnginePictureRecorder`, which
/// enforces the single-use recording state machine. A backend recorder is
/// created right before recording begins and is used for exactly one
/// recording.
abstract class BackendPictureRecorder {
  /// Starts recording drawing operations bounded by [cullRect] and returns the
  /// native canvas that records them.
  BackendCanvas beginRecording(ui.Rect cullRect);

  /// Finishes the recording started by [beginRecording] and returns the
  /// recorded picture, which the caller owns.
  BackendPicture endRecording();

  /// Releases the native picture recorder.
  ///
  /// Must be safe to call whether or not recording has finished.
  void dispose();
}
