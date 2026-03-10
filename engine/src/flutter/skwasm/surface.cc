// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/surface.h"

#include <algorithm>

#include <emscripten/wasm_worker.h>

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/skwasm/live_objects.h"
#include "flutter/skwasm/skwasm_support.h"
#include "third_party/skia/include/core/SkColorSpace.h"

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

Skwasm::Surface::Surface() {
  if (skwasm_isSingleThreaded()) {
    skwasm_connectThread(0);
  } else {
    assert(emscripten_is_main_browser_thread());

    thread_ = emscripten_malloc_wasm_worker(65536);
    emscripten_wasm_worker_post_function_v(thread_, []() {
      // Listen to the main thread from the worker
      skwasm_connectThread(0);
    });

    // Listen to messages from the worker
    skwasm_connectThread(thread_);
  }
}

// General getters are implemented in the header.

// Lifecycle

void Skwasm::Surface::SetCallbackHandler(CallbackHandler* callback_handler) {
  assert(emscripten_is_main_browser_thread());
  callback_handler_ = callback_handler;
}

void Skwasm::Surface::Dispose() {
  if (gl_context_) {
    skwasm_destroyContext(gl_context_);
  }
  delete this;
}

// Main thread only
uint32_t Skwasm::Surface::SetCanvas(SkwasmObject canvas) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callback_id = ++current_callback_id_;
  skwasm_dispatchTransferCanvas(thread_, this, canvas, callback_id);
  return callback_id;
}

void Skwasm::Surface::OnInitialized(uint32_t callback_id) {
  assert(emscripten_is_main_browser_thread());
  callback_handler_(callback_id, (void*)context_lost_callback_id_,
                    __builtin_wasm_ref_null_extern());
}

// Worker thread only
void Skwasm::Surface::ReceiveCanvasOnWorker(SkwasmObject canvas,
                                            uint32_t callback_id) {
  if (render_context_) {
    render_context_.reset();
  }
  canvas_width_ = 1;
  canvas_height_ = 1;
  gl_context_ = skwasm_getGlContextForCanvas(canvas, this);
  if (!gl_context_) {
    printf("Failed to create context!\n");
    return;
  }

  Skwasm::makeCurrent(gl_context_);
  emscripten_webgl_enable_extension(gl_context_, "WEBGL_debug_renderer_info");

  // WebGL should already be clearing the color and stencil buffers, but do it
  // again here to ensure Skia receives them in the expected state.
  emscripten_glBindFramebuffer(GL_FRAMEBUFFER, 0);
  emscripten_glClearColor(0, 0, 0, 0);
  emscripten_glClearStencil(0);
  emscripten_glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

  int sample_count;
  int stencil;
  emscripten_glGetIntegerv(GL_SAMPLES, &sample_count);
  emscripten_glGetIntegerv(GL_STENCIL_BITS, &stencil);

  render_context_ = Skwasm::RenderContext::Make(sample_count, stencil);
  render_context_->Resize(canvas_width_, canvas_height_);

  context_lost_callback_id_ = ++current_callback_id_;

  skwasm_reportInitialized(this, context_lost_callback_id_, callback_id);
}

// Resizing

uint32_t Skwasm::Surface::SetSize(int width, int height) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callback_id = ++current_callback_id_;

  skwasm_dispatchResizeSurface(thread_, this, width, height, callback_id);
  return callback_id;
}

void Skwasm::Surface::OnResizeComplete(uint32_t callback_id) {
  assert(emscripten_is_main_browser_thread());
  callback_handler_(callback_id, nullptr, __builtin_wasm_ref_null_extern());
}

void Skwasm::Surface::ResizeOnWorker(int width,
                                     int height,
                                     uint32_t callback_id) {
  ResizeSurface(width, height);
  skwasm_reportResizeComplete(this, callback_id);
}

void Skwasm::Surface::ResizeSurface(int width, int height) {
  if (width != canvas_width_ || height != canvas_height_) {
    canvas_width_ = width;
    canvas_height_ = height;
    RecreateSurface();
  }
}

// Rendering

uint32_t Skwasm::Surface::RenderPictures(flutter::DisplayList** pictures,
                                         int count) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callback_id = ++current_callback_id_;
  std::unique_ptr<sk_sp<flutter::DisplayList>[]> picture_pointers =
      std::make_unique<sk_sp<flutter::DisplayList>[]>(count);
  for (int i = 0; i < count; i++) {
    picture_pointers[i] = sk_ref_sp(pictures[i]);
  }

  // Releasing picture_pointers here and will recreate the unique_ptr on the
  // other thread See surface_renderPicturesOnWorker
  skwasm_dispatchRenderPictures(thread_, this, picture_pointers.release(),
                                count, callback_id);
  return callback_id;
}

void Skwasm::Surface::OnRenderComplete(uint32_t callback_id,
                                       SkwasmObject image_bitmap) {
  assert(emscripten_is_main_browser_thread());
  callback_handler_(callback_id, nullptr, image_bitmap);
}

void Skwasm::Surface::RenderPicturesOnWorker(
    sk_sp<flutter::DisplayList>* pictures,
    int picture_count,
    uint32_t callback_id,
    double raster_start) {
  Skwasm::makeCurrent(gl_context_);
  // This is initialized on the first call to `skwasm_captureImageBitmap` and
  // then populated with more bitmaps on subsequent calls.
  SkwasmObject image_bitmap_array = __builtin_wasm_ref_null_extern();
  for (int i = 0; i < picture_count; i++) {
    sk_sp<flutter::DisplayList> picture = pictures[i];
    render_context_->RenderPicture(picture);
    image_bitmap_array =
        skwasm_captureImageBitmap(gl_context_, image_bitmap_array);
  }
  skwasm_resolveAndPostImages(this, image_bitmap_array, raster_start,
                              callback_id);
}

// Image Rasterization

uint32_t Skwasm::Surface::RasterizeImage(flutter::DlImage* image,
                                         Skwasm::ImageByteFormat format) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callback_id = ++current_callback_id_;
  image->ref();

  skwasm_dispatchRasterizeImage(thread_, this, image, format, callback_id);
  return callback_id;
}

void Skwasm::Surface::OnRasterizeComplete(uint32_t callback_id, SkData* data) {
  assert(emscripten_is_main_browser_thread());
  callback_handler_(callback_id, data, __builtin_wasm_ref_null_extern());
}

void Skwasm::Surface::RasterizeImageOnWorker(flutter::DlImage* image,
                                             Skwasm::ImageByteFormat format,
                                             uint32_t callback_id) {
  // We handle PNG encoding with browser APIs so that we can omit libpng from
  // skia to save binary size.
  assert(format != Skwasm::ImageByteFormat::png);
  Skwasm::makeCurrent(gl_context_);
  SkAlphaType alpha_type = format == Skwasm::ImageByteFormat::rawStraightRgba
                               ? SkAlphaType::kUnpremul_SkAlphaType
                               : SkAlphaType::kPremul_SkAlphaType;
  SkImageInfo info = SkImageInfo::Make(image->width(), image->height(),
                                       SkColorType::kRGBA_8888_SkColorType,
                                       alpha_type, SkColorSpace::MakeSRGB());
  sk_sp<SkData> data;
  size_t bytes_per_row = 4 * image->width();
  size_t byte_size = info.computeByteSize(bytes_per_row);
  data = SkData::MakeUninitialized(byte_size);
  uint8_t* pixels = reinterpret_cast<uint8_t*>(data->writable_data());

  // TODO(jacksongardner):
  // Normally we'd just call `readPixels` on the image. However, this doesn't
  // actually work in some cases due to a skia bug. Instead, we just draw the
  // image to our scratch canvas and grab the pixels out directly with
  // `glReadPixels`. Once the skia bug is fixed, we should switch back to using
  // `SkImage::readPixels` instead.
  // See https://g-issues.skia.org/issues/349201915
  render_context_->RenderImage(image, format);

  emscripten_glReadPixels(0, 0, image->width(), image->height(), GL_RGBA,
                          GL_UNSIGNED_BYTE, reinterpret_cast<void*>(pixels));

  image->unref();
  skwasm_postRasterizeResult(this, data.release(), callback_id);
}

// Context Loss

uint32_t Skwasm::Surface::TriggerContextLoss() {
  assert(emscripten_is_main_browser_thread());
  uint32_t callback_id = ++current_callback_id_;
  skwasm_dispatchTriggerContextLoss(thread_, this, callback_id);
  return callback_id;
}

void Skwasm::Surface::OnContextLossTriggered(uint32_t callback_id) {
  assert(emscripten_is_main_browser_thread());
  callback_handler_(callback_id, nullptr, __builtin_wasm_ref_null_extern());
}

void Skwasm::Surface::ReportContextLost(uint32_t callback_id) {
  assert(emscripten_is_main_browser_thread());
  callback_handler_(callback_id, nullptr, __builtin_wasm_ref_null_extern());
}

void Skwasm::Surface::TriggerContextLossOnWorker(uint32_t callback_id) {
  Skwasm::makeCurrent(gl_context_);
  skwasm_triggerContextLossOnCanvas();
  skwasm_reportContextLossTriggered(this, callback_id);
}

void Skwasm::Surface::OnContextLost() {
  if (!context_lost_callback_id_) {
    printf("Received context lost event but never set callback handler!\n");
    return;
  }
  skwasm_reportContextLost(this, context_lost_callback_id_);
}

// Other

void Skwasm::Surface::SetResourceCacheLimit(int bytes) {
  render_context_->SetResourceCacheLimit(bytes);
}

std::unique_ptr<Skwasm::TextureSourceWrapper>
Skwasm::Surface::CreateTextureSourceWrapper(SkwasmObject texture_source) {
  return std::unique_ptr<Skwasm::TextureSourceWrapper>(
      new Skwasm::TextureSourceWrapper(thread_, texture_source));
}

// Private methods

void Skwasm::Surface::RecreateSurface() {
  Skwasm::makeCurrent(gl_context_);
  skwasm_resizeCanvas(gl_context_, canvas_width_, canvas_height_);
  render_context_->Resize(canvas_width_, canvas_height_);
}

// TextureSourceWrapper implementation

Skwasm::TextureSourceWrapper::TextureSourceWrapper(unsigned long thread_id,
                                                   SkwasmObject texture_source)
    : raster_thread_id_(thread_id) {
  skwasm_setAssociatedObjectOnThread(thread_id, this, texture_source);
}

Skwasm::TextureSourceWrapper::~TextureSourceWrapper() {
  skwasm_disposeAssociatedObjectOnThread(raster_thread_id_, this);
}

SkwasmObject Skwasm::TextureSourceWrapper::GetTextureSource() {
  return skwasm_getAssociatedObject(this);
}

// C-style API

SKWASM_EXPORT Skwasm::Surface* surface_create() {
  Skwasm::live_surface_count++;
  return new Skwasm::Surface();
}

SKWASM_EXPORT uint32_t surface_setCanvas(Skwasm::Surface* surface,
                                         SkwasmObject canvas) {
  // Dispatch to the worker so the canvas can be transferred to the worker.
  return surface->SetCanvas(canvas);
}

SKWASM_EXPORT void surface_receiveCanvasOnWorker(Skwasm::Surface* surface,
                                                 SkwasmObject canvas,
                                                 uint32_t callback_id) {
  surface->ReceiveCanvasOnWorker(canvas, callback_id);
}

SKWASM_EXPORT void surface_onInitialized(Skwasm::Surface* surface,
                                         uint32_t callback_id) {
  surface->OnInitialized(callback_id);
}

SKWASM_EXPORT uint32_t surface_setSize(Skwasm::Surface* surface,
                                       int width,
                                       int height) {
  return surface->SetSize(width, height);
}

SKWASM_EXPORT void surface_resizeOnWorker(Skwasm::Surface* surface,
                                          int width,
                                          int height,
                                          uint32_t callback_id) {
  surface->ResizeOnWorker(width, height, callback_id);
}

SKWASM_EXPORT void surface_onResizeComplete(Skwasm::Surface* surface,
                                            uint32_t callback_id) {
  surface->OnResizeComplete(callback_id);
}

SKWASM_EXPORT unsigned long surface_getThreadId(Skwasm::Surface* surface) {
  return surface->GetThreadId();
}

SKWASM_EXPORT EMSCRIPTEN_WEBGL_CONTEXT_HANDLE
surface_getGlContext(Skwasm::Surface* surface) {
  return surface->GetGlContext();
}

SKWASM_EXPORT uint32_t surface_triggerContextLoss(Skwasm::Surface* surface) {
  return surface->TriggerContextLoss();
}

SKWASM_EXPORT void surface_triggerContextLossOnWorker(Skwasm::Surface* surface,
                                                      uint32_t callback_id) {
  surface->TriggerContextLossOnWorker(callback_id);
}

SKWASM_EXPORT void surface_onContextLossTriggered(Skwasm::Surface* surface,
                                                  uint32_t callback_id) {
  surface->OnContextLossTriggered(callback_id);
}

SKWASM_EXPORT void surface_reportContextLost(Skwasm::Surface* surface,
                                             uint32_t callback_id) {
  surface->ReportContextLost(callback_id);
}

SKWASM_EXPORT void surface_setCallbackHandler(
    Skwasm::Surface* surface,
    Skwasm::Surface::CallbackHandler* callback_handler) {
  surface->SetCallbackHandler(callback_handler);
}

SKWASM_EXPORT void surface_destroy(Skwasm::Surface* surface) {
  Skwasm::live_surface_count--;
  // Dispatch to the worker
  skwasm_dispatchDisposeSurface(surface->GetThreadId(), surface);
}

SKWASM_EXPORT void surface_dispose(Skwasm::Surface* surface) {
  // This should be called directly only on the worker
  surface->Dispose();
}

SKWASM_EXPORT void surface_setResourceCacheLimitBytes(Skwasm::Surface* surface,
                                                      int bytes) {
  surface->SetResourceCacheLimit(bytes);
}

SKWASM_EXPORT uint32_t surface_renderPictures(Skwasm::Surface* surface,
                                              flutter::DisplayList** pictures,
                                              int count) {
  return surface->RenderPictures(pictures, count);
}

SKWASM_EXPORT void surface_renderPicturesOnWorker(
    Skwasm::Surface* surface,
    sk_sp<flutter::DisplayList>* pictures,
    int picture_count,
    uint32_t callback_id,
    double raster_start) {
  // This will release the pictures when they leave scope.
  std::unique_ptr<sk_sp<flutter::DisplayList>[]> pictures_pointer =
      std::unique_ptr<sk_sp<flutter::DisplayList>[]>(pictures);
  surface->RenderPicturesOnWorker(pictures, picture_count, callback_id,
                                  raster_start);
}

SKWASM_EXPORT uint32_t surface_rasterizeImage(Skwasm::Surface* surface,
                                              flutter::DlImage* image,
                                              Skwasm::ImageByteFormat format) {
  return surface->RasterizeImage(image, format);
}

SKWASM_EXPORT void surface_rasterizeImageOnWorker(
    Skwasm::Surface* surface,
    flutter::DlImage* image,
    Skwasm::ImageByteFormat format,
    uint32_t callback_id) {
  surface->RasterizeImageOnWorker(image, format, callback_id);
}

// This is used by the skwasm JS support code to call back into C++ when the
// we finish creating the image bitmap, which is an asynchronous operation.
SKWASM_EXPORT void surface_onRenderComplete(Skwasm::Surface* surface,
                                            uint32_t callback_id,
                                            SkwasmObject image_bitmap) {
  surface->OnRenderComplete(callback_id, image_bitmap);
}

SKWASM_EXPORT void surface_onRasterizeComplete(Skwasm::Surface* surface,
                                               SkData* data,
                                               uint32_t callback_id) {
  surface->OnRasterizeComplete(callback_id, data);
}

SKWASM_EXPORT void surface_onContextLost(Skwasm::Surface* surface) {
  surface->OnContextLost();
}

SKWASM_EXPORT bool skwasm_isMultiThreaded() {
  return !skwasm_isSingleThreaded();
}
