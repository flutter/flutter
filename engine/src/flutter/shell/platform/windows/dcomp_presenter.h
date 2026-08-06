// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_DCOMP_PRESENTER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_DCOMP_PRESENTER_H_

#include <d3d11_1.h>
#include <dcomp.h>
#include <dxgi1_3.h>
#include <windows.h>
#include <wrl/client.h>

#include <array>
#include <cstdint>
#include <memory>
#include <unordered_map>

#include "flutter/fml/macros.h"

namespace flutter {

/// Presents Vulkan-rendered content to a window through DirectComposition.
///
/// The presenter owns a Direct3D 11 device on the same adapter as the Vulkan
/// device (matched by LUID), a flip-model composition swapchain, and a
/// DirectComposition visual tree rooted on the window. It also allocates the
/// shared textures that Vulkan renders into: Windows drivers expose
/// Direct3D 11 texture memory to Vulkan as import-only, so the allocation
/// must originate here (see |CreateSharedTexture| and
/// |VulkanImportedImage|). Each frame, the shared texture is copied into the
/// swapchain backbuffer and presented; DWM then composes the window content
/// and chrome in one transaction, which is what makes resizing atomic.
///
/// Synchronization: the engine performs a host sync for all layers before
/// invoking the compositor present callback, so the Vulkan writes are
/// complete before the copy. The Direct3D side still brackets its access
/// with the shared texture's keyed mutex (acquire and release with key 0),
/// which issues the cross-device flushes on the adapter. If a driver ever
/// requires Vulkan-side participation in the keyed mutex, the acquire and
/// release must additionally be chained onto the final Vulkan submission
/// through VkWin32KeyedMutexAcquireReleaseInfoKHR; that requires an engine
/// hook and is deliberately not part of this presenter.
class DCompPresenter {
 public:
  /// Creates a presenter on the adapter identified by |adapter_luid| (from
  /// VulkanManager::GetDeviceLUID). Returns nullptr on failure. The
  /// presenter can allocate shared textures immediately; presentation
  /// additionally requires |BindToWindow|.
  static std::unique_ptr<DCompPresenter> Create(
      const std::array<uint8_t, 8>& adapter_luid);

  ~DCompPresenter();

  /// Roots the composition target on |hwnd|. Idempotent for the same
  /// window; rebinding to a different window replaces the target. Returns
  /// false on failure.
  bool BindToWindow(HWND hwnd);

  /// Allocates a shared BGRA8 render target texture of the given size with
  /// a keyed mutex, and returns the NT handle identifying it. Vulkan
  /// imports the handle via |VulkanImportedImage|. Returns nullptr on
  /// failure. The presenter owns the texture and the handle until
  /// |EvictTexture| is called with the returned handle.
  HANDLE CreateSharedTexture(uint32_t width, uint32_t height);

  /// Copies the shared texture identified by |nt_handle| into the swapchain
  /// and presents it. |width| and |height| are the texture dimensions; the
  /// swapchain is resized when they change. Returns false on failure.
  bool PresentTexture(HANDLE nt_handle, uint32_t width, uint32_t height);

  /// Destroys the shared texture for |nt_handle| and closes the handle.
  /// Call when the backing store owning the texture is collected.
  void EvictTexture(HANDLE nt_handle);

  /// The Direct3D device, exposed for tests.
  ID3D11Device1* GetD3DDeviceForTesting() const { return d3d_device_.Get(); }

 private:
  struct SharedTexture {
    Microsoft::WRL::ComPtr<ID3D11Texture2D> texture;
    Microsoft::WRL::ComPtr<IDXGIKeyedMutex> keyed_mutex;
  };

  DCompPresenter() = default;

  bool Initialize(const std::array<uint8_t, 8>& adapter_luid);
  bool EnsureSwapChain(uint32_t width, uint32_t height);

  Microsoft::WRL::ComPtr<ID3D11Device1> d3d_device_;
  Microsoft::WRL::ComPtr<ID3D11DeviceContext> d3d_context_;
  Microsoft::WRL::ComPtr<IDXGIFactory2> dxgi_factory_;
  Microsoft::WRL::ComPtr<IDXGISwapChain1> swapchain_;
  Microsoft::WRL::ComPtr<IDCompositionDevice> dcomp_device_;
  Microsoft::WRL::ComPtr<IDCompositionTarget> dcomp_target_;
  Microsoft::WRL::ComPtr<IDCompositionVisual> dcomp_visual_;

  std::unordered_map<HANDLE, SharedTexture> texture_cache_;
  HWND bound_hwnd_ = nullptr;
  uint32_t swapchain_width_ = 0;
  uint32_t swapchain_height_ = 0;
  bool committed_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(DCompPresenter);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_DCOMP_PRESENTER_H_
