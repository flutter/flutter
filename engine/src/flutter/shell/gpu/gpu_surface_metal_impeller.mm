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
#include "flutter/impeller/display_list/display_list_dispatcher.h"
#include "flutter/impeller/renderer/backend/metal/surface_mtl.h"

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
                                                 const std::shared_ptr<impeller::Context>& context)
    : delegate_(delegate),
      impeller_renderer_(CreateImpellerRenderer(context)),
      aiks_context_(
          std::make_shared<impeller::AiksContext>(impeller_renderer_ ? context : nullptr)) {}

GPUSurfaceMetalImpeller::~GPUSurfaceMetalImpeller() = default;

// |Surface|
bool GPUSurfaceMetalImpeller::IsValid() {
  return !!aiks_context_;
}

// |Surface|
std::unique_ptr<SurfaceFrame> GPUSurfaceMetalImpeller::AcquireFrame(const SkISize& frame_info) {
  TRACE_EVENT0("impeller", "GPUSurfaceMetalImpeller::AcquireFrame");

  if (!IsValid()) {
    FML_LOG(ERROR) << "Metal surface was invalid.";
    return nullptr;
  }

  auto layer = delegate_->GetCAMetalLayer(frame_info);
  if (!layer) {
    FML_LOG(ERROR) << "Invalid CAMetalLayer given by the embedder.";
    return nullptr;
  }

  auto* mtl_layer = (CAMetalLayer*)layer;

  auto surface = impeller::SurfaceMTL::WrapCurrentMetalLayerDrawable(
      impeller_renderer_->GetContext(), mtl_layer);
  if (Settings::kSurfaceDataAccessible) {
    last_drawable_.reset([surface->drawable() retain]);
  }

  SurfaceFrame::SubmitCallback submit_callback =
      fml::MakeCopyable([renderer = impeller_renderer_,  //
                         aiks_context = aiks_context_,   //
                         surface = std::move(surface)    //
  ](SurfaceFrame& surface_frame, SkCanvas* canvas) mutable -> bool {
        if (!aiks_context) {
          return false;
        }

        auto display_list = surface_frame.BuildDisplayList();
        if (!display_list) {
          FML_LOG(ERROR) << "Could not build display list for surface frame.";
          return false;
        }

        impeller::DisplayListDispatcher impeller_dispatcher;
        display_list->Dispatch(impeller_dispatcher);
        auto picture = impeller_dispatcher.EndRecordingAsPicture();

        return renderer->Render(
            std::move(surface),
            fml::MakeCopyable([aiks_context, picture = std::move(picture)](
                                  impeller::RenderTarget& render_target) -> bool {
              return aiks_context->Render(picture, render_target);
            }));
      });

  return std::make_unique<SurfaceFrame>(nullptr,                          // surface
                                        SurfaceFrame::FramebufferInfo{},  // framebuffer info
                                        submit_callback,                  // submit callback
                                        frame_info,                       // frame size
                                        nullptr,                          // context result
                                        true                              // display list fallback
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
impeller::AiksContext* GPUSurfaceMetalImpeller::GetAiksContext() const {
  return aiks_context_.get();
}

Surface::SurfaceData GPUSurfaceMetalImpeller::GetSurfaceData() const {
  if (!(last_drawable_ && [last_drawable_ conformsToProtocol:@protocol(CAMetalDrawable)])) {
    return {};
  }
  id<CAMetalDrawable> metal_drawable = static_cast<id<CAMetalDrawable>>(last_drawable_);
  id<MTLTexture> texture = metal_drawable.texture;
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
