// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show Image, decodeImageFromList;

/// Creates an image from a list of bytes.
///
/// This function attempts to interpret the given bytes an image. If successful,
/// the returned [Future] resolves to the decoded image. Otherwise, the [Future]
/// resolves to null.
Future<ui.Image> decodeImageFromList(Uint8List list) {
  final Completer<ui.Image> completer = Completer<ui.Image>();
  ui.decodeImageFromList(list, completer.complete);
  return completer.future;
}
