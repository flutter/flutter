// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library skwasm_impl;

import 'dart:ffi';

import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

final class RawAnimatedImage extends Opaque {}

typedef AnimatedImageHandle = Pointer<RawAnimatedImage>;

@Native<AnimatedImageHandle Function(SkDataHandle, Int32, Int32)>(
  symbol: 'animatedImage_create',
  isLeaf: true,
)
external AnimatedImageHandle animatedImageCreate(SkDataHandle handle, int width, int height);

@Native<Void Function(AnimatedImageHandle)>(symbol: 'animatedImage_dispose', isLeaf: true)
external void animatedImageDispose(AnimatedImageHandle handle);

@Native<Int32 Function(AnimatedImageHandle)>(symbol: 'animatedImage_getFrameCount', isLeaf: true)
external int animatedImageGetFrameCount(AnimatedImageHandle handle);

@Native<Int32 Function(AnimatedImageHandle)>(
  symbol: 'animatedImage_getRepetitionCount',
  isLeaf: true,
)
external int animatedImageGetRepetitionCount(AnimatedImageHandle handle);

@Native<Int32 Function(AnimatedImageHandle)>(
  symbol: 'animatedImage_getCurrentFrameDurationMilliseconds',
  isLeaf: true,
)
external int animatedImageGetCurrentFrameDurationMilliseconds(AnimatedImageHandle handle);

@Native<Void Function(AnimatedImageHandle)>(symbol: 'animatedImage_decodeNextFrame', isLeaf: true)
external void animatedImageDecodeNextFrame(AnimatedImageHandle handle);

@Native<ImageHandle Function(AnimatedImageHandle)>(
  symbol: 'animatedImage_getCurrentFrame',
  isLeaf: true,
)
external ImageHandle animatedImageGetCurrentFrame(AnimatedImageHandle handle);
