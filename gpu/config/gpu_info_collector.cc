// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_info_collector.h"

#include <string>
#include <vector>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_piece.h"
#include "base/strings/string_split.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface.h"

namespace {

scoped_refptr<gfx::GLSurface> InitializeGLSurface() {
  scoped_refptr<gfx::GLSurface> surface(
      gfx::GLSurface::CreateOffscreenGLSurface(gfx::Size(),
                                               gfx::SurfaceConfiguration()));
  if (!surface.get()) {
    LOG(ERROR) << "gfx::GLContext::CreateOffscreenGLSurface failed";
    return NULL;
  }

  return surface;
}

scoped_refptr<gfx::GLContext> InitializeGLContext(gfx::GLSurface* surface) {

  scoped_refptr<gfx::GLContext> context(
      gfx::GLContext::CreateGLContext(NULL,
                                      surface,
                                      gfx::PreferIntegratedGpu));
  if (!context.get()) {
    LOG(ERROR) << "gfx::GLContext::CreateGLContext failed";
    return NULL;
  }

  if (!context->MakeCurrent(surface)) {
    LOG(ERROR) << "gfx::GLContext::MakeCurrent() failed";
    return NULL;
  }

  return context;
}

std::string GetGLString(unsigned int pname) {
  const char* gl_string =
      reinterpret_cast<const char*>(glGetString(pname));
  if (gl_string)
    return std::string(gl_string);
  return std::string();
}

// Return a version string in the format of "major.minor".
std::string GetVersionFromString(const std::string& version_string) {
  size_t begin = version_string.find_first_of("0123456789");
  if (begin != std::string::npos) {
    size_t end = version_string.find_first_not_of("01234567890.", begin);
    std::string sub_string;
    if (end != std::string::npos)
      sub_string = version_string.substr(begin, end - begin);
    else
      sub_string = version_string.substr(begin);
    std::vector<std::string> pieces;
    base::SplitString(sub_string, '.', &pieces);
    if (pieces.size() >= 2)
      return pieces[0] + "." + pieces[1];
  }
  return std::string();
}

}  // namespace anonymous

namespace gpu {

CollectInfoResult CollectGraphicsInfoGL(GPUInfo* gpu_info) {
  TRACE_EVENT0("startup", "gpu_info_collector::CollectGraphicsInfoGL");
  DCHECK_NE(gfx::GetGLImplementation(), gfx::kGLImplementationNone);

  scoped_refptr<gfx::GLSurface> surface(InitializeGLSurface());
  if (!surface.get()) {
    LOG(ERROR) << "Could not create surface for info collection.";
    return kCollectInfoFatalFailure;
  }

  scoped_refptr<gfx::GLContext> context(InitializeGLContext(surface.get()));
  if (!context.get()) {
    LOG(ERROR) << "Could not create context for info collection.";
    return kCollectInfoFatalFailure;
  }

  gpu_info->gl_renderer = GetGLString(GL_RENDERER);
  gpu_info->gl_vendor = GetGLString(GL_VENDOR);
  gpu_info->gl_extensions = GetGLString(GL_EXTENSIONS);
  gpu_info->gl_version = GetGLString(GL_VERSION);
  std::string glsl_version_string = GetGLString(GL_SHADING_LANGUAGE_VERSION);

  gfx::GLWindowSystemBindingInfo window_system_binding_info;
  if (GetGLWindowSystemBindingInfo(&window_system_binding_info)) {
    gpu_info->gl_ws_vendor = window_system_binding_info.vendor;
    gpu_info->gl_ws_version = window_system_binding_info.version;
    gpu_info->gl_ws_extensions = window_system_binding_info.extensions;
    gpu_info->direct_rendering = window_system_binding_info.direct_rendering;
  }

  bool supports_robustness =
      gpu_info->gl_extensions.find("GL_EXT_robustness") != std::string::npos ||
      gpu_info->gl_extensions.find("GL_KHR_robustness") != std::string::npos ||
      gpu_info->gl_extensions.find("GL_ARB_robustness") != std::string::npos;
  if (supports_robustness) {
    glGetIntegerv(GL_RESET_NOTIFICATION_STRATEGY_ARB,
        reinterpret_cast<GLint*>(&gpu_info->gl_reset_notification_strategy));
  }

  // TODO(kbr): remove once the destruction of a current context automatically
  // clears the current context.
  context->ReleaseCurrent(surface.get());

  std::string glsl_version = GetVersionFromString(glsl_version_string);
  gpu_info->pixel_shader_version = glsl_version;
  gpu_info->vertex_shader_version = glsl_version;

  return CollectDriverInfoGL(gpu_info);
}

void MergeGPUInfoGL(GPUInfo* basic_gpu_info,
                    const GPUInfo& context_gpu_info) {
  DCHECK(basic_gpu_info);
  basic_gpu_info->gl_renderer = context_gpu_info.gl_renderer;
  basic_gpu_info->gl_vendor = context_gpu_info.gl_vendor;
  basic_gpu_info->gl_version = context_gpu_info.gl_version;
  basic_gpu_info->gl_extensions = context_gpu_info.gl_extensions;
  basic_gpu_info->pixel_shader_version =
      context_gpu_info.pixel_shader_version;
  basic_gpu_info->vertex_shader_version =
      context_gpu_info.vertex_shader_version;
  basic_gpu_info->gl_ws_vendor = context_gpu_info.gl_ws_vendor;
  basic_gpu_info->gl_ws_version = context_gpu_info.gl_ws_version;
  basic_gpu_info->gl_ws_extensions = context_gpu_info.gl_ws_extensions;
  basic_gpu_info->gl_reset_notification_strategy =
      context_gpu_info.gl_reset_notification_strategy;

  if (!context_gpu_info.driver_vendor.empty())
    basic_gpu_info->driver_vendor = context_gpu_info.driver_vendor;
  if (!context_gpu_info.driver_version.empty())
    basic_gpu_info->driver_version = context_gpu_info.driver_version;

  basic_gpu_info->can_lose_context = context_gpu_info.can_lose_context;
  basic_gpu_info->sandboxed = context_gpu_info.sandboxed;
  basic_gpu_info->direct_rendering = context_gpu_info.direct_rendering;
  basic_gpu_info->context_info_state = context_gpu_info.context_info_state;
  basic_gpu_info->initialization_time = context_gpu_info.initialization_time;
  basic_gpu_info->video_encode_accelerator_supported_profiles =
      context_gpu_info.video_encode_accelerator_supported_profiles;
}

}  // namespace gpu

