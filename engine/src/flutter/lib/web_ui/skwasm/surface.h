// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_WEB_UI_SKWASM_SURFACE_H_
#define FLUTTER_LIB_WEB_UI_SKWASM_SURFACE_H_

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
  TextureSourceWrapper(unsigned long threadId, SkwasmObject textureSource);
  ~TextureSourceWrapper();

  SkwasmObject getTextureSource();

 private:
  unsigned long _rasterThreadId;
};

class Surface {
 public:
  using CallbackHandler = void(uint32_t, void*, SkwasmObject);

  // Main thread only
  Surface();

  unsigned long getThreadId() { return _thread; }

  // Main thread only
  void dispose();
  void setResourceCacheLimit(int bytes);
  uint32_t renderPictures(flutter::DisplayList** picture,
                          int width,
                          int height,
                          int count);
  uint32_t rasterizeImage(flutter::DlImage* image, ImageByteFormat format);
  void setCallbackHandler(CallbackHandler* callbackHandler);
  void onRenderComplete(uint32_t callbackId, SkwasmObject imageBitmap);
  void onRasterizeComplete(uint32_t callbackId, SkData* data);

  // Any thread
  std::unique_ptr<TextureSourceWrapper> createTextureSourceWrapper(
      SkwasmObject textureSource);

  // Worker thread
  void renderPicturesOnWorker(sk_sp<flutter::DisplayList>* picture,
                              int width,
                              int height,
                              int pictureCount,
                              uint32_t callbackId,
                              double rasterStart);
  void rasterizeImageOnWorker(flutter::DlImage* image,
                              ImageByteFormat format,
                              uint32_t callbackId);

 private:
  void _init();
  void _resizeSurface(int width, int height);
  void _recreateSurface();

  CallbackHandler* _callbackHandler = nullptr;
  uint32_t _currentCallbackId = 0;

  int _canvasWidth = 0;
  int _canvasHeight = 0;

  EMSCRIPTEN_WEBGL_CONTEXT_HANDLE _glContext = 0;
  std::unique_ptr<RenderContext> _renderContext;

  pthread_t _thread;

  bool _isInitialized = false;
};
}  // namespace Skwasm

#endif  // FLUTTER_LIB_WEB_UI_SKWASM_SURFACE_H_
