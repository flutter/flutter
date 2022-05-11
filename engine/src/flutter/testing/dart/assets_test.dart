// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:litetest/litetest.dart';

void main() {
  test('Loading an asset that does not exist returns null', () async {
    Object? error;
    try {
      await ui.ImmutableBuffer.fromAsset('ThisDoesNotExist');
    } catch (err) {
      error = err;
    }
    expect(error, isNotNull);
    expect(error is Exception, true);
  });

  test('returns the bytes of a bundled asset', () async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromAsset('assets/DashInNooglerHat.jpg');

    expect(buffer.length == 354679, true);
  });

  test('can dispose immutable buffer', () async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromAsset('assets/DashInNooglerHat.jpg');

    buffer.dispose();
  });
}
