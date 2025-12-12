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

  Surface();

  // General getters
  unsigned long getThreadId() { return _thread; }
  EMSCRIPTEN_WEBGL_CONTEXT_HANDLE getGlContext() { return _glContext; }

  // Lifecycle
  void setCallbackHandler(CallbackHandler* callbackHandler);
  void dispose();

  // Surface setup
  uint32_t setCanvas(SkwasmObject canvas);
  void onInitialized(uint32_t callbackId);
  void receiveCanvasOnWorker(SkwasmObject canvas, uint32_t callbackId);

  // Resizing
  uint32_t setSize(int width, int height);
  void onResizeComplete(uint32_t callbackId);
  void resizeOnWorker(int width, int height, uint32_t callbackId);

  // Rendering
  uint32_t renderPictures(flutter::DisplayList** picture, int count);
  void onRenderComplete(uint32_t callbackId, SkwasmObject imageBitmap);
  void renderPicturesOnWorker(sk_sp<flutter::DisplayList>* picture,
                              int pictureCount,
                              uint32_t callbackId,
                              double rasterStart);

  // Image Rasterization
  uint32_t rasterizeImage(flutter::DlImage* image, ImageByteFormat format);
  void onRasterizeComplete(uint32_t callbackId, SkData* data);
  void rasterizeImageOnWorker(flutter::DlImage* image,
                              ImageByteFormat format,
                              uint32_t callbackId);

  // Context Loss
  uint32_t triggerContextLoss();
  void onContextLossTriggered(uint32_t callbackId);
  void reportContextLost(uint32_t callbackId);
  void triggerContextLossOnWorker(uint32_t callbackId);
  void onContextLost();

  // Other
  void setResourceCacheLimit(int bytes);
  std::unique_ptr<TextureSourceWrapper> createTextureSourceWrapper(
      SkwasmObject textureSource);

 private:
  void _init();
  void _resizeSurface(int width, int height);
  void _recreateSurface();

  CallbackHandler* _callbackHandler = nullptr;
  inline static uint32_t _currentCallbackId = 0;

  int _canvasWidth = 0;
  int _canvasHeight = 0;

  EMSCRIPTEN_WEBGL_CONTEXT_HANDLE _glContext = 0;
  std::unique_ptr<RenderContext> _renderContext;
  uint32_t _contextLostCallbackId = 0;

  pthread_t _thread;

  bool _isInitialized = false;
};
}  // namespace Skwasm

#endif  // FLUTTER_LIB_WEB_UI_SKWASM_SURFACE_H_
