// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file implements the MGL and MGL onscreen entry points exposed to the
// Mojo application by the shell.

#include "mojo/gles2/control_thunks_impl.h"
#include "mojo/public/c/gles2/gles2.h"
#include "mojo/public/c/gpu/MGL/mgl.h"
#include "mojo/public/c/gpu/MGL/mgl_onscreen.h"

extern "C" {

MGLContext MGLCreateContext(MGLOpenGLAPIVersion version,
                            MojoHandle command_buffer_handle,
                            MGLContext share_group,
                            MGLContextLostCallback lost_callback,
                            void* lost_callback_closure,
                            const struct MojoAsyncWaiter* async_waiter) {
  return gles2::ControlThunksImpl::Get()->CreateContext(
      version, command_buffer_handle, share_group, lost_callback,
      lost_callback_closure, async_waiter);
}

void MGLDestroyContext(MGLContext context) {
  return gles2::ControlThunksImpl::Get()->DestroyContext(context);
}

void MGLMakeCurrent(MGLContext context) {
  return gles2::ControlThunksImpl::Get()->MakeCurrent(context);
}

MGLContext MGLGetCurrentContext() {
  return gles2::ControlThunksImpl::Get()->GetCurrentContext();
}

void MGLResizeSurface(uint32_t width, uint32_t height) {
  return gles2::ControlThunksImpl::Get()->ResizeSurface(width, height);
}

void MGLSwapBuffers() {
  return gles2::ControlThunksImpl::Get()->SwapBuffers();
}

}  // extern "C"
