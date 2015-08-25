// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_GLES2_CONTROL_THUNKS_IMPL_H_
#define MOJO_GLES2_CONTROL_THUNKS_IMPL_H_

#include "base/lazy_instance.h"
#include "base/macros.h"
#include "base/threading/thread_local.h"
#include "gpu/GLES2/gl2extchromium.h"
#include "mojo/gles2/gles2_context.h"
#include "mojo/public/c/gles2/gles2.h"
#include "mojo/public/c/gpu/MGL/mgl.h"

namespace gpu {
namespace gles2 {
class GLES2Interface;
}
}

namespace gles2 {

// ControlThunksImpl is a singleton class that implements the MGL and MojoGLES2
// control functions. The class maintains a lazily allocated TLS slot on each
// thread for the current GL context.
class ControlThunksImpl {
 public:
  static ControlThunksImpl* Get();

  MGLContext CreateContext(MGLOpenGLAPIVersion version,
                           MojoHandle command_buffer_handle,
                           MGLContext share_group,
                           MGLContextLostCallback lost_callback,
                           void* lost_callback_closure,
                           const struct MojoAsyncWaiter* async_waiter);

  void DestroyContext(MGLContext context);

  void MakeCurrent(MGLContext context);

  MGLContext GetCurrentContext();

  void ResizeSurface(uint32_t width, uint32_t height);

  void SwapBuffers();

  void* GetGLES2Interface(MojoGLES2Context context);

  void SignalSyncPoint(MojoGLES2Context context,
                       uint32_t sync_point,
                       MojoGLES2SignalSyncPointCallback callback,
                       void* closure);

  gpu::gles2::GLES2Interface* CurrentGLES2Interface();

 private:
  friend base::DefaultLazyInstanceTraits<gles2::ControlThunksImpl>;
  ControlThunksImpl();
  ~ControlThunksImpl();

  base::ThreadLocalPointer<GLES2Context> current_context_tls_;

  DISALLOW_COPY_AND_ASSIGN(ControlThunksImpl);
};

}  // namespace gles2

#endif  // MOJO_GLES2_CONTROL_THUNKS_IMPL_H_
