// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_OCCLUSION_QUERY_EXT_THUNKS_H_
#define MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_OCCLUSION_QUERY_EXT_THUNKS_H_

#include <stddef.h>

#include "mojo/public/c/gles2/occlusion_query_ext.h"

// Specifies the frozen API for the Occlusion Query Extension.
#pragma pack(push, 8)
struct MojoGLES2ImplOcclusionQueryExtThunks {
  size_t size;  // Should be set to sizeof(*this).

#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS) \
  ReturnType(*Function) PARAMETERS;
#include "mojo/public/c/gles2/gles2_call_visitor_occlusion_query_ext_autogen.h"
#undef VISIT_GL_CALL
};
#pragma pack(pop)

// Intended to be called from the embedder to get the embedder's implementation
// of GLES2.
inline MojoGLES2ImplOcclusionQueryExtThunks
MojoMakeGLES2ImplOcclusionQueryExtThunks() {
  MojoGLES2ImplOcclusionQueryExtThunks gles2_impl_occlusion_query_ext_thunks = {
      sizeof(MojoGLES2ImplOcclusionQueryExtThunks),
#define VISIT_GL_CALL(Function, ReturnType, PARAMETERS, ARGUMENTS) gl##Function,
#include "mojo/public/c/gles2/gles2_call_visitor_occlusion_query_ext_autogen.h"
#undef VISIT_GL_CALL
  };

  return gles2_impl_occlusion_query_ext_thunks;
}

// Use this type for the function found by dynamically discovering it in
// a DSO linked with mojo_system.
// The contents of |gles2_impl_occlusion_query_ext_thunks| are copied.
typedef size_t (*MojoSetGLES2ImplOcclusionQueryExtThunksFn)(
    const MojoGLES2ImplOcclusionQueryExtThunks* thunks);

#endif  // MOJO_PUBLIC_PLATFORM_NATIVE_GLES2_IMPL_CHROMIUM_SYNC_POINT_THUNKS_H_
