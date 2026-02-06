// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SKWASM_SKWASM_SUPPORT_H_
#define FLUTTER_SKWASM_SKWASM_SUPPORT_H_

#include <cinttypes>

#include <emscripten/threading.h>

#include "flutter/display_list/image/dl_image.h"
#include "flutter/skwasm/surface.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkPicture.h"

using SkwasmObject = __externref_t;

namespace flutter {
class DisplayList;
}

extern "C" {
extern bool skwasm_isSingleThreaded();
extern void skwasm_setAssociatedObjectOnThread(unsigned long thread_id,
                                               void* pointer,
                                               SkwasmObject object);
extern SkwasmObject skwasm_getAssociatedObject(void* pointer);
extern void skwasm_disposeAssociatedObjectOnThread(unsigned long thread_id,
                                                   void* pointer);
extern void skwasm_connectThread(pthread_t thread_id);
extern void skwasm_dispatchRenderPictures(unsigned long thread_id,
                                          Skwasm::Surface* surface,
                                          sk_sp<flutter::DisplayList>* pictures,
                                          int count,
                                          uint32_t callback_id);
extern uint32_t skwasm_getGlContextForCanvas(SkwasmObject canvas,
                                             Skwasm::Surface* surface);
extern void skwasm_reportInitialized(Skwasm::Surface* surface,
                                     uint32_t callback_id,
                                     uint32_t context_lost_callback_id);
extern void skwasm_reportResizeComplete(Skwasm::Surface* surface,
                                        uint32_t callback_id);
extern void skwasm_dispatchResizeSurface(unsigned long thread_id,
                                         Skwasm::Surface* surface,
                                         int width,
                                         int height,
                                         uint32_t callback_id);
extern void skwasm_resizeCanvas(uint32_t contextHandle, int width, int height);
extern SkwasmObject skwasm_captureImageBitmap(uint32_t context_handle,
                                              SkwasmObject image_bitmaps);
extern void skwasm_resolveAndPostImages(Skwasm::Surface* surface,
                                        SkwasmObject image_bitmaps,
                                        double raster_start,
                                        uint32_t callback_id);
extern unsigned int skwasm_createGlTextureFromTextureSource(
    SkwasmObject texture_source,
    int width,
    int height);
extern void skwasm_dispatchTriggerContextLoss(unsigned long thread_id,
                                              Skwasm::Surface* surface,
                                              uint32_t callback_id);
extern void skwasm_triggerContextLossOnCanvas();
extern void skwasm_reportContextLossTriggered(Skwasm::Surface* surface,
                                              uint32_t callback_id);
extern void skwasm_reportContextLost(Skwasm::Surface* surface,
                                     uint32_t callback_id);
extern void skwasm_destroyContext(uint32_t context_handle);
extern void skwasm_dispatchTransferCanvas(unsigned long thread_id,
                                          Skwasm::Surface* surface,
                                          SkwasmObject canvas,
                                          uint32_t callback_id);
extern void skwasm_dispatchDisposeSurface(unsigned long thread_id,
                                          Skwasm::Surface* surface);
extern void skwasm_dispatchRasterizeImage(unsigned long thread_id,
                                          Skwasm::Surface* surface,
                                          flutter::DlImage* image,
                                          Skwasm::ImageByteFormat format,
                                          uint32_t callback_id);
extern void skwasm_postRasterizeResult(Skwasm::Surface* surface,
                                       SkData* data,
                                       uint32_t callback_id);
}

#endif  // FLUTTER_SKWASM_SKWASM_SUPPORT_H_
