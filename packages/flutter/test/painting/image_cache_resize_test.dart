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

    imageCache.maximumSize = 2;

    final TestImageInfo a = await extractOneFrame(const TestImageProvider(1, 1).resolve(ImageConfiguration.empty));
    final TestImageInfo b = await extractOneFrame(const TestImageProvider(2, 2).resolve(ImageConfiguration.empty));
    final TestImageInfo c = await extractOneFrame(const TestImageProvider(3, 3).resolve(ImageConfiguration.empty));
    final TestImageInfo d = await extractOneFrame(const TestImageProvider(1, 4).resolve(ImageConfiguration.empty));
    expect(a.value, equals(1));
    expect(b.value, equals(2));
    expect(c.value, equals(3));
    expect(d.value, equals(4));

    imageCache.maximumSize = 0;

    final TestImageInfo e = await extractOneFrame(const TestImageProvider(1, 5).resolve(ImageConfiguration.empty));
    expect(e.value, equals(5));

    final TestImageInfo f = await extractOneFrame(const TestImageProvider(1, 6).resolve(ImageConfiguration.empty));
    expect(f.value, equals(6));

    imageCache.maximumSize = 3;

    final TestImageInfo g = await extractOneFrame(const TestImageProvider(1, 7).resolve(ImageConfiguration.empty));
    expect(g.value, equals(7));

    final TestImageInfo h = await extractOneFrame(const TestImageProvider(1, 8).resolve(ImageConfiguration.empty));
    expect(h.value, equals(7));

  });
}
