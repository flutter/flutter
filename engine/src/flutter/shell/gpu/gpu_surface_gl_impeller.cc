// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/gpu/gpu_surface_gl_impeller.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/impeller/display_list/display_list_dispatcher.h"
#include "flutter/impeller/renderer/backend/gles/surface_gles.h"
#include "flutter/impeller/renderer/renderer.h"

namespace flutter {

GPUSurfaceGLImpeller::GPUSurfaceGLImpeller(
    GPUSurfaceGLDelegate* delegate,
    std::shared_ptr<impeller::Context> context)
    : weak_factory_(this) {
  if (delegate == nullptr) {
    return;
  }

  if (!context || !context->IsValid()) {
    return;
  }

  auto renderer = std::make_shared<impeller::Renderer>(context);
  if (!renderer->IsValid()) {
    return;
  }

  auto aiks_context = std::make_shared<impeller::AiksContext>(context);

  if (!aiks_context->IsValid()) {
    return;
  }

  delegate_ = delegate;
  impeller_context_ = std::move(context);
  impeller_renderer_ = std::move(renderer);
  aiks_context_ = std::move(aiks_context);
  is_valid_ = true;
}

// |Surface|
GPUSurfaceGLImpeller::~GPUSurfaceGLImpeller() = default;

// |Surface|
bool GPUSurfaceGLImpeller::IsValid() {
  return is_valid_;
}

// |Surface|
std::unique_ptr<SurfaceFrame> GPUSurfaceGLImpeller::AcquireFrame(
    const SkISize& size) {
  if (!IsValid()) {
    FML_LOG(ERROR) << "OpenGL surface was invalid.";
    return nullptr;
  }

  auto swap_callback = [weak = weak_factory_.GetWeakPtr(),
                        delegate = delegate_]() -> bool {
    if (weak) {
      GLPresentInfo present_info = {
          .fbo_id = 0,
          .frame_damage = std::nullopt,
          // TODO (https://github.com/flutter/flutter/issues/105597): wire-up
          // presentation time to impeller backend.
          .presentation_time = std::nullopt,
          .buffer_damage = std::nullopt,
      };
      delegate->GLContextPresent(present_info);
    }
    return true;
  };

  auto context_switch = delegate_->GLContextMakeCurrent();
  if (!context_switch->GetResult()) {
    FML_LOG(ERROR)
        << "Could not make the context current to acquire the frame.";
    return nullptr;
  }

  auto surface = impeller::SurfaceGLES::WrapFBO(
      impeller_context_,                            // context
      swap_callback,                                // swap_callback
      0u,                                           // fbo
      impeller::PixelFormat::kR8G8B8A8UNormInt,     // color_format
      impeller::ISize{size.width(), size.height()}  // fbo_size
  );

  SurfaceFrame::SubmitCallback submit_callback =
      fml::MakeCopyable([renderer = impeller_renderer_,  //
                         aiks_context = aiks_context_,   //
                         surface = std::move(surface)    //
  ](SurfaceFrame& surface_frame, DlCanvas* canvas) mutable -> bool {
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
            fml::MakeCopyable(
                [aiks_context, picture = std::move(picture)](
                    impeller::RenderTarget& render_target) -> bool {
                  return aiks_context->Render(picture, render_target);
                }));
      });

  return std::make_unique<SurfaceFrame>(
      nullptr,                          // surface
      SurfaceFrame::FramebufferInfo{},  // framebuffer info
      submit_callback,                  // submit callback
      size,                             // frame size
      std::move(context_switch),        // context result
      true                              // display list fallback
  );
}

// |Surface|
SkMatrix GPUSurfaceGLImpeller::GetRootTransformation() const {
  // This backend does not currently support root surface transformations. Just
  // return identity.
  return {};
}

// |Surface|
GrDirectContext* GPUSurfaceGLImpeller::GetContext() {
  // Impeller != Skia.
  return nullptr;
}

// |Surface|
std::unique_ptr<GLContextResult>
GPUSurfaceGLImpeller::MakeRenderContextCurrent() {
  return delegate_->GLContextMakeCurrent();
}

// |Surface|
bool GPUSurfaceGLImpeller::ClearRenderContext() {
  return delegate_->GLContextClearCurrent();
}

bool GPUSurfaceGLImpeller::AllowsDrawingWhenGpuDisabled() const {
  return delegate_->AllowsDrawingWhenGpuDisabled();
}

// |Surface|
bool GPUSurfaceGLImpeller::EnableRasterCache() const {
  return false;
}

// |Surface|
std::shared_ptr<impeller::AiksContext> GPUSurfaceGLImpeller::GetAiksContext()
    const {
  return aiks_context_;
}

}  // namespace flutter
