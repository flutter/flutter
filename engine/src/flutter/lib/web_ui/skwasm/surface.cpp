// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "surface.h"
#include <algorithm>

#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"

using namespace Skwasm;

Surface::Surface() {
  assert(emscripten_is_main_browser_thread());

  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

  pthread_create(
      &_thread, &attr,
      [](void* context) -> void* {
        static_cast<Surface*>(context)->_runWorker();
        return nullptr;
      },
      this);
  // Listen to messages from the worker
  skwasm_registerMessageListener(_thread);
}

// Main thread only
void Surface::dispose() {
  assert(emscripten_is_main_browser_thread());
  emscripten_dispatch_to_thread(_thread, EM_FUNC_SIG_VI,
                                reinterpret_cast<void*>(fDispose), nullptr,
                                this);
}

// Main thread only
uint32_t Surface::renderPicture(SkPicture* picture) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callbackId = ++_currentCallbackId;
  picture->ref();
  emscripten_dispatch_to_thread(_thread, EM_FUNC_SIG_VIII,
                                reinterpret_cast<void*>(fRenderPicture),
                                nullptr, this, picture, callbackId);
  return callbackId;
}

// Main thread only
uint32_t Surface::rasterizeImage(SkImage* image, ImageByteFormat format) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callbackId = ++_currentCallbackId;
  image->ref();

  emscripten_dispatch_to_thread(_thread, EM_FUNC_SIG_VIIII,
                                reinterpret_cast<void*>(fRasterizeImage),
                                nullptr, this, image, format, callbackId);
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
void Surface::_runWorker() {
  _init();
  emscripten_exit_with_live_runtime();
}

// Worker thread only
void Surface::_init() {
  // Listen to messages from the main thread
  skwasm_registerMessageListener(0);
  _glContext = skwasm_createOffscreenCanvas(256, 256);
  if (!_glContext) {
    printf("Failed to create context!\n");
    return;
  }

  makeCurrent(_glContext);
  emscripten_webgl_enable_extension(_glContext, "WEBGL_debug_renderer_info");

  _grContext = GrDirectContext::MakeGL(GrGLMakeNativeInterface());

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
}

// Worker thread only
void Surface::_dispose() {
  delete this;
}

// Worker thread only
void Surface::_resizeCanvasToFit(int width, int height) {
  if (!_surface || width > _canvasWidth || height > _canvasHeight) {
    _canvasWidth = std::max(width, _canvasWidth);
    _canvasHeight = std::max(height, _canvasHeight);
    _recreateSurface();
  }
}

// Worker thread only
void Surface::_recreateSurface() {
  makeCurrent(_glContext);
  skwasm_resizeCanvas(_glContext, _canvasWidth, _canvasHeight);
  auto target = GrBackendRenderTargets::MakeGL(_canvasWidth, _canvasHeight,
                                               _sampleCount, _stencil, _fbInfo);
  _surface = SkSurfaces::WrapBackendRenderTarget(
      _grContext.get(), target, kBottomLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, SkColorSpace::MakeSRGB(), nullptr);
}

// Worker thread only
void Surface::_renderPicture(const SkPicture* picture, uint32_t callbackId) {
  SkRect pictureRect = picture->cullRect();
  SkIRect roundedOutRect;
  pictureRect.roundOut(&roundedOutRect);
  _resizeCanvasToFit(roundedOutRect.width(), roundedOutRect.height());
  SkMatrix matrix =
      SkMatrix::Translate(-roundedOutRect.fLeft, -roundedOutRect.fTop);
  makeCurrent(_glContext);
  auto canvas = _surface->getCanvas();
  canvas->drawColor(SK_ColorTRANSPARENT, SkBlendMode::kSrc);
  canvas->drawPicture(sk_ref_sp<SkPicture>(picture), &matrix, nullptr);
  _grContext->flush(_surface);
  skwasm_captureImageBitmap(this, _glContext, callbackId,
                            roundedOutRect.width(), roundedOutRect.height());
}

void Surface::_rasterizeImage(SkImage* image,
                              ImageByteFormat format,
                              uint32_t callbackId) {
  // We handle PNG encoding with browser APIs so that we can omit libpng from
  // skia to save binary size.
  assert(format != ImageByteFormat::png);
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
  bool success = image->readPixels(_grContext.get(), image->imageInfo(), pixels,
                                   bytesPerRow, 0, 0);
  if (!success) {
    printf("Failed to read pixels from image!\n");
    data = nullptr;
  }
  emscripten_async_run_in_main_runtime_thread(
      EM_FUNC_SIG_VIII, fOnRasterizeComplete, this, data.release(), callbackId);
}

void Surface::_onRasterizeComplete(SkData* data, uint32_t callbackId) {
  _callbackHandler(callbackId, data, __builtin_wasm_ref_null_extern());
}

// Main thread only
void Surface::onRenderComplete(uint32_t callbackId, SkwasmObject imageBitmap) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler(callbackId, nullptr, imageBitmap);
}

void Surface::fDispose(Surface* surface) {
  surface->_dispose();
}

void Surface::fRenderPicture(Surface* surface,
                             SkPicture* picture,
                             uint32_t callbackId) {
  surface->_renderPicture(picture, callbackId);
  picture->unref();
}

void Surface::fOnRasterizeComplete(Surface* surface,
                                   SkData* imageData,
                                   uint32_t callbackId) {
  surface->_onRasterizeComplete(imageData, callbackId);
}

void Surface::fRasterizeImage(Surface* surface,
                              SkImage* image,
                              ImageByteFormat format,
                              uint32_t callbackId) {
  surface->_rasterizeImage(image, format, callbackId);
  image->unref();
}

SKWASM_EXPORT Surface* surface_create() {
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
  surface->dispose();
}

SKWASM_EXPORT uint32_t surface_renderPicture(Surface* surface,
                                             SkPicture* picture) {
  return surface->renderPicture(picture);
}

SKWASM_EXPORT uint32_t surface_rasterizeImage(Surface* surface,
                                              SkImage* image,
                                              ImageByteFormat format) {
  return surface->rasterizeImage(image, format);
}

// This is used by the skwasm JS support code to call back into C++ when the
// we finish creating the image bitmap, which is an asynchronous operation.
SKWASM_EXPORT void surface_onRenderComplete(Surface* surface,
                                            uint32_t callbackId,
                                            SkwasmObject imageBitmap) {
  return surface->onRenderComplete(callbackId, imageBitmap);
}
