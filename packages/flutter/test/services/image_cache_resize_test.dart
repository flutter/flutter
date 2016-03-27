// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:test/test.dart';

import 'mocks_for_image_cache.dart';

void main() {
  test('Image cache resizing', () async {

    imageCache.maximumSize = 2;

    TestImageInfo a = (await imageCache.loadProvider(new TestProvider(1, 1)).first);
    TestImageInfo b = (await imageCache.loadProvider(new TestProvider(2, 2)).first);
    TestImageInfo c = (await imageCache.loadProvider(new TestProvider(3, 3)).first);
    TestImageInfo d = (await imageCache.loadProvider(new TestProvider(1, 4)).first);
    expect(a.value, equals(1));
    expect(b.value, equals(2));
    expect(c.value, equals(3));
    expect(d.value, equals(4));

    imageCache.maximumSize = 0;

    TestImageInfo e = (await imageCache.loadProvider(new TestProvider(1, 5)).first);
    expect(e.value, equals(5));

    TestImageInfo f = (await imageCache.loadProvider(new TestProvider(1, 6)).first);
    expect(f.value, equals(6));

    imageCache.maximumSize = 3;

    TestImageInfo g = (await imageCache.loadProvider(new TestProvider(1, 7)).first);
    expect(g.value, equals(7));

    TestImageInfo h = (await imageCache.loadProvider(new TestProvider(1, 8)).first);
    expect(h.value, equals(7));

  });
}
