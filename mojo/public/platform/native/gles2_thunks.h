// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_THUNKS_H_
#define MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_THUNKS_H_

#include <stddef.h>

#include "mojo/public/c/gles2/gles2.h"

// Structure used to bind the interface which manipulates GLES2 surfaces to a
// DSO to theose of the embedder.
//
// This is the ABI between the embedder and the DSO. It can only have new
// functions added to the end. No other changes are supported.
#pragma pack(push, 8)
struct MojoGLES2ControlThunks {
  size_t size;  // Should be set to sizeof(MojoGLES2ControlThunks).

  MojoGLES2Context (*GLES2CreateContext)(MojoHandle handle,
                                         MojoGLES2ContextLost lost_callback,
                                         void* closure,
                                         const MojoAsyncWaiter* async_waiter);
  void (*GLES2DestroyContext)(MojoGLES2Context context);
  void (*GLES2MakeCurrent)(MojoGLES2Context context);
  void (*GLES2SwapBuffers)();

  // TODO(piman): We shouldn't have to leak these 2 interfaces, especially in a
  // type-unsafe way.
  void* (*GLES2GetGLES2Interface)(MojoGLES2Context context);
  void* (*GLES2GetContextSupport)(MojoGLES2Context context);

  void (*GLES2SignalSyncPoint)(MojoGLES2Context context,
                               uint32_t sync_point,
                               MojoGLES2SignalSyncPointCallback callback,
                               void* closure);
};
#pragma pack(pop)

// Intended to be called from the embedder. Returns an object initialized to
// contain pointers to each of the embedder's MojoGLES2ControlThunks functions.
inline MojoGLES2ControlThunks MojoMakeGLES2ControlThunks() {
  MojoGLES2ControlThunks gles2_control_thunks = {
      sizeof(MojoGLES2ControlThunks),
      MojoGLES2CreateContext,
      MojoGLES2DestroyContext,
      MojoGLES2MakeCurrent,
      MojoGLES2SwapBuffers,
      MojoGLES2GetGLES2Interface,
      MojoGLES2GetContextSupport,
      MojoGLES2SignalSyncPoint,
  };

  return gles2_control_thunks;
}

// Use this type for the function found by dynamically discovering it in
// a DSO linked with mojo_system. For example:
// MojoSetGLES2ControlThunksFn mojo_set_gles2_control_thunks_fn =
//     reinterpret_cast<MojoSetGLES2ControlThunksFn>(
//         app_library.GetFunctionPointer("MojoSetGLES2ControlThunks"));
// The expected size of |gles2_control_thunks| is returned.
// The contents of |gles2_control_thunks| are copied.
typedef size_t (*MojoSetGLES2ControlThunksFn)(
    const MojoGLES2ControlThunks* gles2_control_thunks);

#endif  // MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_THUNKS_H_
