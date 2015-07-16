// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_C_GLES2_GLES2_H_
#define MOJO_PUBLIC_C_GLES2_GLES2_H_

// Note: This header should be compilable as C.

#include <stdint.h>
#include <GLES2/gl2.h>

#include "mojo/public/c/environment/async_waiter.h"
#include "mojo/public/c/gles2/gles2_export.h"
#include "mojo/public/c/gles2/gles2_types.h"
#include "mojo/public/c/system/types.h"

#ifdef __cplusplus
extern "C" {
#endif

MOJO_GLES2_EXPORT MojoGLES2Context
    MojoGLES2CreateContext(MojoHandle handle,
                           MojoGLES2ContextLost lost_callback,
                           void* closure,
                           const MojoAsyncWaiter* async_waiter);
MOJO_GLES2_EXPORT void MojoGLES2DestroyContext(MojoGLES2Context context);
MOJO_GLES2_EXPORT void MojoGLES2MakeCurrent(MojoGLES2Context context);
MOJO_GLES2_EXPORT void MojoGLES2SwapBuffers(void);
MOJO_GLES2_EXPORT void MojoGLES2SignalSyncPoint(
    MojoGLES2Context context,
    uint32_t sync_point,
    MojoGLES2SignalSyncPointCallback callback,
    void* closure);

// TODO(piman): We shouldn't have to leak those 2 interfaces, especially in a
// type-unsafe way.
MOJO_GLES2_EXPORT void* MojoGLES2GetGLES2Interface(MojoGLES2Context context);
MOJO_GLES2_EXPORT void* MojoGLES2GetContextSupport(MojoGLES2Context context);

#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS) \
  MOJO_GLES2_EXPORT ReturnType GL_APIENTRY gl##Function PARAMETERS;
#include "mojo/public/c/gles2/gles2_call_visitor_autogen.h"
#undef VISIT_GL_CALL

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // MOJO_PUBLIC_C_GLES2_GLES2_H_
