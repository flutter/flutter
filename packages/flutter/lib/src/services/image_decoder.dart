// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:mojo/core.dart' show MojoDataPipeConsumer;

Future<ui.Image> decodeImageFromDataPipe(MojoDataPipeConsumer consumerHandle) {
  Completer<ui.Image> completer = new Completer<ui.Image>();
  ui.decodeImageFromDataPipe(consumerHandle.handle.h, (ui.Image image) {
    completer.complete(image);
  });
  return completer.future;
}

Future<ui.Image> decodeImageFromList(Uint8List list) {
  Completer<ui.Image> completer = new Completer<ui.Image>();
  ui.decodeImageFromList(list, (ui.Image image) {
    completer.complete(image);
  });
  return completer.future;
}
