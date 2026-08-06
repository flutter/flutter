// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/dcomp_presenter.h"

#include "flutter/shell/platform/windows/vulkan_imported_image.h"
#include "flutter/shell/platform/windows/vulkan_manager.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

// A hidden top-level window to attach DirectComposition targets to.
class TestWindow {
 public:
  TestWindow() {
    WNDCLASS window_class = {};
    window_class.lpszClassName = L"FlutterDCompPresenterTestWindow";
    window_class.lpfnWndProc = ::DefWindowProc;
    window_class.hInstance = ::GetModuleHandle(nullptr);
    ::RegisterClass(&window_class);
    hwnd_ = ::CreateWindowEx(0, window_class.lpszClassName, L"", WS_POPUP, 0, 0,
                             320, 240, nullptr, nullptr, window_class.hInstance,
                             nullptr);
  }

  ~TestWindow() {
    if (hwnd_) {
      ::DestroyWindow(hwnd_);
    }
    ::UnregisterClass(L"FlutterDCompPresenterTestWindow",
                      ::GetModuleHandle(nullptr));
  }

  HWND hwnd() const { return hwnd_; }

 private:
  HWND hwnd_ = nullptr;
};

}  // namespace

// A LUID that matches no adapter must fail creation instead of silently
// using a different GPU, where the shared textures could not be imported
// by the Vulkan device.
TEST(DCompPresenterTest, CreateWithUnknownLuidFails) {
  std::array<uint8_t, 8> bogus_luid;
  bogus_luid.fill(0xFF);
  EXPECT_EQ(DCompPresenter::Create(bogus_luid), nullptr);
}

// Presentation requires a window binding; texture allocation does not.
TEST(DCompPresenterTest, PresentWithoutWindowBindingFails) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan with D3D11 interop is not available.";
  }

  auto presenter = DCompPresenter::Create(manager->GetDeviceLUID());
  ASSERT_NE(presenter, nullptr);

  EXPECT_FALSE(presenter->BindToWindow(nullptr));

  HANDLE handle = presenter->CreateSharedTexture(64, 64);
  ASSERT_NE(handle, nullptr);
  EXPECT_FALSE(presenter->PresentTexture(handle, 64, 64));

  presenter->EvictTexture(handle);
}

// The full interop pipeline: shared texture allocated on the Direct3D
// side, imported into Vulkan, then copied and presented through
// DirectComposition. This is the regression test for the Vulkan to DXGI
// handoff itself.
TEST(DCompPresenterTest, PresentsSharedTextureImportedByVulkan) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan with D3D11 interop is not available.";
  }

  TestWindow window;
  ASSERT_NE(window.hwnd(), nullptr);

  auto presenter = DCompPresenter::Create(manager->GetDeviceLUID());
  ASSERT_NE(presenter, nullptr);
  ASSERT_TRUE(presenter->BindToWindow(window.hwnd()));

  EXPECT_EQ(presenter->CreateSharedTexture(0, 256), nullptr);

  HANDLE handle = presenter->CreateSharedTexture(256, 256);
  ASSERT_NE(handle, nullptr);

  auto image = VulkanImportedImage::Import(manager.get(), handle, 256, 256);
  ASSERT_NE(image, nullptr);
  EXPECT_NE(image->image(), VK_NULL_HANDLE);

  // First present commits the visual tree; repeats exercise the steady
  // state and the keyed mutex round trips.
  EXPECT_TRUE(presenter->PresentTexture(handle, 256, 256));
  EXPECT_TRUE(presenter->PresentTexture(handle, 256, 256));
  EXPECT_TRUE(presenter->PresentTexture(handle, 256, 256));

  // The imported image must be released before the texture is evicted:
  // this mirrors the backing store collect order in the compositor.
  image.reset();
  presenter->EvictTexture(handle);
  EXPECT_FALSE(presenter->PresentTexture(handle, 256, 256));
}

// A size change resizes the swapchain in place and keeps presenting.
TEST(DCompPresenterTest, ResizeRecreatesSwapchainBuffers) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan with D3D11 interop is not available.";
  }

  TestWindow window;
  ASSERT_NE(window.hwnd(), nullptr);

  auto presenter = DCompPresenter::Create(manager->GetDeviceLUID());
  ASSERT_NE(presenter, nullptr);
  ASSERT_TRUE(presenter->BindToWindow(window.hwnd()));

  // Note: |small| is a macro in the Windows headers; avoid it as a name.
  HANDLE small_texture = presenter->CreateSharedTexture(256, 256);
  HANDLE large_texture = presenter->CreateSharedTexture(512, 384);
  ASSERT_NE(small_texture, nullptr);
  ASSERT_NE(large_texture, nullptr);

  EXPECT_TRUE(presenter->PresentTexture(small_texture, 256, 256));
  EXPECT_TRUE(presenter->PresentTexture(large_texture, 512, 384));
  EXPECT_TRUE(presenter->PresentTexture(small_texture, 256, 256));

  presenter->EvictTexture(small_texture);
  presenter->EvictTexture(large_texture);
}

// Repeated allocate, import, and evict cycles model the engine collecting
// and recreating backing stores across resizes; nothing may leak or crash.
TEST(DCompPresenterTest, RepeatedSharedTextureLifecycle) {
  auto manager = VulkanManager::Create();
  if (!manager) {
    GTEST_SKIP() << "Vulkan with D3D11 interop is not available.";
  }

  TestWindow window;
  ASSERT_NE(window.hwnd(), nullptr);

  auto presenter = DCompPresenter::Create(manager->GetDeviceLUID());
  ASSERT_NE(presenter, nullptr);
  ASSERT_TRUE(presenter->BindToWindow(window.hwnd()));

  for (int i = 0; i < 8; i++) {
    HANDLE handle = presenter->CreateSharedTexture(128 + i, 128 + i);
    ASSERT_NE(handle, nullptr);
    auto image =
        VulkanImportedImage::Import(manager.get(), handle, 128 + i, 128 + i);
    ASSERT_NE(image, nullptr);
    image.reset();
    presenter->EvictTexture(handle);
  }
}

}  // namespace testing
}  // namespace flutter
