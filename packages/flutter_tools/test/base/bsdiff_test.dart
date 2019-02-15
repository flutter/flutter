// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_tools/src/base/bsdiff.dart';

import '../src/common.dart';

void main() {
  group('Main', () {
    test('generates diff', () {
      final Uint8List a = Uint8List.fromList('Hello'.runes.toList());
      final Uint8List b = Uint8List.fromList('World'.runes.toList());
      final Uint8List c = Uint8List.fromList(bsdiff(a, b));
      expect(bspatch(a, c), equals(b));
    });
  });
}
