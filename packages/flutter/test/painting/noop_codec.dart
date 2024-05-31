// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

class NoopCodec implements Codec {
  @override
  void dispose() {}

  @override
  int get frameCount => throw UnimplementedError();

  @override
  Future<FrameInfo> getNextFrame() => throw UnimplementedError();

  @override
  int get repetitionCount => throw UnimplementedError();
}

Future<Codec> noopCodec(
  ImmutableBuffer buffer, {
  int? cacheWidth,
  int? cacheHeight,
  bool? allowUpscaling,
}) async =>
    NoopCodec();
