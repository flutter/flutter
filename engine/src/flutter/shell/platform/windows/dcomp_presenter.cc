// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/dcomp_presenter.h"

#include <cstring>

#include "flutter/fml/logging.h"

namespace flutter {

namespace {

// Both sides of the shared texture access it under key 0; each acquires and
// releases with the same key so the next acquire succeeds. See the class
// comment in the header for the synchronization contract.
constexpr uint64_t kKeyedMutexKey = 0;

// How long to wait for the keyed mutex before dropping the frame. The
// Vulkan work is host-synced before present, so contention can only come
// from a previous copy still in flight; 100ms is far beyond any sane frame.
constexpr DWORD kAcquireTimeoutMs = 100;

}  // namespace

// static
std::unique_ptr<DCompPresenter> DCompPresenter::Create(
    const std::array<uint8_t, 8>& adapter_luid) {
  auto presenter = std::unique_ptr<DCompPresenter>(new DCompPresenter());
  if (!presenter->Initialize(adapter_luid)) {
    return nullptr;
  }
  return presenter;
}

DCompPresenter::~DCompPresenter() = default;

bool DCompPresenter::Initialize(const std::array<uint8_t, 8>& adapter_luid) {
  Microsoft::WRL::ComPtr<IDXGIFactory2> factory;
  HRESULT hr = ::CreateDXGIFactory2(0, IID_PPV_ARGS(&factory));
  if (FAILED(hr)) {
    FML_LOG(ERROR) << "DCompPresenter: CreateDXGIFactory2 failed (hr=" << hr
                   << ").";
    return false;
  }

  // Open the adapter the Vulkan device renders on. Creating the Direct3D
  // device on any other adapter would make the shared textures unopenable.
  Microsoft::WRL::ComPtr<IDXGIAdapter1> adapter;
  Microsoft::WRL::ComPtr<IDXGIAdapter1> candidate;
  for (UINT i = 0;
       factory->EnumAdapters1(i, candidate.ReleaseAndGetAddressOf()) !=
       DXGI_ERROR_NOT_FOUND;
       i++) {
    DXGI_ADAPTER_DESC1 desc;
    if (FAILED(candidate->GetDesc1(&desc))) {
      continue;
    }
    static_assert(sizeof(desc.AdapterLuid) == 8,
                  "LUID size mismatch with VK_LUID_SIZE");
    if (std::memcmp(&desc.AdapterLuid, adapter_luid.data(), 8) == 0) {
      adapter = candidate;
      break;
    }
  }
  if (!adapter) {
    FML_LOG(ERROR) << "DCompPresenter: No DXGI adapter matches the Vulkan "
                      "device LUID.";
    return false;
  }

  UINT flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT;
  Microsoft::WRL::ComPtr<ID3D11Device> device;
  Microsoft::WRL::ComPtr<ID3D11DeviceContext> context;
  hr = ::D3D11CreateDevice(adapter.Get(), D3D_DRIVER_TYPE_UNKNOWN, nullptr,
                           flags, nullptr, 0, D3D11_SDK_VERSION, &device,
                           nullptr, &context);
  if (FAILED(hr)) {
    FML_LOG(ERROR) << "DCompPresenter: D3D11CreateDevice failed (hr=" << hr
                   << ").";
    return false;
  }
  if (FAILED(device.As(&d3d_device_))) {
    FML_LOG(ERROR) << "DCompPresenter: ID3D11Device1 is unavailable.";
    return false;
  }
  d3d_context_ = std::move(context);
  dxgi_factory_ = std::move(factory);

  Microsoft::WRL::ComPtr<IDXGIDevice> dxgi_device;
  if (FAILED(d3d_device_.As(&dxgi_device))) {
    FML_LOG(ERROR) << "DCompPresenter: IDXGIDevice is unavailable.";
    return false;
  }

  hr = ::DCompositionCreateDevice(dxgi_device.Get(),
                                  IID_PPV_ARGS(&dcomp_device_));
  if (FAILED(hr)) {
    FML_LOG(ERROR) << "DCompPresenter: DCompositionCreateDevice failed (hr="
                   << hr << ").";
    return false;
  }

  hr = dcomp_device_->CreateVisual(&dcomp_visual_);
  if (FAILED(hr)) {
    FML_LOG(ERROR) << "DCompPresenter: CreateVisual failed (hr=" << hr << ").";
    return false;
  }

  return true;
}

bool DCompPresenter::BindToWindow(HWND hwnd) {
  if (!hwnd) {
    return false;
  }
  if (hwnd == bound_hwnd_) {
    return true;
  }

  Microsoft::WRL::ComPtr<IDCompositionTarget> target;
  HRESULT hr =
      dcomp_device_->CreateTargetForHwnd(hwnd, /*topmost=*/TRUE, &target);
  if (FAILED(hr)) {
    FML_LOG(ERROR) << "DCompPresenter: CreateTargetForHwnd failed (hr=" << hr
                   << ").";
    return false;
  }

  hr = target->SetRoot(dcomp_visual_.Get());
  if (FAILED(hr)) {
    FML_LOG(ERROR) << "DCompPresenter: SetRoot failed (hr=" << hr << ").";
    return false;
  }

  dcomp_target_ = std::move(target);
  bound_hwnd_ = hwnd;
  // The new target needs a commit before its content becomes visible.
  committed_ = false;
  return true;
}

bool DCompPresenter::EnsureSwapChain(uint32_t width, uint32_t height) {
  if (swapchain_ && swapchain_width_ == width && swapchain_height_ == height) {
    return true;
  }

  if (swapchain_) {
    // Flip-model resizing requires all backbuffer references to be dropped.
    d3d_context_->ClearState();
    d3d_context_->Flush();
    HRESULT hr =
        swapchain_->ResizeBuffers(0, width, height, DXGI_FORMAT_UNKNOWN, 0);
    if (FAILED(hr)) {
      FML_LOG(ERROR) << "DCompPresenter: ResizeBuffers failed (hr=" << hr
                     << ").";
      return false;
    }
    swapchain_width_ = width;
    swapchain_height_ = height;
    return true;
  }

  DXGI_SWAP_CHAIN_DESC1 desc = {};
  desc.Width = width;
  desc.Height = height;
  desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  desc.SampleDesc.Count = 1;
  desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
  desc.BufferCount = 2;
  desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL;
  desc.AlphaMode = DXGI_ALPHA_MODE_PREMULTIPLIED;

  HRESULT hr = dxgi_factory_->CreateSwapChainForComposition(
      d3d_device_.Get(), &desc, nullptr, &swapchain_);
  if (FAILED(hr)) {
    FML_LOG(ERROR)
        << "DCompPresenter: CreateSwapChainForComposition failed (hr=" << hr
        << ").";
    return false;
  }

  swapchain_width_ = width;
  swapchain_height_ = height;

  hr = dcomp_visual_->SetContent(swapchain_.Get());
  if (FAILED(hr)) {
    FML_LOG(ERROR) << "DCompPresenter: SetContent failed (hr=" << hr << ").";
    return false;
  }
  committed_ = false;
  return true;
}

HANDLE DCompPresenter::CreateSharedTexture(uint32_t width, uint32_t height) {
  if (width == 0 || height == 0) {
    return nullptr;
  }

  D3D11_TEXTURE2D_DESC desc = {};
  desc.Width = width;
  desc.Height = height;
  desc.MipLevels = 1;
  desc.ArraySize = 1;
  desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  desc.SampleDesc.Count = 1;
  desc.Usage = D3D11_USAGE_DEFAULT;
  desc.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
  desc.MiscFlags = D3D11_RESOURCE_MISC_SHARED_KEYEDMUTEX |
                   D3D11_RESOURCE_MISC_SHARED_NTHANDLE;

  SharedTexture entry;
  HRESULT hr = d3d_device_->CreateTexture2D(&desc, nullptr, &entry.texture);
  if (FAILED(hr)) {
    FML_LOG(ERROR) << "DCompPresenter: CreateTexture2D failed (hr=" << hr
                   << ").";
    return nullptr;
  }
  if (FAILED(entry.texture.As(&entry.keyed_mutex))) {
    FML_LOG(ERROR) << "DCompPresenter: Shared texture has no keyed mutex.";
    return nullptr;
  }

  Microsoft::WRL::ComPtr<IDXGIResource1> resource;
  if (FAILED(entry.texture.As(&resource))) {
    FML_LOG(ERROR) << "DCompPresenter: IDXGIResource1 is unavailable.";
    return nullptr;
  }

  HANDLE nt_handle = nullptr;
  hr = resource->CreateSharedHandle(
      nullptr, DXGI_SHARED_RESOURCE_READ | DXGI_SHARED_RESOURCE_WRITE, nullptr,
      &nt_handle);
  if (FAILED(hr) || nt_handle == nullptr) {
    FML_LOG(ERROR) << "DCompPresenter: CreateSharedHandle failed (hr=" << hr
                   << ").";
    return nullptr;
  }

  texture_cache_.emplace(nt_handle, std::move(entry));
  return nt_handle;
}

bool DCompPresenter::PresentTexture(HANDLE nt_handle,
                                    uint32_t width,
                                    uint32_t height) {
  if (!nt_handle || width == 0 || height == 0) {
    return false;
  }
  if (!bound_hwnd_) {
    FML_LOG(ERROR) << "DCompPresenter: PresentTexture requires BindToWindow.";
    return false;
  }
  if (!EnsureSwapChain(width, height)) {
    return false;
  }

  auto it = texture_cache_.find(nt_handle);
  if (it == texture_cache_.end()) {
    FML_LOG(ERROR) << "DCompPresenter: Unknown shared texture handle.";
    return false;
  }
  SharedTexture* shared = &it->second;

  Microsoft::WRL::ComPtr<ID3D11Texture2D> backbuffer;
  HRESULT hr = swapchain_->GetBuffer(0, IID_PPV_ARGS(&backbuffer));
  if (FAILED(hr)) {
    FML_LOG(ERROR) << "DCompPresenter: GetBuffer failed (hr=" << hr << ").";
    return false;
  }

  hr = shared->keyed_mutex->AcquireSync(kKeyedMutexKey, kAcquireTimeoutMs);
  if (hr != S_OK) {
    // WAIT_TIMEOUT and abandoned-mutex results both mean the frame cannot
    // be copied safely; drop it rather than stall the raster thread.
    FML_LOG(ERROR) << "DCompPresenter: AcquireSync failed (hr=" << hr << ").";
    return false;
  }

  d3d_context_->CopyResource(backbuffer.Get(), shared->texture.Get());
  shared->keyed_mutex->ReleaseSync(kKeyedMutexKey);

  hr = swapchain_->Present(0, 0);
  if (FAILED(hr)) {
    FML_LOG(ERROR) << "DCompPresenter: Present failed (hr=" << hr << ").";
    return false;
  }

  // The visual tree only changes on the first present and on resize; DWM
  // picks up swapchain presents without a new commit.
  if (!committed_) {
    hr = dcomp_device_->Commit();
    if (FAILED(hr)) {
      FML_LOG(ERROR) << "DCompPresenter: Commit failed (hr=" << hr << ").";
      return false;
    }
    committed_ = true;
  }

  return true;
}

void DCompPresenter::EvictTexture(HANDLE nt_handle) {
  auto it = texture_cache_.find(nt_handle);
  if (it == texture_cache_.end()) {
    return;
  }
  texture_cache_.erase(it);
  ::CloseHandle(nt_handle);
}

}  // namespace flutter
