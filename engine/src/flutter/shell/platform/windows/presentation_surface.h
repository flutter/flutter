// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_PRESENTATION_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_PRESENTATION_SURFACE_H_

#include <d3d11.h>
#include <dcomp.h>
#include <dxgi1_3.h>
#include <presentation.h>
#include <windows.h>
#include <wrl/client.h>

#include <array>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/egl/manager.h"

namespace flutter {

// A DirectComposition-hosted Presentation Manager surface that ANGLE can render
// to from the raster thread.
class PresentationSurface {
 public:
  static std::unique_ptr<PresentationSurface> Create(HWND hwnd,
                                                     size_t width,
                                                     size_t height,
                                                     egl::Manager* egl_manager);
  virtual ~PresentationSurface();

  virtual bool IsValid() const;
  virtual bool Resize(size_t width, size_t height);
  virtual bool MakeCurrent();
  virtual bool Present();

  size_t width() const { return width_; }
  size_t height() const { return height_; }

 protected:
  PresentationSurface(size_t width, size_t height);

  size_t width_ = 0;
  size_t height_ = 0;

 private:
  struct PresentationBuffer {
    Microsoft::WRL::ComPtr<ID3D11Texture2D> texture;
    Microsoft::WRL::ComPtr<IPresentationBuffer> presentation_buffer;
    EGLSurface egl_surface = EGL_NO_SURFACE;
    HANDLE available_event = nullptr;
  };

  static constexpr size_t kBufferCount = 3;

  enum class Backend {
    kNone,
    kPresentationManager,
    kDxgiFallback,
  };

  PresentationSurface(HWND hwnd,
                      size_t width,
                      size_t height,
                      egl::Manager* egl_manager);

  bool Initialize();
  bool CreatePresentationManager();
  bool CreateDxgiFallback();
  bool CreateDirectCompositionVisual();
  bool CreateBuffers();
  bool CreateBuffer(PresentationBuffer& buffer);
  void DestroyBuffers();
  PresentationBuffer* AcquireBuffer();
  void DrainPresentStatistics();
  bool CreateDxgiFallbackBuffer();
  void DestroyDxgiFallbackBuffer();

  HWND hwnd_ = nullptr;
  egl::Manager* egl_manager_ = nullptr;
  Backend backend_ = Backend::kNone;

  Microsoft::WRL::ComPtr<ID3D11Device> d3d_device_;
  Microsoft::WRL::ComPtr<IDXGIDevice> dxgi_device_;
  Microsoft::WRL::ComPtr<IDXGIFactory2> dxgi_factory_;
  Microsoft::WRL::ComPtr<IDCompositionDevice> dcomp_device_;
  Microsoft::WRL::ComPtr<IDCompositionTarget> dcomp_target_;
  Microsoft::WRL::ComPtr<IDCompositionVisual> dcomp_root_visual_;
  Microsoft::WRL::ComPtr<IDCompositionVisual> dcomp_visual_;
  Microsoft::WRL::ComPtr<IUnknown> dcomp_surface_;
  Microsoft::WRL::ComPtr<IPresentationFactory> presentation_factory_;
  Microsoft::WRL::ComPtr<IPresentationManager> presentation_manager_;
  Microsoft::WRL::ComPtr<IPresentationSurface> presentation_surface_;
  HANDLE presentation_surface_handle_ = nullptr;
  HANDLE presentation_lost_event_ = nullptr;
  HANDLE presentation_statistics_event_ = nullptr;
  std::array<PresentationBuffer, kBufferCount> buffers_;
  PresentationBuffer* current_buffer_ = nullptr;
  Microsoft::WRL::ComPtr<IDXGISwapChain1> dxgi_swapchain_;
  Microsoft::WRL::ComPtr<IDXGISwapChain2> dxgi_swapchain2_;
  Microsoft::WRL::ComPtr<ID3D11Texture2D> dxgi_back_buffer_;
  EGLSurface dxgi_egl_surface_ = EGL_NO_SURFACE;

  FML_DISALLOW_COPY_AND_ASSIGN(PresentationSurface);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_PRESENTATION_SURFACE_H_
