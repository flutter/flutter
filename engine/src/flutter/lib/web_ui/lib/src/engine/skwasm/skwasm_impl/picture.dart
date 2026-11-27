// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

/// The Skwasm [BackendPicture], wrapping a native picture handle.
class SkwasmPicture implements BackendPicture {
  /// Wraps [handle], which this picture owns.
  SkwasmPicture(this.handle);

  /// The underlying native picture.
  final PictureHandle handle;

  @override
  ui.Rect get cullRect {
    return withStackScope((StackScope s) {
      final RawRect rect = s.allocFloatArray(4);
      pictureGetCullRect(handle, rect);
      return s.convertRectFromNative(rect);
    });
  }

  @override
  int get approximateBytesUsed => pictureApproximateBytesUsed(handle);

  @override
  bool get toImageSyncIsDeferred => true;

  @override
  BackendImage toImageSync(int width, int height, ui.TargetPixelFormat targetFormat) {
    return SkwasmImage(imageCreateFromPicture(handle, width, height));
  }

  @override
  void dispose() => pictureDispose(handle);
}

/// The Skwasm [BackendPictureRecorder], wrapping a native picture recorder
/// handle.
class SkwasmPictureRecorder implements BackendPictureRecorder {
  final PictureRecorderHandle _handle = pictureRecorderCreate();
  bool _disposed = false;

  @override
  BackendCanvas beginRecording(ui.Rect cullRect) {
    return SkwasmCanvas(
      withStackScope(
        (StackScope s) => pictureRecorderBeginRecording(_handle, s.convertRectToNative(cullRect)),
      ),
    );
  }

  @override
  BackendPicture endRecording() => SkwasmPicture(pictureRecorderEndRecording(_handle));

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    pictureRecorderDispose(_handle);
  }
}
