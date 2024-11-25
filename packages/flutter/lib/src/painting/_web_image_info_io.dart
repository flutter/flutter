// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'image_stream.dart';

/// An [ImageInfo] object indicating that the image can only be displayed in
/// an <img> element, and no [dart:ui.Image] can be created for it.
///
/// This occurs on the web when the image resource is from a different origin
/// and is not configured for CORS. Since the image bytes cannot be directly
/// fetched, Flutter cannot create a [ui.Image] for it. However, the image can
/// still be displayed if an <img> element is used.
class WebImageInfo implements ImageInfo {
  @override
  ImageInfo clone() {
    throw UnsupportedError(
        'WebImageInfo should never be instantiated in a non-web context.');
  }

  @override
  String? get debugLabel => throw UnsupportedError(
      'WebImageInfo should never be instantiated in a non-web context.');

  @override
  void dispose() {
    throw UnsupportedError(
        'WebImageInfo should never be instantiated in a non-web context.');
  }

  @override
  ui.Image get image => throw UnsupportedError(
      'WebImageInfo should never be instantiated in a non-web context.');

  @override
  bool isCloneOf(ImageInfo other) {
    throw UnimplementedError();
  }

  @override
  double get scale => throw UnsupportedError(
      'WebImageInfo should never be instantiated in a non-web context.');

  @override
  int get sizeBytes => throw UnsupportedError(
      'WebImageInfo should never be instantiated in a non-web context.');
}
