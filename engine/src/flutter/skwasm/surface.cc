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

// Worker thread only
void Skwasm::Surface::Dispose() {
  delete this;
}

// Main thread only
void Skwasm::Surface::SetResourceCacheLimit(int bytes) {
  render_context_->SetResourceCacheLimit(bytes);
}

// Main thread only
uint32_t Skwasm::Surface::RenderPictures(flutter::DisplayList** pictures,
                                         int width,
                                         int height,
                                         int count) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callback_id = ++current_callback_id_;
  std::unique_ptr<sk_sp<flutter::DisplayList>[]> picture_pointers =
      std::make_unique<sk_sp<flutter::DisplayList>[]>(count);
  for (int i = 0; i < count; i++) {
    picture_pointers[i] = sk_ref_sp(pictures[i]);
  }

  // Releasing picturePointers here and will recreate the unique_ptr on the
  // other thread See surface_renderPicturesOnWorker
  skwasm_dispatchRenderPictures(thread_, this, picture_pointers.release(),
                                width, height, count, callback_id);
  return callback_id;
}

// Main thread only
uint32_t Skwasm::Surface::RasterizeImage(flutter::DlImage* image,
                                         Skwasm::ImageByteFormat format) {
  assert(emscripten_is_main_browser_thread());
  uint32_t callback_id = ++current_callback_id_;
  image->ref();

  skwasm_dispatchRasterizeImage(thread_, this, image, format, callback_id);
  return callback_id;
}

std::unique_ptr<Skwasm::TextureSourceWrapper>
Skwasm::Surface::CreateTextureSourceWrapper(
    Skwasm::SkwasmObject texture_source) {
  return std::unique_ptr<Skwasm::TextureSourceWrapper>(
      new Skwasm::TextureSourceWrapper(thread_, texture_source));
}

// Main thread only
void Skwasm::Surface::SetCallbackHandler(
    Skwasm::Surface::CallbackHandler* callback_handler) {
  assert(emscripten_is_main_browser_thread());
  callback_handler_ = callback_handler;
}

// Worker thread only
void Skwasm::Surface::Init() {
  // 256x256 is just an arbitrary size for the initial canvas, so that we can
  // get a gl context off of it.
  gl_context_ = skwasm_createOffscreenCanvas(256, 256);
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
  render_context_->Resize(256, 256);

  is_initialized_ = true;
}

// Worker thread only
void Skwasm::Surface::ResizeSurface(int width, int height) {
  if (width != canvas_width_ || height != canvas_height_) {
    canvas_width_ = width;
    canvas_height_ = height;
    RecreateSurface();
  }
}

// Worker thread only
void Skwasm::Surface::RecreateSurface() {
  Skwasm::makeCurrent(gl_context_);
  skwasm_resizeCanvas(gl_context_, canvas_width_, canvas_height_);
  render_context_->Resize(canvas_width_, canvas_height_);
}

// Worker thread only
void Skwasm::Surface::RenderPicturesOnWorker(
    sk_sp<flutter::DisplayList>* pictures,
    int width,
    int height,
    int picture_count,
    uint32_t callback_id,
    double raster_start) {
  if (!is_initialized_) {
    Init();
  }

  // This is initialized on the first call to `skwasm_captureImageBitmap` and
  // then populated with more bitmaps on subsequent calls.
  Skwasm::SkwasmObject image_bitmap_array = __builtin_wasm_ref_null_extern();
  for (int i = 0; i < picture_count; i++) {
    sk_sp<flutter::DisplayList> picture = pictures[i];
    ResizeSurface(width, height);
    Skwasm::makeCurrent(gl_context_);

    render_context_->RenderPicture(picture);

    image_bitmap_array =
        skwasm_captureImageBitmap(gl_context_, image_bitmap_array);
  }
  skwasm_resolveAndPostImages(this, image_bitmap_array, raster_start,
                              callback_id);
}

// Worker thread only
void Skwasm::Surface::RasterizeImageOnWorker(flutter::DlImage* image,
                                             Skwasm::ImageByteFormat format,
                                             uint32_t callback_id) {
  if (!is_initialized_) {
    Init();
  }

  // We handle PNG encoding with browser APIs so that we can omit libpng from
  // skia to save binary size.
  assert(format != Skwasm::ImageByteFormat::png);
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
  ResizeSurface(image->width(), image->height());

  render_context_->RenderImage(image, format);

  emscripten_glReadPixels(0, 0, image->width(), image->height(), GL_RGBA,
                          GL_UNSIGNED_BYTE, reinterpret_cast<void*>(pixels));

  image->unref();
  skwasm_postRasterizeResult(this, data.release(), callback_id);
}

void Skwasm::Surface::OnRasterizeComplete(uint32_t callback_id, SkData* data) {
  callback_handler_(callback_id, data, __builtin_wasm_ref_null_extern());
}

// Main thread only
void Skwasm::Surface::OnRenderComplete(uint32_t callback_id,
                                       Skwasm::SkwasmObject image_bitmap) {
  assert(emscripten_is_main_browser_thread());
  callback_handler_(callback_id, nullptr, image_bitmap);
}

Skwasm::TextureSourceWrapper::TextureSourceWrapper(
    unsigned long thread_id,
    Skwasm::SkwasmObject texture_source)
    : raster_thread_id_(thread_id) {
  skwasm_setAssociatedObjectOnThread(raster_thread_id_, this, texture_source);
}

Skwasm::TextureSourceWrapper::~TextureSourceWrapper() {
  skwasm_disposeAssociatedObjectOnThread(raster_thread_id_, this);
}

Skwasm::SkwasmObject Skwasm::TextureSourceWrapper::GetTextureSource() {
  return skwasm_getAssociatedObject(this);
}

SKWASM_EXPORT Skwasm::Surface* surface_create() {
  Skwasm::live_surface_count++;
  return new Skwasm::Surface();
}

SKWASM_EXPORT unsigned long surface_getThreadId(Skwasm::Surface* surface) {
  return surface->GetThreadId();
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
                                              int width,
                                              int height,
                                              int count) {
  return surface->RenderPictures(pictures, width, height, count);
}

SKWASM_EXPORT void surface_renderPicturesOnWorker(
    Skwasm::Surface* surface,
    sk_sp<flutter::DisplayList>* pictures,
    int width,
    int height,
    int picture_count,
    uint32_t callback_id,
    double raster_start) {
  // This will release the pictures when they leave scope.
  std::unique_ptr<sk_sp<flutter::DisplayList>[]> pictures_pointer =
      std::unique_ptr<sk_sp<flutter::DisplayList>[]>(pictures);
  surface->RenderPicturesOnWorker(pictures, width, height, picture_count,
                                  callback_id, raster_start);
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
                                            Skwasm::SkwasmObject image_bitmap) {
  surface->OnRenderComplete(callback_id, image_bitmap);
}

SKWASM_EXPORT void surface_onRasterizeComplete(Skwasm::Surface* surface,
                                               SkData* data,
                                               uint32_t callback_id) {
  surface->OnRasterizeComplete(callback_id, data);
}

SKWASM_EXPORT bool skwasm_isMultiThreaded() {
  return !skwasm_isSingleThreaded();
}
