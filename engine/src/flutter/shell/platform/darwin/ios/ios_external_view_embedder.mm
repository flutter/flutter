// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_external_view_embedder.h"
// #include <__config>
#include "fml/task_runner.h"
#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#include "impeller/renderer/backend/metal/surface_mtl.h"
#include "impeller/renderer/backend/metal/swapchain_transients_mtl.h"
#include "impeller/display_list/dl_dispatcher.h"
#include "flutter/fml/make_copyable.h"
#import "flutter/shell/platform/darwin/ios/ios_surface_metal_impeller.h"
#import "flutter/shell/gpu/gpu_surface_metal_impeller.h"

#include "flutter/common/constants.h"

FLUTTER_ASSERT_ARC

namespace flutter {

// IOSExternalView::IOSExternalView(const DlISize& frame_size,
//                     GPUSurfaceMetalDelegate* delegate,
//                     const std::shared_ptr<impeller::AiksContext>& context
//                 ): render_surface_size_(frame_size),
//                    delegate_(delegate),
//                    aiks_context_(context) {
//   // If this preference is explicitly set, we allow for disabling partial repaint.
//   NSNumber* disablePartialRepaint =
//       [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FLTDisablePartialRepaint"];
//   if (disablePartialRepaint != nil) {
//     disable_partial_repaint_ = disablePartialRepaint.boolValue;
//   }
//   if (aiks_context_) {
//     swapchain_transients_ = std::make_shared<impeller::SwapchainTransientsMTL>(
//         aiks_context_->GetContext()->GetResourceAllocator());
//   }
// }

// IOSExternalView::~IOSExternalView() = default;

// std::unique_ptr<SurfaceFrame> IOSExternalView::MakeSurfaceFrame() {
//   return AcquireFrameFromCAMetalLayer(delegate_, render_surface_size_);
// }

// std::unique_ptr<SurfaceFrame> IOSExternalView::AcquireFrameFromCAMetalLayer(
//     const GPUSurfaceMetalDelegate* delegate,
//     const DlISize& frame_size) {
//   // const GPUSurfaceMetalDelegate* delegate = get_gpu_surface_metal_delegate_
//   //                                             ? get_gpu_surface_metal_delegate_(view_id)
//   //                                             : delegate_;
//   // FML_CHECK(delegate);

//   CAMetalLayer* layer = (__bridge CAMetalLayer*)delegate->GetCAMetalLayer(frame_size);
//   if (!layer) {
//     FML_LOG(ERROR) << "Invalid CAMetalLayer given by the embedder.";
//     return nullptr;
//   }

//   id<CAMetalDrawable> drawable =
//       impeller::SurfaceMTL::GetMetalDrawableAndValidate(aiks_context_->GetContext(), layer);
//   if (!drawable) {
//     return nullptr;
//   }
//   if (Settings::kSurfaceDataAccessible) {
//     last_texture_ = drawable.texture;
//   }

// #ifdef IMPELLER_DEBUG
//   impeller::ContextMTL::Cast(*aiks_context_->GetContext()).GetCaptureManager()->StartCapture();
// #endif  // IMPELLER_DEBUG

//   __weak id<MTLTexture> weak_last_texture = last_texture_;
//   __weak CAMetalLayer* weak_layer = layer;
//   SurfaceFrame::EncodeCallback encode_callback =
//       fml::MakeCopyable([damage = damage_,
//                          disable_partial_repaint = disable_partial_repaint_,  //
//                          aiks_context = aiks_context_,                        //
//                          drawable,                                            //
//                          weak_last_texture,                                   //
//                          weak_layer,                                          //
//                          swapchain_transients = swapchain_transients_         //
//   ](SurfaceFrame& surface_frame, DlCanvas* canvas) mutable -> bool {
//         id<MTLTexture> strong_last_texture = weak_last_texture;
//         CAMetalLayer* strong_layer = weak_layer;
//         if (!strong_last_texture || !strong_layer) {
//           return false;
//         }
//         strong_layer.presentsWithTransaction = surface_frame.submit_info().present_with_transaction;
//         if (!aiks_context) {
//           return false;
//         }

//         auto display_list = surface_frame.BuildDisplayList();
//         if (!display_list) {
//           FML_LOG(ERROR) << "Could not build display list for surface frame.";
//           return false;
//         }

//         if (!disable_partial_repaint && damage) {
//           void* texture = (__bridge void*)strong_last_texture;
//           for (auto& entry : *damage) {
//             if (entry.first != texture) {
//               // Accumulate damage for other framebuffers
//               if (surface_frame.submit_info().frame_damage) {
//                 entry.second = entry.second.Union(*surface_frame.submit_info().frame_damage);
//               }
//             }
//           }
//           // Reset accumulated damage for current framebuffer
//           (*damage)[texture] = DlIRect();
//         }

//         std::optional<impeller::IRect> clip_rect;
//         if (surface_frame.submit_info().buffer_damage.has_value()) {
//           auto buffer_damage = surface_frame.submit_info().buffer_damage;
//           clip_rect =
//               impeller::IRect::MakeLTRB(buffer_damage->GetLeft(), buffer_damage->GetTop(),
//                                         buffer_damage->GetRight(), buffer_damage->GetBottom());
//         }

//         auto surface = impeller::SurfaceMTL::MakeFromMetalLayerDrawable(
//             aiks_context->GetContext(), drawable, swapchain_transients, clip_rect);

//         // The surface may be null if we failed to allocate the onscreen render target
//         // due to running out of memory.
//         if (!surface) {
//           return false;
//         }
//         surface->PresentWithTransaction(surface_frame.submit_info().present_with_transaction);

//         if (clip_rect && clip_rect->IsEmpty()) {
//           if (!surface->PreparePresent()) {
//             return false;
//           }
//           surface_frame.set_user_data(std::move(surface));
//           return true;
//         }

//         impeller::Rect cull_rect = impeller::Rect::Make(surface->coverage());
//         surface->SetFrameBoundary(surface_frame.submit_info().frame_boundary);

//         const bool reset_host_buffer = surface_frame.submit_info().frame_boundary;
//         auto render_result = impeller::RenderToTarget(aiks_context->GetContentContext(),       //
//                                                       surface->GetRenderTarget(),              //
//                                                       display_list,                            //
//                                                       cull_rect,                               //
//                                                       /*reset_host_buffer=*/reset_host_buffer  //
//         );
//         if (!render_result) {
//           return false;
//         }

//         if (!surface->PreparePresent()) {
//           return false;
//         }
//         surface_frame.set_user_data(std::move(surface));
//         return true;
//       });

//   SurfaceFrame::FramebufferInfo framebuffer_info;
//   framebuffer_info.supports_readback = true;

//   if (!disable_partial_repaint_) {
//     // Provide accumulated damage to rasterizer (area in current framebuffer that lags behind
//     // front buffer)
//     void* texture = (__bridge void*)drawable.texture;
//     auto i = damage_->find(texture);
//     if (i != damage_->end()) {
//       framebuffer_info.existing_damage = i->second;
//     }
//     framebuffer_info.supports_partial_repaint = true;
//   }

//   return std::make_unique<SurfaceFrame>(
//       nullptr,           // surface
//       framebuffer_info,  // framebuffer info
//       encode_callback,   // submit callback
//       [](SurfaceFrame& surface_frame) { return surface_frame.take_user_data()->Present(); },
//       frame_size,  // frame size
//       nullptr,     // context result
//       true         // display list fallback
//   );
// }

IOSExternalViewEmbedder::IOSExternalViewEmbedder(
    __weak FlutterPlatformViewsController* platform_views_controller,
    const std::shared_ptr<IOSContext>& context,
    const GetIOSRenderingSurfaceCallback& get_ios_rendering_surface_callback
    // const std::shared_ptr<IOSSurfacesManager> &ios_surfaces_manager
    )
    : platform_views_controller_(platform_views_controller),
    ios_context_(context),
    //  ios_surfaces_manager_(ios_surfaces_manager)
    get_ios_rendering_surface_callback_(get_ios_rendering_surface_callback)
     {
  FML_CHECK(ios_context_);
}

IOSExternalViewEmbedder::~IOSExternalViewEmbedder() = default;

// |ExternalViewEmbedder|
DlCanvas* IOSExternalViewEmbedder::GetRootCanvas() {
  // On iOS, the root surface is created from the on-screen render target. Only the surfaces for the
  // various overlays are controlled by this class.
  return nullptr;
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::CancelFrame() {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::CancelFrame");
  FML_CHECK(platform_views_controller_);
  [platform_views_controller_ cancelFrame];
}

bool IOSExternalViewEmbedder::SkipFrame(int64_t flutter_view_id) {
  auto *rendering_surface = get_ios_rendering_surface_callback_(flutter_view_id);
  return rendering_surface == nullptr;
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::BeginFrame(
    GrDirectContext* context,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PrepareFlutterView(int64_t flutter_view_id, DlISize frame_size, double device_pixel_ratio) {
  FML_CHECK(platform_views_controller_);

  pending_frame_size_ = frame_size;

  [platform_views_controller_ beginFrameWithSize:flutter_view_id frameSize:frame_size];
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PrerollCompositeEmbeddedView(
    int64_t view_id,
    std::unique_ptr<EmbeddedViewParams> params) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::PrerollCompositeEmbeddedView");
  FML_CHECK(platform_views_controller_);
  [platform_views_controller_ prerollCompositeEmbeddedView:view_id withParams:std::move(params)];
}

// |ExternalViewEmbedder|
PostPrerollResult IOSExternalViewEmbedder::PostPrerollAction(
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::PostPrerollAction");
  FML_CHECK(platform_views_controller_);
  PostPrerollResult result =
      [platform_views_controller_ postPrerollActionWithThreadMerger:raster_thread_merger];
  return result;
}

// |ExternalViewEmbedder|
DlCanvas* IOSExternalViewEmbedder::CompositeEmbeddedView(int64_t view_id) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::CompositeEmbeddedView");
  FML_CHECK(platform_views_controller_);
  return [platform_views_controller_ compositeEmbeddedViewWithId:view_id];
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::SubmitFlutterView(
    int64_t flutter_view_id,
    GrDirectContext* context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    std::unique_ptr<SurfaceFrame> frame) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::SubmitFlutterView");

  // TODO(dkwingsmt): This class only supports rendering into the implicit view.
  // Properly support multi-view in the future.
//  FML_DCHECK(flutter_view_id == kFlutterImplicitViewId);
  FML_CHECK(platform_views_controller_);
  [platform_views_controller_ submitFrame:std::move(frame) withIosContext:ios_context_];
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::DidSubmitFrame");
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::EndFrame(
    bool should_resubmit_frame,
    const fml::RefPtr<fml::RasterThreadMerger>& raster_thread_merger) {
  TRACE_EVENT0("flutter", "IOSExternalViewEmbedder::EndFrame");
  [platform_views_controller_ endFrameWithResubmit:should_resubmit_frame
                                      threadMerger:raster_thread_merger];
}

// |ExternalViewEmbedder|
bool IOSExternalViewEmbedder::SupportsDynamicThreadMerging() {
  return false;
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushFilterToVisitedPlatformViews(
    const std::shared_ptr<DlImageFilter>& filter,
    const DlRect& filter_rect) {
  [platform_views_controller_ pushFilterToVisitedPlatformViews:filter withRect:filter_rect];
}

// |ExternalViewEmbedder|
void IOSExternalViewEmbedder::PushVisitedPlatformView(int64_t view_id) {
  [platform_views_controller_ pushVisitedPlatformViewId:view_id];
}

void IOSExternalViewEmbedder::CollectView(int64_t view_id) {
  [platform_views_controller_ collectView:view_id];
}

std::unique_ptr<SurfaceFrame> IOSExternalViewEmbedder::AcquireRootFrame(int64_t flutter_view_id) {
  auto *rendering_surface = get_ios_rendering_surface_callback_(flutter_view_id);
  if (!rendering_surface) {
    return std::make_unique<SurfaceFrame>(
        nullptr, SurfaceFrame::FramebufferInfo(),
        [](const SurfaceFrame& surface_frame, DlCanvas* canvas) { return true; },
        [](const SurfaceFrame& surface_frame) { return true; },
        pending_frame_size_,
        nullptr,
        true);
  }

  return rendering_surface->AcquireFrame(pending_frame_size_);
}

void IOSExternalViewEmbedder::Reset() {

}

}  // namespace flutter
