// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_render_target_impeller.h"

#include "flutter/fml/logging.h"
#include "flutter/impeller/renderer/render_target.h"

#if defined(_WIN32) && defined(SHELL_ENABLE_GL)
#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#endif

namespace flutter {

#if defined(_WIN32) && defined(SHELL_ENABLE_GL)
static bool SupportsDirectMSAA4Rendering(
    const FlutterBackingStore& store,
    const impeller::AiksContext& aiks_context,
    const impeller::RenderTarget& target) {
  if (store.type != kFlutterBackingStoreTypeOpenGL ||
      store.open_gl.type != kFlutterOpenGLTargetTypeFramebuffer ||
      store.open_gl.framebuffer.name == 0 ||
      target.GetRenderTargetPixelFormat() !=
          impeller::PixelFormat::kB8G8R8A8UNormInt) {
    return false;
  }
  const auto& context = *aiks_context.GetContext();
  if (context.GetBackendType() != impeller::Context::BackendType::kOpenGLES) {
    return false;
  }
  const auto& gl_context = impeller::ContextGLES::Cast(context);
  const auto& caps = *context.GetCapabilities();
  const auto& description =
      *gl_context.GetReactor()->GetProcTable().GetDescription();
  return !caps.SupportsImplicitResolvingMSAA() &&
         caps.SupportsOffscreenMSAA() &&
         caps.GetDefaultColorFormat() ==
             impeller::PixelFormat::kR8G8B8A8UNormInt &&
         gl_context.HasTopLeftDefaultFramebufferOrigin() &&
         description.IsANGLE() && description.IsES() &&
         description.GetGlVersion().major_version >= 3 &&
         !description.HasExtension("GL_MESA_framebuffer_flip_y");
}
#endif

EmbedderRenderTargetImpeller::EmbedderRenderTargetImpeller(
    FlutterBackingStore backing_store,
    std::shared_ptr<impeller::AiksContext> aiks_context,
    std::unique_ptr<impeller::RenderTarget> impeller_target,
    fml::closure on_release,
    fml::closure framebuffer_destruction_callback,
    bool supports_direct_msaa4_rendering)
    : EmbedderRenderTarget(backing_store, std::move(on_release)),
      aiks_context_(std::move(aiks_context)),
      impeller_target_(std::move(impeller_target)),
      framebuffer_destruction_callback_(
          std::move(framebuffer_destruction_callback)) {
  FML_DCHECK(aiks_context_);
  FML_DCHECK(impeller_target_);
#if defined(_WIN32) && defined(SHELL_ENABLE_GL)
  if (supports_direct_msaa4_rendering &&
      SupportsDirectMSAA4Rendering(backing_store, *aiks_context_,
                                   *impeller_target_)) {
    impeller_target_->SetVerifiedExternalMSAA4(
        impeller_target_->GetColorAttachment(0).texture);
  }
#endif
}

EmbedderRenderTargetImpeller::~EmbedderRenderTargetImpeller() {
  if (framebuffer_destruction_callback_) {
    framebuffer_destruction_callback_();
  }
}

sk_sp<SkSurface> EmbedderRenderTargetImpeller::GetSkiaSurface() const {
  return nullptr;
}

impeller::RenderTarget* EmbedderRenderTargetImpeller::GetImpellerRenderTarget()
    const {
  return impeller_target_.get();
}

std::shared_ptr<impeller::AiksContext>
EmbedderRenderTargetImpeller::GetAiksContext() const {
  return aiks_context_;
}

DlISize EmbedderRenderTargetImpeller::GetRenderTargetSize() const {
  auto size = impeller_target_->GetRenderTargetSize();
  return DlISize(size);
}

}  // namespace flutter
