// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "base/bind.h"
#include "base/cancelable_callback.h"
#include "base/command_line.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/threading/thread_local.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_gl_api_implementation.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface.h"
#include "ui/gl/gl_switches.h"
#include "ui/gl/gl_version_info.h"
#include "ui/gl/gpu_timing.h"

namespace gfx {

namespace {
base::LazyInstance<base::ThreadLocalPointer<GLContext> >::Leaky
    current_context_ = LAZY_INSTANCE_INITIALIZER;

base::LazyInstance<base::ThreadLocalPointer<GLContext> >::Leaky
    current_real_context_ = LAZY_INSTANCE_INITIALIZER;
}  // namespace

GLContext::ScopedReleaseCurrent::ScopedReleaseCurrent() : canceled_(false) {}

GLContext::ScopedReleaseCurrent::~ScopedReleaseCurrent() {
  if (!canceled_ && GetCurrent()) {
    GetCurrent()->ReleaseCurrent(NULL);
  }
}

void GLContext::ScopedReleaseCurrent::Cancel() {
  canceled_ = true;
}

GLContext::GLContext(GLShareGroup* share_group) :
    share_group_(share_group),
    state_dirtied_externally_(false),
    swap_interval_(1),
    force_swap_interval_zero_(false),
    state_dirtied_callback_(
        base::Bind(&GLContext::SetStateWasDirtiedExternally,
        // Note that if this is not unretained, it will create a cycle (and
        // will never be freed.
        base::Unretained(this),
        true)) {
  if (!share_group_.get())
    share_group_ = new GLShareGroup;

  share_group_->AddContext(this);
}

GLContext::~GLContext() {
  share_group_->RemoveContext(this);
  if (GetCurrent() == this) {
    SetCurrent(NULL);
  }
}

bool GLContext::GetTotalGpuMemory(size_t* bytes) {
  DCHECK(bytes);
  *bytes = 0;
  return false;
}

void GLContext::SetSafeToForceGpuSwitch() {
}

bool GLContext::ForceGpuSwitchIfNeeded() {
  return true;
}

void GLContext::SetUnbindFboOnMakeCurrent() {
  NOTIMPLEMENTED();
}

std::string GLContext::GetExtensions() {
  DCHECK(IsCurrent(NULL));
  const char* ext = reinterpret_cast<const char*>(glGetString(GL_EXTENSIONS));
  return std::string(ext ? ext : "");
}

std::string GLContext::GetGLVersion() {
  DCHECK(IsCurrent(NULL));
  const char *version =
      reinterpret_cast<const char*>(glGetString(GL_VERSION));
  return std::string(version ? version : "");
}

std::string GLContext::GetGLRenderer() {
  DCHECK(IsCurrent(NULL));
  const char *renderer =
      reinterpret_cast<const char*>(glGetString(GL_RENDERER));
  return std::string(renderer ? renderer : "");
}

base::Closure GLContext::GetStateWasDirtiedExternallyCallback() {
  return state_dirtied_callback_.callback();
}

void GLContext::RestoreStateIfDirtiedExternally() {
  NOTREACHED();
}

bool GLContext::GetStateWasDirtiedExternally() const {
  DCHECK(virtual_gl_api_);
  return state_dirtied_externally_;
}

void GLContext::SetStateWasDirtiedExternally(bool dirtied_externally) {
  DCHECK(virtual_gl_api_);
  state_dirtied_externally_ = dirtied_externally;
}

bool GLContext::HasExtension(const char* name) {
  std::string extensions = GetExtensions();
  extensions += " ";

  std::string delimited_name(name);
  delimited_name += " ";

  return extensions.find(delimited_name) != std::string::npos;
}

const GLVersionInfo* GLContext::GetVersionInfo() {
  if(!version_info_) {
    std::string version = GetGLVersion();
    std::string renderer = GetGLRenderer();
    version_info_ =
        make_scoped_ptr(new GLVersionInfo(version.c_str(), renderer.c_str()));
  }
  return version_info_.get();
}

GLShareGroup* GLContext::share_group() {
  return share_group_.get();
}

bool GLContext::LosesAllContextsOnContextLost() {
  switch (GetGLImplementation()) {
    case kGLImplementationDesktopGL:
      return false;
    case kGLImplementationEGLGLES2:
      return true;
    case kGLImplementationOSMesaGL:
    case kGLImplementationAppleGL:
      return false;
    case kGLImplementationMockGL:
      return false;
    default:
      NOTREACHED();
      return true;
  }
}

GLContext* GLContext::GetCurrent() {
  return current_context_.Pointer()->Get();
}

GLContext* GLContext::GetRealCurrent() {
  return current_real_context_.Pointer()->Get();
}

void GLContext::SetCurrent(GLSurface* surface) {
  current_context_.Pointer()->Set(surface ? this : NULL);
  GLSurface::SetCurrent(surface);
  // Leave the real GL api current so that unit tests work correctly.
  // TODO(sievers): Remove this, but needs all gpu_unittest classes
  // to create and make current a context.
  if (!surface && GetGLImplementation() != kGLImplementationMockGL) {
    SetGLApiToNoContext();
  }
}

GLStateRestorer* GLContext::GetGLStateRestorer() {
  return state_restorer_.get();
}

void GLContext::SetGLStateRestorer(GLStateRestorer* state_restorer) {
  state_restorer_ = make_scoped_ptr(state_restorer);
}

void GLContext::SetSwapInterval(int interval) {
  swap_interval_ = interval;
  OnSetSwapInterval(force_swap_interval_zero_ ? 0 : swap_interval_);
}

void GLContext::ForceSwapIntervalZero(bool force) {
  force_swap_interval_zero_ = force;
  OnSetSwapInterval(force_swap_interval_zero_ ? 0 : swap_interval_);
}

bool GLContext::WasAllocatedUsingRobustnessExtension() {
  return false;
}

bool GLContext::InitializeDynamicBindings() {
  DCHECK(IsCurrent(NULL));
  static bool initialized = false;
  if (initialized)
    return initialized;
  initialized = InitializeDynamicGLBindings(GetGLImplementation(), this);
  if (!initialized)
    LOG(ERROR) << "Could not initialize dynamic bindings.";
  return initialized;
}

void GLContext::SetupForVirtualization() {
  if (!virtual_gl_api_) {
    virtual_gl_api_.reset(new VirtualGLApi());
    virtual_gl_api_->Initialize(&g_driver_gl, this);
  }
}

bool GLContext::MakeVirtuallyCurrent(
    GLContext* virtual_context, GLSurface* surface) {
  DCHECK(virtual_gl_api_);
  if (!ForceGpuSwitchIfNeeded())
    return false;
  return virtual_gl_api_->MakeCurrent(virtual_context, surface);
}

void GLContext::OnReleaseVirtuallyCurrent(GLContext* virtual_context) {
  if (virtual_gl_api_)
    virtual_gl_api_->OnReleaseVirtuallyCurrent(virtual_context);
}

void GLContext::SetRealGLApi() {
  SetGLToRealGLApi();
}

GLContextReal::GLContextReal(GLShareGroup* share_group)
    : GLContext(share_group) {}

scoped_refptr<gfx::GPUTimingClient> GLContextReal::CreateGPUTimingClient() {
  if (!gpu_timing_) {
    gpu_timing_.reset(new gfx::GPUTiming(this));
  }
  return gpu_timing_->CreateGPUTimingClient();
}

GLContextReal::~GLContextReal() {}

void GLContextReal::SetCurrent(GLSurface* surface) {
  GLContext::SetCurrent(surface);
  current_real_context_.Pointer()->Set(surface ? this : NULL);
}

}  // namespace gfx
