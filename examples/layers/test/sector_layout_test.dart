// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/src/sector_layout.dart';

void main() {
  group('hit testing', () {
    test('SectorHitTestResult wrapping HitTestResult', () {
      final HitTestEntry entry1 = HitTestEntry(_DummyHitTestTarget());
      final HitTestEntry entry2 = HitTestEntry(_DummyHitTestTarget());
      final HitTestEntry entry3 = HitTestEntry(_DummyHitTestTarget());

      final HitTestResult wrapped = HitTestResult();
      wrapped.add(entry1);
      expect(wrapped.path, equals(<HitTestEntry>[entry1]));

      final SectorHitTestResult wrapping = SectorHitTestResult.wrap(wrapped);
      expect(wrapping.path, equals(<HitTestEntry>[entry1]));
      expect(wrapping.path, same(wrapped.path));

      wrapping.add(entry2);
      expect(wrapping.path, equals(<HitTestEntry>[entry1, entry2]));
      expect(wrapped.path, equals(<HitTestEntry>[entry1, entry2]));

      wrapped.add(entry3);
      expect(wrapping.path, equals(<HitTestEntry>[entry1, entry2, entry3]));
      expect(wrapped.path, equals(<HitTestEntry>[entry1, entry2, entry3]));
    });
  });
}

class _DummyHitTestTarget implements HitTestTarget {
  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    // Nothing to do.
  }
}
