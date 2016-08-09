// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/gpu/gl_context.h"

#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/interfaces/application/application_connector.mojom.h"
#include "mojo/services/gpu/interfaces/gpu.mojom.h"

namespace mojo {

GLContext::GLContext(InterfaceHandle<CommandBuffer> command_buffer)
    : mgl_context_(
          MGLCreateContext(MGL_API_VERSION_GLES2,
                           command_buffer.PassHandle().release().value(),
                           MGL_NO_CONTEXT,
                           &ContextLostThunk,
                           this,
                           Environment::GetDefaultAsyncWaiter())) {
  DCHECK(mgl_context_ != MGL_NO_CONTEXT);
}

GLContext::~GLContext() {
  MGLDestroyContext(mgl_context_);
}

scoped_refptr<GLContext> GLContext::CreateOffscreen(
    ApplicationConnector* connector) {
  ServiceProviderPtr native_viewport;
  connector->ConnectToApplication("mojo:native_viewport_service",
                                  GetProxy(&native_viewport));
  GpuPtr gpu_service;
  ConnectToService(native_viewport.get(), GetProxy(&gpu_service));
  InterfaceHandle<CommandBuffer> command_buffer;
  gpu_service->CreateOffscreenGLES2Context(GetProxy(&command_buffer));
  return new GLContext(command_buffer.Pass());
}

scoped_refptr<GLContext> GLContext::CreateFromCommandBuffer(
    InterfaceHandle<CommandBuffer> command_buffer) {
  return new GLContext(command_buffer.Pass());
}

bool GLContext::IsCurrent() const {
  return mgl_context_ == MGLGetCurrentContext();
}

void GLContext::AddObserver(Observer* observer) {
  DCHECK(observer);
  observers_.AddObserver(observer);
}

void GLContext::RemoveObserver(Observer* observer) {
  DCHECK(observer);
  observers_.RemoveObserver(observer);
}

void GLContext::ContextLostThunk(void* self) {
  static_cast<GLContext*>(self)->OnContextLost();
}

void GLContext::OnContextLost() {
  DCHECK(!lost_);

  lost_ = true;
  FOR_EACH_OBSERVER(Observer, observers_, OnContextLost());
}

GLContext::Scope::Scope(const scoped_refptr<GLContext>& gl_context)
    : gl_context_(gl_context), prior_mgl_context_(MGLGetCurrentContext()) {
  DCHECK(gl_context_);
  CHECK(!gl_context_->is_lost());  // common bug, check it in release builds

  MGLMakeCurrent(gl_context_->mgl_context_);
}

GLContext::Scope::~Scope() {
  DCHECK(gl_context_->IsCurrent());

  MGLMakeCurrent(prior_mgl_context_);
}

GLContext::Observer::~Observer() {}

}  // namespace mojo
