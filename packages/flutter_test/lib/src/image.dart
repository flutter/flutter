// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'test_async_utils.dart';

final Map<int, ui.Image> _cache = <int, ui.Image>{};

/// Creates an arbitrarily sized image for testing.
///
/// If the [cache] parameter is set to true, the image will be cached. This
/// should be avoided for images that are used only once in a test suite,
/// especially if they are large.
///
/// This method requires real async work, and will not work properly in the
/// [FakeAsync] zones set up by [testWidgets]. Typically, it should be invoked
/// as a setup step before [testWidgets] are run. If needed, it can be invoked
/// using [WidgetTester.runAsync].
Future<ui.Image> createTestImage({
  int width = 1,
  int height = 1,
  bool cache = true,
}) => TestAsyncUtils.guard(() async {
  assert(width != null && width > 0);
  assert(height != null && height > 0);

  if (cache && _cache.containsKey(hashValues(width, height))) {
    return _cache[hashValues(width,height)];
  }
  final Completer<ui.Image> completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    Uint8List.fromList(List<int>.filled(width * height * 4, 0, growable: false)),
    width,
    height,
    ui.PixelFormat.rgba8888,
    (ui.Image image) {
      if (cache) {
        _cache[hashValues(width, height)] = image;
      }
      completer.complete(image);
    },
  );
  return completer.future;
});
