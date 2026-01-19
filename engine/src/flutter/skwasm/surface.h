// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SKWASM_SURFACE_H_
#define FLUTTER_SKWASM_SURFACE_H_

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <emscripten.h>
#include <emscripten/html5_webgl.h>
#include <emscripten/threading.h>
#include <webgl/webgl1.h>
#include <cassert>
#include "export.h"
#include "render_context.h"
#include "wrappers.h"

namespace flutter {
class DisplayList;
}

namespace Skwasm {

class TextureSourceWrapper {
 public:
  TextureSourceWrapper(unsigned long thread_id, SkwasmObject texture_source);
  ~TextureSourceWrapper();

  SkwasmObject GetTextureSource();

 private:
  unsigned long raster_thread_id_;
};

class Surface {
 public:
  using CallbackHandler = void(uint32_t, void*, SkwasmObject);

  // Main thread only
  Surface();

  // General getters
  unsigned long GetThreadId() { return thread_; }
  EMSCRIPTEN_WEBGL_CONTEXT_HANDLE GetGlContext() { return gl_context_; }

  // Lifecycle
  void SetCallbackHandler(CallbackHandler* callback_handler);
  void Dispose();

  // Surface setup
  uint32_t SetCanvas(SkwasmObject canvas);
  void OnInitialized(uint32_t callback_id);
  void ReceiveCanvasOnWorker(SkwasmObject canvas, uint32_t callback_id);

  // Resizing
  uint32_t SetSize(int width, int height);
  void OnResizeComplete(uint32_t callback_id);
  void ResizeOnWorker(int width, int height, uint32_t callback_id);

  // Rendering
  uint32_t RenderPictures(flutter::DisplayList** picture, int count);
  void OnRenderComplete(uint32_t callback_id, SkwasmObject image_bitmap);
  void RenderPicturesOnWorker(sk_sp<flutter::DisplayList>* picture,
                              int picture_count,
                              uint32_t callback_id,
                              double raster_start);

  // Image Rasterization
  uint32_t RasterizeImage(flutter::DlImage* image, ImageByteFormat format);
  void OnRasterizeComplete(uint32_t callback_id, SkData* data);
  void RasterizeImageOnWorker(flutter::DlImage* image,
                              ImageByteFormat format,
                              uint32_t callback_id);

  // Context Loss
  uint32_t TriggerContextLoss();
  void OnContextLossTriggered(uint32_t callback_id);
  void ReportContextLost(uint32_t callback_id);
  void TriggerContextLossOnWorker(uint32_t callback_id);
  void OnContextLost();

  // Other
  void SetResourceCacheLimit(int bytes);
  std::unique_ptr<TextureSourceWrapper> CreateTextureSourceWrapper(
      SkwasmObject textureSource);

 private:
  void Init();
  void ResizeSurface(int width, int height);
  void RecreateSurface();

  CallbackHandler* callback_handler_ = nullptr;
  uint32_t current_callback_id_ = 0;

  int canvas_width_ = 0;
  int canvas_height_ = 0;

  EMSCRIPTEN_WEBGL_CONTEXT_HANDLE gl_context_ = 0;
  std::unique_ptr<RenderContext> render_context_;
  uint32_t context_lost_callback_id_ = 0;

  unsigned long thread_;

  bool is_initialized_ = false;
};
}  // namespace Skwasm

#endif  // FLUTTER_SKWASM_SURFACE_H_
