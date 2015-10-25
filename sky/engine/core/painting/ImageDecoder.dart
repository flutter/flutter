// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

class ImageDecoder extends _ImageDecoder {
  ImageDecoder.consume(int h, ImageDecoderCallback callback)
    : super(callback) {
    this._initWithConsumer(h);
  }

  ImageDecoder.fromList(Uint8List list, ImageDecoderCallback callback)
    : super(callback) {
    this._initWithList(list);
  }
}
