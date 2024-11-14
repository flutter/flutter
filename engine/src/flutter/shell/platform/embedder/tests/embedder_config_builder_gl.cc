// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"

#include "flutter/shell/platform/embedder/tests/embedder_test_compositor_gl.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_gl.h"

namespace flutter::testing {

void EmbedderConfigBuilder::InitializeGLRendererConfig() {
  opengl_renderer_config_.struct_size = sizeof(FlutterOpenGLRendererConfig);
  opengl_renderer_config_.make_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLMakeCurrent();
  };
  opengl_renderer_config_.clear_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLClearCurrent();
  };
  opengl_renderer_config_.present_with_info =
      [](void* context, const FlutterPresentInfo* present_info) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLPresent(
        *present_info);
  };
  opengl_renderer_config_.fbo_with_frame_info_callback =
      [](void* context, const FlutterFrameInfo* frame_info) -> uint32_t {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLGetFramebuffer(
        *frame_info);
  };
  opengl_renderer_config_.populate_existing_damage = nullptr;
  opengl_renderer_config_.make_resource_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)
        ->GLMakeResourceCurrent();
  };
  opengl_renderer_config_.gl_proc_resolver = [](void* context,
                                                const char* name) -> void* {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLGetProcAddress(
        name);
  };
  opengl_renderer_config_.fbo_reset_after_present = true;
  opengl_renderer_config_.surface_transformation =
      [](void* context) -> FlutterTransformation {
    return reinterpret_cast<EmbedderTestContext*>(context)
        ->GetRootSurfaceTransformation();
  };
}

void EmbedderConfigBuilder::SetOpenGLFBOCallBack() {
  // SetOpenGLRendererConfig must be called before this.
  FML_CHECK(renderer_config_.type == FlutterRendererType::kOpenGL);
  renderer_config_.open_gl.fbo_callback = [](void* context) -> uint32_t {
    FlutterFrameInfo frame_info = {};
    // fbo_callback doesn't use the frame size information, only
    // fbo_callback_with_frame_info does.
    frame_info.struct_size = sizeof(FlutterFrameInfo);
    frame_info.size.width = 0;
    frame_info.size.height = 0;
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLGetFramebuffer(
        frame_info);
  };
}

void EmbedderConfigBuilder::SetOpenGLPresentCallBack() {
  // SetOpenGLRendererConfig must be called before this.
  FML_CHECK(renderer_config_.type == FlutterRendererType::kOpenGL);
  renderer_config_.open_gl.present = [](void* context) -> bool {
    // passing a placeholder fbo_id.
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLPresent(
        FlutterPresentInfo{
            .fbo_id = 0,
        });
  };
}

void EmbedderConfigBuilder::SetOpenGLRendererConfig(SkISize surface_size) {
  renderer_config_.type = FlutterRendererType::kOpenGL;
  renderer_config_.open_gl = opengl_renderer_config_;
  context_.SetupSurface(surface_size);
}

}  // namespace flutter::testing
