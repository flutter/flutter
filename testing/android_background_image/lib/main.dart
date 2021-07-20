// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

final Completer<bool> _completer = Completer<bool>();

Future<void> main() async {
  channelBuffers.setListener('flutter/lifecycle', _lifecycle);
  final bool success = await _completer.future;
  final Uint8List? message = success ? null : Uint8List.fromList(const <int>[1]);
  PlatformDispatcher.instance.sendPlatformMessage('finish', message?.buffer.asByteData(), null);
}

Future<void> _lifecycle(ByteData? data, PlatformMessageResponseCallback? callback) async {
  final String lifecycleState = String.fromCharCodes(data!.buffer.asUint8List());
  if (lifecycleState == AppLifecycleState.paused.toString()) {
    await _testImage();
  }
}

Future<void> _testImage() async {
  // A single pixel image.
  final Uint8List pixels = Uint8List.fromList(const <int>[0, 1, 2, 3]);

  // As long as we're using the GL backend, this will go down a path that uses
  // a cross context image.
  final Completer<Image> imageCompleter = Completer<Image>();
  decodeImageFromPixels(
    pixels,
    1,
    1,
    PixelFormat.rgba8888,
    (Image image) {
      imageCompleter.complete(image);
    },
  );
  final Image image = await imageCompleter.future;
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawImage(image, Offset.zero, Paint());
  final Picture picture = recorder.endRecording();
  final Image newImage = await picture.toImage(1, 1);
  final ByteData imageData = (await newImage.toByteData())!;
  final Uint32List newPixels = imageData.buffer.asUint32List();

  if (pixels.buffer.asUint32List()[0] != newPixels[0]) {
    print('Pixels do not match');
    print('original pixels: $pixels');
    print('new pixels:      ${newPixels.buffer.asUint8List()}');
    _completer.complete(false);
  } else {
    print('Images are identical!');
    _completer.complete(true);
  }
}
