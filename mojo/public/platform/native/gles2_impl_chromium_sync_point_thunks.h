// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_CHROMIUM_SYNC_POINT_THUNKS_H_
#define MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_CHROMIUM_SYNC_POINT_THUNKS_H_

#include <stddef.h>

#include "mojo/public/c/gles2/chromium_sync_point.h"

// Specifies the frozen API for the GLES2 CHROMIUM_sync_point extension.
#pragma pack(push, 8)
struct MojoGLES2ImplChromiumSyncPointThunks {
  size_t size;  // Should be set to sizeof(*this).

#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS) \
  ReturnType(*Function) PARAMETERS;
#include "mojo/public/c/gles2/gles2_call_visitor_chromium_sync_point_autogen.h"
#undef VISIT_GL_CALL
};
#pragma pack(pop)

// Intended to be called from the embedder to get the embedder's implementation
// of GLES2.
inline MojoGLES2ImplChromiumSyncPointThunks
MojoMakeGLES2ImplChromiumSyncPointThunks() {
  MojoGLES2ImplChromiumSyncPointThunks gles2_impl_chromium_sync_point_thunks = {
      sizeof(MojoGLES2ImplChromiumSyncPointThunks),
#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS) gl##Function,
#include "mojo/public/c/gles2/gles2_call_visitor_chromium_sync_point_autogen.h"
#undef VISIT_GL_CALL
  };

  return gles2_impl_chromium_sync_point_thunks;
}

// Use this type for the function found by dynamically discovering it in
// a DSO linked with mojo_system.
// The contents of |gles2_impl_chromium_sync_point_thunks| are copied.
typedef size_t (*MojoSetGLES2ImplChromiumSyncPointThunksFn)(
    const MojoGLES2ImplChromiumSyncPointThunks* thunks);

#endif  // MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_CHROMIUM_SYNC_POINT_THUNKS_H_
