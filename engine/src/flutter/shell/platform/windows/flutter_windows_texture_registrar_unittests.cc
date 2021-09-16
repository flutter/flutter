// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_texture_registrar.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/mock_gl_functions.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {
// Returns an engine instance configured with dummy project path values.
std::unique_ptr<FlutterWindowsEngine> GetTestEngine() {
  FlutterDesktopEngineProperties properties = {};
  properties.assets_path = L"C:\\foo\\flutter_assets";
  properties.icu_data_path = L"C:\\foo\\icudtl.dat";
  properties.aot_library_path = L"C:\\foo\\aot.so";
  FlutterProjectBundle project(properties);
  return std::make_unique<FlutterWindowsEngine>(project);
}
}  // namespace

TEST(FlutterWindowsTextureRegistrarTest, CreateDestroy) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();
  std::unique_ptr<MockGlFunctions> gl = std::make_unique<MockGlFunctions>();

  FlutterWindowsTextureRegistrar registrar(engine.get(), gl->gl_procs());

  EXPECT_TRUE(true);
}

TEST(FlutterWindowsTextureRegistrarTest, RegisterUnregisterTexture) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();
  EngineModifier modifier(engine.get());
  std::unique_ptr<MockGlFunctions> gl = std::make_unique<MockGlFunctions>();

  FlutterWindowsTextureRegistrar registrar(engine.get(), gl->gl_procs());

  FlutterDesktopTextureInfo texture_info = {};
  texture_info.type = kFlutterDesktopPixelBufferTexture;
  texture_info.pixel_buffer_config.callback =
      [](size_t width, size_t height,
         void* user_data) -> const FlutterDesktopPixelBuffer* {
    return nullptr;
  };

  int64_t registered_texture_id = 0;
  bool register_called = false;
  modifier.embedder_api().RegisterExternalTexture = MOCK_ENGINE_PROC(
      RegisterExternalTexture, ([&register_called, &registered_texture_id](
                                    auto engine, auto texture_id) {
        register_called = true;
        registered_texture_id = texture_id;
        return kSuccess;
      }));

  bool unregister_called = false;
  modifier.embedder_api().UnregisterExternalTexture = MOCK_ENGINE_PROC(
      UnregisterExternalTexture, ([&unregister_called, &registered_texture_id](
                                      auto engine, auto texture_id) {
        unregister_called = true;
        EXPECT_EQ(registered_texture_id, texture_id);
        return kSuccess;
      }));

  bool mark_frame_available_called = false;
  modifier.embedder_api().MarkExternalTextureFrameAvailable =
      MOCK_ENGINE_PROC(MarkExternalTextureFrameAvailable,
                       ([&mark_frame_available_called, &registered_texture_id](
                            auto engine, auto texture_id) {
                         mark_frame_available_called = true;
                         EXPECT_EQ(registered_texture_id, texture_id);
                         return kSuccess;
                       }));

  auto texture_id = registrar.RegisterTexture(&texture_info);
  EXPECT_TRUE(register_called);
  EXPECT_NE(texture_id, -1);
  EXPECT_EQ(texture_id, registered_texture_id);

  EXPECT_TRUE(registrar.MarkTextureFrameAvailable(texture_id));
  EXPECT_TRUE(mark_frame_available_called);

  EXPECT_TRUE(registrar.UnregisterTexture(texture_id));
  EXPECT_TRUE(unregister_called);
}

TEST(FlutterWindowsTextureRegistrarTest, RegisterUnknownTextureType) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();
  std::unique_ptr<MockGlFunctions> gl = std::make_unique<MockGlFunctions>();

  FlutterWindowsTextureRegistrar registrar(engine.get(), gl->gl_procs());

  FlutterDesktopTextureInfo texture_info = {};
  texture_info.type = static_cast<FlutterDesktopTextureType>(1234);

  auto texture_id = registrar.RegisterTexture(&texture_info);

  EXPECT_EQ(texture_id, -1);
}

TEST(FlutterWindowsTextureRegistrarTest, PopulatePixelBufferTexture) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();
  EngineModifier modifier(engine.get());
  std::unique_ptr<MockGlFunctions> gl = std::make_unique<MockGlFunctions>();

  FlutterWindowsTextureRegistrar registrar(engine.get(), gl->gl_procs());

  bool release_callback_called = false;
  size_t width = 100;
  size_t height = 100;
  std::unique_ptr<uint8_t[]> pixels(new uint8_t[width * height * 4]);
  FlutterDesktopPixelBuffer pixel_buffer = {};
  pixel_buffer.width = width;
  pixel_buffer.height = height;
  pixel_buffer.buffer = pixels.get();
  pixel_buffer.release_context = &release_callback_called;
  pixel_buffer.release_callback = [](void* release_context) {
    bool* called = reinterpret_cast<bool*>(release_context);
    *called = true;
  };

  FlutterDesktopTextureInfo texture_info = {};
  texture_info.type = kFlutterDesktopPixelBufferTexture;
  texture_info.pixel_buffer_config.user_data = &pixel_buffer;
  texture_info.pixel_buffer_config.callback =
      [](size_t width, size_t height,
         void* user_data) -> const FlutterDesktopPixelBuffer* {
    return reinterpret_cast<const FlutterDesktopPixelBuffer*>(user_data);
  };

  modifier.embedder_api().RegisterExternalTexture =
      MOCK_ENGINE_PROC(RegisterExternalTexture,
                       ([](auto engine, auto texture_id) { return kSuccess; }));

  FlutterOpenGLTexture flutter_texture = {};
  auto texture_id = registrar.RegisterTexture(&texture_info);
  EXPECT_NE(texture_id, -1);

  auto result =
      registrar.PopulateTexture(texture_id, 640, 480, &flutter_texture);
  EXPECT_TRUE(result);
  EXPECT_EQ(flutter_texture.width, width);
  EXPECT_EQ(flutter_texture.height, height);
  EXPECT_EQ(flutter_texture.target, GL_TEXTURE_2D);
  EXPECT_TRUE(release_callback_called);
}

TEST(FlutterWindowsTextureRegistrarTest, PopulateInvalidTexture) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();
  std::unique_ptr<MockGlFunctions> gl = std::make_unique<MockGlFunctions>();

  FlutterWindowsTextureRegistrar registrar(engine.get(), gl->gl_procs());

  auto result = registrar.PopulateTexture(1, 640, 480, nullptr);
  EXPECT_FALSE(result);
}

}  // namespace testing
}  // namespace flutter
