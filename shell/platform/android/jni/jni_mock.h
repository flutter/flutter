// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_MOCK_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_MOCK_H_

#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "gmock/gmock.h"

namespace flutter {

//------------------------------------------------------------------------------
/// Mock for |PlatformViewAndroidJNI|. This implementation can be used in unit
/// tests without requiring the Android toolchain.
///
class JNIMock final : public PlatformViewAndroidJNI {
 public:
  MOCK_METHOD(void,
              FlutterViewHandlePlatformMessage,
              (fml::RefPtr<flutter::PlatformMessage> message, int responseId),
              (override));

  MOCK_METHOD(void,
              FlutterViewHandlePlatformMessageResponse,
              (int responseId, std::unique_ptr<fml::Mapping> data),
              (override));

  MOCK_METHOD(void,
              FlutterViewUpdateSemantics,
              (std::vector<uint8_t> buffer, std::vector<std::string> strings),
              (override));

  MOCK_METHOD(void,
              FlutterViewUpdateCustomAccessibilityActions,
              (std::vector<uint8_t> actions_buffer,
               std::vector<std::string> strings),
              (override));

  MOCK_METHOD(void, FlutterViewOnFirstFrame, (), (override));

  MOCK_METHOD(void, FlutterViewOnPreEngineRestart, (), (override));

  MOCK_METHOD(void,
              SurfaceTextureAttachToGLContext,
              (JavaWeakGlobalRef surface_texture, int textureId),
              (override));

  MOCK_METHOD(void,
              SurfaceTextureUpdateTexImage,
              (JavaWeakGlobalRef surface_texture),
              (override));

  MOCK_METHOD(void,
              SurfaceTextureGetTransformMatrix,
              (JavaWeakGlobalRef surface_texture, SkMatrix& transform),
              (override));

  MOCK_METHOD(void,
              SurfaceTextureDetachFromGLContext,
              (JavaWeakGlobalRef surface_texture),
              (override));

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

  MOCK_METHOD(std::unique_ptr<PlatformViewAndroidJNI::OverlayMetadata>,
              FlutterViewCreateOverlaySurface,
              (),
              (override));

  MOCK_METHOD(void, FlutterViewDestroyOverlaySurfaces, (), (override));

  MOCK_METHOD(std::unique_ptr<std::vector<std::string>>,
              FlutterViewComputePlatformResolvedLocale,
              (std::vector<std::string> supported_locales_data),
              (override));

  MOCK_METHOD(double, GetDisplayRefreshRate, (), (override));
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_MOCK_H_
