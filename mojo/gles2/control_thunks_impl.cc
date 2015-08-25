// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/gles2/control_thunks_impl.h"

#include "mojo/gles2/gles2_context.h"
#include "mojo/public/cpp/system/message_pipe.h"

namespace gles2 {

// static
ControlThunksImpl* ControlThunksImpl::Get() {
  static base::LazyInstance<ControlThunksImpl>::Leaky thunks;
  return thunks.Pointer();
}

MGLContext ControlThunksImpl::CreateContext(
    MGLOpenGLAPIVersion version,
    MojoHandle command_buffer_handle,
    MGLContext share_group,
    MGLContextLostCallback lost_callback,
    void* lost_callback_closure,
    const struct MojoAsyncWaiter* async_waiter) {
  mojo::MessagePipeHandle mph(command_buffer_handle);
  mojo::ScopedMessagePipeHandle scoped_handle(mph);
  scoped_ptr<GLES2Context> client(
      new GLES2Context(async_waiter, scoped_handle.Pass(), lost_callback,
                       lost_callback_closure));
  if (!client->Initialize())
    client.reset();
  return client.release();
}

void ControlThunksImpl::DestroyContext(MGLContext context) {
  delete static_cast<GLES2Context*>(context);
}

void ControlThunksImpl::MakeCurrent(MGLContext context) {
  current_context_tls_.Set(static_cast<GLES2Context*>(context));
}

MGLContext ControlThunksImpl::GetCurrentContext() {
  return current_context_tls_.Get();
}

void ControlThunksImpl::ResizeSurface(uint32_t width, uint32_t height) {
  current_context_tls_.Get()->interface()->ResizeCHROMIUM(width, height, 1.f);
}

void ControlThunksImpl::SwapBuffers() {
  current_context_tls_.Get()->interface()->SwapBuffers();
}

void* ControlThunksImpl::GetGLES2Interface(MojoGLES2Context context) {
  GLES2Context* client = reinterpret_cast<GLES2Context*>(context);
  DCHECK(client);
  return client->interface();
}

void ControlThunksImpl::SignalSyncPoint(
    MojoGLES2Context context,
    uint32_t sync_point,
    MojoGLES2SignalSyncPointCallback callback,
    void* closure) {
  current_context_tls_.Get()->context_support()->SignalSyncPoint(
      sync_point, base::Bind(callback, closure));
}

gpu::gles2::GLES2Interface* ControlThunksImpl::CurrentGLES2Interface() {
  if (!current_context_tls_.Get())
    return nullptr;
  return current_context_tls_.Get()->interface();
}

ControlThunksImpl::ControlThunksImpl() {
}

ControlThunksImpl::~ControlThunksImpl() {
}

}  // namespace gles2
