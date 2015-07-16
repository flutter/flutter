// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_CHROMIUM_COPY_TEXTURE_THUNKS_H_
#define MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_CHROMIUM_COPY_TEXTURE_THUNKS_H_

#include <stddef.h>

#include "mojo/public/c/gles2/chromium_copy_texture.h"

// Specifies the frozen API for the GLES2 CHROMIUM_copy_texture extension.
#pragma pack(push, 8)
struct MojoGLES2ImplChromiumCopyTextureThunks {
  size_t size;  // Should be set to sizeof(*this).

#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS) \
  ReturnType(*Function) PARAMETERS;
#include "mojo/public/c/gles2/gles2_call_visitor_chromium_copy_texture_autogen.h"
#undef VISIT_GL_CALL
};
#pragma pack(pop)

// Intended to be called from the embedder to get the embedder's implementation
// of GLES2.
inline MojoGLES2ImplChromiumCopyTextureThunks
MojoMakeGLES2ImplChromiumCopyTextureThunks() {
  MojoGLES2ImplChromiumCopyTextureThunks gles2_impl_chromium_copy_texture_thunks = {
      sizeof(MojoGLES2ImplChromiumCopyTextureThunks),
#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS) gl##Function,
#include "mojo/public/c/gles2/gles2_call_visitor_chromium_copy_texture_autogen.h"
#undef VISIT_GL_CALL
  };

  return gles2_impl_chromium_copy_texture_thunks;
}

// Use this type for the function found by dynamically discovering it in
// a DSO linked with mojo_system.
// The contents of |gles2_impl_chromium_copy_texture_thunks| are copied.
typedef size_t (*MojoSetGLES2ImplChromiumCopyTextureThunksFn)(
    const MojoGLES2ImplChromiumCopyTextureThunks* thunks);

#endif  // MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_CHROMIUM_COPY_TEXTURE_THUNKS_H_
