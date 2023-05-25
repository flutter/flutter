// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <emscripten/threading.h>
#include <cinttypes>

using SkwasmObjectId = uint32_t;

extern "C" {
extern void skwasm_transferObjectToMain(SkwasmObjectId objectId);
extern void skwasm_transferObjectToThread(SkwasmObjectId objectId,
                                          pthread_t threadId);
extern unsigned int skwasm_createGlTextureFromVideoFrame(
    SkwasmObjectId videoFrameId,
    int width,
    int height);
extern void skwasm_disposeVideoFrame(SkwasmObjectId videoFrameId);
}
