// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <Foundation/Foundation.h>
#include <QuartzCore/QuartzCore.h>

#include <atomic>

#include "flutter/fml/trace_event.h"
#include "flutter/shell/gpu/gpu_surface_metal_impeller.h"
#include "gtest/gtest.h"
#include "impeller/display_list/aiks_context.h"
#include "impeller/entity/mtl/entity_shaders.h"
#include "impeller/entity/mtl/framebuffer_blend_shaders.h"
#include "impeller/entity/mtl/modern_shaders.h"
#include "impeller/renderer/backend/metal/context_mtl.h"
#include "impeller/renderer/backend/metal/surface_mtl.h"
#include "impeller/renderer/backend/metal/swapchain_transients_mtl.h"
#include "impeller/typographer/typographer_context.h"

// A drawable that records presentation without requiring a window.
@interface TestCAMetalDrawable : NSObject <CAMetalDrawable>

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@property(nonatomic) NSUInteger presentCount;

@end

@implementation TestCAMetalDrawable {
  id<MTLTexture> _texture;
  CAMetalLayer* _layer;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  self = [super init];
  if (self) {
    _texture = [device
        newTextureWithDescriptor:[MTLTextureDescriptor
                                     texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                  width:100
                                                                 height:100
                                                              mipmapped:NO]];
    _layer = [[CAMetalLayer alloc] init];
    _layer.device = device;
  }
  return self;
}

- (id<MTLTexture>)texture {
  return _texture;
}

- (CAMetalLayer*)layer {
  return _layer;
}

- (void)present {
  self.presentCount++;
}

- (void)presentAtTime:(CFTimeInterval)presentationTime {
  [self present];
}

- (void)presentAfterMinimumDuration:(CFTimeInterval)duration {
  [self present];
}

- (void)addPresentedHandler:(MTLDrawablePresentedHandler)block {
}

- (CFTimeInterval)presentedTime {
  return 0;
}

- (NSUInteger)drawableID {
  return 0;
}

@end

namespace flutter {
namespace testing {

class TestGPUSurfaceMetalDelegate : public GPUSurfaceMetalDelegate {
 public:
  TestGPUSurfaceMetalDelegate() : GPUSurfaceMetalDelegate(MTLRenderTargetType::kCAMetalLayer) {
    layer_ = [[CAMetalLayer alloc] init];
  }

  ~TestGPUSurfaceMetalDelegate() = default;

  GPUCAMetalLayerHandle GetCAMetalLayer(const DlISize& frame_info) const override {
    layer_.drawableSize = CGSizeMake(frame_info.width, frame_info.height);
    return (__bridge GPUCAMetalLayerHandle)(layer_);
  }

  bool PresentDrawable(GrMTLHandle drawable) const override { return true; }

  GPUMTLTextureInfo GetMTLTexture(const DlISize& frame_info) const override { return {}; }

  bool PresentTexture(GPUMTLTextureInfo texture) const override { return true; }

  bool AllowsDrawingWhenGpuDisabled() const override { return true; }

  void SetDevice() { layer_.device = ::MTLCreateSystemDefaultDevice(); }

 private:
  CAMetalLayer* layer_ = nil;
};

static std::shared_ptr<impeller::ContextMTL> CreateImpellerContext() {
  std::vector<std::shared_ptr<fml::Mapping>> shader_mappings = {
      std::make_shared<fml::NonOwnedMapping>(impeller_entity_shaders_data,
                                             impeller_entity_shaders_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_modern_shaders_data,
                                             impeller_modern_shaders_length),
      std::make_shared<fml::NonOwnedMapping>(impeller_framebuffer_blend_shaders_data,
                                             impeller_framebuffer_blend_shaders_length),
  };
  auto sync_switch = std::make_shared<fml::SyncSwitch>(false);
  return impeller::ContextMTL::Create(impeller::Flags{}, shader_mappings, sync_switch,
                                      "Impeller Library");
}

#if FLUTTER_TIMELINE_ENABLED
static std::atomic_int g_wait_until_scheduled_count = 0;

static void CountWaitUntilScheduledEvents(const char*,
                                          int64_t,
                                          int64_t,
                                          intptr_t,
                                          const int64_t*,
                                          Dart_Timeline_Event_Type type,
                                          intptr_t,
                                          const char**,
                                          const char**) {
  if (type == Dart_Timeline_Event_Begin) {
    g_wait_until_scheduled_count++;
  }
}
#endif  // FLUTTER_TIMELINE_ENABLED

TEST(SurfaceMTL, DefersTransactionPresentationUntilFrameBoundary) {
  auto context = CreateImpellerContext();
#ifdef IMPELLER_DEBUG
  context->GetCaptureManager()->StartCapture();
#endif  // IMPELLER_DEBUG
  auto previous_transaction_drawable =
      [[TestCAMetalDrawable alloc] initWithDevice:context->GetMTLDevice()];
  auto overlay_drawable = [[TestCAMetalDrawable alloc] initWithDevice:context->GetMTLDevice()];
  auto background_drawable = [[TestCAMetalDrawable alloc] initWithDevice:context->GetMTLDevice()];
  auto make_surface = [&context](TestCAMetalDrawable* drawable) {
    auto transients =
        std::make_shared<impeller::SwapchainTransientsMTL>(context->GetResourceAllocator());
    return impeller::SurfaceMTL::MakeFromMetalLayerDrawable(context, drawable, transients);
  };
  auto previous_transaction_surface = make_surface(previous_transaction_drawable);
  auto overlay_surface = make_surface(overlay_drawable);
  auto background_surface = make_surface(background_drawable);
  ASSERT_TRUE(previous_transaction_surface);
  ASSERT_TRUE(overlay_surface);
  ASSERT_TRUE(background_surface);
  previous_transaction_surface->PresentWithTransaction(true);
  previous_transaction_surface->SetFrameBoundary(false);
  overlay_surface->PresentWithTransaction(true);
  overlay_surface->SetFrameBoundary(false);
  background_surface->PresentWithTransaction(true);
  background_surface->SetFrameBoundary(true);

  // A transaction without a frame boundary must not leak its pending drawable
  // into the next transaction.
  [CATransaction begin];
  EXPECT_TRUE(previous_transaction_surface->Present());
  EXPECT_EQ(previous_transaction_drawable.presentCount, 0u);
  [CATransaction commit];

  [CATransaction begin];
  EXPECT_TRUE(overlay_surface->Present());
  EXPECT_EQ(overlay_drawable.presentCount, 0u);
  EXPECT_TRUE(background_surface->Present());
  EXPECT_EQ(previous_transaction_drawable.presentCount, 0u);
  EXPECT_EQ(overlay_drawable.presentCount, 1u);
  EXPECT_EQ(background_drawable.presentCount, 1u);
  [CATransaction commit];
}

TEST(GPUSurfaceMetalImpeller, InvalidImpellerContextCreatesCausesSurfaceToBeInvalid) {
  auto delegate = std::make_shared<TestGPUSurfaceMetalDelegate>();
  auto surface = std::make_shared<GPUSurfaceMetalImpeller>(delegate.get(), nullptr);

  ASSERT_FALSE(surface->IsValid());
}

TEST(GPUSurfaceMetalImpeller, CanCreateValidSurface) {
  auto delegate = std::make_shared<TestGPUSurfaceMetalDelegate>();
  auto surface = std::make_shared<GPUSurfaceMetalImpeller>(
      delegate.get(), std::make_shared<impeller::AiksContext>(CreateImpellerContext(), nullptr));

  ASSERT_TRUE(surface->IsValid());
}

TEST(GPUSurfaceMetalImpeller, AcquireFrameFromCAMetalLayerNullChecksDrawable) {
  auto delegate = std::make_shared<TestGPUSurfaceMetalDelegate>();
  std::shared_ptr<Surface> surface = std::make_shared<GPUSurfaceMetalImpeller>(
      delegate.get(), std::make_shared<impeller::AiksContext>(CreateImpellerContext(), nullptr));

  ASSERT_TRUE(surface->IsValid());

  auto frame = surface->AcquireFrame(DlISize(100, 100));
  ASSERT_EQ(frame, nullptr);
}

TEST(GPUSurfaceMetalImpeller, AcquireFrameFromCAMetalLayerDoesNotRetainThis) {
  auto delegate = std::make_shared<TestGPUSurfaceMetalDelegate>();
  delegate->SetDevice();
  std::unique_ptr<Surface> surface = std::make_unique<GPUSurfaceMetalImpeller>(
      delegate.get(), std::make_shared<impeller::AiksContext>(CreateImpellerContext(), nullptr));

  ASSERT_TRUE(surface->IsValid());

  auto frame = surface->AcquireFrame(DlISize(100, 100));
  ASSERT_TRUE(frame);

  // Simulate a rasterizer teardown, e.g. due to going to the background.
  surface.reset();

  ASSERT_TRUE(frame->Submit());
}

TEST(GPUSurfaceMetalImpeller, ResetHostBufferBasedOnFrameBoundary) {
  auto delegate = std::make_shared<TestGPUSurfaceMetalDelegate>();
  delegate->SetDevice();

  auto context = CreateImpellerContext();
  std::unique_ptr<Surface> surface = std::make_unique<GPUSurfaceMetalImpeller>(
      delegate.get(), std::make_shared<impeller::AiksContext>(context, nullptr));

  ASSERT_TRUE(surface->IsValid());

  auto& data_host_buffer = surface->GetAiksContext()->GetContentContext().GetTransientsDataBuffer();

  EXPECT_EQ(data_host_buffer.GetStateForTest().current_frame, 0u);

  auto frame = surface->AcquireFrame(DlISize(100, 100));
  frame->set_submit_info({.frame_boundary = false});

  ASSERT_TRUE(frame->Submit());
  EXPECT_EQ(data_host_buffer.GetStateForTest().current_frame, 0u);

  frame = surface->AcquireFrame(DlISize(100, 100));
  frame->set_submit_info({.frame_boundary = true});

  ASSERT_TRUE(frame->Submit());
  EXPECT_EQ(data_host_buffer.GetStateForTest().current_frame, 1u);
}

#if FLUTTER_TIMELINE_ENABLED
TEST(GPUSurfaceMetalImpeller, WaitsForSchedulingOnlyAtFrameBoundaryWithTransaction) {
  auto overlay_delegate = std::make_shared<TestGPUSurfaceMetalDelegate>();
  overlay_delegate->SetDevice();
  auto background_delegate = std::make_shared<TestGPUSurfaceMetalDelegate>();
  background_delegate->SetDevice();

  auto aiks_context = std::make_shared<impeller::AiksContext>(CreateImpellerContext(), nullptr);
  std::unique_ptr<Surface> overlay_surface =
      std::make_unique<GPUSurfaceMetalImpeller>(overlay_delegate.get(), aiks_context);
  std::unique_ptr<Surface> background_surface =
      std::make_unique<GPUSurfaceMetalImpeller>(background_delegate.get(), aiks_context);

  auto overlay_frame = overlay_surface->AcquireFrame(DlISize(100, 100));
  auto background_frame = background_surface->AcquireFrame(DlISize(100, 100));
  ASSERT_TRUE(overlay_frame);
  ASSERT_TRUE(background_frame);
  overlay_frame->set_submit_info({.frame_boundary = false, .present_with_transaction = true});
  // Exercise the early return used when the final surface has no damage.
  background_frame->set_submit_info({
      .buffer_damage = DlIRect(),
      .frame_boundary = true,
      .present_with_transaction = true,
  });

  ASSERT_FALSE(fml::tracing::TraceHasTimelineEventHandler());
  g_wait_until_scheduled_count = 0;
  fml::tracing::TraceSetAllowlist({"waitUntilScheduled"});
  fml::tracing::TraceSetTimelineEventHandler(CountWaitUntilScheduledEvents);

  [CATransaction begin];
  const bool overlay_submitted = overlay_frame->Submit();
  const int waits_after_overlay = g_wait_until_scheduled_count.load();
  const bool background_submitted = background_frame->Submit();
  [CATransaction commit];
  const int total_waits = g_wait_until_scheduled_count.load();

  fml::tracing::TraceSetTimelineEventHandler(nullptr);
  fml::tracing::TraceSetAllowlist({});

  EXPECT_TRUE(overlay_submitted);
  EXPECT_TRUE(background_submitted);
  EXPECT_EQ(waits_after_overlay, 0);
  EXPECT_EQ(total_waits, 1);
}
#endif  // FLUTTER_TIMELINE_ENABLED

#ifdef IMPELLER_DEBUG
TEST(GPUSurfaceMetalImpeller, CreatesImpellerCaptureScope) {
  auto delegate = std::make_shared<TestGPUSurfaceMetalDelegate>();
  delegate->SetDevice();

  auto context = CreateImpellerContext();
  auto aiks_context = std::make_shared<impeller::AiksContext>(context, nullptr);

  EXPECT_FALSE(context->GetCaptureManager()->CaptureScopeActive());

  std::unique_ptr<Surface> surface =
      std::make_unique<GPUSurfaceMetalImpeller>(delegate.get(), aiks_context);
  auto frame_1 = surface->AcquireFrame(DlISize(100, 100));
  frame_1->set_submit_info({.frame_boundary = false});

  EXPECT_TRUE(context->GetCaptureManager()->CaptureScopeActive());

  std::unique_ptr<Surface> surface_2 =
      std::make_unique<GPUSurfaceMetalImpeller>(delegate.get(), aiks_context);
  auto frame_2 = surface->AcquireFrame(DlISize(100, 100));
  frame_2->set_submit_info({.frame_boundary = true});

  EXPECT_TRUE(context->GetCaptureManager()->CaptureScopeActive());

  ASSERT_TRUE(frame_1->Submit());
  EXPECT_TRUE(context->GetCaptureManager()->CaptureScopeActive());
  ASSERT_TRUE(frame_2->Submit());
  EXPECT_FALSE(context->GetCaptureManager()->CaptureScopeActive());
}
#endif  // IMPELLER_DEBUG

}  // namespace testing
}  // namespace flutter
