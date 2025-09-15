// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "render_context.h"

#include "export.h"
#include "impeller/display_list/dl_dispatcher.h"
#include "impeller/entity/gles3/entity_shaders_gles.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/backend/gles/surface_gles.h"
#include "impeller/typographer/backends/skia/text_frame_skia.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"

using namespace Skwasm;
using namespace flutter;

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

class ImpellerRenderContext : public RenderContext {
 public:
  ImpellerRenderContext(std::shared_ptr<impeller::ContextGLES> context,
                        std::shared_ptr<ReactorWorker> worker)
      : _context(std::move(context)),
        _worker(std::move(worker)),
        _typographerContext(impeller::TypographerContextSkia::Make()) {}

  virtual void renderPicture(
      const sk_sp<flutter::DisplayList> displayList) override {
    auto surface = impeller::SurfaceGLES::WrapFBO(
        _context,                                  // context
        []() { return true; },                     // swap callback
        0u,                                        // fbo
        impeller::PixelFormat::kR8G8B8A8UNormInt,  // pixel format
        {_width, _height}                          // surface size
    );
    auto contentContext = std::make_unique<impeller::ContentContext>(
        _context, _typographerContext, nullptr);
    RenderToTarget(*contentContext, surface->GetRenderTarget(), displayList,
                   impeller::Rect::MakeLTRB(0, 0, _width, _height), true);
  }

  virtual void renderImage(flutter::DlImage* image,
                           ImageByteFormat format) override {}

  virtual void resize(int width, int height) override {
    _width = width;
    _height = height;
  }

 private:
  std::shared_ptr<impeller::ContextGLES> _context;
  std::shared_ptr<ReactorWorker> _worker;
  std::shared_ptr<impeller::TypographerContext> _typographerContext;
  int _width = 0;
  int _height = 0;
};
}  // namespace

std::unique_ptr<RenderContext> Skwasm::RenderContext::Make(int sampleCount,
                                                           int stencil) {
  auto clearDepthEmulated = [](float depth) {};
  auto depthRangeEmulated = [](float nearVal, float farVal) {};

  static std::map<std::string, void*> gl_procs;

  gl_procs["glGetError"] = (void*)&glGetError;
  gl_procs["glClearDepthf"] = (void*)&clearDepthEmulated;
  gl_procs["glDepthRangef"] = (void*)&depthRangeEmulated;

#define IMPELLER_PROC(name) gl_procs["gl" #name] = (void*)&gl##name;
  FOR_EACH_IMPELLER_PROC(IMPELLER_PROC);
  FOR_EACH_IMPELLER_ES_ONLY_PROC(IMPELLER_PROC);
  FOR_EACH_IMPELLER_GLES3_PROC(IMPELLER_PROC);
  // IMPELLER_PROC(DebugMessageControlKHR);
  // IMPELLER_PROC(DiscardFramebufferEXT);
  // IMPELLER_PROC(FramebufferTexture2DMultisampleEXT);
  // IMPELLER_PROC(PushDebugGroupKHR);
  // IMPELLER_PROC(PopDebugGroupKHR);
  // IMPELLER_PROC(ObjectLabelKHR);
  // IMPELLER_PROC(RenderbufferStorageMultisampleEXT);
  IMPELLER_PROC(GenQueriesEXT);
  IMPELLER_PROC(DeleteQueriesEXT);
  IMPELLER_PROC(GetQueryObjectui64vEXT);
  IMPELLER_PROC(BeginQueryEXT);
  IMPELLER_PROC(EndQueryEXT);
  IMPELLER_PROC(GetQueryObjectuivEXT);
#undef IMPELLER_PROC

  auto gl = std::make_unique<impeller::ProcTableGLES>(
      [](const char* function_name) -> void* {
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
