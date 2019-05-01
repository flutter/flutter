// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import '../flutter_test_alternative.dart';

void main() {
  test('wrpped HitTestResult gets HitTestEntry added to wrapping HitTestResult', () async {
    final HitTestEntry entry1 = HitTestEntry(_DummyHitTestTarget());
    final HitTestEntry entry2 = HitTestEntry(_DummyHitTestTarget());
    final HitTestEntry entry3 = HitTestEntry(_DummyHitTestTarget());

    final HitTestResult wrapped = HitTestResult();
    wrapped.add(entry1);
    expect(wrapped.path, equals(<HitTestEntry>[entry1]));

    final HitTestResult wrapping = HitTestResult.wrap(wrapped);
    expect(wrapping.path, equals(<HitTestEntry>[entry1]));
    expect(wrapping.path, same(wrapped.path));

    wrapping.add(entry2);
    expect(wrapping.path, equals(<HitTestEntry>[entry1, entry2]));
    expect(wrapped.path, equals(<HitTestEntry>[entry1, entry2]));

    wrapped.add(entry3);
    expect(wrapping.path, equals(<HitTestEntry>[entry1, entry2, entry3]));
    expect(wrapped.path, equals(<HitTestEntry>[entry1, entry2, entry3]));
  });
}

class _DummyHitTestTarget implements HitTestTarget {
  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    // Nothing to do.
  }
}
