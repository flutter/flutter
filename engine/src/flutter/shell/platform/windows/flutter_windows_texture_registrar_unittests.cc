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

using Microsoft::WRL::ComPtr;

namespace {
// Returns an engine instance configured with dummy project path values.
std::unique_ptr<FlutterWindowsEngine> GetTestEngine() {
  FlutterDesktopEngineProperties properties = {};
  properties.assets_path = L"C:\\foo\\flutter_assets";
  properties.icu_data_path = L"C:\\foo\\icudtl.dat";
  properties.aot_library_path = L"C:\\foo\\aot.so";
  FlutterProjectBundle project(properties);
  auto engine = std::make_unique<FlutterWindowsEngine>(project);

  EngineModifier modifier(engine.get());
  modifier.embedder_api().RegisterExternalTexture =
      MOCK_ENGINE_PROC(RegisterExternalTexture,
                       ([](auto engine, auto texture_id) { return kSuccess; }));

  return engine;
}

// Creates a ID3D11Texture2D with the specified size.
ComPtr<ID3D11Texture2D> CreateD3dTexture(FlutterWindowsEngine* engine,
                                         UINT width,
                                         UINT height) {
  ComPtr<ID3D11Device> d3d_device;
  ComPtr<ID3D11Texture2D> d3d_texture;
  if (engine->surface_manager()->GetDevice(d3d_device.GetAddressOf())) {
    D3D11_TEXTURE2D_DESC texture_description = {};
    texture_description.MipLevels = 1;
    texture_description.SampleDesc.Count = 1;
    texture_description.BindFlags = D3D11_BIND_RENDER_TARGET;
    texture_description.Usage = D3D11_USAGE_DEFAULT;
    texture_description.CPUAccessFlags = 0;
    texture_description.ArraySize = 1;
    texture_description.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    texture_description.Height = width;
    texture_description.Width = height;
    texture_description.MiscFlags = D3D11_RESOURCE_MISC_SHARED;

    d3d_device->CreateTexture2D(&texture_description, nullptr,
                                d3d_texture.GetAddressOf());
  }
  return d3d_texture;
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
  std::unique_ptr<MockGlFunctions> gl = std::make_unique<MockGlFunctions>();
  FlutterWindowsTextureRegistrar registrar(engine.get(), gl->gl_procs());

  bool release_callback_called = false;
  size_t width = 100;
  size_t height = 100;
  std::unique_ptr<uint8_t[]> pixels =
      std::make_unique<uint8_t[]>(width * height * 4);
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

TEST(FlutterWindowsTextureRegistrarTest, PopulateD3dTextureWithHandle) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();
  std::unique_ptr<MockGlFunctions> gl = std::make_unique<MockGlFunctions>();
  FlutterWindowsTextureRegistrar registrar(engine.get(), gl->gl_procs());

  UINT width = 100;
  UINT height = 100;
  auto d3d_texture = CreateD3dTexture(engine.get(), width, height);
  EXPECT_TRUE(d3d_texture);

  ComPtr<IDXGIResource> shared_resource;
  EXPECT_TRUE(SUCCEEDED(d3d_texture.As(&shared_resource)));

  HANDLE shared_handle;
  EXPECT_TRUE(SUCCEEDED(shared_resource->GetSharedHandle(&shared_handle)));

  bool release_callback_called = false;
  FlutterDesktopGpuSurfaceDescriptor surface_descriptor = {};
  surface_descriptor.struct_size = sizeof(FlutterDesktopGpuSurfaceDescriptor);
  surface_descriptor.handle = shared_handle;
  surface_descriptor.width = surface_descriptor.visible_width = width;
  surface_descriptor.height = surface_descriptor.visible_height = height;
  surface_descriptor.release_context = &release_callback_called;
  surface_descriptor.release_callback = [](void* release_context) {
    bool* called = reinterpret_cast<bool*>(release_context);
    *called = true;
  };

  FlutterDesktopTextureInfo texture_info = {};
  texture_info.type = kFlutterDesktopGpuSurfaceTexture;
  texture_info.gpu_surface_config.struct_size =
      sizeof(FlutterDesktopGpuSurfaceTextureConfig);
  texture_info.gpu_surface_config.type =
      kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle;
  texture_info.gpu_surface_config.user_data = &surface_descriptor;
  texture_info.gpu_surface_config.callback =
      [](size_t width, size_t height,
         void* user_data) -> const FlutterDesktopGpuSurfaceDescriptor* {
    return reinterpret_cast<const FlutterDesktopGpuSurfaceDescriptor*>(
        user_data);
  };

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

TEST(FlutterWindowsTextureRegistrarTest, PopulateD3dTexture) {
  std::unique_ptr<FlutterWindowsEngine> engine = GetTestEngine();
  std::unique_ptr<MockGlFunctions> gl = std::make_unique<MockGlFunctions>();
  FlutterWindowsTextureRegistrar registrar(engine.get(), gl->gl_procs());

  UINT width = 100;
  UINT height = 100;
  auto d3d_texture = CreateD3dTexture(engine.get(), width, height);
  EXPECT_TRUE(d3d_texture);

  bool release_callback_called = false;
  FlutterDesktopGpuSurfaceDescriptor surface_descriptor = {};
  surface_descriptor.struct_size = sizeof(FlutterDesktopGpuSurfaceDescriptor);
  surface_descriptor.handle = d3d_texture.Get();
  surface_descriptor.width = surface_descriptor.visible_width = width;
  surface_descriptor.height = surface_descriptor.visible_height = height;
  surface_descriptor.release_context = &release_callback_called;
  surface_descriptor.release_callback = [](void* release_context) {
    bool* called = reinterpret_cast<bool*>(release_context);
    *called = true;
  };

  FlutterDesktopTextureInfo texture_info = {};
  texture_info.type = kFlutterDesktopGpuSurfaceTexture;
  texture_info.gpu_surface_config.struct_size =
      sizeof(FlutterDesktopGpuSurfaceTextureConfig);
  texture_info.gpu_surface_config.type =
      kFlutterDesktopGpuSurfaceTypeD3d11Texture2D;
  texture_info.gpu_surface_config.user_data = &surface_descriptor;
  texture_info.gpu_surface_config.callback =
      [](size_t width, size_t height,
         void* user_data) -> const FlutterDesktopGpuSurfaceDescriptor* {
    return reinterpret_cast<const FlutterDesktopGpuSurfaceDescriptor*>(
        user_data);
  };

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
