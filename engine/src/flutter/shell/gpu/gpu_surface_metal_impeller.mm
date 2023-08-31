// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_metal_impeller.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "flutter/common/settings.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/trace_event.h"
#include "impeller/display_list/dl_dispatcher.h"
#include "impeller/renderer/backend/metal/surface_mtl.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"

static_assert(!__has_feature(objc_arc), "ARC must be disabled.");

namespace flutter {

static std::shared_ptr<impeller::Renderer> CreateImpellerRenderer(
    std::shared_ptr<impeller::Context> context) {
  auto renderer = std::make_shared<impeller::Renderer>(std::move(context));
  if (!renderer->IsValid()) {
    FML_LOG(ERROR) << "Could not create valid Impeller Renderer.";
    return nullptr;
  }
  return renderer;
}

GPUSurfaceMetalImpeller::GPUSurfaceMetalImpeller(GPUSurfaceMetalDelegate* delegate,
                                                 const std::shared_ptr<impeller::Context>& context,
                                                 bool render_to_surface)
    : delegate_(delegate),
      render_target_type_(delegate->GetRenderTargetType()),
      impeller_renderer_(CreateImpellerRenderer(context)),
      aiks_context_(
          std::make_shared<impeller::AiksContext>(impeller_renderer_ ? context : nullptr,
                                                  impeller::TypographerContextSkia::Make())),
      render_to_surface_(render_to_surface) {
  // If this preference is explicitly set, we allow for disabling partial repaint.
  NSNumber* disablePartialRepaint =
      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FLTDisablePartialRepaint"];
  if (disablePartialRepaint != nil) {
    disable_partial_repaint_ = disablePartialRepaint.boolValue;
  }
}

GPUSurfaceMetalImpeller::~GPUSurfaceMetalImpeller() = default;

// |Surface|
bool GPUSurfaceMetalImpeller::IsValid() {
  return !!aiks_context_;
}

// |Surface|
std::unique_ptr<SurfaceFrame> GPUSurfaceMetalImpeller::AcquireFrame(const SkISize& frame_size) {
  TRACE_EVENT0("impeller", "GPUSurfaceMetalImpeller::AcquireFrame");

  if (!IsValid()) {
    FML_LOG(ERROR) << "Metal surface was invalid.";
    return nullptr;
  }

  if (frame_size.isEmpty()) {
    FML_LOG(ERROR) << "Metal surface was asked for an empty frame.";
    return nullptr;
  }

  if (!render_to_surface_) {
    return std::make_unique<SurfaceFrame>(
        nullptr, SurfaceFrame::FramebufferInfo(),
        [](const SurfaceFrame& surface_frame, DlCanvas* canvas) { return true; }, frame_size);
  }

  switch (render_target_type_) {
    case MTLRenderTargetType::kCAMetalLayer:
      return AcquireFrameFromCAMetalLayer(frame_size);
    case MTLRenderTargetType::kMTLTexture:
      return AcquireFrameFromMTLTexture(frame_size);
    default:
      FML_CHECK(false) << "Unknown MTLRenderTargetType type.";
  }

  return nullptr;
}

std::unique_ptr<SurfaceFrame> GPUSurfaceMetalImpeller::AcquireFrameFromCAMetalLayer(
    const SkISize& frame_size) {
  auto layer = delegate_->GetCAMetalLayer(frame_size);

  if (!layer) {
    FML_LOG(ERROR) << "Invalid CAMetalLayer given by the embedder.";
    return nullptr;
  }

  auto* mtl_layer = (CAMetalLayer*)layer;

  auto drawable = impeller::SurfaceMTL::GetMetalDrawableAndValidate(
      impeller_renderer_->GetContext(), mtl_layer);
  if (Settings::kSurfaceDataAccessible) {
    last_texture_.reset([drawable.texture retain]);
  }

  id<MTLTexture> last_texture = static_cast<id<MTLTexture>>(last_texture_);
  SurfaceFrame::SubmitCallback submit_callback =
      fml::MakeCopyable([this,                           //
                         renderer = impeller_renderer_,  //
                         aiks_context = aiks_context_,   //
                         drawable,                       //
                         last_texture                    //
  ](SurfaceFrame& surface_frame, DlCanvas* canvas) mutable -> bool {
        if (!aiks_context) {
          return false;
        }

        auto display_list = surface_frame.BuildDisplayList();
        if (!display_list) {
          FML_LOG(ERROR) << "Could not build display list for surface frame.";
          return false;
        }

        if (!disable_partial_repaint_) {
          uintptr_t texture = reinterpret_cast<uintptr_t>(last_texture);

          for (auto& entry : damage_) {
            if (entry.first != texture) {
              // Accumulate damage for other framebuffers
              if (surface_frame.submit_info().frame_damage) {
                entry.second.join(*surface_frame.submit_info().frame_damage);
              }
            }
          }
          // Reset accumulated damage for current framebuffer
          damage_[texture] = SkIRect::MakeEmpty();
        }

        std::optional<impeller::IRect> clip_rect;
        if (surface_frame.submit_info().buffer_damage.has_value()) {
          auto buffer_damage = surface_frame.submit_info().buffer_damage;
          clip_rect = impeller::IRect::MakeXYWH(buffer_damage->x(), buffer_damage->y(),
                                                buffer_damage->width(), buffer_damage->height());
        }

        auto surface = impeller::SurfaceMTL::MakeFromMetalLayerDrawable(
            impeller_renderer_->GetContext(), drawable, clip_rect);

        if (clip_rect && (clip_rect->size.width == 0 || clip_rect->size.height == 0)) {
          return surface->Present();
        }

        impeller::IRect cull_rect = surface->coverage();
        SkIRect sk_cull_rect = SkIRect::MakeWH(cull_rect.size.width, cull_rect.size.height);
        impeller::DlDispatcher impeller_dispatcher(cull_rect);
        display_list->Dispatch(impeller_dispatcher, sk_cull_rect);
        auto picture = impeller_dispatcher.EndRecordingAsPicture();

        return renderer->Render(
            std::move(surface),
            fml::MakeCopyable([aiks_context, picture = std::move(picture)](
                                  impeller::RenderTarget& render_target) -> bool {
              return aiks_context->Render(picture, render_target);
            }));
      });

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  if (!disable_partial_repaint_) {
    // Provide accumulated damage to rasterizer (area in current framebuffer that lags behind
    // front buffer)
    uintptr_t texture = reinterpret_cast<uintptr_t>(drawable.texture);
    auto i = damage_.find(texture);
    if (i != damage_.end()) {
      framebuffer_info.existing_damage = i->second;
    }
    framebuffer_info.supports_partial_repaint = true;
  }

  return std::make_unique<SurfaceFrame>(nullptr,           // surface
                                        framebuffer_info,  // framebuffer info
                                        submit_callback,   // submit callback
                                        frame_size,        // frame size
                                        nullptr,           // context result
                                        true               // display list fallback
  );
}

std::unique_ptr<SurfaceFrame> GPUSurfaceMetalImpeller::AcquireFrameFromMTLTexture(
    const SkISize& frame_size) {
  GPUMTLTextureInfo texture_info = delegate_->GetMTLTexture(frame_size);
  id<MTLTexture> mtl_texture = (id<MTLTexture>)(texture_info.texture);

  if (!mtl_texture) {
    FML_LOG(ERROR) << "Invalid MTLTexture given by the embedder.";
    return nullptr;
  }

  if (Settings::kSurfaceDataAccessible) {
    last_texture_.reset([mtl_texture retain]);
  }

  SurfaceFrame::SubmitCallback submit_callback =
      fml::MakeCopyable([this,                           //
                         renderer = impeller_renderer_,  //
                         aiks_context = aiks_context_,   //
                         texture_info,                   //
                         mtl_texture,                    //
                         delegate = delegate_            //
  ](SurfaceFrame& surface_frame, DlCanvas* canvas) mutable -> bool {
        if (!aiks_context) {
          return false;
        }

        auto display_list = surface_frame.BuildDisplayList();
        if (!display_list) {
          FML_LOG(ERROR) << "Could not build display list for surface frame.";
          return false;
        }

        if (!disable_partial_repaint_) {
          uintptr_t texture_ptr = reinterpret_cast<uintptr_t>(mtl_texture);

          for (auto& entry : damage_) {
            if (entry.first != texture_ptr) {
              // Accumulate damage for other framebuffers
              if (surface_frame.submit_info().frame_damage) {
                entry.second.join(*surface_frame.submit_info().frame_damage);
              }
            }
          }
          // Reset accumulated damage for current framebuffer
          damage_[texture_ptr] = SkIRect::MakeEmpty();
        }

        std::optional<impeller::IRect> clip_rect;
        if (surface_frame.submit_info().buffer_damage.has_value()) {
          auto buffer_damage = surface_frame.submit_info().buffer_damage;
          clip_rect = impeller::IRect::MakeXYWH(buffer_damage->x(), buffer_damage->y(),
                                                buffer_damage->width(), buffer_damage->height());
        }

        auto surface =
            impeller::SurfaceMTL::MakeFromTexture(renderer->GetContext(), mtl_texture, clip_rect);

        if (clip_rect && (clip_rect->size.width == 0 || clip_rect->size.height == 0)) {
          return surface->Present();
        }

        impeller::IRect cull_rect = surface->coverage();
        SkIRect sk_cull_rect = SkIRect::MakeWH(cull_rect.size.width, cull_rect.size.height);
        impeller::DlDispatcher impeller_dispatcher(cull_rect);
        display_list->Dispatch(impeller_dispatcher, sk_cull_rect);
        auto picture = impeller_dispatcher.EndRecordingAsPicture();

        bool render_result =
            renderer->Render(std::move(surface),
                             fml::MakeCopyable([aiks_context, picture = std::move(picture)](
                                                   impeller::RenderTarget& render_target) -> bool {
                               return aiks_context->Render(picture, render_target);
                             }));
        if (!render_result) {
          FML_LOG(ERROR) << "Failed to render Impeller frame";
          return false;
        }

        return delegate->PresentTexture(texture_info);
      });

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  if (!disable_partial_repaint_) {
    // Provide accumulated damage to rasterizer (area in current framebuffer that lags behind
    // front buffer)
    uintptr_t texture = reinterpret_cast<uintptr_t>(mtl_texture);
    auto i = damage_.find(texture);
    if (i != damage_.end()) {
      framebuffer_info.existing_damage = i->second;
    }
    framebuffer_info.supports_partial_repaint = true;
  }

  return std::make_unique<SurfaceFrame>(nullptr,           // surface
                                        framebuffer_info,  // framebuffer info
                                        submit_callback,   // submit callback
                                        frame_size,        // frame size
                                        nullptr,           // context result
                                        true               // display list fallback
  );
}

// |Surface|
SkMatrix GPUSurfaceMetalImpeller::GetRootTransformation() const {
  // This backend does not currently support root surface transformations. Just
  // return identity.
  return {};
}

// |Surface|
GrDirectContext* GPUSurfaceMetalImpeller::GetContext() {
  return nullptr;
}

// |Surface|
std::unique_ptr<GLContextResult> GPUSurfaceMetalImpeller::MakeRenderContextCurrent() {
  // This backend has no such concept.
  return std::make_unique<GLContextDefaultResult>(true);
}

bool GPUSurfaceMetalImpeller::AllowsDrawingWhenGpuDisabled() const {
  return delegate_->AllowsDrawingWhenGpuDisabled();
}

// |Surface|
bool GPUSurfaceMetalImpeller::EnableRasterCache() const {
  return false;
}

// |Surface|
std::shared_ptr<impeller::AiksContext> GPUSurfaceMetalImpeller::GetAiksContext() const {
  return aiks_context_;
}

Surface::SurfaceData GPUSurfaceMetalImpeller::GetSurfaceData() const {
  if (!(last_texture_ && [last_texture_ conformsToProtocol:@protocol(MTLTexture)])) {
    return {};
  }
  id<MTLTexture> texture = last_texture_.get();
  int bytesPerPixel = 0;
  std::string pixel_format;
  switch (texture.pixelFormat) {
    case MTLPixelFormatBGR10_XR:
      bytesPerPixel = 4;
      pixel_format = "MTLPixelFormatBGR10_XR";
      break;
    case MTLPixelFormatBGRA10_XR:
      bytesPerPixel = 8;
      pixel_format = "MTLPixelFormatBGRA10_XR";
      break;
    case MTLPixelFormatBGRA8Unorm:
      bytesPerPixel = 4;
      pixel_format = "MTLPixelFormatBGRA8Unorm";
      break;
    case MTLPixelFormatRGBA16Float:
      bytesPerPixel = 8;
      pixel_format = "MTLPixelFormatRGBA16Float";
      break;
    default:
      return {};
  }

  // Zero initialized so that errors are easier to find at the cost of
  // performance.
  sk_sp<SkData> result =
      SkData::MakeZeroInitialized(texture.width * texture.height * bytesPerPixel);
  [texture getBytes:result->writable_data()
        bytesPerRow:texture.width * bytesPerPixel
         fromRegion:MTLRegionMake2D(0, 0, texture.width, texture.height)
        mipmapLevel:0];
  return {
      .pixel_format = pixel_format,
      .data = result,
  };
}

}  // namespace flutter
