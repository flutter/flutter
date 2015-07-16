// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gl_context_virtual.h"

#include "gpu/command_buffer/service/gl_state_restorer_impl.h"
#include "gpu/command_buffer/service/gles2_cmd_decoder.h"
#include "ui/gl/gl_gl_api_implementation.h"
#include "ui/gl/gl_surface.h"
#include "ui/gl/gpu_timing.h"

namespace gpu {

GLContextVirtual::GLContextVirtual(
    gfx::GLShareGroup* share_group,
    gfx::GLContext* shared_context,
    base::WeakPtr<gles2::GLES2Decoder> decoder)
  : GLContext(share_group),
    shared_context_(shared_context),
    display_(NULL),
    decoder_(decoder) {
}

gfx::Display* GLContextVirtual::display() {
  return display_;
}

bool GLContextVirtual::Initialize(
    gfx::GLSurface* compatible_surface, gfx::GpuPreference gpu_preference) {
  SetGLStateRestorer(new GLStateRestorerImpl(decoder_));

  display_ = static_cast<gfx::Display*>(compatible_surface->GetDisplay());

  // Virtual contexts obviously can't make a context that is compatible
  // with the surface (the context already exists), but we do need to
  // make a context current for SetupForVirtualization() below.
  if (!IsCurrent(compatible_surface)) {
    if (!shared_context_->MakeCurrent(compatible_surface)) {
      // This is likely an error. The real context should be made as
      // compatible with all required surfaces when it was created.
      LOG(ERROR) << "Failed MakeCurrent(compatible_surface)";
      return false;
    }
  }

  shared_context_->SetupForVirtualization();
  shared_context_->MakeVirtuallyCurrent(this, compatible_surface);
  return true;
}

void GLContextVirtual::Destroy() {
  shared_context_->OnReleaseVirtuallyCurrent(this);
  shared_context_ = NULL;
  display_ = NULL;
}

bool GLContextVirtual::MakeCurrent(gfx::GLSurface* surface) {
  if (decoder_.get())
    return shared_context_->MakeVirtuallyCurrent(this, surface);

  LOG(ERROR) << "Trying to make virtual context current without decoder.";
  return false;
}

void GLContextVirtual::ReleaseCurrent(gfx::GLSurface* surface) {
  if (IsCurrent(surface)) {
    shared_context_->OnReleaseVirtuallyCurrent(this);
    shared_context_->ReleaseCurrent(surface);
  }
}

bool GLContextVirtual::IsCurrent(gfx::GLSurface* surface) {
  // If it's a real surface it needs to be current.
  if (surface &&
      !surface->IsOffscreen())
    return shared_context_->IsCurrent(surface);

  // Otherwise, only insure the context itself is current.
  return shared_context_->IsCurrent(NULL);
}

void* GLContextVirtual::GetHandle() {
  return shared_context_->GetHandle();
}

scoped_refptr<gfx::GPUTimingClient> GLContextVirtual::CreateGPUTimingClient() {
  return shared_context_->CreateGPUTimingClient();
}

void GLContextVirtual::OnSetSwapInterval(int interval) {
  shared_context_->SetSwapInterval(interval);
}

std::string GLContextVirtual::GetExtensions() {
  return shared_context_->GetExtensions();
}

bool GLContextVirtual::GetTotalGpuMemory(size_t* bytes) {
  return shared_context_->GetTotalGpuMemory(bytes);
}

void GLContextVirtual::SetSafeToForceGpuSwitch() {
  // TODO(ccameron): This will not work if two contexts that disagree
  // about whether or not forced gpu switching may be done both share
  // the same underlying shared_context_.
  return shared_context_->SetSafeToForceGpuSwitch();
}

bool GLContextVirtual::WasAllocatedUsingRobustnessExtension() {
  return shared_context_->WasAllocatedUsingRobustnessExtension();
}

void GLContextVirtual::SetUnbindFboOnMakeCurrent() {
  shared_context_->SetUnbindFboOnMakeCurrent();
}

base::Closure GLContextVirtual::GetStateWasDirtiedExternallyCallback() {
  return shared_context_->GetStateWasDirtiedExternallyCallback();
}

void GLContextVirtual::RestoreStateIfDirtiedExternally() {
  // The dirty bit should only be cleared after the state has been restored,
  // which should be done only when the context is current.
  DCHECK(IsCurrent(NULL));
  if (!shared_context_->GetStateWasDirtiedExternally())
    return;
  gfx::ScopedSetGLToRealGLApi scoped_set_gl_api;
  GetGLStateRestorer()->RestoreState(NULL);
  shared_context_->SetStateWasDirtiedExternally(false);
}

GLContextVirtual::~GLContextVirtual() {
  Destroy();
}

}  // namespace gpu
