// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/shell_test_platform_view_metal.h"

#import <Metal/Metal.h>

#include <utility>

#include "flutter/shell/gpu/gpu_surface_metal_impeller.h"
#include "flutter/shell/gpu/gpu_surface_metal_skia.h"
#include "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetalImpeller.h"
#include "flutter/shell/platform/darwin/graphics/FlutterDarwinContextMetalSkia.h"

FLUTTER_ASSERT_ARC

namespace flutter {
namespace testing {

// This is out of the header so that shell_test_platform_view_metal.h can be included in
// non-Objective-C TUs.
struct DarwinContextMetal {
  FlutterDarwinContextMetalSkia* skia_context;
  FlutterDarwinContextMetalImpeller* impeller_context;
  id<MTLTexture> offscreen_texture;
};

static std::unique_ptr<DarwinContextMetal> CreateDarwinContext(
    bool impeller,
    const std::shared_ptr<const fml::SyncSwitch>& is_gpu_disabled_sync_switch) {
  FlutterDarwinContextMetalSkia* skia_context = nil;
  FlutterDarwinContextMetalImpeller* impeller_context = nil;
  id<MTLDevice> device = nil;
  if (impeller) {
    impeller_context = [[FlutterDarwinContextMetalImpeller alloc] init:is_gpu_disabled_sync_switch];
    FML_CHECK(impeller_context.context);
    device = impeller_context.context->GetMTLDevice();
  } else {
    skia_context = [[FlutterDarwinContextMetalSkia alloc] initWithDefaultMTLDevice];
    FML_CHECK(skia_context.mainContext);
    device = skia_context.device;
  }
  auto descriptor =
      [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                         width:800
                                                        height:600
                                                     mipmapped:NO];
  descriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
  id<MTLTexture> offscreen_texture = [device newTextureWithDescriptor:descriptor];
  return std::make_unique<DarwinContextMetal>(
      DarwinContextMetal{skia_context, impeller_context, offscreen_texture});
}

ShellTestPlatformViewMetal::ShellTestPlatformViewMetal(
    PlatformView::Delegate& delegate,
    const TaskRunners& task_runners,
    std::shared_ptr<ShellTestVsyncClock> vsync_clock,
    CreateVsyncWaiter create_vsync_waiter,
    std::shared_ptr<ShellTestExternalViewEmbedder> shell_test_external_view_embedder,
    const std::shared_ptr<const fml::SyncSwitch>& is_gpu_disabled_sync_switch)
    : ShellTestPlatformView(delegate, task_runners),
      GPUSurfaceMetalDelegate(MTLRenderTargetType::kMTLTexture),
      metal_context_(
          CreateDarwinContext(GetSettings().enable_impeller, is_gpu_disabled_sync_switch)),
      create_vsync_waiter_(std::move(create_vsync_waiter)),
      vsync_clock_(std::move(vsync_clock)),
      shell_test_external_view_embedder_(std::move(shell_test_external_view_embedder)) {}

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
  if (GetSettings().enable_impeller) {
    auto context = metal_context_->impeller_context.context;
    return std::make_unique<GPUSurfaceMetalImpeller>(
        this, std::make_shared<impeller::AiksContext>(context, nullptr));
  }
  return std::make_unique<GPUSurfaceMetalSkia>(this, metal_context_->skia_context.mainContext);
}

// |PlatformView|
std::shared_ptr<impeller::Context> ShellTestPlatformViewMetal::GetImpellerContext() const {
  return metal_context_->impeller_context.context;
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
  return {
      .texture_id = 0,
      .texture = (__bridge GPUMTLTextureHandle)metal_context_->offscreen_texture,
  };
}

// |GPUSurfaceMetalDelegate|
bool ShellTestPlatformViewMetal::PresentTexture(GPUMTLTextureInfo texture) const {
  // The texture resides offscreen. There is nothing to render to.
  return true;
}

}  // namespace testing
}  // namespace flutter
