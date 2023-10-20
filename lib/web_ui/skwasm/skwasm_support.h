// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <emscripten/threading.h>
#include <cinttypes>
#include "third_party/skia/include/core/SkPicture.h"

namespace Skwasm {
class Surface;
}

using SkwasmObject = __externref_t;

extern "C" {
extern void skwasm_setAssociatedObjectOnThread(unsigned long threadId,
                                               void* pointer,
                                               SkwasmObject object);
extern SkwasmObject skwasm_getAssociatedObject(void* pointer);
extern void skwasm_disposeAssociatedObjectOnThread(unsigned long threadId,
                                                   void* pointer);
extern void skwasm_registerMessageListener(pthread_t threadId);
extern void skwasm_dispatchRenderPicture(unsigned long threadId,
                                         Skwasm::Surface* surface,
                                         SkPicture* picture,
                                         uint32_t callbackId);
extern uint32_t skwasm_createOffscreenCanvas(int width, int height);
extern void skwasm_resizeCanvas(uint32_t contextHandle, int width, int height);
extern void skwasm_captureImageBitmap(Skwasm::Surface* surfaceHandle,
                                      uint32_t contextHandle,
                                      uint32_t bitmapId,
                                      int width,
                                      int height);
extern unsigned int skwasm_createGlTextureFromTextureSource(
    SkwasmObject textureSource,
    int width,
    int height);
}
