// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

typedef void _ImageDecoderCallback(Image result);

void decodeImageFromDataPipe(int handle, _ImageDecoderCallback callback)
    native "decodeImageFromDataPipe";

void decodeImageFromList(Uint8List list, _ImageDecoderCallback callback)
    native "decodeImageFromList";
