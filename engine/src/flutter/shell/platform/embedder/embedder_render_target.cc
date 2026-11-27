// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_render_target.h"

#include <optional>
#include <utility>

#ifdef IMPELLER_SUPPORTS_RENDERING
#include "impeller/renderer/render_target.h"  // nogncheck
#if defined(_WIN32) && defined(SHELL_ENABLE_GL)
#include "flutter/display_list/display_list.h"
#include "impeller/display_list/aiks_context.h"           // nogncheck
#include "impeller/entity/entity.h"                       // nogncheck
#include "impeller/renderer/backend/gles/context_gles.h"  // nogncheck
#include "impeller/renderer/backend/gles/windows_backdrop_target.h"  // nogncheck
#endif
#endif

namespace flutter {

EmbedderRenderTarget::EmbedderRenderTarget(FlutterBackingStore backing_store,
                                           fml::closure on_release)
    : backing_store_(backing_store), on_release_(std::move(on_release)) {
  // TODO(38468): The optimization to elide backing store updates between frames
  // has not been implemented yet.
  backing_store_.did_update = true;
}

EmbedderRenderTarget::~EmbedderRenderTarget() {
  if (on_release_) {
    on_release_();
  }
}

const FlutterBackingStore* EmbedderRenderTarget::GetBackingStore() const {
  return &backing_store_;
}

#ifdef IMPELLER_SUPPORTS_RENDERING
#if defined(_WIN32) && defined(SHELL_ENABLE_GL)
static bool CanContinueWindowsBackdropPass(
    const EmbedderRenderTarget& backing_target,
    const impeller::RenderTarget& target,
    const DisplayList& display_list) {
  if (!display_list.root_has_backdrop_filter() ||
      display_list.max_root_blend_mode() >
          impeller::Entity::kLastPipelineBlendMode) {
    return false;
  }
  const auto& store = *backing_target.GetBackingStore();
  if (store.type != kFlutterBackingStoreTypeOpenGL ||
      store.open_gl.type != kFlutterOpenGLTargetTypeFramebuffer ||
      store.open_gl.framebuffer.name == 0 ||
      target.GetRenderTargetPixelFormat() !=
          impeller::PixelFormat::kB8G8R8A8UNormInt) {
    return false;
  }
  const auto& context = *backing_target.GetAiksContext()->GetContext();
  if (context.GetBackendType() != impeller::Context::BackendType::kOpenGLES) {
    return false;
  }
  const auto& gl_context = impeller::ContextGLES::Cast(context);
  const auto& caps = *context.GetCapabilities();
  if (caps.SupportsImplicitResolvingMSAA() || !caps.SupportsOffscreenMSAA() ||
      caps.GetDefaultColorFormat() !=
          impeller::PixelFormat::kR8G8B8A8UNormInt ||
      !gl_context.HasTopLeftDefaultFramebufferOrigin() ||
      !gl_context.GetReactor()->CanReactOnCurrentThread()) {
    return false;
  }
  const auto& gl = gl_context.GetReactor()->GetProcTable();
  const auto& description = *gl.GetDescription();
  const auto size = target.GetRenderTargetSize();
  return description.IsANGLE() && description.IsES() &&
         description.GetGlVersion().major_version >= 3 &&
         !description.HasExtension("GL_MESA_framebuffer_flip_y") &&
         impeller::IsCompatibleWindowsBackdropTarget(
             gl, store.open_gl.framebuffer.name, size.width, size.height);
}
#endif  // defined(_WIN32) && defined(SHELL_ENABLE_GL)

impeller::RenderTarget
EmbedderRenderTarget::GetImpellerRenderTargetForDisplayList(
    const DisplayList& display_list) const {
  auto target = *GetImpellerRenderTarget();
#if defined(_WIN32) && defined(SHELL_ENABLE_GL)
  if (CanContinueWindowsBackdropPass(*this, target, display_list)) {
    target.SetVerifiedExternalMSAA4(target.GetColorAttachment(0).texture);
  }
#endif
  return target;
}
#endif  // IMPELLER_SUPPORTS_RENDERING

}  // namespace flutter
