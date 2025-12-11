// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/render_context.h"

#include "flutter/impeller/display_list/dl_dispatcher.h"
#include "flutter/impeller/entity/gles3/entity_shaders_gles.h"
#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/impeller/renderer/backend/gles/surface_gles.h"
#include "flutter/impeller/typographer/backends/skia/text_frame_skia.h"
#include "flutter/impeller/typographer/backends/skia/typographer_context_skia.h"
#include "flutter/skwasm/export.h"

SKWASM_EXPORT bool skwasm_isWimp() {
  return true;
}

namespace {
std::vector<std::shared_ptr<fml::Mapping>>
ShaderLibraryMappingsForApplication() {
  return {
      std::make_shared<fml::NonOwnedMapping>(
          impeller_entity_shaders_gles3_data,
          impeller_entity_shaders_gles3_length),
  };
}

class ReactorWorker : public impeller::ReactorGLES::Worker {
 public:
  ReactorWorker() = default;
  ReactorWorker(const ReactorWorker&) = delete;

  ReactorWorker& operator=(const ReactorWorker&) = delete;

  virtual bool CanReactorReactOnCurrentThreadNow(
      const impeller::ReactorGLES& reactor) const override {
    return true;
  }
};

class ImpellerRenderContext : public Skwasm::RenderContext {
 public:
  ImpellerRenderContext(std::shared_ptr<impeller::ContextGLES> context,
                        std::shared_ptr<ReactorWorker> worker)
      : context_(std::move(context)),
        worker_(std::move(worker)),
        typographer_context_(impeller::TypographerContextSkia::Make()),
        content_context_(
            std::make_unique<impeller::ContentContext>(context_,
                                                       typographer_context_,
                                                       nullptr)) {}

  virtual void RenderPicture(
      const sk_sp<flutter::DisplayList> display_list) override {
    impeller::RenderToTarget(
        *content_context_, surface_->GetRenderTarget(), display_list,
        impeller::Rect::MakeLTRB(0, 0, width_, height_), true);
  }

  virtual void RenderImage(flutter::DlImage* image,
                           Skwasm::ImageByteFormat format) override {}

  virtual void Resize(int width, int height) override {
    if (width_ != width || height_ != height) {
      width_ = width;
      height_ = height;
      RecreateSurface();
    }
  }

  virtual void SetResourceCacheLimit(int bytes) override {
    // No-op
  }

 private:
  void RecreateSurface() {
    surface_ = impeller::SurfaceGLES::WrapFBO(
        /*context=*/context_,
        /*swap_callback=*/[]() { return true; },
        /*fbo=*/0u,
        /*color_format=*/impeller::PixelFormat::kR8G8B8A8UNormInt,
        /*fbo_size=*/{width_, height_});
  }

  std::shared_ptr<impeller::ContextGLES> context_;
  std::shared_ptr<ReactorWorker> worker_;
  std::shared_ptr<impeller::TypographerContext> typographer_context_;
  std::unique_ptr<impeller::ContentContext> content_context_;
  std::unique_ptr<impeller::Surface> surface_;
  int width_ = 0;
  int height_ = 0;
};
}  // namespace

std::unique_ptr<Skwasm::RenderContext> Skwasm::RenderContext::Make(
    int sample_count,
    int stencil) {
  auto clear_depth_emulated = [](float depth) {};
  auto depth_range_emulated = [](float near_val, float far_val) {};

  std::map<std::string, void*> gl_procs;

  gl_procs["glGetError"] = (void*)&glGetError;
  gl_procs["glClearDepthf"] = (void*)&clear_depth_emulated;
  gl_procs["glDepthRangef"] = (void*)&depth_range_emulated;

#define IMPELLER_PROC(name) gl_procs["gl" #name] = (void*)&gl##name;
  FOR_EACH_IMPELLER_PROC(IMPELLER_PROC);
  FOR_EACH_IMPELLER_ES_ONLY_PROC(IMPELLER_PROC);
  FOR_EACH_IMPELLER_GLES3_PROC(IMPELLER_PROC);
  IMPELLER_PROC(GenQueriesEXT);
  IMPELLER_PROC(DeleteQueriesEXT);
  IMPELLER_PROC(GetQueryObjectui64vEXT);
  IMPELLER_PROC(BeginQueryEXT);
  IMPELLER_PROC(EndQueryEXT);
  IMPELLER_PROC(GetQueryObjectuivEXT);
#undef IMPELLER_PROC

  auto gl = std::make_unique<impeller::ProcTableGLES>(
      [gl_procs = std::move(gl_procs)](const char* function_name) -> void* {
        auto found = gl_procs.find(function_name);
        if (found == gl_procs.end()) {
          return nullptr;
        }
        return found->second;
      });

  auto context = impeller::ContextGLES::Create(
      impeller::Flags{}, std::move(gl), ShaderLibraryMappingsForApplication(),
      false);

  auto worker = std::make_shared<ReactorWorker>();
  context->AddReactorWorker(worker);
  return std::make_unique<ImpellerRenderContext>(std::move(context),
                                                 std::move(worker));
}
