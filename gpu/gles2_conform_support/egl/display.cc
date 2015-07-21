// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/gles2_conform_support/egl/display.h"

#include <vector>
#include "base/bind.h"
#include "base/bind_helpers.h"
#include "gpu/command_buffer/client/gles2_implementation.h"
#include "gpu/command_buffer/client/gles2_lib.h"
#include "gpu/command_buffer/client/transfer_buffer.h"
#include "gpu/command_buffer/common/value_state.h"
#include "gpu/command_buffer/service/context_group.h"
#include "gpu/command_buffer/service/mailbox_manager.h"
#include "gpu/command_buffer/service/memory_tracking.h"
#include "gpu/command_buffer/service/transfer_buffer_manager.h"
#include "gpu/command_buffer/service/valuebuffer_manager.h"
#include "gpu/gles2_conform_support/egl/config.h"
#include "gpu/gles2_conform_support/egl/surface.h"

namespace {
const int32 kCommandBufferSize = 1024 * 1024;
const int32 kTransferBufferSize = 512 * 1024;
}

namespace egl {

Display::Display(EGLNativeDisplayType display_id)
    : display_id_(display_id),
      is_initialized_(false),
      create_offscreen_(false),
      create_offscreen_width_(0),
      create_offscreen_height_(0) {
}

Display::~Display() {
  gles2::Terminate();
}

bool Display::Initialize() {
  gles2::Initialize();
  is_initialized_ = true;
  return true;
}

bool Display::IsValidConfig(EGLConfig config) {
  return (config != NULL) && (config == config_.get());
}

bool Display::ChooseConfigs(EGLConfig* configs,
                            EGLint config_size,
                            EGLint* num_config) {
  // TODO(alokp): Find out a way to find all configs. CommandBuffer currently
  // does not support finding or choosing configs.
  *num_config = 1;
  if (configs != NULL) {
    if (config_ == NULL) {
      config_.reset(new Config);
    }
    configs[0] = config_.get();
  }
  return true;
}

bool Display::GetConfigs(EGLConfig* configs,
                         EGLint config_size,
                         EGLint* num_config) {
  // TODO(alokp): Find out a way to find all configs. CommandBuffer currently
  // does not support finding or choosing configs.
  *num_config = 1;
  if (configs != NULL) {
    if (config_ == NULL) {
      config_.reset(new Config);
    }
    configs[0] = config_.get();
  }
  return true;
}

bool Display::GetConfigAttrib(EGLConfig config,
                              EGLint attribute,
                              EGLint* value) {
  const egl::Config* cfg = static_cast<egl::Config*>(config);
  return cfg->GetAttrib(attribute, value);
}

bool Display::IsValidNativeWindow(EGLNativeWindowType win) {
#if defined OS_WIN
  return ::IsWindow(win) != FALSE;
#else
  // TODO(alokp): Validate window handle.
  return true;
#endif  // OS_WIN
}

bool Display::IsValidSurface(EGLSurface surface) {
  return (surface != NULL) && (surface == surface_.get());
}

EGLSurface Display::CreateWindowSurface(EGLConfig config,
                                        EGLNativeWindowType win,
                                        const EGLint* attrib_list) {
  if (surface_ != NULL) {
    // We do not support more than one window surface.
    return EGL_NO_SURFACE;
  }

  {
    gpu::TransferBufferManager* manager = new gpu::TransferBufferManager();
    transfer_buffer_manager_.reset(manager);
    manager->Initialize();
  }
  scoped_ptr<gpu::CommandBufferService> command_buffer(
      new gpu::CommandBufferService(transfer_buffer_manager_.get()));
  if (!command_buffer->Initialize())
    return NULL;

  scoped_refptr<gpu::gles2::ContextGroup> group(
      new gpu::gles2::ContextGroup(NULL,
                                   NULL,
                                   new gpu::gles2::ShaderTranslatorCache,
                                   NULL,
                                   NULL,
                                   NULL,
                                   true));

  decoder_.reset(gpu::gles2::GLES2Decoder::Create(group.get()));
  if (!decoder_.get())
    return EGL_NO_SURFACE;

  gpu_scheduler_.reset(new gpu::GpuScheduler(command_buffer.get(),
                                             decoder_.get(),
                                             NULL));

  decoder_->set_engine(gpu_scheduler_.get());
  gfx::Size size(create_offscreen_width_, create_offscreen_height_);
  if (create_offscreen_) {
    gl_surface_ = gfx::GLSurface::CreateOffscreenGLSurface(size);
    create_offscreen_ = false;
    create_offscreen_width_ = 0;
    create_offscreen_height_ = 0;
  } else {
    gl_surface_ = gfx::GLSurface::CreateViewGLSurface(win);
  }
  if (!gl_surface_.get())
    return EGL_NO_SURFACE;

  gl_context_ = gfx::GLContext::CreateGLContext(NULL,
                                                gl_surface_.get(),
                                                gfx::PreferDiscreteGpu);
  if (!gl_context_.get())
    return EGL_NO_SURFACE;

  gl_context_->MakeCurrent(gl_surface_.get());

  EGLint depth_size = 0;
  EGLint alpha_size = 0;
  EGLint stencil_size = 0;
  GetConfigAttrib(config, EGL_DEPTH_SIZE, &depth_size);
  GetConfigAttrib(config, EGL_ALPHA_SIZE, &alpha_size);
  GetConfigAttrib(config, EGL_STENCIL_SIZE, &stencil_size);
  std::vector<int32> attribs;
  attribs.push_back(EGL_DEPTH_SIZE);
  attribs.push_back(depth_size);
  attribs.push_back(EGL_ALPHA_SIZE);
  attribs.push_back(alpha_size);
  attribs.push_back(EGL_STENCIL_SIZE);
  attribs.push_back(stencil_size);
  // TODO(gman): Insert attrib_list. Although ES 1.1 says it must be null
  attribs.push_back(EGL_NONE);

  if (!decoder_->Initialize(gl_surface_.get(),
                            gl_context_.get(),
                            gl_surface_->IsOffscreen(),
                            size,
                            gpu::gles2::DisallowedFeatures(),
                            attribs)) {
    return EGL_NO_SURFACE;
  }

  command_buffer->SetPutOffsetChangeCallback(
      base::Bind(&gpu::GpuScheduler::PutChanged,
                 base::Unretained(gpu_scheduler_.get())));
  command_buffer->SetGetBufferChangeCallback(
      base::Bind(&gpu::GpuScheduler::SetGetBuffer,
                 base::Unretained(gpu_scheduler_.get())));

  scoped_ptr<gpu::gles2::GLES2CmdHelper> cmd_helper(
      new gpu::gles2::GLES2CmdHelper(command_buffer.get()));
  if (!cmd_helper->Initialize(kCommandBufferSize))
    return NULL;

  scoped_ptr<gpu::TransferBuffer> transfer_buffer(new gpu::TransferBuffer(
      cmd_helper.get()));

  command_buffer_.reset(command_buffer.release());
  transfer_buffer_.reset(transfer_buffer.release());
  gles2_cmd_helper_.reset(cmd_helper.release());
  surface_.reset(new Surface(win));

  return surface_.get();
}

void Display::DestroySurface(EGLSurface surface) {
  DCHECK(IsValidSurface(surface));
  gpu_scheduler_.reset();
  if (decoder_.get()) {
    decoder_->Destroy(true);
  }
  decoder_.reset();
  gl_surface_ = NULL;
  gl_context_ = NULL;
  surface_.reset();
}

void Display::SwapBuffers(EGLSurface surface) {
  DCHECK(IsValidSurface(surface));
  context_->SwapBuffers();
}

bool Display::IsValidContext(EGLContext ctx) {
  return (ctx != NULL) && (ctx == context_.get());
}

EGLContext Display::CreateContext(EGLConfig config,
                                  EGLContext share_ctx,
                                  const EGLint* attrib_list) {
  DCHECK(IsValidConfig(config));
  // TODO(alokp): Add support for shared contexts.
  if (share_ctx != NULL)
    return EGL_NO_CONTEXT;

  DCHECK(command_buffer_ != NULL);
  DCHECK(transfer_buffer_.get());

  bool bind_generates_resources = true;
  bool lose_context_when_out_of_memory = false;
  bool support_client_side_arrays = true;

  context_.reset(
      new gpu::gles2::GLES2Implementation(gles2_cmd_helper_.get(),
                                          NULL,
                                          transfer_buffer_.get(),
                                          bind_generates_resources,
                                          lose_context_when_out_of_memory,
                                          support_client_side_arrays,
                                          this));

  if (!context_->Initialize(
      kTransferBufferSize,
      kTransferBufferSize / 2,
      kTransferBufferSize * 2,
      gpu::gles2::GLES2Implementation::kNoLimit)) {
    return EGL_NO_CONTEXT;
  }

  context_->EnableFeatureCHROMIUM("pepper3d_allow_buffers_on_multiple_targets");
  context_->EnableFeatureCHROMIUM("pepper3d_support_fixed_attribs");

  return context_.get();
}

void Display::DestroyContext(EGLContext ctx) {
  DCHECK(IsValidContext(ctx));
  context_.reset();
  transfer_buffer_.reset();
}

bool Display::MakeCurrent(EGLSurface draw, EGLSurface read, EGLContext ctx) {
  if (ctx == EGL_NO_CONTEXT) {
    gles2::SetGLContext(NULL);
  } else {
    DCHECK(IsValidSurface(draw));
    DCHECK(IsValidSurface(read));
    DCHECK(IsValidContext(ctx));
    gles2::SetGLContext(context_.get());
  }
  return true;
}

gpu::Capabilities Display::GetCapabilities() {
  return decoder_->GetCapabilities();
}

int32_t Display::CreateImage(ClientBuffer buffer,
                             size_t width,
                             size_t height,
                             unsigned internalformat) {
  NOTIMPLEMENTED();
  return -1;
}

void Display::DestroyImage(int32 id) {
  NOTIMPLEMENTED();
}

int32_t Display::CreateGpuMemoryBufferImage(size_t width,
                                            size_t height,
                                            unsigned internalformat,
                                            unsigned usage) {
  NOTIMPLEMENTED();
  return -1;
}

uint32 Display::InsertSyncPoint() {
  NOTIMPLEMENTED();
  return 0u;
}

uint32 Display::InsertFutureSyncPoint() {
  NOTIMPLEMENTED();
  return 0u;
}

void Display::RetireSyncPoint(uint32 sync_point) {
  NOTIMPLEMENTED();
}

void Display::SignalSyncPoint(uint32 sync_point,
                              const base::Closure& callback) {
  NOTIMPLEMENTED();
}

void Display::SignalQuery(uint32 query, const base::Closure& callback) {
  NOTIMPLEMENTED();
}

void Display::SetSurfaceVisible(bool visible) {
  NOTIMPLEMENTED();
}

uint32 Display::CreateStreamTexture(uint32 texture_id) {
  NOTIMPLEMENTED();
  return 0;
}

void Display::SetLock(base::Lock*) {
  NOTIMPLEMENTED();
}

}  // namespace egl
