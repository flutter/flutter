// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:test/test.dart';

import 'mocks_for_image_cache.dart';

void main() {
  test('Image cache resizing', () async {

    imageCache.maximumSize = 2;

    TestImageInfo a = await extractOneFrame(const TestImageProvider(1, 1).resolve(ImageConfiguration.empty));
    TestImageInfo b = await extractOneFrame(const TestImageProvider(2, 2).resolve(ImageConfiguration.empty));
    TestImageInfo c = await extractOneFrame(const TestImageProvider(3, 3).resolve(ImageConfiguration.empty));
    TestImageInfo d = await extractOneFrame(const TestImageProvider(1, 4).resolve(ImageConfiguration.empty));
    expect(a.value, equals(1));
    expect(b.value, equals(2));
    expect(c.value, equals(3));
    expect(d.value, equals(4));

    imageCache.maximumSize = 0;

    TestImageInfo e = await extractOneFrame(const TestImageProvider(1, 5).resolve(ImageConfiguration.empty));
    expect(e.value, equals(5));

    TestImageInfo f = await extractOneFrame(const TestImageProvider(1, 6).resolve(ImageConfiguration.empty));
    expect(f.value, equals(6));

    imageCache.maximumSize = 3;

    TestImageInfo g = await extractOneFrame(const TestImageProvider(1, 7).resolve(ImageConfiguration.empty));
    expect(g.value, equals(7));

    TestImageInfo h = await extractOneFrame(const TestImageProvider(1, 8).resolve(ImageConfiguration.empty));
    expect(h.value, equals(7));

  });
}
