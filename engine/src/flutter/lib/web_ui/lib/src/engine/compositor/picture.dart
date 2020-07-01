// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

class CkPicture implements ui.Picture {
  final SkiaObject skPicture;
  final ui.Rect? cullRect;

  CkPicture(this.skPicture, this.cullRect);

  @override
  int get approximateBytesUsed => 0;

  @override
  void dispose() {
    skPicture.delete();
  }

  @override
  Future<ui.Image> toImage(int width, int height) {
    throw UnsupportedError('Picture.toImage not yet implemented for CanvasKit and HTML');
  }
}
