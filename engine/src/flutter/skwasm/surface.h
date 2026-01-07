// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SKWASM_SURFACE_H_
#define FLUTTER_SKWASM_SURFACE_H_

#include <cassert>

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <emscripten.h>
#include <emscripten/html5_webgl.h>
#include <emscripten/threading.h>
#include <webgl/webgl1.h>

#include "flutter/display_list/image/dl_image.h"
#include "flutter/skwasm/export.h"
#include "flutter/skwasm/render_context.h"
#include "flutter/skwasm/wrappers.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkRefCnt.h"

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

  unsigned long GetThreadId() { return thread_; }

  // Main thread only
  void Dispose();
  void SetResourceCacheLimit(int bytes);
  uint32_t RenderPictures(flutter::DisplayList** pictures,
                          int width,
                          int height,
                          int count);
  uint32_t RasterizeImage(flutter::DlImage* image, ImageByteFormat format);
  void SetCallbackHandler(CallbackHandler* callback_handler);
  void OnRenderComplete(uint32_t callback_id, SkwasmObject image_bitmap);
  void OnRasterizeComplete(uint32_t callback_id, SkData* data);

  // Any thread
  std::unique_ptr<TextureSourceWrapper> CreateTextureSourceWrapper(
      SkwasmObject texture_source);

  // Worker thread
  void RenderPicturesOnWorker(sk_sp<flutter::DisplayList>* pictures,
                              int width,
                              int height,
                              int picture_count,
                              uint32_t callback_id,
                              double raster_start);
  void RasterizeImageOnWorker(flutter::DlImage* image,
                              ImageByteFormat format,
                              uint32_t callback_id);

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
  unsigned long thread_;

  bool is_initialized_ = false;
};
}  // namespace Skwasm

#endif  // FLUTTER_SKWASM_SURFACE_H_
