// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:sky' show Image, ImageDecoder, ImageDecoderCallback;
import 'dart:typed_data';

import 'package:mojo/core.dart' show MojoDataPipeConsumer;

final Set<ImageDecoder> _activeDecoders = new Set<ImageDecoder>();

typedef ImageDecoder _DecoderFactory(ImageDecoderCallback callback);

Future<Image> _decode(_DecoderFactory createDecoder) {
  Completer<Image> completer = new Completer<Image>();
  ImageDecoder decoder;
  decoder = createDecoder((Image image) {
    _activeDecoders.remove(decoder);
    completer.complete(image);
  });
  _activeDecoders.add(decoder);
  return completer.future;
}

Future<Image> decodeImageFromDataPipe(MojoDataPipeConsumer consumerHandle) {
  return _decode((ImageDecoderCallback callback) => new ImageDecoder.consume(consumerHandle.handle.h, callback));
}

Future<Image> decodeImageFromList(Uint8List list) {
  return _decode((ImageDecoderCallback callback) => new ImageDecoder.fromList(list, callback));
}
