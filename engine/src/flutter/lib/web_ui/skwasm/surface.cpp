// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "surface.h"
#include "live_objects.h"
#include "skwasm_support.h"

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/skia/dl_sk_dispatcher.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLMakeWebGLInterface.h"

#include <emscripten/wasm_worker.h>
#include <algorithm>

// This file implements the C++ side of the Skwasm Surface API.
//
// The general lifecycle of a method call that needs to be performed on the
// web worker thread is as follows:
//
// 1. The method is called on the [Surface] object on the main thread.
//    This method will have the same name as the dart method that is calling it.
//    It will extract the arguments, generate a callback id, and then call a
//    `skwasm_dispatch*` method to send a message to the worker thread.
// 2. The `skwasm_dispatch*` method will be a javascript method in
//    `library_skwasm_support.js`. This method will use `postMessage` to send a
//    message to the worker thread.
// 3. The worker thread will receive the message in its `message` event
//    listener. The listener will call a `surface_*OnWorker` C++ method.
// 4. The `surface_*OnWorker` method will call the corresponding `*OnWorker`
//    method on the [Surface] object. This method will do the actual work of
//    the method call.
// 5. When the work is complete, the `*OnWorker` method will call a
//    `skwasm_report*` method. This will be a javascript method in
//    `library_skwasm_support.js` which will use `postMessage` to send a
//    message back to the main thread.
// 6. The main thread will receive the message in its `message` event listener.
//    The listener will call an `on*` method on the C++ [Surface] object.
// 7. The `on*` method will invoke the callback handler that was registered by
//    the Dart code, which will complete the future that was returned by the
//    original Dart method call.

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

// General getters are implemented in the header.

// Lifecycle

void Surface::setCallbackHandler(CallbackHandler* callbackHandler) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler = callbackHandler;
}

void Surface::dispose() {
  if (_grContext) {
    _grContext->releaseResourcesAndAbandonContext();
  }
  if (_glContext) {
    skwasm_destroyContext(_glContext);
  }
  delete this;
}

// Surface setup

uint32_t Surface::setCanvas(SkwasmObject canvas) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callbackId = ++_currentCallbackId;
  skwasm_dispatchTransferCanvas(_thread, this, canvas, callbackId);
  return callbackId;
}

void Surface::onInitialized(uint32_t callbackId) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler(callbackId, (void*)_contextLostCallbackId,
                   __builtin_wasm_ref_null_extern());
}

void Surface::receiveCanvasOnWorker(SkwasmObject canvas, uint32_t callbackId) {
  if (_grContext) {
    _grContext->releaseResourcesAndAbandonContext();
  }
  if (_glContext) {
    skwasm_destroyContext(_glContext);
  }
  _canvasWidth = 0;
  _canvasHeight = 0;
  _surface = nullptr;
  _glContext = skwasm_getGlContextForCanvas(canvas, this);
  if (!_glContext) {
    printf("Failed to create context!\n");
    return;
  }

  makeCurrent(_glContext);
  emscripten_webgl_enable_extension(_glContext, "WEBGL_debug_renderer_info");

  _grContext = GrDirectContexts::MakeGL(GrGLInterfaces::MakeWebGL());

  // WebGL should already be clearing the color and stencil buffers, but do it
  // again here to ensure Skia receives them in the expected state.
  emscripten_glBindFramebuffer(GL_FRAMEBUFFER, 0);
  emscripten_glClearColor(0, 0, 0, 0);
  emscripten_glClearStencil(0);
  emscripten_glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
  _grContext->resetContext(kRenderTarget_GrGLBackendState |
                           kMisc_GrGLBackendState);

  // The on-screen canvas is FBO 0. Wrap it in a Skia render target so Skia
  // can render to it.
  _fbInfo.fFBOID = 0;
  _fbInfo.fFormat = GL_RGBA8_OES;

  emscripten_glGetIntegerv(GL_SAMPLES, &_sampleCount);
  emscripten_glGetIntegerv(GL_STENCIL_BITS, &_stencil);

  uint32_t contextLostCallbackId = ++_currentCallbackId;
  _contextLostCallbackId = contextLostCallbackId;

  skwasm_reportInitialized(this, contextLostCallbackId, callbackId);
}

// Resizing

uint32_t Surface::setSize(int width, int height) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callbackId = ++_currentCallbackId;

  skwasm_dispatchResizeSurface(_thread, this, width, height, callbackId);
  return callbackId;
}

void Surface::onResizeComplete(uint32_t callbackId) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler(callbackId, nullptr, __builtin_wasm_ref_null_extern());
}

void Surface::resizeOnWorker(int width, int height, uint32_t callbackId) {
  _resizeSurface(width, height);
  skwasm_reportResizeComplete(this, callbackId);
}

// Rendering

uint32_t Surface::renderPictures(DisplayList** pictures, int count) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callbackId = ++_currentCallbackId;
  std::unique_ptr<sk_sp<DisplayList>[]> picturePointers =
      std::make_unique<sk_sp<DisplayList>[]>(count);
  for (int i = 0; i < count; i++) {
    picturePointers[i] = sk_ref_sp(pictures[i]);
  }

  // Releasing picturePointers here and will recreate the unique_ptr on the
  // other thread See surface_renderPicturesOnWorker
  skwasm_dispatchRenderPictures(_thread, this, picturePointers.release(), count,
                                callbackId);
  return callbackId;
}

void Surface::onRenderComplete(uint32_t callbackId, SkwasmObject imageBitmap) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler(callbackId, nullptr, imageBitmap);
}

void Surface::renderPicturesOnWorker(sk_sp<DisplayList>* pictures,
                                     int pictureCount,
                                     uint32_t callbackId,
                                     double rasterStart) {
  makeCurrent(_glContext);
  // This is initialized on the first call to `skwasm_captureImageBitmap` and
  // then populated with more bitmaps on subsequent calls.
  SkwasmObject imageBitmapArray = __builtin_wasm_ref_null_extern();
  for (int i = 0; i < pictureCount; i++) {
    sk_sp<DisplayList> picture = pictures[i];
    auto canvas = _surface->getCanvas();
    canvas->drawColor(SK_ColorTRANSPARENT, SkBlendMode::kSrc);
    auto dispatcher = DlSkCanvasDispatcher(canvas);
    dispatcher.save();
    dispatcher.drawDisplayList(picture, 1.0f);
    dispatcher.restore();

    _grContext->flush(_surface.get());
    imageBitmapArray = skwasm_captureImageBitmap(_glContext, imageBitmapArray);
  }
  skwasm_resolveAndPostImages(this, imageBitmapArray, rasterStart, callbackId);
}

// Image Rasterization

uint32_t Surface::rasterizeImage(SkImage* image, ImageByteFormat format) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callbackId = ++_currentCallbackId;
  image->ref();

  skwasm_dispatchRasterizeImage(_thread, this, image, format, callbackId);
  return callbackId;
}

void Surface::onRasterizeComplete(uint32_t callbackId, SkData* data) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler(callbackId, data, __builtin_wasm_ref_null_extern());
}

void Surface::rasterizeImageOnWorker(SkImage* image,
                                     ImageByteFormat format,
                                     uint32_t callbackId) {
  // We handle PNG encoding with browser APIs so that we can omit libpng from
  // skia to save binary size.
  assert(format != ImageByteFormat::png);
  makeCurrent(_glContext);
  sk_sp<SkData> data;
  SkAlphaType alphaType = format == ImageByteFormat::rawStraightRgba
                              ? SkAlphaType::kUnpremul_SkAlphaType
                              : SkAlphaType::kPremul_SkAlphaType;
  SkImageInfo info = SkImageInfo::Make(image->width(), image->height(),
                                       SkColorType::kRGBA_8888_SkColorType,
                                       alphaType, SkColorSpace::MakeSRGB());
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
  auto canvas = _surface->getCanvas();
  canvas->drawColor(SK_ColorTRANSPARENT, SkBlendMode::kSrc);

  // We want the pixels from the upper left corner, but glReadPixels gives us
  // the pixels from the lower left corner. So we have to flip the image when we
  // are drawing it to get the pixels in the desired order.
  canvas->save();
  canvas->scale(1, -1);
  canvas->drawImage(image, 0, -_canvasHeight);
  canvas->restore();
  _grContext->flush(_surface.get());

  emscripten_glReadPixels(0, 0, image->width(), image->height(), GL_RGBA,
                          GL_UNSIGNED_BYTE, reinterpret_cast<void*>(pixels));

  image->unref();
  skwasm_postRasterizeResult(this, data.release(), callbackId);
}

// Context Loss

uint32_t Surface::triggerContextLoss() {
  assert(emscripten_is_main_browser_thread());
  uint32_t callbackId = ++_currentCallbackId;
  skwasm_dispatchTriggerContextLoss(_thread, this, callbackId);
  return callbackId;
}

void Surface::onContextLossTriggered(uint32_t callbackId) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler(callbackId, nullptr, __builtin_wasm_ref_null_extern());
}

void Surface::reportContextLost(uint32_t callbackId) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler(callbackId, nullptr, __builtin_wasm_ref_null_extern());
}

void Surface::triggerContextLossOnWorker(uint32_t callbackId) {
  makeCurrent(_glContext);
  skwasm_triggerContextLossOnCanvas();
  skwasm_reportContextLossTriggered(this, callbackId);
}

void Surface::onContextLost() {
  if (!_contextLostCallbackId) {
    printf("Received context lost event but never set callback handler!\n");
    return;
  }
  skwasm_reportContextLost(this, _contextLostCallbackId);
}

// Other

void Surface::setResourceCacheLimit(int bytes) {
  _grContext->setResourceCacheLimit(bytes);
}

std::unique_ptr<TextureSourceWrapper> Surface::createTextureSourceWrapper(
    SkwasmObject textureSource) {
  return std::unique_ptr<TextureSourceWrapper>(
      new TextureSourceWrapper(_thread, textureSource));
}

// Private methods

void Surface::_resizeSurface(int width, int height) {
  if (!_surface || width != _canvasWidth || height != _canvasHeight) {
    _canvasWidth = width;
    _canvasHeight = height;
    _recreateSurface();
  }
}

void Surface::_recreateSurface() {
  makeCurrent(_glContext);
  skwasm_resizeCanvas(_glContext, _canvasWidth, _canvasHeight);
  auto target = GrBackendRenderTargets::MakeGL(_canvasWidth, _canvasHeight,
                                               _sampleCount, _stencil, _fbInfo);
  _surface = SkSurfaces::WrapBackendRenderTarget(
      _grContext.get(), target, kBottomLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, SkColorSpace::MakeSRGB(), nullptr);
}

// TextureSourceWrapper implementation

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

// C-style API

SKWASM_EXPORT Surface* surface_create() {
  liveSurfaceCount++;
  return new Surface();
}

SKWASM_EXPORT uint32_t surface_setCanvas(Surface* surface,
                                         SkwasmObject canvas) {
  // Dispatch to the worker so the canvas can be transferred to the worker.
  return surface->setCanvas(canvas);
}

SKWASM_EXPORT void surface_receiveCanvasOnWorker(Surface* surface,
                                                 SkwasmObject canvas,
                                                 uint32_t callbackId) {
  surface->receiveCanvasOnWorker(canvas, callbackId);
}

SKWASM_EXPORT void surface_onInitialized(Surface* surface,
                                         uint32_t callbackId) {
  surface->onInitialized(callbackId);
}

SKWASM_EXPORT uint32_t surface_setSize(Surface* surface,
                                       int width,
                                       int height) {
  return surface->setSize(width, height);
}

SKWASM_EXPORT void surface_resizeOnWorker(Surface* surface,
                                          int width,
                                          int height,
                                          uint32_t callbackId) {
  surface->resizeOnWorker(width, height, callbackId);
}

SKWASM_EXPORT void surface_onResizeComplete(Surface* surface,
                                            uint32_t callbackId) {
  surface->onResizeComplete(callbackId);
}

SKWASM_EXPORT unsigned long surface_getThreadId(Surface* surface) {
  return surface->getThreadId();
}

SKWASM_EXPORT EMSCRIPTEN_WEBGL_CONTEXT_HANDLE
surface_getGlContext(Surface* surface) {
  return surface->getGlContext();
}

SKWASM_EXPORT uint32_t surface_triggerContextLoss(Surface* surface) {
  return surface->triggerContextLoss();
}

SKWASM_EXPORT void surface_triggerContextLossOnWorker(Surface* surface,
                                                      uint32_t callbackId) {
  surface->triggerContextLossOnWorker(callbackId);
}

SKWASM_EXPORT void surface_onContextLossTriggered(Surface* surface,
                                                  uint32_t callbackId) {
  surface->onContextLossTriggered(callbackId);
}

SKWASM_EXPORT void surface_reportContextLost(Surface* surface,
                                             uint32_t callbackId) {
  surface->reportContextLost(callbackId);
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
                                              int count) {
  return surface->renderPictures(pictures, count);
}

SKWASM_EXPORT void surface_renderPicturesOnWorker(
    Surface* surface,
    sk_sp<flutter::DisplayList>* pictures,
    int pictureCount,
    uint32_t callbackId,
    double rasterStart) {
  // This will release the pictures when they leave scope.
  std::unique_ptr<sk_sp<flutter::DisplayList>[]> picturesPointer =
      std::unique_ptr<sk_sp<flutter::DisplayList>[]>(pictures);
  surface->renderPicturesOnWorker(pictures, pictureCount, callbackId,
                                  rasterStart);
}

SKWASM_EXPORT uint32_t surface_rasterizeImage(Surface* surface,
                                              SkImage* image,
                                              ImageByteFormat format) {
  return surface->rasterizeImage(image, format);
}

SKWASM_EXPORT void surface_rasterizeImageOnWorker(Surface* surface,
                                                  SkImage* image,
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

SKWASM_EXPORT void surface_onContextLost(Surface* surface) {
  surface->onContextLost();
}

SKWASM_EXPORT bool skwasm_isMultiThreaded() {
  return !skwasm_isSingleThreaded();
}
