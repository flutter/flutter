// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart';

import '../flutter_test_alternative.dart';

void main() {
  test('wrapped HitTestResult gets HitTestEntry added to wrapping HitTestResult', () async {
    final HitTestEntry entry1 = HitTestEntry(_DummyHitTestTarget());
    final HitTestEntry entry2 = HitTestEntry(_DummyHitTestTarget());
    final HitTestEntry entry3 = HitTestEntry(_DummyHitTestTarget());
    final Matrix4 transform = Matrix4.translationValues(40.0, 150.0, 0.0);

    final HitTestResult wrapped = MyHitTestResult()
      ..publicPushTransform(transform);
    wrapped.add(entry1);
    expect(wrapped.path, equals(<HitTestEntry>[entry1]));
    expect(entry1.transform, transform);

    final HitTestResult wrapping = HitTestResult.wrap(wrapped);
    expect(wrapping.path, equals(<HitTestEntry>[entry1]));
    expect(wrapping.path, same(wrapped.path));

    wrapping.add(entry2);
    expect(wrapping.path, equals(<HitTestEntry>[entry1, entry2]));
    expect(wrapped.path, equals(<HitTestEntry>[entry1, entry2]));
    expect(entry2.transform, transform);

    wrapped.add(entry3);
    expect(wrapping.path, equals(<HitTestEntry>[entry1, entry2, entry3]));
    expect(wrapped.path, equals(<HitTestEntry>[entry1, entry2, entry3]));
    expect(entry3.transform, transform);
  });
}

class _DummyHitTestTarget implements HitTestTarget {
  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    // Nothing to do.
  }
}

class MyHitTestResult extends HitTestResult {
  void publicPushTransform(Matrix4 transform) => pushTransform(transform);
}
