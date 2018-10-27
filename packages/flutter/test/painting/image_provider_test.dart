// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/rendering_tester.dart';
import 'image_data.dart';

void main() {
  TestRenderingFlutterBinding(); // initializes the imageCache
  group(ImageProvider, () {
    tearDown(() {
      imageCache.clear();
    });

    test('NetworkImage non-null url test', () {
      expect(() {
        NetworkImage(nonconst(null));
      }, throwsAssertionError);
    });

    test('ImageProvider can evict images', () async {
      final Uint8List bytes = Uint8List.fromList(kTransparentImage);
      final MemoryImage imageProvider = MemoryImage(bytes);
      final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
      final Completer<void> completer = Completer<void>();
      stream.addListener((ImageInfo info, bool syncCall) => completer.complete());
      await completer.future;

      expect(imageCache.currentSize, 1);
      expect(await MemoryImage(bytes).evict(), true);
      expect(imageCache.currentSize, 0);
    });

    test('ImageProvider.evict respects the provided ImageCache', () async {
      final ImageCache otherCache = ImageCache();
      final Uint8List bytes = Uint8List.fromList(kTransparentImage);
      final MemoryImage imageProvider = MemoryImage(bytes);
      otherCache.putIfAbsent(imageProvider, () => imageProvider.load(imageProvider));
      final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
      final Completer<void> completer = Completer<void>();
      stream.addListener((ImageInfo info, bool syncCall) => completer.complete());
      await completer.future;

      expect(otherCache.currentSize, 1);
      expect(imageCache.currentSize, 1);
      expect(await imageProvider.evict(cache: otherCache), true);
      expect(otherCache.currentSize, 0);
      expect(imageCache.currentSize, 1);
    });
  });
}
