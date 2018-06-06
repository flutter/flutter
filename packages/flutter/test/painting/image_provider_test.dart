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
  new TestRenderingFlutterBinding(); // initializes the imageCache

  test('NetworkImage non-null url test', () {
    expect(() {
      new NetworkImage(nonconst(null));
    }, throwsAssertionError);
  });

  test('ImageProvider can evict images', () async {
    imageCache.clear();
    final Uint8List bytes = new Uint8List.fromList(kTransparentImage);
    final MemoryImage imageProvider = new MemoryImage(bytes);
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    final Completer<void> completer = new Completer<void>();
    stream.addListener((ImageInfo info, bool syncCall) => completer.complete());
    await completer.future;

    expect(imageCache.currentSize, 1);
    expect(await new MemoryImage(bytes).evict(), true);
    expect(imageCache.currentSize, 0);
  });
}
