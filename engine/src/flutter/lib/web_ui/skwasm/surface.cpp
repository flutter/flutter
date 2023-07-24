// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "surface.h"

#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"

using namespace Skwasm;

Surface::Surface(const char* canvasID) : _canvasID(canvasID) {
  assert(emscripten_is_main_browser_thread());

  pthread_attr_t attr;
  pthread_attr_init(&attr);
  pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
  emscripten_pthread_attr_settransferredcanvases(&attr, _canvasID.c_str());

  pthread_create(
      &_thread, &attr,
      [](void* context) -> void* {
        static_cast<Surface*>(context)->_runWorker();
        return nullptr;
      },
      this);
}

// Main thread only
void Surface::dispose() {
  assert(emscripten_is_main_browser_thread());
  emscripten_dispatch_to_thread(_thread, EM_FUNC_SIG_VI,
                                reinterpret_cast<void*>(fDispose), nullptr,
                                this);
}

// Main thread only
void Surface::setCanvasSize(int width, int height) {
  assert(emscripten_is_main_browser_thread());
  emscripten_dispatch_to_thread(_thread, EM_FUNC_SIG_VIII,
                                reinterpret_cast<void*>(fSetCanvasSize),
                                nullptr, this, width, height);
}

// Main thread only
uint32_t Surface::renderPicture(SkPicture* picture) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callbackId = ++_currentCallbackId;
  picture->ref();
  emscripten_dispatch_to_thread(_thread, EM_FUNC_SIG_VII,
                                reinterpret_cast<void*>(fRenderPicture),
                                nullptr, this, picture);

  // After drawing to the surface, the browser implicitly flushes the drawing
  // commands at the end of the event loop. As a result, in order to make
  // sure we call back after the rendering has actually occurred, we issue
  // the callback in a subsequent event, after the flushing has happened.
  emscripten_dispatch_to_thread(_thread, EM_FUNC_SIG_VII,
                                reinterpret_cast<void*>(fNotifyRenderComplete),
                                nullptr, this, callbackId);
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

void Surface::disposeVideoFrame(SkwasmObjectId videoFrameId) {
  emscripten_dispatch_to_thread(_thread, EM_FUNC_SIG_VII,
                                reinterpret_cast<void*>(fDisposeVideoFrame),
                                nullptr, this, videoFrameId);
}

// Main thread only
void Surface::setCallbackHandler(CallbackHandler* callbackHandler) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler = callbackHandler;
}

// Worker thread only
void Surface::_runWorker() {
  _init();
  emscripten_unwind_to_js_event_loop();
}

// Worker thread only
void Surface::_init() {
  EmscriptenWebGLContextAttributes attributes;
  emscripten_webgl_init_context_attributes(&attributes);

  attributes.alpha = true;
  attributes.depth = true;
  attributes.stencil = true;
  attributes.antialias = false;
  attributes.premultipliedAlpha = true;
  attributes.preserveDrawingBuffer = 0;
  attributes.powerPreference = EM_WEBGL_POWER_PREFERENCE_DEFAULT;
  attributes.failIfMajorPerformanceCaveat = false;
  attributes.enableExtensionsByDefault = true;
  attributes.explicitSwapControl = false;
  attributes.renderViaOffscreenBackBuffer = true;
  attributes.majorVersion = 2;

  _glContext = emscripten_webgl_create_context(_canvasID.c_str(), &attributes);
  if (!_glContext) {
    printf("Failed to create context!\n");
    return;
  }

  makeCurrent(_glContext);

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
void Surface::_setCanvasSize(int width, int height) {
  if (_canvasWidth != width || _canvasHeight != height) {
    emscripten_set_canvas_element_size(_canvasID.c_str(), width, height);
    _canvasWidth = width;
    _canvasHeight = height;
    _recreateSurface();
  }
}

// Worker thread only
void Surface::_recreateSurface() {
  makeCurrent(_glContext);
  GrBackendRenderTarget target(_canvasWidth, _canvasHeight, _sampleCount,
                               _stencil, _fbInfo);
  _surface = SkSurfaces::WrapBackendRenderTarget(
      _grContext.get(), target, kBottomLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, SkColorSpace::MakeSRGB(), nullptr);
}

// Worker thread only
void Surface::_renderPicture(const SkPicture* picture) {
  if (!_surface) {
    printf("Can't render picture with no surface.\n");
    return;
  }

  makeCurrent(_glContext);
  auto canvas = _surface->getCanvas();
  canvas->drawPicture(picture);
  _grContext->flush(_surface);
}

void Surface::_rasterizeImage(SkImage* image,
                              ImageByteFormat format,
                              uint32_t callbackId) {
  sk_sp<SkData> data;
  if (format == ImageByteFormat::png) {
    data = SkPngEncoder::Encode(_grContext.get(), image, {});
  } else {
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
    bool success = image->readPixels(_grContext.get(), image->imageInfo(),
                                     pixels, bytesPerRow, 0, 0);
    if (!success) {
      printf("Failed to read pixels from image!\n");
      data = nullptr;
    }
  }
  emscripten_sync_run_in_main_runtime_thread(
      EM_FUNC_SIG_VIII, fOnRasterizeComplete, this, data.release(), callbackId);
}

void Surface::_disposeVideoFrame(SkwasmObjectId objectId) {
  skwasm_disposeVideoFrame(objectId);
}

void Surface::_onRasterizeComplete(SkData* data, uint32_t callbackId) {
  _callbackHandler(callbackId, data);
}

// Worker thread only
void Surface::_notifyRenderComplete(uint32_t callbackId) {
  emscripten_sync_run_in_main_runtime_thread(EM_FUNC_SIG_VII, fOnRenderComplete,
                                             this, callbackId);
}

// Main thread only
void Surface::_onRenderComplete(uint32_t callbackId) {
  assert(emscripten_is_main_browser_thread());
  _callbackHandler(callbackId, nullptr);
}

void Surface::fDispose(Surface* surface) {
  surface->_dispose();
}

void Surface::fSetCanvasSize(Surface* surface, int width, int height) {
  surface->_setCanvasSize(width, height);
}

void Surface::fRenderPicture(Surface* surface, SkPicture* picture) {
  surface->_renderPicture(picture);
  picture->unref();
}

void Surface::fNotifyRenderComplete(Surface* surface, uint32_t callbackId) {
  surface->_notifyRenderComplete(callbackId);
}

void Surface::fOnRenderComplete(Surface* surface, uint32_t callbackId) {
  surface->_onRenderComplete(callbackId);
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

void Surface::fDisposeVideoFrame(Surface* surface,
                                 SkwasmObjectId videoFrameId) {
  surface->_disposeVideoFrame(videoFrameId);
}

SKWASM_EXPORT Surface* surface_createFromCanvas(const char* canvasID) {
  return new Surface(canvasID);
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

SKWASM_EXPORT void surface_setCanvasSize(Surface* surface,
                                         int width,
                                         int height) {
  surface->setCanvasSize(width, height);
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
