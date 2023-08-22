// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Signature of the callback that receives progress updates as image chunks are
/// loaded.
typedef ImageCodecChunkCallback = void Function(
  int cumulativeBytesLoaded,
  int expectedTotalBytes,
);

/// Creates a [ui.Codec] for the image located at [uri].
///
/// The [chunkCallback] is called with progress updates as image chunks are
/// loaded.
Future<ui.Codec> createImageCodecFromUrl(
  Uri uri, {
  ImageCodecChunkCallback? chunkCallback,
}) {
  return renderer.instantiateImageCodecFromUrl(
    uri,
    chunkCallback: chunkCallback,
  );
}
