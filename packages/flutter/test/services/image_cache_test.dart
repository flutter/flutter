// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:test/test.dart';

import 'mocks_for_image_cache.dart';

void main() {
  test('Image cache', () async {

    imageCache.maximumSize = 3;

    TestImageInfo a = (await imageCache.loadProvider(new TestProvider(1, 1)).first);
    expect(a.value, equals(1));
    TestImageInfo b = (await imageCache.loadProvider(new TestProvider(1, 2)).first);
    expect(b.value, equals(1));
    TestImageInfo c = (await imageCache.loadProvider(new TestProvider(1, 3)).first);
    expect(c.value, equals(1));
    TestImageInfo d = (await imageCache.loadProvider(new TestProvider(1, 4)).first);
    expect(d.value, equals(1));
    TestImageInfo e = (await imageCache.loadProvider(new TestProvider(1, 5)).first);
    expect(e.value, equals(1));
    TestImageInfo f = (await imageCache.loadProvider(new TestProvider(1, 6)).first);
    expect(f.value, equals(1));

    expect(f, equals(a));

    // cache still only has one entry in it: 1(1)

    TestImageInfo g = (await imageCache.loadProvider(new TestProvider(2, 7)).first);
    expect(g.value, equals(7));

    // cache has two entries in it: 1(1), 2(7)

    TestImageInfo h = (await imageCache.loadProvider(new TestProvider(1, 8)).first);
    expect(h.value, equals(1));

    // cache still has two entries in it: 2(7), 1(1)

    TestImageInfo i = (await imageCache.loadProvider(new TestProvider(3, 9)).first);
    expect(i.value, equals(9));

    // cache has three entries in it: 2(7), 1(1), 3(9)

    TestImageInfo j = (await imageCache.loadProvider(new TestProvider(1, 10)).first);
    expect(j.value, equals(1));

    // cache still has three entries in it: 2(7), 3(9), 1(1)

    TestImageInfo k = (await imageCache.loadProvider(new TestProvider(4, 11)).first);
    expect(k.value, equals(11));

    // cache has three entries: 3(9), 1(1), 4(11)

    TestImageInfo l = (await imageCache.loadProvider(new TestProvider(1, 12)).first);
    expect(l.value, equals(1));

    // cache has three entries: 3(9), 4(11), 1(1)

    TestImageInfo m = (await imageCache.loadProvider(new TestProvider(2, 13)).first);
    expect(m.value, equals(13));

    // cache has three entries: 4(11), 1(1), 2(13)

    TestImageInfo n = (await imageCache.loadProvider(new TestProvider(3, 14)).first);
    expect(n.value, equals(14));

    // cache has three entries: 1(1), 2(13), 3(14)

    TestImageInfo o = (await imageCache.loadProvider(new TestProvider(4, 15)).first);
    expect(o.value, equals(15));

    // cache has three entries: 2(13), 3(14), 4(15)

    TestImageInfo p = (await imageCache.loadProvider(new TestProvider(1, 16)).first);
    expect(p.value, equals(16));

    // cache has three entries: 3(14), 4(15), 1(16)

  });
}
