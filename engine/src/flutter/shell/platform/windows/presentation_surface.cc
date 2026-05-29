// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/presentation_surface.h"

#include <EGL/eglext_angle.h>

#include "flutter/fml/logging.h"

namespace flutter {

namespace {

constexpr DXGI_FORMAT kPresentationFormat = DXGI_FORMAT_B8G8R8A8_UNORM;
constexpr DWORD kPresentationWaitTimeoutMs = 1000;

using CreatePresentationFactoryProc = HRESULT(
    WINAPI*)(IUnknown* d3dDevice, REFIID riid, void** presentationFactory);

CreatePresentationFactoryProc GetCreatePresentationFactory() {
  static CreatePresentationFactoryProc create_proc = [] {
    HMODULE dcomp = ::LoadLibraryW(L"dcomp.dll");
    if (!dcomp) {
      return static_cast<CreatePresentationFactoryProc>(nullptr);
    }
    return reinterpret_cast<CreatePresentationFactoryProc>(
        ::GetProcAddress(dcomp, "CreatePresentationFactory"));
  }();
  return create_proc;
}

}  // namespace

std::unique_ptr<PresentationSurface> PresentationSurface::Create(
    HWND hwnd,
    size_t width,
    size_t height,
    egl::Manager* egl_manager) {
  auto surface = std::unique_ptr<PresentationSurface>(
      new PresentationSurface(hwnd, width, height, egl_manager));
  if (!surface->Initialize()) {
    return nullptr;
  }
  return surface;
}

PresentationSurface::PresentationSurface(HWND hwnd,
                                         size_t width,
                                         size_t height,
                                         egl::Manager* egl_manager)
    : hwnd_(hwnd), width_(width), height_(height), egl_manager_(egl_manager) {}

PresentationSurface::PresentationSurface(size_t width, size_t height)
    : width_(width), height_(height) {}

PresentationSurface::~PresentationSurface() {
  DestroyBuffers();
  if (presentation_surface_handle_) {
    ::CloseHandle(presentation_surface_handle_);
    presentation_surface_handle_ = nullptr;
  }
  if (presentation_lost_event_) {
    ::CloseHandle(presentation_lost_event_);
    presentation_lost_event_ = nullptr;
  }
  if (presentation_statistics_event_) {
    ::CloseHandle(presentation_statistics_event_);
    presentation_statistics_event_ = nullptr;
  }
}

bool PresentationSurface::Initialize() {
  if (!hwnd_ || width_ == 0 || height_ == 0 || !egl_manager_) {
    return false;
  }

  if (!egl_manager_->GetDevice(&d3d_device_)) {
    FML_LOG(ERROR)
        << "Unable to get ANGLE D3D11 device for Presentation Manager.";
    return false;
  }

  HRESULT result = d3d_device_.As(&dxgi_device_);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to query ANGLE device for IDXGIDevice.";
    return false;
  }

  Microsoft::WRL::ComPtr<IDXGIAdapter> adapter;
  result = dxgi_device_->GetAdapter(&adapter);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to query DXGI adapter.";
    return false;
  }

  result = adapter->GetParent(IID_PPV_ARGS(&dxgi_factory_));
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to query DXGI factory.";
    return false;
  }

  if (!CreatePresentationManager()) {
    if (!CreateDxgiFallback()) {
      return false;
    }
  }
  if (!CreateDirectCompositionVisual()) {
    return false;
  }
  return CreateBuffers();
}

bool PresentationSurface::CreatePresentationManager() {
  auto create_presentation_factory = GetCreatePresentationFactory();
  if (!create_presentation_factory) {
    FML_LOG(INFO) << "Presentation Manager factory is unavailable; falling "
                     "back to DXGI composition swapchain.";
    return false;
  }

  HRESULT result = create_presentation_factory(
      d3d_device_.Get(), IID_PPV_ARGS(&presentation_factory_));
  if (FAILED(result)) {
    FML_LOG(INFO) << "Presentation Manager factory is unavailable; falling "
                     "back to DXGI composition swapchain.";
    return false;
  }

  if (!presentation_factory_->IsPresentationSupported()) {
    FML_LOG(INFO) << "Presentation Manager is not supported; falling back to "
                     "DXGI composition swapchain.";
    return false;
  }

  result =
      presentation_factory_->CreatePresentationManager(&presentation_manager_);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to create Presentation Manager.";
    return false;
  }

  result = presentation_manager_->GetLostEvent(&presentation_lost_event_);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to get Presentation Manager lost event.";
    return false;
  }

  result = presentation_manager_->GetPresentStatisticsAvailableEvent(
      &presentation_statistics_event_);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to get Presentation Manager statistics event.";
    return false;
  }

  presentation_manager_->EnablePresentStatisticsKind(
      PresentStatisticsKind_PresentStatus, true);
  presentation_manager_->EnablePresentStatisticsKind(
      PresentStatisticsKind_CompositionFrame, true);
  presentation_manager_->EnablePresentStatisticsKind(
      PresentStatisticsKind_IndependentFlipFrame, true);
  presentation_manager_->ForceVSyncInterrupt(true);

  backend_ = Backend::kPresentationManager;
  return true;
}

bool PresentationSurface::CreateDxgiFallback() {
  DXGI_SWAP_CHAIN_DESC1 desc = {};
  desc.Width = static_cast<UINT>(width_);
  desc.Height = static_cast<UINT>(height_);
  desc.Format = kPresentationFormat;
  desc.Stereo = FALSE;
  desc.SampleDesc.Count = 1;
  desc.SampleDesc.Quality = 0;
  desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
  desc.BufferCount = 2;
  desc.Scaling = DXGI_SCALING_STRETCH;
  desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
  desc.AlphaMode = DXGI_ALPHA_MODE_IGNORE;
  desc.Flags = DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT;

  HRESULT result = dxgi_factory_->CreateSwapChainForComposition(
      d3d_device_.Get(), &desc, nullptr, &dxgi_swapchain_);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to create DXGI fallback swapchain.";
    return false;
  }

  result = dxgi_swapchain_.As(&dxgi_swapchain2_);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to query IDXGISwapChain2 for fallback.";
    return false;
  }

  result = dxgi_swapchain2_->SetMaximumFrameLatency(1);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to set DXGI fallback maximum frame latency.";
    return false;
  }

  backend_ = Backend::kDxgiFallback;
  return true;
}

bool PresentationSurface::CreateDirectCompositionVisual() {
  if (backend_ == Backend::kPresentationManager) {
    HRESULT result = ::DCompositionCreateSurfaceHandle(
        COMPOSITIONOBJECT_ALL_ACCESS, nullptr, &presentation_surface_handle_);
    if (FAILED(result)) {
      FML_LOG(ERROR) << "Unable to create Presentation Manager surface handle.";
      return false;
    }

    result = presentation_manager_->CreatePresentationSurface(
        presentation_surface_handle_, &presentation_surface_);
    if (FAILED(result)) {
      FML_LOG(ERROR) << "Unable to create Presentation Manager surface.";
      return false;
    }

    RECT source_rect = {0, 0, static_cast<LONG>(width_),
                        static_cast<LONG>(height_)};
    presentation_surface_->SetSourceRect(&source_rect);
    presentation_surface_->SetAlphaMode(DXGI_ALPHA_MODE_IGNORE);
  }

  HRESULT result = ::DCompositionCreateDevice(dxgi_device_.Get(),
                                              IID_PPV_ARGS(&dcomp_device_));
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to create DirectComposition device.";
    return false;
  }

  result = dcomp_device_->CreateTargetForHwnd(hwnd_, TRUE, &dcomp_target_);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to create DirectComposition HWND target.";
    return false;
  }

  result = dcomp_device_->CreateVisual(&dcomp_root_visual_);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to create DirectComposition root visual.";
    return false;
  }

  result = dcomp_device_->CreateVisual(&dcomp_visual_);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to create DirectComposition visual.";
    return false;
  }

  if (backend_ == Backend::kPresentationManager) {
    result = dcomp_device_->CreateSurfaceFromHandle(
        presentation_surface_handle_, &dcomp_surface_);
    if (FAILED(result)) {
      FML_LOG(ERROR)
          << "Unable to create DirectComposition surface from presentation "
             "handle.";
      return false;
    }

    result = dcomp_visual_->SetContent(dcomp_surface_.Get());
  } else {
    result = dcomp_visual_->SetContent(dxgi_swapchain_.Get());
  }
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to attach presentation content to DComp visual.";
    return false;
  }

  result = dcomp_root_visual_->AddVisual(dcomp_visual_.Get(), FALSE, nullptr);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to attach DirectComposition visual.";
    return false;
  }

  result = dcomp_target_->SetRoot(dcomp_root_visual_.Get());
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to set DirectComposition root visual.";
    return false;
  }

  result = dcomp_device_->Commit();
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to commit DirectComposition visual tree.";
    return false;
  }

  return true;
}

bool PresentationSurface::CreateBuffers() {
  if (backend_ == Backend::kDxgiFallback) {
    return CreateDxgiFallbackBuffer();
  }

  DestroyBuffers();

  for (auto& buffer : buffers_) {
    if (!CreateBuffer(buffer)) {
      DestroyBuffers();
      return false;
    }
  }

  return true;
}

bool PresentationSurface::CreateBuffer(PresentationBuffer& buffer) {
  D3D11_TEXTURE2D_DESC texture_desc = {};
  texture_desc.Width = static_cast<UINT>(width_);
  texture_desc.Height = static_cast<UINT>(height_);
  texture_desc.MipLevels = 1;
  texture_desc.ArraySize = 1;
  texture_desc.Format = kPresentationFormat;
  texture_desc.SampleDesc.Count = 1;
  texture_desc.Usage = D3D11_USAGE_DEFAULT;
  texture_desc.BindFlags =
      D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET;
  texture_desc.MiscFlags = D3D11_RESOURCE_MISC_SHARED |
                           D3D11_RESOURCE_MISC_SHARED_NTHANDLE |
                           D3D11_RESOURCE_MISC_SHARED_DISPLAYABLE;

  HRESULT result =
      d3d_device_->CreateTexture2D(&texture_desc, nullptr, &buffer.texture);
  if (FAILED(result)) {
    texture_desc.MiscFlags =
        D3D11_RESOURCE_MISC_SHARED | D3D11_RESOURCE_MISC_SHARED_NTHANDLE;
    result =
        d3d_device_->CreateTexture2D(&texture_desc, nullptr, &buffer.texture);
  }
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to create presentation texture.";
    return false;
  }

  result = presentation_manager_->AddBufferFromResource(
      buffer.texture.Get(), &buffer.presentation_buffer);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to register presentation buffer.";
    return false;
  }

  result =
      buffer.presentation_buffer->GetAvailableEvent(&buffer.available_event);
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to get presentation buffer availability event.";
    return false;
  }

  EGLint attributes[] = {
      EGL_WIDTH,          static_cast<EGLint>(width_),
      EGL_HEIGHT,         static_cast<EGLint>(height_),
      EGL_TEXTURE_TARGET, EGL_TEXTURE_2D,
      EGL_TEXTURE_FORMAT, EGL_TEXTURE_RGBA,
      EGL_NONE,
  };

  buffer.egl_surface = egl_manager_->CreateSurfaceFromHandle(
      EGL_D3D_TEXTURE_ANGLE, buffer.texture.Get(), attributes);
  if (buffer.egl_surface == EGL_NO_SURFACE) {
    FML_LOG(ERROR) << "Unable to create EGL surface for presentation buffer.";
    return false;
  }

  return true;
}

void PresentationSurface::DestroyBuffers() {
  if (backend_ == Backend::kDxgiFallback) {
    DestroyDxgiFallbackBuffer();
    return;
  }

  current_buffer_ = nullptr;
  if (egl_manager_) {
    egl_manager_->render_context()->ClearCurrent();
  }

  for (auto& buffer : buffers_) {
    if (buffer.egl_surface != EGL_NO_SURFACE && egl_manager_) {
      eglDestroySurface(egl_manager_->egl_display(), buffer.egl_surface);
      buffer.egl_surface = EGL_NO_SURFACE;
    }
    if (buffer.available_event) {
      ::CloseHandle(buffer.available_event);
      buffer.available_event = nullptr;
    }
    buffer.presentation_buffer.Reset();
    buffer.texture.Reset();
  }
}

bool PresentationSurface::IsValid() const {
  if (backend_ == Backend::kPresentationManager) {
    return presentation_manager_ && presentation_surface_ &&
           buffers_[0].egl_surface != EGL_NO_SURFACE;
  }
  if (backend_ == Backend::kDxgiFallback) {
    return dxgi_swapchain2_ && dxgi_egl_surface_ != EGL_NO_SURFACE;
  }
  return false;
}

bool PresentationSurface::Resize(size_t width, size_t height) {
  if (width == 0 || height == 0) {
    return false;
  }
  if (width == width_ && height == height_) {
    return true;
  }

  DestroyBuffers();

  width_ = width;
  height_ = height;

  if (backend_ == Backend::kPresentationManager) {
    if (!presentation_surface_) {
      return false;
    }
    RECT source_rect = {0, 0, static_cast<LONG>(width_),
                        static_cast<LONG>(height_)};
    presentation_surface_->SetSourceRect(&source_rect);
  } else if (backend_ == Backend::kDxgiFallback) {
    if (!dxgi_swapchain_) {
      return false;
    }
    HRESULT result = dxgi_swapchain_->ResizeBuffers(
        0, static_cast<UINT>(width_), static_cast<UINT>(height_),
        DXGI_FORMAT_UNKNOWN,
        DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT);
    if (FAILED(result)) {
      FML_LOG(ERROR) << "Unable to resize DXGI fallback swapchain buffers.";
      return false;
    }
  }

  return CreateBuffers();
}

PresentationSurface::PresentationBuffer* PresentationSurface::AcquireBuffer() {
  if (!IsValid()) {
    return nullptr;
  }

  for (auto& buffer : buffers_) {
    boolean is_available = false;
    HRESULT result = buffer.presentation_buffer->IsAvailable(&is_available);
    if (SUCCEEDED(result) && is_available) {
      return &buffer;
    }
  }

  std::vector<HANDLE> handles;
  handles.push_back(presentation_lost_event_);
  for (auto& buffer : buffers_) {
    handles.push_back(buffer.available_event);
  }

  DWORD wait_result = ::WaitForMultipleObjects(
      static_cast<DWORD>(handles.size()), handles.data(), FALSE,
      kPresentationWaitTimeoutMs);
  if (wait_result == WAIT_OBJECT_0) {
    FML_LOG(ERROR) << "Presentation Manager surface was lost.";
    return nullptr;
  }
  if (wait_result <= WAIT_OBJECT_0 ||
      wait_result >= WAIT_OBJECT_0 + handles.size()) {
    FML_LOG(ERROR) << "Timed out waiting for a presentation buffer.";
    return nullptr;
  }

  return &buffers_[wait_result - (WAIT_OBJECT_0 + 1)];
}

bool PresentationSurface::MakeCurrent() {
  if (!IsValid()) {
    return false;
  }

  if (backend_ == Backend::kDxgiFallback) {
    return eglMakeCurrent(egl_manager_->egl_display(), dxgi_egl_surface_,
                          dxgi_egl_surface_,
                          egl_manager_->render_context()->GetHandle()) ==
           EGL_TRUE;
  }

  current_buffer_ = AcquireBuffer();
  if (!current_buffer_) {
    return false;
  }

  if (eglMakeCurrent(egl_manager_->egl_display(), current_buffer_->egl_surface,
                     current_buffer_->egl_surface,
                     egl_manager_->render_context()->GetHandle()) != EGL_TRUE) {
    current_buffer_ = nullptr;
    return false;
  }

  return true;
}

bool PresentationSurface::Present() {
  if (backend_ == Backend::kDxgiFallback) {
    if (!dxgi_swapchain_) {
      return false;
    }
    DXGI_PRESENT_PARAMETERS parameters = {};
    HRESULT result = dxgi_swapchain_->Present1(1, 0, &parameters);
    if (FAILED(result)) {
      FML_LOG(ERROR) << "DXGI fallback Present1 failed.";
      return false;
    }
    return true;
  }

  if (!presentation_manager_ || !presentation_surface_ || !current_buffer_) {
    return false;
  }

  HRESULT result = presentation_surface_->SetBuffer(
      current_buffer_->presentation_buffer.Get());
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to bind presentation buffer.";
    current_buffer_ = nullptr;
    return false;
  }

  SystemInterruptTime target_time = {};
  presentation_manager_->SetTargetTime(target_time);
  result = presentation_manager_->Present();
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Presentation Manager present failed.";
    current_buffer_ = nullptr;
    return false;
  }

  current_buffer_ = nullptr;
  DrainPresentStatistics();
  return true;
}

bool PresentationSurface::CreateDxgiFallbackBuffer() {
  DestroyDxgiFallbackBuffer();

  HRESULT result =
      dxgi_swapchain_->GetBuffer(0, IID_PPV_ARGS(&dxgi_back_buffer_));
  if (FAILED(result)) {
    FML_LOG(ERROR) << "Unable to get DXGI fallback backbuffer.";
    return false;
  }

  EGLint attributes[] = {
      EGL_WIDTH,          static_cast<EGLint>(width_),
      EGL_HEIGHT,         static_cast<EGLint>(height_),
      EGL_TEXTURE_TARGET, EGL_TEXTURE_2D,
      EGL_TEXTURE_FORMAT, EGL_TEXTURE_RGBA,
      EGL_NONE,
  };

  dxgi_egl_surface_ = egl_manager_->CreateSurfaceFromHandle(
      EGL_D3D_TEXTURE_ANGLE, dxgi_back_buffer_.Get(), attributes);
  if (dxgi_egl_surface_ == EGL_NO_SURFACE) {
    FML_LOG(ERROR) << "Unable to create EGL surface for DXGI fallback.";
    dxgi_back_buffer_.Reset();
    return false;
  }

  return true;
}

void PresentationSurface::DestroyDxgiFallbackBuffer() {
  if (dxgi_egl_surface_ != EGL_NO_SURFACE && egl_manager_) {
    egl_manager_->render_context()->ClearCurrent();
    eglDestroySurface(egl_manager_->egl_display(), dxgi_egl_surface_);
    dxgi_egl_surface_ = EGL_NO_SURFACE;
  }
  dxgi_back_buffer_.Reset();
}

void PresentationSurface::DrainPresentStatistics() {
  if (!presentation_manager_ || !presentation_statistics_event_) {
    return;
  }

  UINT drained_count = 0;
  while (::WaitForSingleObject(presentation_statistics_event_, 0) ==
             WAIT_OBJECT_0 &&
         drained_count < 1024) {
    Microsoft::WRL::ComPtr<IPresentStatistics> statistics;
    if (FAILED(presentation_manager_->GetNextPresentStatistics(&statistics)) ||
        !statistics) {
      break;
    }
    drained_count++;
  }
}

}  // namespace flutter
