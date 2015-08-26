// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/gles2_interface.h"
#include "mojo/gles2/control_thunks_impl.h"
#include "mojo/public/c/gles2/gles2.h"
#include "mojo/public/c/gpu/MGL/mgl.h"

extern "C" {

MojoGLES2Context MojoGLES2CreateContext(MojoHandle handle,
                                        MojoGLES2ContextLost lost_callback,
                                        void* closure,
                                        const MojoAsyncWaiter* async_waiter) {
  MGLContext context = gles2::ControlThunksImpl::Get()->CreateContext(
      MGL_API_VERSION_GLES2,  // version
      handle,                 // command_buffer_handle
      MGL_NO_CONTEXT,         // share_group
      static_cast<MGLContextLostCallback>(lost_callback), closure,
      async_waiter);
  return reinterpret_cast<MojoGLES2Context>(context);
}

void MojoGLES2DestroyContext(MojoGLES2Context context) {
  gles2::ControlThunksImpl::Get()->DestroyContext(
      reinterpret_cast<MGLContext>(context));
}

void MojoGLES2MakeCurrent(MojoGLES2Context context) {
  gles2::ControlThunksImpl::Get()->MakeCurrent(
      reinterpret_cast<MGLContext>(context));
}

void MojoGLES2SwapBuffers() {
  gles2::ControlThunksImpl::Get()->SwapBuffers();
}

void* MojoGLES2GetGLES2Interface(MojoGLES2Context context) {
  return gles2::ControlThunksImpl::Get()->GetGLES2Interface(context);
}

void MojoGLES2SignalSyncPoint(MojoGLES2Context context,
                              uint32_t sync_point,
                              MojoGLES2SignalSyncPointCallback callback,
                              void* closure) {
  gles2::ControlThunksImpl::Get()->SignalSyncPoint(context, sync_point,
                                                   callback, closure);
}

#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS)             \
  ReturnType GL_APIENTRY gl##Function PARAMETERS {                             \
    auto interface = gles2::ControlThunksImpl::Get()->CurrentGLES2Interface(); \
    DCHECK(interface);                                                         \
    return interface->Function ARGUMENTS;                                      \
  }
#include "mojo/public/platform/native/gles2/call_visitor_autogen.h"
#include "mojo/public/platform/native/gles2/call_visitor_chromium_bind_uniform_location_autogen.h"
#include "mojo/public/platform/native/gles2/call_visitor_chromium_map_sub_autogen.h"
#include "mojo/public/platform/native/gles2/call_visitor_chromium_miscellaneous_autogen.h"
#include "mojo/public/platform/native/gles2/call_visitor_chromium_resize_autogen.h"
#include "mojo/public/platform/native/gles2/call_visitor_chromium_sync_point_autogen.h"
#include "mojo/public/platform/native/gles2/call_visitor_chromium_texture_mailbox_autogen.h"
#include "mojo/public/platform/native/gles2/call_visitor_ext_debug_marker_autogen.h"
#include "mojo/public/platform/native/gles2/call_visitor_occlusion_query_ext_autogen.h"
#include "mojo/public/platform/native/gles2/call_visitor_oes_vertex_array_object_autogen.h"
#undef VISIT_GL_CALL

}  // extern "C"
