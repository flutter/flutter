// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <emscripten.h>
#include <emscripten/html5_webgl.h>
#include <emscripten/threading.h>
#include <webgl/webgl1.h>
#include <cassert>
#include "export.h"
#include "skwasm_support.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/encode/SkPngEncoder.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/SkSurfaceGanesh.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"
#include "third_party/skia/include/gpu/gl/GrGLTypes.h"
#include "wrappers.h"

namespace Skwasm {
// This must be kept in sync with the `ImageByteFormat` enum in dart:ui.
enum class ImageByteFormat {
  rawRgba,
  rawStraightRgba,
  rawUnmodified,
  png,
};

class Surface {
 public:
 public:
  using CallbackHandler = void(uint32_t, void*);

  // Main thread only
  Surface(const char* canvasID);

  unsigned long getThreadId() { return _thread; }

  // Main thread only
  void dispose();
  void setCanvasSize(int width, int height);
  uint32_t renderPicture(SkPicture* picture);
  uint32_t rasterizeImage(SkImage* image, ImageByteFormat format);
  void setCallbackHandler(CallbackHandler* callbackHandler);

  // Any thread
  void disposeVideoFrame(SkwasmObjectId videoFrameId);

 private:
  void _runWorker();
  void _init();
  void _dispose();
  void _setCanvasSize(int width, int height);
  void _recreateSurface();
  void _renderPicture(const SkPicture* picture);
  void _rasterizeImage(SkImage* image,
                       ImageByteFormat format,
                       uint32_t callbackId);
  void _disposeVideoFrame(SkwasmObjectId objectId);
  void _onRasterizeComplete(SkData* data, uint32_t callbackId);
  void _notifyRenderComplete(uint32_t callbackId);
  void _onRenderComplete(uint32_t callbackId);

  std::string _canvasID;
  CallbackHandler* _callbackHandler = nullptr;
  uint32_t _currentCallbackId = 0;

  int _canvasWidth = 0;
  int _canvasHeight = 0;

  EMSCRIPTEN_WEBGL_CONTEXT_HANDLE _glContext = 0;
  sk_sp<GrDirectContext> _grContext = nullptr;
  sk_sp<SkSurface> _surface = nullptr;
  GrGLFramebufferInfo _fbInfo;
  GrGLint _sampleCount;
  GrGLint _stencil;

  pthread_t _thread;

  static void fDispose(Surface* surface);
  static void fSetCanvasSize(Surface* surface, int width, int height);
  static void fRenderPicture(Surface* surface, SkPicture* picture);
  static void fNotifyRenderComplete(Surface* surface, uint32_t callbackId);
  static void fOnRenderComplete(Surface* surface, uint32_t callbackId);
  static void fRasterizeImage(Surface* surface,
                              SkImage* image,
                              ImageByteFormat format,
                              uint32_t callbackId);
  static void fOnRasterizeComplete(Surface* surface,
                                   SkData* imageData,
                                   uint32_t callbackId);
  static void fDisposeVideoFrame(Surface* surface, SkwasmObjectId videoFrameId);
};
}  // namespace Skwasm
