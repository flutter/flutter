// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/shell_test_platform_view_metal.h"

#import <Metal/Metal.h>

#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/gpu/gpu_surface_metal_skia.h"
#include "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetal.h"

namespace flutter {
namespace testing {

static fml::scoped_nsprotocol<id<MTLTexture>> CreateOffscreenTexture(id<MTLDevice> device) {
  auto descriptor =
      [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                         width:800
                                                        height:600
                                                     mipmapped:NO];
  descriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
  return fml::scoped_nsprotocol<id<MTLTexture>>{[device newTextureWithDescriptor:descriptor]};
}

// This is out of the header so that shell_test_platform_view_metal.h can be included in
// non-Objective-C TUs.
class DarwinContextMetal {
 public:
  DarwinContextMetal()
      : context_([[FlutterDarwinContextMetal alloc] initWithDefaultMTLDevice]),
        offscreen_texture_(CreateOffscreenTexture([context_.get() device])) {}

  ~DarwinContextMetal() = default;

  fml::scoped_nsobject<FlutterDarwinContextMetal> context() const { return context_; }

  fml::scoped_nsprotocol<id<MTLTexture>> offscreen_texture() const { return offscreen_texture_; }

  GPUMTLTextureInfo offscreen_texture_info() const {
    GPUMTLTextureInfo info = {};
    info.texture_id = 0;
    info.texture = reinterpret_cast<GPUMTLTextureHandle>(offscreen_texture_.get());
    return info;
  }

 private:
  const fml::scoped_nsobject<FlutterDarwinContextMetal> context_;
  const fml::scoped_nsprotocol<id<MTLTexture>> offscreen_texture_;

  FML_DISALLOW_COPY_AND_ASSIGN(DarwinContextMetal);
};

ShellTestPlatformViewMetal::ShellTestPlatformViewMetal(
    PlatformView::Delegate& delegate,
    TaskRunners task_runners,
    std::shared_ptr<ShellTestVsyncClock> vsync_clock,
    CreateVsyncWaiter create_vsync_waiter,
    std::shared_ptr<ShellTestExternalViewEmbedder> shell_test_external_view_embedder)
    : ShellTestPlatformView(delegate, std::move(task_runners)),
      GPUSurfaceMetalDelegate(MTLRenderTargetType::kMTLTexture),
      metal_context_(std::make_unique<DarwinContextMetal>()),
      create_vsync_waiter_(std::move(create_vsync_waiter)),
      vsync_clock_(vsync_clock),
      shell_test_external_view_embedder_(shell_test_external_view_embedder) {
  FML_CHECK([metal_context_->context() mainContext] != nil);
}

ShellTestPlatformViewMetal::~ShellTestPlatformViewMetal() = default;

std::unique_ptr<VsyncWaiter> ShellTestPlatformViewMetal::CreateVSyncWaiter() {
  return create_vsync_waiter_();
}

// |ShellTestPlatformView|
void ShellTestPlatformViewMetal::SimulateVSync() {
  vsync_clock_->SimulateVSync();
}

// |PlatformView|
std::shared_ptr<ExternalViewEmbedder> ShellTestPlatformViewMetal::CreateExternalViewEmbedder() {
  return shell_test_external_view_embedder_;
}

// |PlatformView|
PointerDataDispatcherMaker ShellTestPlatformViewMetal::GetDispatcherMaker() {
  return [](DefaultPointerDataDispatcher::Delegate& delegate) {
    return std::make_unique<SmoothPointerDataDispatcher>(delegate);
  };
}

// |PlatformView|
std::unique_ptr<Surface> ShellTestPlatformViewMetal::CreateRenderingSurface() {
  return std::make_unique<GPUSurfaceMetalSkia>(this, [metal_context_->context() mainContext],
                                               MsaaSampleCount::kNone);
}

// |GPUSurfaceMetalDelegate|
GPUCAMetalLayerHandle ShellTestPlatformViewMetal::GetCAMetalLayer(const SkISize& frame_info) const {
  FML_CHECK(false) << "A Metal Delegate configured with MTLRenderTargetType::kMTLTexture was asked "
                      "to acquire a layer.";
  return nullptr;
}

// |GPUSurfaceMetalDelegate|
bool ShellTestPlatformViewMetal::PresentDrawable(GrMTLHandle drawable) const {
  FML_CHECK(false) << "A Metal Delegate configured with MTLRenderTargetType::kMTLTexture was asked "
                      "to present a layer drawable.";
  return true;
}

// |GPUSurfaceMetalDelegate|
GPUMTLTextureInfo ShellTestPlatformViewMetal::GetMTLTexture(const SkISize& frame_info) const {
  return metal_context_->offscreen_texture_info();
}

// |GPUSurfaceMetalDelegate|
bool ShellTestPlatformViewMetal::PresentTexture(GPUMTLTextureInfo texture) const {
  // The texture resides offscreen. There is nothing to render to.
  return true;
}

}  // namespace testing
}  // namespace flutter
