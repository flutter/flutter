// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "surface.h"
#include "live_objects.h"
#include "skwasm_support.h"

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/image/dl_image.h"

#include <emscripten/wasm_worker.h>
#include <algorithm>

using namespace Skwasm;
using namespace flutter;

Surface::Surface() {
  if (skwasm_isSingleThreaded()) {
    skwasm_connectThread(0);
  } else {
    assert(emscripten_is_main_browser_thread());

    _thread = emscripten_malloc_wasm_worker(65536);
    emscripten_wasm_worker_post_function_v(_thread, []() {
      // Listen to the main thread from the worker
      skwasm_connectThread(0);
    });

    // Listen to messages from the worker
    skwasm_connectThread(_thread);
  }
}

// Worker thread only
void Surface::dispose() {
  delete this;
}

// Main thread only
void Surface::setResourceCacheLimit(int bytes) {
  _renderContext->setResourceCacheLimit(bytes);
}

// Main thread only
uint32_t Surface::renderPictures(DisplayList** pictures,
                                 int width,
                                 int height,
                                 int count) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callbackId = ++_currentCallbackId;
  std::unique_ptr<sk_sp<DisplayList>[]> picturePointers =
      std::make_unique<sk_sp<DisplayList>[]>(count);
  for (int i = 0; i < count; i++) {
    picturePointers[i] = sk_ref_sp(pictures[i]);
  }

  // Releasing picturePointers here and will recreate the unique_ptr on the
  // other thread See surface_renderPicturesOnWorker
  skwasm_dispatchRenderPictures(_thread, this, picturePointers.release(), width,
                                height, count, callbackId);
  return callbackId;
}

// Main thread only
uint32_t Surface::rasterizeImage(DlImage* image, ImageByteFormat format) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callbackId = ++_currentCallbackId;
  image->ref();

  skwasm_dispatchRasterizeImage(_thread, this, image, format, callbackId);
  return callbackId;
}

std::unique_ptr<TextureSourceWrapper> Surface::createTextureSourceWrapper(
    SkwasmObject textureSource) {
  return std::unique_ptr<TextureSourceWrapper>(
      new TextureSourceWrapper(_thread, textureSource));
}

// Main thread only
void Surface::setCallbackHandler(CallbackHandler* callbackHandler) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler = callbackHandler;
}

// Worker thread only
void Surface::_init() {
  // 256x256 is just an arbitrary size for the initial canvas, so that we can
  // get a gl context off of it.
  _glContext = skwasm_createOffscreenCanvas(256, 256);
  if (!_glContext) {
    printf("Failed to create context!\n");
    return;
  }

  makeCurrent(_glContext);
  emscripten_webgl_enable_extension(_glContext, "WEBGL_debug_renderer_info");

  // WebGL should already be clearing the color and stencil buffers, but do it
  // again here to ensure Skia receives them in the expected state.
  emscripten_glBindFramebuffer(GL_FRAMEBUFFER, 0);
  emscripten_glClearColor(0, 0, 0, 0);
  emscripten_glClearStencil(0);
  emscripten_glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

  int sampleCount;
  int stencil;
  emscripten_glGetIntegerv(GL_SAMPLES, &sampleCount);
  emscripten_glGetIntegerv(GL_STENCIL_BITS, &stencil);

  _renderContext = RenderContext::Make(sampleCount, stencil);
  _renderContext->resize(256, 256);

  _isInitialized = true;
}

// Worker thread only
void Surface::_resizeSurface(int width, int height) {
  if (width != _canvasWidth || height != _canvasHeight) {
    _canvasWidth = width;
    _canvasHeight = height;
    _recreateSurface();
  }
}

// Worker thread only
void Surface::_recreateSurface() {
  makeCurrent(_glContext);
  skwasm_resizeCanvas(_glContext, _canvasWidth, _canvasHeight);
  _renderContext->resize(_canvasWidth, _canvasHeight);
}

// Worker thread only
void Surface::renderPicturesOnWorker(sk_sp<DisplayList>* pictures,
                                     int width,
                                     int height,
                                     int pictureCount,
                                     uint32_t callbackId,
                                     double rasterStart) {
  if (!_isInitialized) {
    _init();
  }

  // This is initialized on the first call to `skwasm_captureImageBitmap` and
  // then populated with more bitmaps on subsequent calls.
  SkwasmObject imageBitmapArray = __builtin_wasm_ref_null_extern();
  for (int i = 0; i < pictureCount; i++) {
    sk_sp<DisplayList> picture = pictures[i];
    _resizeSurface(width, height);
    makeCurrent(_glContext);

    _renderContext->renderPicture(picture);

    imageBitmapArray = skwasm_captureImageBitmap(_glContext, imageBitmapArray);
  }
  skwasm_resolveAndPostImages(this, imageBitmapArray, rasterStart, callbackId);
}

// Worker thread only
void Surface::rasterizeImageOnWorker(DlImage* image,
                                     ImageByteFormat format,
                                     uint32_t callbackId) {
  if (!_isInitialized) {
    _init();
  }

  // We handle PNG encoding with browser APIs so that we can omit libpng from
  // skia to save binary size.
  assert(format != ImageByteFormat::png);
  SkAlphaType alphaType = format == ImageByteFormat::rawStraightRgba
                              ? SkAlphaType::kUnpremul_SkAlphaType
                              : SkAlphaType::kPremul_SkAlphaType;
  SkImageInfo info = SkImageInfo::Make(image->width(), image->height(),
                                       SkColorType::kRGBA_8888_SkColorType,
                                       alphaType, SkColorSpace::MakeSRGB());
  sk_sp<SkData> data;
  size_t bytesPerRow = 4 * image->width();
  size_t byteSize = info.computeByteSize(bytesPerRow);
  data = SkData::MakeUninitialized(byteSize);
  uint8_t* pixels = reinterpret_cast<uint8_t*>(data->writable_data());

  // TODO(jacksongardner):
  // Normally we'd just call `readPixels` on the image. However, this doesn't
  // actually work in some cases due to a skia bug. Instead, we just draw the
  // image to our scratch canvas and grab the pixels out directly with
  // `glReadPixels`. Once the skia bug is fixed, we should switch back to using
  // `SkImage::readPixels` instead.
  // See https://g-issues.skia.org/issues/349201915
  _resizeSurface(image->width(), image->height());

  _renderContext->renderImage(image, format);

  emscripten_glReadPixels(0, 0, image->width(), image->height(), GL_RGBA,
                          GL_UNSIGNED_BYTE, reinterpret_cast<void*>(pixels));

  image->unref();
  skwasm_postRasterizeResult(this, data.release(), callbackId);
}

void Surface::onRasterizeComplete(uint32_t callbackId, SkData* data) {
  _callbackHandler(callbackId, data, __builtin_wasm_ref_null_extern());
}

// Main thread only
void Surface::onRenderComplete(uint32_t callbackId, SkwasmObject imageBitmap) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler(callbackId, nullptr, imageBitmap);
}

TextureSourceWrapper::TextureSourceWrapper(unsigned long threadId,
                                           SkwasmObject textureSource)
    : _rasterThreadId(threadId) {
  skwasm_setAssociatedObjectOnThread(_rasterThreadId, this, textureSource);
}

TextureSourceWrapper::~TextureSourceWrapper() {
  skwasm_disposeAssociatedObjectOnThread(_rasterThreadId, this);
}

SkwasmObject TextureSourceWrapper::getTextureSource() {
  return skwasm_getAssociatedObject(this);
}

SKWASM_EXPORT Surface* surface_create() {
  liveSurfaceCount++;
  return new Surface();
}

SKWASM_EXPORT unsigned long surface_getThreadId(Surface* surface) {
  return surface->getThreadId();
}

SKWASM_EXPORT void surface_setCallbackHandler(
    Surface* surface,
    Surface::CallbackHandler* callbackHandler) {
  surface->setCallbackHandler(callbackHandler);
}

SKWASM_EXPORT void surface_destroy(Surface* surface) {
  liveSurfaceCount--;
  // Dispatch to the worker
  skwasm_dispatchDisposeSurface(surface->getThreadId(), surface);
}

SKWASM_EXPORT void surface_dispose(Surface* surface) {
  // This should be called directly only on the worker
  surface->dispose();
}

SKWASM_EXPORT void surface_setResourceCacheLimitBytes(Surface* surface,
                                                      int bytes) {
  surface->setResourceCacheLimit(bytes);
}

SKWASM_EXPORT uint32_t surface_renderPictures(Surface* surface,
                                              DisplayList** pictures,
                                              int width,
                                              int height,
                                              int count) {
  return surface->renderPictures(pictures, width, height, count);
}

SKWASM_EXPORT void surface_renderPicturesOnWorker(Surface* surface,
                                                  sk_sp<DisplayList>* pictures,
                                                  int width,
                                                  int height,
                                                  int pictureCount,
                                                  uint32_t callbackId,
                                                  double rasterStart) {
  // This will release the pictures when they leave scope.
  std::unique_ptr<sk_sp<DisplayList>[]> picturesPointer =
      std::unique_ptr<sk_sp<DisplayList>[]>(pictures);
  surface->renderPicturesOnWorker(pictures, width, height, pictureCount,
                                  callbackId, rasterStart);
}

SKWASM_EXPORT uint32_t surface_rasterizeImage(Surface* surface,
                                              DlImage* image,
                                              ImageByteFormat format) {
  return surface->rasterizeImage(image, format);
}

SKWASM_EXPORT void surface_rasterizeImageOnWorker(Surface* surface,
                                                  DlImage* image,
                                                  ImageByteFormat format,
                                                  uint32_t callbackId) {
  surface->rasterizeImageOnWorker(image, format, callbackId);
}

// This is used by the skwasm JS support code to call back into C++ when the
// we finish creating the image bitmap, which is an asynchronous operation.
SKWASM_EXPORT void surface_onRenderComplete(Surface* surface,
                                            uint32_t callbackId,
                                            SkwasmObject imageBitmap) {
  surface->onRenderComplete(callbackId, imageBitmap);
}

SKWASM_EXPORT void surface_onRasterizeComplete(Surface* surface,
                                               SkData* data,
                                               uint32_t callbackId) {
  surface->onRasterizeComplete(callbackId, data);
}

SKWASM_EXPORT bool skwasm_isMultiThreaded() {
  return !skwasm_isSingleThreaded();
}
