// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:test/test.dart';

import 'mocks_for_image_cache.dart';

void main() {
  test('Image cache', () async {

    imageCache.maximumSize = 3;

    TestImageInfo a = await extractOneFrame(const TestImageProvider(1, 1).resolve(ImageConfiguration.empty));
    expect(a.value, equals(1));
    TestImageInfo b = await extractOneFrame(const TestImageProvider(1, 2).resolve(ImageConfiguration.empty));
    expect(b.value, equals(1));
    TestImageInfo c = await extractOneFrame(const TestImageProvider(1, 3).resolve(ImageConfiguration.empty));
    expect(c.value, equals(1));
    TestImageInfo d = await extractOneFrame(const TestImageProvider(1, 4).resolve(ImageConfiguration.empty));
    expect(d.value, equals(1));
    TestImageInfo e = await extractOneFrame(const TestImageProvider(1, 5).resolve(ImageConfiguration.empty));
    expect(e.value, equals(1));
    TestImageInfo f = await extractOneFrame(const TestImageProvider(1, 6).resolve(ImageConfiguration.empty));
    expect(f.value, equals(1));

    expect(f, equals(a));

    // cache still only has one entry in it: 1(1)

    TestImageInfo g = await extractOneFrame(const TestImageProvider(2, 7).resolve(ImageConfiguration.empty));
    expect(g.value, equals(7));

    // cache has two entries in it: 1(1), 2(7)

    TestImageInfo h = await extractOneFrame(const TestImageProvider(1, 8).resolve(ImageConfiguration.empty));
    expect(h.value, equals(1));

    // cache still has two entries in it: 2(7), 1(1)

    TestImageInfo i = await extractOneFrame(const TestImageProvider(3, 9).resolve(ImageConfiguration.empty));
    expect(i.value, equals(9));

    // cache has three entries in it: 2(7), 1(1), 3(9)

    TestImageInfo j = await extractOneFrame(const TestImageProvider(1, 10).resolve(ImageConfiguration.empty));
    expect(j.value, equals(1));

    // cache still has three entries in it: 2(7), 3(9), 1(1)

    TestImageInfo k = await extractOneFrame(const TestImageProvider(4, 11).resolve(ImageConfiguration.empty));
    expect(k.value, equals(11));

    // cache has three entries: 3(9), 1(1), 4(11)

    TestImageInfo l = await extractOneFrame(const TestImageProvider(1, 12).resolve(ImageConfiguration.empty));
    expect(l.value, equals(1));

    // cache has three entries: 3(9), 4(11), 1(1)

    TestImageInfo m = await extractOneFrame(const TestImageProvider(2, 13).resolve(ImageConfiguration.empty));
    expect(m.value, equals(13));

    // cache has three entries: 4(11), 1(1), 2(13)

    TestImageInfo n = await extractOneFrame(const TestImageProvider(3, 14).resolve(ImageConfiguration.empty));
    expect(n.value, equals(14));

    // cache has three entries: 1(1), 2(13), 3(14)

    TestImageInfo o = await extractOneFrame(const TestImageProvider(4, 15).resolve(ImageConfiguration.empty));
    expect(o.value, equals(15));

    // cache has three entries: 2(13), 3(14), 4(15)

    TestImageInfo p = await extractOneFrame(const TestImageProvider(1, 16).resolve(ImageConfiguration.empty));
    expect(p.value, equals(16));

    // cache has three entries: 3(14), 4(15), 1(16)

  });
}
