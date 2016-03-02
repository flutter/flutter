// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/gpu/gl_context.h"

#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/interfaces/application/application_connector.mojom.h"
#include "mojo/services/gpu/interfaces/gpu.mojom.h"

namespace mojo {

GLContext::Observer::~Observer() {}

GLContext::GLContext(InterfaceHandle<CommandBuffer> command_buffer)
    : weak_factory_(this) {
  context_ = MGLCreateContext(MGL_API_VERSION_GLES2,
                              command_buffer.PassHandle().release().value(),
                              MGL_NO_CONTEXT, &ContextLostThunk, this,
                              Environment::GetDefaultAsyncWaiter());
  DCHECK(context_ != MGL_NO_CONTEXT);
}

GLContext::~GLContext() {
  MGLDestroyContext(context_);
}

base::WeakPtr<GLContext> GLContext::CreateOffscreen(
    ApplicationConnector* connector) {
  ServiceProviderPtr native_viewport;
  connector->ConnectToApplication("mojo:native_viewport_service",
                                  GetProxy(&native_viewport), nullptr);
  GpuPtr gpu_service;
  ConnectToService(native_viewport.get(), &gpu_service);
  InterfaceHandle<CommandBuffer> command_buffer;
  gpu_service->CreateOffscreenGLES2Context(GetProxy(&command_buffer));
  return CreateFromCommandBuffer(command_buffer.Pass());
}

base::WeakPtr<GLContext> GLContext::CreateFromCommandBuffer(
    InterfaceHandle<CommandBuffer> command_buffer) {
  return (new GLContext(command_buffer.Pass()))->weak_factory_.GetWeakPtr();
}

void GLContext::MakeCurrent() {
  MGLMakeCurrent(context_);
}

bool GLContext::IsCurrent() {
  return context_ == MGLGetCurrentContext();
}

void GLContext::Destroy() {
  delete this;
}

void GLContext::AddObserver(Observer* observer) {
  observers_.AddObserver(observer);
}

void GLContext::RemoveObserver(Observer* observer) {
  observers_.RemoveObserver(observer);
}

void GLContext::ContextLostThunk(void* self) {
  static_cast<GLContext*>(self)->OnContextLost();
}

void GLContext::OnContextLost() {
  FOR_EACH_OBSERVER(Observer, observers_, OnContextLost());
}

}  // namespace mojo
