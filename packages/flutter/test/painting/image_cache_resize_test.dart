// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:test/test.dart';

import '../rendering/rendering_tester.dart';
import 'mocks_for_image_cache.dart';

void main() {
  new TestRenderingFlutterBinding(); // initializes the imageCache

  test('Image cache resizing', () async {
    const FakeImage image = const FakeImage(16, 16); // 1 KB.

    imageCache.maximumSize = 2.0; // 2 KB

    final TestImageInfo a = await extractOneFrame(const TestImageProvider(1, 1, image: image).resolve(ImageConfiguration.empty));
    final TestImageInfo b = await extractOneFrame(const TestImageProvider(2, 2, image: image).resolve(ImageConfiguration.empty));
    final TestImageInfo c = await extractOneFrame(const TestImageProvider(3, 3, image: image).resolve(ImageConfiguration.empty));
    final TestImageInfo d = await extractOneFrame(const TestImageProvider(1, 4, image: image).resolve(ImageConfiguration.empty));
    expect(a.value, equals(1));
    expect(b.value, equals(2));
    expect(c.value, equals(3));
    expect(d.value, equals(4));

    imageCache.maximumSize = 0.0;

    final TestImageInfo e = await extractOneFrame(const TestImageProvider(1, 5, image: image).resolve(ImageConfiguration.empty));
    expect(e.value, equals(5));

    final TestImageInfo f = await extractOneFrame(const TestImageProvider(1, 6, image: image).resolve(ImageConfiguration.empty));
    expect(f.value, equals(6));

    imageCache.maximumSize = 3.0;

    final TestImageInfo g = await extractOneFrame(const TestImageProvider(1, 7, image: image).resolve(ImageConfiguration.empty));
    expect(g.value, equals(7));

    final TestImageInfo h = await extractOneFrame(const TestImageProvider(1, 8, image: image).resolve(ImageConfiguration.empty));
    expect(h.value, equals(7));

  });
}
