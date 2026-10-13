// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_DELEGATE_MOCK_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_DELEGATE_MOCK_H_

#include <memory>

#include "flutter/shell/platform/embedder/android/external_view_embedder/surface_pool.h"
#include "gmock/gmock.h"

namespace flutter {

class ExternalViewEmbedderDelegateMock final
    : public AndroidExternalViewEmbedderDelegate {
 public:
  MOCK_METHOD(void,
              FlutterViewOnDisplayPlatformView,
              (int view_id,
               int x,
               int y,
               int width,
               int height,
               int viewWidth,
               int viewHeight,
               MutatorsStack mutators_stack),
              (override));

  MOCK_METHOD(void,
              FlutterViewDisplayOverlaySurface,
              (int surface_id, int x, int y, int width, int height),
              (override));

  MOCK_METHOD(void, FlutterViewBeginFrame, (), (override));

  MOCK_METHOD(void, FlutterViewEndFrame, (), (override));

  MOCK_METHOD(
      std::unique_ptr<AndroidExternalViewEmbedderDelegate::OverlayMetadata>,
      FlutterViewCreateOverlaySurface,
      (),
      (override));

  MOCK_METHOD(void, FlutterViewDestroyOverlaySurfaces, (), (override));

  MOCK_METHOD(void, swapTransaction, (), (override));

  MOCK_METHOD(void, destroyOverlaySurface2, (), (override));

  MOCK_METHOD(
      std::unique_ptr<AndroidExternalViewEmbedderDelegate::OverlayMetadata>,
      createOverlaySurface2,
      (),
      (override));

  MOCK_METHOD(void,
              onDisplayPlatformView2,
              (int32_t view_id,
               int32_t x,
               int32_t y,
               int32_t width,
               int32_t height,
               int32_t viewWidth,
               int32_t viewHeight,
               MutatorsStack mutators_stack),
              (override));

  MOCK_METHOD(void, hidePlatformView2, (int32_t view_id), (override));
  MOCK_METHOD(void, onEndFrame2, (), (override));
  MOCK_METHOD(void, hideOverlaySurface2, (), (override));
  MOCK_METHOD(void, showOverlaySurface2, (), (override));

  MOCK_METHOD(void,
              MaybeResizeSurfaceView,
              (int32_t width, int32_t height),
              (const, override));
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_ANDROID_EXTERNAL_VIEW_EMBEDDER_EXTERNAL_VIEW_EMBEDDER_DELEGATE_MOCK_H_
